//
//  NerualAnalyzerLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/NerualAnalyzerLayer.h>
#import <CoreML/CoreML.h>
#import <CamPresentation/MLModelAsset+Category.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <Vision/Vision.h>
#import <Accelerate/Accelerate.h>
#include <ranges>
#import <CamPresentation/VNRequest+Category.h>
#import <CamPresentation/BoundingBoxLayer.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <os/lock.h>

__attribute__((objc_direct_members))
@interface NerualAnalyzerLayer () {
    os_unfair_lock _lock;
}
@property (retain, nonatomic, nullable) MLModel *_model;
@property (retain, nonatomic, nullable) VNCoreMLRequest *_vnRequest;
@property (retain, nonatomic, readonly) SVRunLoop *_runLoop;
@property (retain, nonatomic, readonly) CATextLayer *_textLayer;
@property (retain, nonatomic, readonly) BoundingBoxLayer *_boundingBoxLayer;
@property (assign, nonatomic) CGSize _pixelBufferSize;
@end

@implementation NerualAnalyzerLayer

- (instancetype)init {
    if (self = [super init]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    if (![layer isKindOfClass:[NerualAnalyzerLayer class]]) {
        [self release];
        self = nil;
        return nil;
    }
    
    auto casted = static_cast<NerualAnalyzerLayer *>(layer);
    
    if (self = [super initWithLayer:casted]) {
        self.modelType = casted.modelType;
        _lock = casted->_lock;
        __runLoop = [casted->__runLoop retain];
        __textLayer = [[CATextLayer alloc] initWithLayer:casted->__textLayer];
        
        [self addSublayer:__textLayer];
    }
    
    return self;
}

- (void)dealloc {
    [__model release];
    [__vnRequest release];
    [__runLoop release];
    [__textLayer release];
    [__boundingBoxLayer release];
    [super dealloc];
}

- (void)setContentsScale:(CGFloat)contentsScale {
    [super setContentsScale:contentsScale];
    __textLayer.contentsScale = contentsScale;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self _layoutSublayers];
}

- (void)drawInContext:(CGContextRef)ctx {
    os_unfair_lock_lock(&_lock);
    [super drawInContext:ctx];
    os_unfair_lock_unlock(&_lock);
}

- (void)_commonInit {
    _lock = OS_UNFAIR_LOCK_INIT;
    __runLoop = [[SVRunLoop alloc] initWithThreadName:@"NerualAnalyzerLayer"];
    
    CATextLayer *textLayer = [CATextLayer new];
    
    CGColorRef backgroundColor = CGColorCreateSRGB(0.0, 0.0, 0.0, 0.5);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    CGColorRef foregroundColor = CGColorCreateSRGB(1.0, 1.0, 1.0, 1.0);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    textLayer.fontSize = 17.;
    textLayer.alignmentMode = kCAAlignmentCenter;
    
    __textLayer = textLayer;
    [self addSublayer:textLayer];
    
    BoundingBoxLayer *boundingBoxLayer = [BoundingBoxLayer new];
    CGColorRef strokeColor = CGColorCreateSRGB(1., 0., 0., 1.);
    boundingBoxLayer.strokeColor = strokeColor;
    CGColorRelease(strokeColor);
    boundingBoxLayer.strokeWidth = 10.;
    __boundingBoxLayer = boundingBoxLayer;
    [self addSublayer:boundingBoxLayer];
    
    [self _layoutSublayers];
}

- (std::optional<NerualAnalyzerModelType>)modelType {
    MLModel * _Nullable model = __model;
    if (model == nil) {
        return std::nullopt;
    }
    
    NSString *modelDisplayName = model.configuration.modelDisplayName;
    NerualAnalyzerModelType modelType = NerualAnalyzerModelTypeFromNSString(modelDisplayName);
    
    return modelType;
}

