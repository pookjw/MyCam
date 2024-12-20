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

__attribute__((objc_direct_members))
@interface NerualAnalyzerLayer ()
@property (retain, nonatomic, nullable) MLModel *_model;
@property (retain, nonatomic, nullable) VNCoreMLRequest *_vnRequest;
@property (retain, nonatomic, readonly) SVRunLoop *_runLoop;
@property (retain, nonatomic, readonly) CATextLayer *_textLayer;
@end

@implementation NerualAnalyzerLayer

- (instancetype)init {
    if (self = [super init]) {
        
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
        
        [self _layoutTextLayer];
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
    [super dealloc];
}

- (void)setContentsScale:(CGFloat)contentsScale {
    [super setContentsScale:contentsScale];
    __textLayer.contentsScale = contentsScale;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self _layoutTextLayer];
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
        SVRunLoop *runLoop = __runLoop;
        
        VNCoreMLRequest *vnRequest = [[VNCoreMLRequest alloc] initWithModel:visionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            __kindof VNObservation *maxObs = nil;
            for (__kindof VNObservation *result in request.results) {
                if (maxObs == nil) {
                    maxObs = result;
                    continue;
                }
                
                if (maxObs.confidence < result.confidence) {
                    maxObs = result;
                    continue;
                }
            }
            
            [runLoop runBlock:^{
                textLayer.string = static_cast<VNClassificationObservation *>(maxObs).identifier;
            }];
        }];
//        vnRequest.preferBackgroundProcessing = YES;
        vnRequest.cp_processAsynchronously = YES;
        
        self._vnRequest = vnRequest;
        [vnRequest release];
    } else {
        self._model = nil;
    }
}

- (void)updateWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
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

- (void)_layoutTextLayer __attribute__((objc_direct)) {
    CATextLayer *textLayer = __textLayer;
    
    CGRect frame = self.bounds;
    frame = CGRectInset(frame, 5., 5.);
//    frame.size.height /= 3.;
    frame.size.height = 27.;
    
    textLayer.frame = frame;
}

@end