- (void)setModelType:(std::optional<NerualAnalyzerModelType>)modelType {
    if (auto ptr = modelType) {
        NerualAnalyzerModelType modelType = *ptr;
        
        MLModelConfiguration *configuration = [MLModelConfiguration new];
        configuration.modelDisplayName = NSStringFromNerualAnalyzerModelType(modelType);
        configuration.allowLowPrecisionAccumulationOnGPU = NO;
        configuration.computeUnits = MLComputeUnitsAll;
        
        MLOptimizationHints * optimizationHints = [MLOptimizationHints new];
        optimizationHints.reshapeFrequency = MLReshapeFrequencyHintFrequent;
        optimizationHints.specializationStrategy = MLSpecializationStrategyFastPrediction;
        
        configuration.optimizationHints = optimizationHints;
        [optimizationHints release];
        
        NSError * _Nullable error = nil;
        MLModelAsset *modelAsset = [MLModelAsset cp_modelAssetWithModelType:modelType error:&error];
        assert(error == nil);
        
        MLModel *model = reinterpret_cast<id (*)(id, SEL, id, id *)>(objc_msgSend)(modelAsset, sel_registerName("modelWithConfiguration:error:"), configuration, &error);
        [configuration release];
        assert(error == nil);
        
        self._model = model;
        
        
        VNCoreMLModel *visionModel = [VNCoreMLModel modelForMLModel:model error:&error];
        assert(error == nil);
        
        CATextLayer *textLayer = __textLayer;
        BoundingBoxLayer *boundingBoxLayer = __boundingBoxLayer;
        SVRunLoop *runLoop = __runLoop;
        
        VNCoreMLRequest *vnRequest = [[VNCoreMLRequest alloc] initWithModel:visionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            __kindof VNObservation *maxObservation = nil;
            for (__kindof VNObservation *result in request.results) {
                if (maxObservation == nil) {
                    maxObservation = result;
                    continue;
                }
                
                if (maxObservation.confidence < result.confidence) {
                    maxObservation = result;
                    continue;
                }
            }
            
            if ([maxObservation isKindOfClass:[VNClassificationObservation class]]) {
                [runLoop runBlock:^{
                    os_unfair_lock_lock(&_lock);
                    
                    boundingBoxLayer.hidden = YES;
                    boundingBoxLayer.boundingBox = CGRectNull;
                    textLayer.hidden = NO;
                    textLayer.string = static_cast<VNClassificationObservation *>(maxObservation).identifier;
                    
                    os_unfair_lock_unlock(&_lock);
                }];
            } else if ([maxObservation isKindOfClass:[VNRecognizedObjectObservation class]]) {
                auto casted = static_cast<VNRecognizedObjectObservation *>(maxObservation);
                CGRect boundingBox = casted.boundingBox;
                
                [runLoop runBlock:^{
                    os_unfair_lock_lock(&_lock);
                    boundingBoxLayer.hidden = NO;
                    
                    CGRect bounds = AVMakeRectWithAspectRatioInsideRect(self._pixelBufferSize, boundingBoxLayer.bounds);
                    
                    boundingBoxLayer.boundingBox = CGRectMake(CGRectGetMinX(bounds) + CGRectGetWidth(bounds) * CGRectGetMinX(boundingBox),
                                                              CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * (1. - CGRectGetMaxY(boundingBox)),
                                                              CGRectGetWidth(bounds) * CGRectGetWidth(boundingBox),
                                                              CGRectGetHeight(bounds) * CGRectGetHeight(boundingBox));
                    
                    textLayer.hidden = YES;
                    textLayer.string = nil;
                    
                    os_unfair_lock_unlock(&_lock);
                }];
            } else {
                [runLoop runBlock:^{
                    os_unfair_lock_lock(&_lock);
                    
                    boundingBoxLayer.hidden = YES;
                    boundingBoxLayer.boundingBox = CGRectNull;
                    textLayer.hidden = YES;
                    textLayer.string = nil;
                    
                    os_unfair_lock_unlock(&_lock);
                }];
            }
        }];
//        vnRequest.preferBackgroundProcessing = YES;
//        vnRequest.cp_processAsynchronously = YES;
        
        self._vnRequest = vnRequest;
        [vnRequest release];
    } else {
        self._model = nil;
    }
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    self._pixelBufferSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    
//    MLFeatureValue *featureValue = [MLFeatureValue featureValueWithPixelBuffer:pixelBuffer];
//    NSError * _Nullable error = nil;
//    MLDictionaryFeatureProvider *inputProvider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:@{@"image": featureValue} error:&error];
//    assert(error == nil);
//    MLModel *model = __model;
//    CATextLayer *textLayer = __textLayer;
//    
//    [__runLoop runBlock:^{
//        NSError * _Nullable error = nil;
//        id<MLFeatureProvider> outputProvider = [model predictionFromFeatures:inputProvider error:&error];
//        assert(error == nil);
//        NSString *target = [outputProvider featureValueForName:@"target"].stringValue;
//        assert(target != nil);
//        NSDictionary<NSString *, NSNumber *> *targetProbability = [outputProvider featureValueForName:@"targetProbability"].dictionaryValue;
//        assert(targetProbability != nil);
//        
//        textLayer.string = [NSString stringWithFormat:@"%@\n%@", target, targetProbability];
////        [self setNeedsDisplay];
//    }];
//    
//    [inputProvider release];
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer options:@{}];
    NSError * _Nullable error = nil;
    [handler performRequests:@[self._vnRequest] error:&error];
    assert(error == nil);
    [handler release];
    
    [pool release];
}

- (void)_layoutSublayers __attribute__((objc_direct)) {
    CATextLayer *textLayer = __textLayer;
    
    CGRect frame = self.bounds;
    frame = CGRectInset(frame, 5., 5.);
//    frame.size.height /= 3.;
    frame.size.height = 27.;
    
    textLayer.frame = frame;
    
    BoundingBoxLayer *boundingBoxLayer = __boundingBoxLayer;
    boundingBoxLayer.frame = self.bounds;
}

@end
