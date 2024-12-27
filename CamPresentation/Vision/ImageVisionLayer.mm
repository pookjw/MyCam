//
//  ImageVisionLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/ImageVisionLayer.h>
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#include <ranges>
#include <vector>
#include <optional>
#include <algorithm>
#include <utility>
#include <string>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreImage/CoreImage.h>
#import <Metal/Metal.h>
#import <CoreImage/CIFilterBuiltins.h>
#import <os/lock.h>
#include <iostream>
#include <random>

OBJC_EXPORT void objc_setProperty_atomic(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);
OBJC_EXPORT void objc_setProperty_atomic_copy(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);

@interface ImageVisionLayer () {
    os_unfair_lock _lock;
}
@property (retain, nonatomic, readonly) CIContext *_ciContext;
@end

@implementation ImageVisionLayer

+ (NSString *)_stringFromFeaturePrintObservation:(VNFeaturePrintObservation *)featurePrintObservation {
    NSString *elementTypeString;
    NSString *dataString;
    
    VNElementType elementType = featurePrintObservation.elementType;
    switch (elementType) {
        case VNElementTypeFloat: {
            elementTypeString = @"Float";
            auto values = reinterpret_cast<const float *>(featurePrintObservation.data.bytes);
            
            NSMutableArray<NSString *> *array = [[NSMutableArray alloc] initWithCapacity:featurePrintObservation.elementCount];
            for (const float *value : std::ranges::views::iota(values, values + featurePrintObservation.elementCount)) {
                [array addObject:@(*value).stringValue];
            }
            dataString = [array componentsJoinedByString:@", "];
            [array release];
            break;
        }
        case VNElementTypeDouble: {
            elementTypeString = @"Double";
            auto values = reinterpret_cast<const double *>(featurePrintObservation.data.bytes);
            
            NSMutableArray<NSString *> *array = [[NSMutableArray alloc] initWithCapacity:featurePrintObservation.elementCount];
            for (const double *value : std::ranges::views::iota(values, values + featurePrintObservation.elementCount)) {
                [array addObject:@(*value).stringValue];
            }
            dataString = [array componentsJoinedByString:@", "];
            [array release];
            break;
        }
        default:
            abort();
    }
    
    return [NSString stringWithFormat:@"elementType: %@\ndata: %@", elementTypeString, dataString];
}

- (instancetype)init {
    if (self = [super init]) {
        id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        __ciContext = [[CIContext contextWithMTLDevice:mtlDevice] retain];
        [mtlDevice release];
        
        _shouldDrawImage = YES;
        _shouldDrawDetails = YES;
        _shouldDrawContoursSeparately = YES;
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:[ImageVisionLayer class]]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<ImageVisionLayer *>(layer);
        __ciContext = [casted->__ciContext retain];
        _image = [casted.image retain];
        _observations = [casted.observations copy];
        _shouldDrawImage = casted->_shouldDrawImage;
        _shouldDrawDetails = casted->_shouldDrawDetails;
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    
    return self;
}

- (void)dealloc {
    [__ciContext release];
    [_image release];
    [_observations release];
    [super dealloc];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setImage:(UIImage *)image {
#pragma clang diagnostic pop
    Ivar ivar = object_getInstanceVariable(self, "_image", NULL);
    assert(ivar);
    
    os_unfair_lock_lock(&_lock);
    objc_setProperty_atomic(self, _cmd, image, ivar_getOffset(ivar));
    os_unfair_lock_unlock(&_lock);
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setObservations:(NSArray<__kindof VNObservation *> *)observations {
#pragma clang diagnostic pop
    Ivar ivar = object_getInstanceVariable(self, "_observations", NULL);
    assert(ivar);
    
    os_unfair_lock_lock(&_lock);
    objc_setProperty_atomic(self, _cmd, observations, ivar_getOffset(ivar));
    os_unfair_lock_unlock(&_lock);
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setShouldDrawImage:(BOOL)shouldDrawImage {
#pragma clang diagnostic pop
    if (_shouldDrawImage == shouldDrawImage) return;
    
    os_unfair_lock_lock(&_lock);
    _shouldDrawImage = shouldDrawImage;
    os_unfair_lock_unlock(&_lock);
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setShouldDrawDetails:(BOOL)shouldDrawDetails {
#pragma clang diagnostic pop
    if (_shouldDrawDetails == shouldDrawDetails) return;
    
    os_unfair_lock_lock(&_lock);
    _shouldDrawDetails = shouldDrawDetails;
    os_unfair_lock_unlock(&_lock);
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setShouldDrawContoursSeparately:(BOOL)shouldDrawContoursSeparately {
#pragma clang diagnostic pop
    if (_shouldDrawContoursSeparately == shouldDrawContoursSeparately) return;
    
    os_unfair_lock_lock(&_lock);
    _shouldDrawContoursSeparately = shouldDrawContoursSeparately;
    os_unfair_lock_unlock(&_lock);
    
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    os_unfair_lock_lock(&_lock);
    
    UIImage *image = self.image;
    if (image == nil) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    
    CGRect aspectBounds = AVMakeRectWithAspectRatioInsideRect(image.size, self.bounds);
    
    if (self.shouldDrawImage) {
        UIGraphicsPushContext(ctx);
        [image drawInRect:AVMakeRectWithAspectRatioInsideRect(image.size, aspectBounds)];
        UIGraphicsPopContext();
    }
    
    NSMutableArray<VNClassificationObservation *> *classificationObservations = [NSMutableArray new];
    
    for (__kindof VNObservation *observation in self.observations) {
        if ([observation class] == [VNFaceObservation class]) {
            auto faceObservation = static_cast<VNFaceObservation *>(observation);
            [self _drawFaceObservation:faceObservation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNPixelBufferObservation class]) {
            auto pixelBufferObservation = static_cast<VNPixelBufferObservation *>(observation);
            id originatingRequestSpecifier = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(pixelBufferObservation, sel_registerName("originatingRequestSpecifier"));
            NSString *requestClassName = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(originatingRequestSpecifier, sel_registerName("requestClassName"));
            
            if ([requestClassName isEqualToString:NSStringFromClass([VNGeneratePersonSegmentationRequest class])]) {
                [self _drawPixelBufferObservation:pixelBufferObservation aspectBounds:aspectBounds maskImage:YES inContext:ctx];
            } else {
                abort();
            }
        } else if ([observation class] == [VNImageAestheticsScoresObservation class]) {
            auto imageAestheticsScoresObservation = static_cast<VNImageAestheticsScoresObservation *>(observation);
            [self _drawImageAestheticsScoresObservation:imageAestheticsScoresObservation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNClassificationObservation class]) {
            auto classificationObservation = static_cast<VNClassificationObservation *>(observation);
            [classificationObservations addObject:classificationObservation];
        } else if ([observation class] == objc_lookUpClass("VNImageAestheticsObservation")) {
            [self _drawImageAestheticsObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNAnimalObservation")) {
            [self _drawImageAnimalObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNDetectionprintObservation")) {
            [self _drawImageDetectionprintObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNImageFingerprintsObservation")) {
            [self _drawImageFingerprintsObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNImageprintObservation")) {
            [self _drawImageprintObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNImageNeuralHashprintObservation")) {
            [self _drawImageNeuralHashprintObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNSceneObservation")) {
            [self _drawSceneObservationObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == objc_lookUpClass("VNSmartCamObservation")) {
            [self _drawSceneSmartCamObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNHumanObservation class]) {
            [self _drawHumanObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNAnimalBodyPoseObservation class]) {
            [self _drawAnimalBodyPoseObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNRectangleObservation class]) {
            [self _drawRectangleObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNInstanceMaskObservation class]) {
            [self _drawInstanceMaskObservation:observation aspectBounds:aspectBounds maskImage:YES inContext:ctx];
        } else if ([observation class] == [VNBarcodeObservation class]) {
            [self _drawBarcodeObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation class] == [VNContoursObservation class]) {
            [self _drawContoursObservation:observation aspectBounds:aspectBounds inContext:ctx];
        } else {
            NSLog(@"%@", observation);
            abort();
        }
    }
    
    if (classificationObservations.count > 0) {
        [classificationObservations sortUsingComparator:^NSComparisonResult(VNClassificationObservation * _Nonnull obj1, VNClassificationObservation * _Nonnull obj2) {
            if (obj1.confidence == obj2.confidence) {
                return NSOrderedSame;
            } else if (obj1.confidence < obj2.confidence) {
                return NSOrderedDescending;
            } else {
                return NSOrderedAscending;
            }
        }];
        
        [self _drawClassificationObservations:classificationObservations frame:CGRectNull aspectBounds:aspectBounds inContext:ctx];
    }
    
    [classificationObservations release];
    
    os_unfair_lock_unlock(&_lock);
}

- (void)_drawDetectedObjectObservation:(VNDetectedObjectObservation *)detectedObjectObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx convertedBoundingBox:(CGRect * _Nullable)convertedBoundingBoxOut {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    CGContextSetRGBStrokeColor(ctx, 0., 1., 1., 1.);
    CGRect boundingBox = detectedObjectObservation.boundingBox;
    CGRect convertedBoundingBox = CGRectMake(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * CGRectGetMinX(boundingBox),
                                             CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds) * (1. - CGRectGetMinY(boundingBox) - CGRectGetHeight(boundingBox)),
                                             CGRectGetWidth(aspectBounds) * CGRectGetWidth(boundingBox),
                                             CGRectGetHeight(aspectBounds) * CGRectGetHeight(boundingBox));
    
    if (convertedBoundingBoxOut != NULL) {
        *convertedBoundingBoxOut = convertedBoundingBox;
    }
    
    CGContextStrokeRectWithWidth(ctx, convertedBoundingBox, 10.);
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawFaceObservation:(VNFaceObservation *)faceObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    CGRect convertedBoundingBox;
    [self _drawDetectedObjectObservation:faceObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:&convertedBoundingBox];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    __kindof VNFaceLandmarks *landmarks3d = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(faceObservation, sel_registerName("landmarks3d"));
    __kindof VNFaceLandmarkRegion *allPoints3d = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(landmarks3d, sel_registerName("allPoints"));
    
    if (allPoints3d != nil) {
        struct Point3D {
            float x, y, z;
        };
        
        NSUInteger pointCount = allPoints3d.pointCount;
        const Point3D *points = reinterpret_cast<const Point3D * (*)(id, SEL)>(objc_msgSend)(allPoints3d, sel_registerName("points"));
        
        for (const Point3D *point : std::ranges::views::iota(points, points + pointCount)) {
            NSLog(@"%lf %lf %lf", point->x, point->y, point->z);
        }
        
#warning TODO
    } else if (VNFaceLandmarkRegion2D *region = faceObservation.landmarks.allPoints) {
        NSUInteger pointCount = region.pointCount;
        
        const CGPoint *points = [region pointsInImageOfSize:aspectBounds.size];
        
        //
        
        NSArray<NSNumber*> *precisionEstimatesPerPoint = region.precisionEstimatesPerPoint;
        std::vector<float> precisionEstimatesPerPointVec {};
        
        if (!self.shouldDrawDetails) {
            // 0 부터 1 사이로 정규화
            if (precisionEstimatesPerPoint != nil and precisionEstimatesPerPoint.count > 0) {
                precisionEstimatesPerPointVec.reserve(precisionEstimatesPerPoint.count);
                
                std::optional<float> minValue = std::nullopt;
                std::optional<float> maxValue = std::nullopt;
                
                for (NSNumber *number in precisionEstimatesPerPoint) {
                    precisionEstimatesPerPointVec.push_back(number.floatValue);
                    
                    if (minValue.has_value()) {
                        minValue = std::min(minValue.value(), number.floatValue);
                    } else {
                        minValue = number.floatValue;
                    }
                    
                    if (maxValue.has_value()) {
                        maxValue = std::max(maxValue.value(), number.floatValue);
                    } else {
                        maxValue = number.floatValue;
                    }
                }
                
                assert(minValue.has_value());
                assert(maxValue.has_value());
                
                for (size_t idx : std::ranges::views::iota(0, (long long)precisionEstimatesPerPointVec.size())) {
                    if (minValue.value() != maxValue.value()) {
                        assert(minValue.value() < maxValue.value());
                        float value = precisionEstimatesPerPointVec[idx];
                        value = (value - minValue.value()) / (maxValue.value() - minValue.value());
                        precisionEstimatesPerPointVec[idx] = value;
                    } else {
                        precisionEstimatesPerPointVec[idx] = 1.f;
                    }
                }
            }
        }
        
        
        //
        
        for (NSUInteger idx : std::views::iota(0, (NSInteger)pointCount)) {
            const CGPoint point = points[idx];
            CGFloat precision;
            if (!self.shouldDrawDetails) {
                if (idx < precisionEstimatesPerPointVec.size()) {
                    precision = precisionEstimatesPerPointVec[idx];
                } else {
                    precision = 1.;
                }
            } else {
                precision = 1.;
            }
            
            CGContextSetRGBStrokeColor(ctx, 1., 0.5, 0.5, precision);
            
            CGContextStrokeRectWithWidth(ctx,
                                         CGRectMake(CGRectGetMinX(aspectBounds) + point.x - 3.,
                                                    CGRectGetMaxY(aspectBounds) - point.y - 3.,
                                                    1.,
                                                    1.),
                                         6.);
        }
    }
    
    //
    
    {
        CGContextSaveGState(ctx);
        
        BOOL isBlinking = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(faceObservation, sel_registerName("isBlinking"));
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = isBlinking ? @"😔" : @"😳";
        textLayer.wrapped = YES;
        textLayer.fontSize = 24.;
        textLayer.contentsScale = self.contentsScale;
        
        float blinkScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(faceObservation, sel_registerName("blinkScore"));
        CGColorRef backgroundColor = CGColorCreateSRGB(0., 1., 0., blinkScore);
        textLayer.backgroundColor = backgroundColor;
        CGColorRelease(backgroundColor);
        
        textLayer.frame = CGRectMake(0.,
                                     0.,
                                     30.,
                                     30.);
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(convertedBoundingBox),
                                                                         CGRectGetMinY(convertedBoundingBox) - 15.);
        
        CGContextConcatCTM(ctx, translation);
        
        [textLayer renderInContext:ctx];
        [textLayer release];
        
        CGContextRestoreGState(ctx);
    }
    
    //
    
    if (NSNumber *faceCaptureQuality = faceObservation.faceCaptureQuality) {
        CGContextSaveGState(ctx);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = [NSString stringWithFormat:@"Face Quality: %@", faceCaptureQuality];
        textLayer.wrapped = YES;
        textLayer.font = [UIFont systemFontOfSize:10.];
        textLayer.fontSize = 10.;
        textLayer.contentsScale = self.contentsScale;
        
        CGColorRef backgroundColor = CGColorCreateGenericGray(1., 1.);
        textLayer.backgroundColor = backgroundColor;
        CGColorRelease(backgroundColor);
        
        CGColorRef foregroundColor = CGColorCreateGenericGray(0., 1.);
        textLayer.foregroundColor = foregroundColor;
        CGColorRelease(foregroundColor);
        
        NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:textLayer.string attributes:@{
            NSFontAttributeName: (id)textLayer.font
        }];
        CGSize textSize = attributeString.size;
        [attributeString release];
        
        textLayer.frame = CGRectMake(0.,
                                     0.,
                                     textSize.width,
                                     textSize.height);
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMaxX(convertedBoundingBox) - textSize.width,
                                                                         CGRectGetMinY(convertedBoundingBox) - 5.);
        
        CGContextConcatCTM(ctx, translation);
        
        [textLayer renderInContext:ctx];
        [textLayer release];
        
        CGContextRestoreGState(ctx);
    }
    
    //
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawPixelBufferObservation:(VNPixelBufferObservation *)pixelBufferObservation aspectBounds:(CGRect)aspectBounds maskImage:(BOOL)maskImage inContext:(CGContextRef)ctx {
    if (maskImage) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        CGContextSaveGState(ctx);
        
        CIFilter<CIBlendWithMask> *blendWithMaskFilter = [CIFilter blendWithMaskFilter];
        
        //
        
        CIImage *inputCIImage = self.image.CIImage;
        if (inputCIImage == nil) {
            inputCIImage = [[[CIImage alloc] initWithCGImage:self.image.CGImage options:nil] autorelease];
        }
        blendWithMaskFilter.inputImage = inputCIImage;
        
        //
        
        CVPixelBufferRef maskPixelBuffer = pixelBufferObservation.pixelBuffer;
        CIImage *maskCIImage = [[CIImage alloc] initWithCVPixelBuffer:maskPixelBuffer options:nil];
        CGFloat scaleX = CGRectGetWidth(inputCIImage.extent) / CGRectGetWidth(maskCIImage.extent);
        CGFloat sclaeY = CGRectGetHeight(inputCIImage.extent) / CGRectGetHeight(maskCIImage.extent);
        CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, sclaeY);
        CIImage *transformedCIImage = [maskCIImage imageByApplyingTransform:transform highQualityDownsample:YES];
        [maskCIImage release];
        blendWithMaskFilter.maskImage = transformedCIImage;
        
        //
        
        CIImage *outputCIImage = [blendWithMaskFilter.outputImage imageByApplyingTransform:CGAffineTransformMakeScale(1., -1.)];
        CGImageRef outputCGImage = [self._ciContext createCGImage:outputCIImage fromRect:outputCIImage.extent];
        
        CGContextDrawImage(ctx, aspectBounds, outputCGImage);
        CGImageRelease(outputCGImage);
        
        CGContextRestoreGState(ctx);
        [pool release];
    } else {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        CVPixelBufferRef maskPixelBuffer = pixelBufferObservation.pixelBuffer;
        CIImage *maskCIImage = [[CIImage alloc] initWithCVPixelBuffer:maskPixelBuffer options:nil];
        CGFloat scaleX = CGRectGetWidth(aspectBounds) / CGRectGetWidth(maskCIImage.extent);
        CGFloat sclaeY = CGRectGetHeight(aspectBounds) / CGRectGetHeight(maskCIImage.extent);
        CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, -sclaeY);
        CIImage *transformedCIImage = [maskCIImage imageByApplyingTransform:transform highQualityDownsample:YES];
        [maskCIImage release];
        CGImageRef cgImage = [self._ciContext createCGImage:transformedCIImage fromRect:transformedCIImage.extent];
        CGContextDrawImage(ctx, aspectBounds, cgImage);
        CGImageRelease(cgImage);
        
        [pool release];
    }
}

- (void)_drawImageAestheticsScoresObservation:(VNImageAestheticsScoresObservation *)imageAestheticsScoresObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    CATextLayer *textLayer = [CATextLayer new];
    
    BOOL isUtility = imageAestheticsScoresObservation.isUtility;
    float overallScore = imageAestheticsScoresObservation.overallScore;
    float aestheticScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("aestheticScore"));
    float failureScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("failureScore"));
    float junkNegativeScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("junkNegativeScore"));
    float junkTragicFailureScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("junkTragicFailureScore"));
    float poorQualityScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("poorQualityScore"));
    float nonMemorableScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("nonMemorableScore"));
    float screenShotScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("screenShotScore"));
    float receiptOrDocumentScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("receiptOrDocumentScore"));
    float textDocumentScore = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(imageAestheticsScoresObservation, sel_registerName("textDocumentScore"));
    
    NSString *string = [[NSString alloc] initWithFormat:@"isUtility: %d\noverallScore: %lf\naestheticScore: %lf\nfailureScore: %lf\njunkNegativeScore: %lf\njunkTragicFailureScore: %lf\npoorQualityScore: %lf\nnonMemorableScore: %lf\nscreenShotScore: %lf\nreceiptOrDocumentScore: %lf\ntextDocumentScore: %lf", isUtility, overallScore, aestheticScore, failureScore, junkNegativeScore, junkTragicFailureScore, poorQualityScore, nonMemorableScore, screenShotScore, receiptOrDocumentScore, textDocumentScore];

    textLayer.string = string;
    [string release];
    
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawClassificationObservations:(NSArray<VNClassificationObservation *> *)classificationObservations frame:(CGRect)frame aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    CATextLayer *textLayer = [CATextLayer new];
    
    NSMutableString *string = [NSMutableString new];
    [classificationObservations enumerateObjectsUsingBlock:^(VNClassificationObservation * _Nonnull observation, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isLast = (idx == classificationObservations.count - 1);
        NSString *identifier = observation.identifier;
        VNConfidence confidence = observation.confidence;
        
        [string appendFormat:@"%@ (%lf)", identifier, confidence];
        
        if (!isLast) {
            [string appendString:@"\n"];
        }
    }];
    
    textLayer.string = string;
    [string release];
    
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation;
    if (CGRectIsNull(frame)) {
        textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
        translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                       CGRectGetMinY(aspectBounds));
    } else {
        textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(frame), CGRectGetHeight(frame));
        translation = CGAffineTransformMakeTranslation(CGRectGetMinX(frame),
                                                       CGRectGetMinY(frame));
    }
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawImageAestheticsObservation:(__kindof VNObservation *)imageAestheticsObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    NSDictionary<NSString *, NSNumber *> *_scoresDictionary = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageAestheticsObservation, sel_registerName("_scoresDictionary"));
    __block std::vector<std::pair<std::string, std::float_t>> scorePairs {};
    scorePairs.reserve(_scoresDictionary.count);
    
    [_scoresDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        std::string identifier = [key cStringUsingEncoding:NSUTF8StringEncoding];
        std::float_t score = obj.floatValue;
        scorePairs.push_back({identifier, score});
    }];
    
    std::sort(scorePairs.begin(), scorePairs.end(), [](auto lhs, auto rhs) {
        return rhs.second < lhs.second;
    });
    
    NSMutableString *string = [NSMutableString new];
    for (size_t idx : std::ranges::views::iota(0, (long long)scorePairs.size())) {
        auto pair = scorePairs[idx];
        [string appendFormat:@"%s: %lf", pair.first.data(), pair.second];
        bool isLast = (idx == scorePairs.size() - 1);
        if (!isLast) {
            [string appendString:@"\n"];
        }
    }
    
    CATextLayer *textLayer = [CATextLayer new];
    textLayer.string = string;
    [string release];
    
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawRecognizedObjectObservation:(__kindof VNRecognizedObjectObservation *)recognizedObjectObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx convertedBoundingBox:(CGRect * _Nullable)convertedBoundingBoxOut {
    CGRect convertedBoundingBox;
    [self _drawDetectedObjectObservation:recognizedObjectObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:&convertedBoundingBox];
    
    if (convertedBoundingBoxOut != NULL) {
        *convertedBoundingBoxOut = convertedBoundingBox;
    }
    
    [self _drawClassificationObservations:recognizedObjectObservation.labels frame:convertedBoundingBox aspectBounds:aspectBounds inContext:ctx];
}

- (void)_drawImageAnimalObservation:(__kindof VNRecognizedObjectObservation *)animalObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    [self _drawRecognizedObjectObservation:animalObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:NULL];
}

- (void)_drawImageDetectionprintObservation:(__kindof VNObservation *)detectionprintObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    id detectionprint = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(detectionprintObservation, sel_registerName("detectionprint"));
    
    //
    
    NSArray<NSString *> *tensorKeys = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(detectionprint, sel_registerName("tensorKeys"));
    NSMutableArray<NSString *> *strings = [[NSMutableArray alloc] initWithCapacity:tensorKeys.count];
    
    for (NSString *tensorKey in tensorKeys) {
        NSError * _Nullable error = nil;
        NSString *tensor = reinterpret_cast<id (*)(id, SEL, id, id *)>(objc_msgSend)(detectionprint, sel_registerName("tensorForKey:error:"), tensorKey, &error);
        assert(error == nil);
        NSString *tensorShape = reinterpret_cast<id (*)(Class, SEL, id, id *)>(objc_msgSend)(objc_lookUpClass("VNDetectionprint"), sel_registerName("tensorShapeForKey:error:"), tensorKey, &error);
        assert(error == nil);
        
        [strings addObject:[NSString stringWithFormat:@"%@: %@ Shape: %@", tensorKey, tensor, tensorShape]];
    }
    
    NSString *string = [strings componentsJoinedByString:@"\n"];
    [strings release];
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    textLayer.string = string;
    
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawImageFingerprintsObservation:(__kindof VNObservation *)imageFingerprintsObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSArray *fingerprintHashes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageFingerprintsObservation, sel_registerName("fingerprintHashes"));
    NSMutableArray<NSString *> *strings = [[NSMutableArray alloc] initWithCapacity:fingerprintHashes.count];
    
    for (id fingerprintHash in fingerprintHashes) {
        NSString *hashString = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(fingerprintHash, sel_registerName("hashString"));
        [strings addObject:hashString];
    }
    
    NSString *string = [strings componentsJoinedByString:@"\n"];
    [strings release];
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    textLayer.string = string;
    
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawImageprintObservation:(__kindof VNObservation *)imageprintObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSString *imageprintVersion = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageprintObservation, sel_registerName("imageprintVersion"));
    id imageprint = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageprintObservation, sel_registerName("imageprint"));
    id descriptor = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageprint, sel_registerName("descriptor"));
    
    NSString *imagepointIvarDescription = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageprint, sel_registerName("_ivarDescription"));
    NSString *descriptorIvarDescription = reinterpret_cast<id (*)(id ,SEL)>(objc_msgSend)(descriptor, sel_registerName("_ivarDescription"));
    
    NSString *string = [[NSString alloc] initWithFormat:@"imageprintVersion: %@\n\n%@\n\n%@", imageprintVersion, imagepointIvarDescription, descriptorIvarDescription];
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    
    textLayer.string = string;
    [string release];
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawImageNeuralHashprintObservation:(__kindof VNObservation *)imageNeuralHashprintObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSObject *imageNeuralHashprint = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(imageNeuralHashprintObservation, sel_registerName("imageNeuralHashprint"));
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    
    textLayer.string = imageNeuralHashprint.description;
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawSceneObservationObservation:(__kindof VNFeaturePrintObservation *)sceneObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSString *featureprintObservationString = [ImageVisionLayer _stringFromFeaturePrintObservation:sceneObservation];
    BOOL trimmed = (1500 < featureprintObservationString.length);
    // 글자수 제한
    featureprintObservationString = [featureprintObservationString substringWithRange:NSMakeRange(0, MIN(1500, featureprintObservationString.length))];
    if (trimmed) {
        featureprintObservationString = [featureprintObservationString stringByAppendingString:@"... (Trimmed)"];
    }
    
    NSArray<NSObject *> *sceneprints = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(sceneObservation, sel_registerName("sceneprints"));
    NSMutableArray<NSString *> *sceneprintStringArray = [[NSMutableArray alloc] initWithCapacity:sceneprints.count];
    for (NSObject *screenprint in sceneprints) {
        [sceneprintStringArray addObject:screenprint.description];
    }
    NSString *screenprintsString = [sceneprintStringArray componentsJoinedByString:@", "];
    [sceneprintStringArray release];
    
    NSString *string = [NSString stringWithFormat:@"%@\n\nscreenprints: %@", featureprintObservationString, screenprintsString];
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    
    textLayer.string = string;
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawSceneSmartCamObservation:(__kindof VNObservation *)smartCamObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSArray<NSObject *> *smartCamprints = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(smartCamObservation, sel_registerName("smartCamprints"));
    NSMutableArray<NSString *> *smartCamprintStringArray = [[NSMutableArray alloc] initWithCapacity:smartCamprints.count];
    for (NSObject *smartCamprint in smartCamprints) {
        [smartCamprintStringArray addObject:smartCamprint.description];
    }
    NSString *smartCamprintString = [smartCamprintStringArray componentsJoinedByString:@", "];
    [smartCamprintStringArray release];
    
    //
    
    CATextLayer *textLayer = [CATextLayer new];
    
    textLayer.string = smartCamprintString;
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(aspectBounds), CGRectGetHeight(self.bounds) - CGRectGetMinY(aspectBounds));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds),
                                                                     CGRectGetMinY(aspectBounds));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawHumanObservation:(VNHumanObservation *)humanObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    CGRect convertedBoundingBox;
    [self _drawDetectedObjectObservation:humanObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:&convertedBoundingBox];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    NSObject *torsoprint = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(humanObservation, sel_registerName("torsoprint"));
    
    CATextLayer *textLayer = [CATextLayer new];
    
    textLayer.string = [NSString stringWithFormat:@"upperBodyOnly: %d\ntorsoprint: %@", humanObservation.upperBodyOnly, torsoprint.description];
    textLayer.wrapped = YES;
    textLayer.fontSize = 17.;
    
    CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
    textLayer.foregroundColor = foregroundColor;
    CGColorRelease(foregroundColor);
    
    CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
    textLayer.backgroundColor = backgroundColor;
    CGColorRelease(backgroundColor);
    
    textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(convertedBoundingBox), CGRectGetHeight(convertedBoundingBox));
    textLayer.contentsScale = self.contentsScale;
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(convertedBoundingBox),
                                                                     CGRectGetMinY(convertedBoundingBox));
    
    CGContextConcatCTM(ctx, translation);
    
    [textLayer renderInContext:ctx];
    [textLayer release];
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawAnimalBodyPoseObservation:(VNAnimalBodyPoseObservation *)animalBodyPoseObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    [self _drawRecognizedPointsObservation:animalBodyPoseObservation aspectBounds:aspectBounds inContext:ctx];
}

- (void)_drawRecognizedPointsObservation:(VNRecognizedPointsObservation *)recognizedPointsObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    NSError * _Nullable error = nil;
    
    for (NSString *groupKey in recognizedPointsObservation.availableGroupKeys) {
        NSDictionary<VNRecognizedPointKey, VNRecognizedPoint *> * _Nullable recognizedPointsForGroupKey = [recognizedPointsObservation recognizedPointsForGroupKey:groupKey error:&error];
        
        __block std::optional<CGFloat> minX = std::nullopt;
        __block std::optional<CGFloat> minY = std::nullopt;
        __block std::optional<CGFloat> maxX = std::nullopt;
        __block std::optional<CGFloat> maxY = std::nullopt;
        
        [recognizedPointsForGroupKey enumerateKeysAndObjectsUsingBlock:^(VNRecognizedPointKey  _Nonnull key, VNRecognizedPoint * _Nonnull obj, BOOL * _Nonnull stop) {
            if (minX.has_value()) {
                minX = std::min(minX.value(), obj.x);
            } else {
                minX = obj.x;
            }
            
            if (minY.has_value()) {
                minY = std::min(minY.value(), obj.y);
            } else {
                minY = obj.y;
            }
            
            if (maxX.has_value()) {
                maxX = std::max(maxX.value(), obj.x);
            } else {
                maxX = obj.x;
            }
            
            if (maxY.has_value()) {
                maxY = std::max(maxY.value(), obj.y);
            } else {
                maxY = obj.y;
            }
        }];
        
        if (!minX.has_value()) continue;
        
        CGRect rectangle = CGRectMake(CGRectGetMinX(aspectBounds) + minX.value() * CGRectGetWidth(aspectBounds),
                                      CGRectGetMinY(aspectBounds) + (1. - maxY.value()) * CGRectGetHeight(aspectBounds),
                                      (maxX.value() - minX.value()) * CGRectGetWidth(aspectBounds),
                                      (maxY.value() - minY.value()) * CGRectGetHeight(aspectBounds));
        
        CGContextSetRGBStrokeColor(ctx, 0., 0.5, 0.5, 1.);
        
        CGContextStrokeRectWithWidth(ctx,
                                     rectangle,
                                     6.);
        
        if (self.shouldDrawDetails) {
            CGContextSaveGState(ctx);
            
            CATextLayer *textLayer = [CATextLayer new];
            
            textLayer.string = groupKey;
            textLayer.wrapped = YES;
            textLayer.font = [UIFont systemFontOfSize:12.];
            textLayer.fontSize = 12.;
            
            CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
            textLayer.foregroundColor = foregroundColor;
            CGColorRelease(foregroundColor);
            
            CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
            textLayer.backgroundColor = backgroundColor;
            CGColorRelease(backgroundColor);
            
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:groupKey attributes:@{NSFontAttributeName: (id)textLayer.font}];
            CGSize size = attributedString.size;
            [attributedString release];
            textLayer.frame = CGRectMake(0., 0., size.width, size.height);
            
            textLayer.contentsScale = self.contentsScale;
            
            CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(rectangle), CGRectGetMinY(rectangle) - size.height - 3.);
            
            CGContextConcatCTM(ctx, translation);
            
            [textLayer renderInContext:ctx];
            [textLayer release];
            
            CGContextRestoreGState(ctx);
        }
    }
    
    //
    
    for (NSString *key in recognizedPointsObservation.availableKeys) {
        VNRecognizedPoint *recognizedPoint = [recognizedPointsObservation recognizedPointForKey:key error:&error];
        VNConfidence confidence = recognizedPoint.confidence;
        CGContextSetRGBStrokeColor(ctx, 1., 0.5, 0.5, confidence);
        
        CGContextStrokeRectWithWidth(ctx,
                                     CGRectMake(CGRectGetMinX(aspectBounds) + (recognizedPoint.x * CGRectGetWidth(aspectBounds)) - 3.,
                                                CGRectGetMaxY(aspectBounds) - (recognizedPoint.y * CGRectGetHeight(aspectBounds)) - 3.,
                                                1.,
                                                1.),
                                     6.);
        
        if (self.shouldDrawDetails) {
            CGContextSaveGState(ctx);
            
            CATextLayer *textLayer = [CATextLayer new];
            
            textLayer.string = key;
            textLayer.wrapped = YES;
            textLayer.font = [UIFont systemFontOfSize:8.];
            textLayer.fontSize = 8.;
            
            CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
            textLayer.foregroundColor = foregroundColor;
            CGColorRelease(foregroundColor);
            
            CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
            textLayer.backgroundColor = backgroundColor;
            CGColorRelease(backgroundColor);
            
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:key attributes:@{NSFontAttributeName: (id)textLayer.font}];
            CGSize size = attributedString.size;
            [attributedString release];
            textLayer.frame = CGRectMake(0., 0., size.width, size.height);
            
            textLayer.contentsScale = self.contentsScale;
            
            CGAffineTransform translation = CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * recognizedPoint.x,
                                                                             CGRectGetMaxY(aspectBounds) - CGRectGetHeight(aspectBounds) * recognizedPoint.y);
            
            CGContextConcatCTM(ctx, translation);
            
            [textLayer renderInContext:ctx];
            [textLayer release];
            
            CGContextRestoreGState(ctx);
        }
    }
    
    //
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawRectangleObservation:(VNRectangleObservation *)rectangleObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    [self _drawDetectedObjectObservation:rectangleObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:NULL];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
//    auto convertPoint = ^CGPoint (CGPoint normalizedPoint) {
//        return CGPointMake(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * normalizedPoint.x,
//                           CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds) * (1. - normalizedPoint.y));
//    };
//    
//    CGPoint convTopLeft = convertPoint(rectangleObservation.bottomLeft);
//    CGPoint convTopRight = convertPoint(rectangleObservation.bottomRight);
//    CGPoint convBottomLeft = convertPoint(rectangleObservation.topLeft);
//    CGPoint convBottomRight = convertPoint(rectangleObservation.topRight);
//    
//#warning CGPathCreateMutableCopyByTransformingPath으로 하는게 더 나은 것 같음
//    
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGPathMoveToPoint(path, NULL, convTopLeft.x, convTopLeft.y);
//    CGPathAddLineToPoint(path, NULL, convTopRight.x, convTopRight.y);
//    CGPathAddLineToPoint(path, NULL, convBottomRight.x, convBottomRight.y);
//    CGPathAddLineToPoint(path, NULL, convBottomLeft.x, convBottomLeft.y);
//    CGPathAddLineToPoint(path, NULL, convTopLeft.x, convTopLeft.y);
//    CGPathCloseSubpath(path);
    
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(CGRectGetMinX(aspectBounds), CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds)), CGRectGetWidth(aspectBounds), -CGRectGetHeight(aspectBounds));
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &transform, rectangleObservation.topLeft.x, rectangleObservation.topLeft.y);
    CGPathAddLineToPoint(path, &transform, rectangleObservation.topRight.x, rectangleObservation.topRight.y);
    CGPathAddLineToPoint(path, &transform, rectangleObservation.bottomRight.x, rectangleObservation.bottomRight.y);
    CGPathAddLineToPoint(path, &transform, rectangleObservation.bottomLeft.x, rectangleObservation.bottomLeft.y);
    CGPathAddLineToPoint(path, &transform, rectangleObservation.topLeft.x, rectangleObservation.topLeft.y);
    
    CGContextAddPath(ctx, path);
    CGPathRelease(path);
    CGContextSetRGBStrokeColor(ctx, 0., 1., 0., 1.);
    CGContextSetLineWidth(ctx, 3.);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawInstanceMaskObservation:(VNInstanceMaskObservation *)instanceMaskObservation aspectBounds:(CGRect)aspectBounds maskImage:(BOOL)maskImage inContext:(CGContextRef)ctx {
    NSIndexSet *allInstances = instanceMaskObservation.allInstances;
    if (allInstances.count == 0) return;
    
    UIImage *image = self.image;
    if (image == nil) return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
    CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
    
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage orientation:cgImagePropertyOrientation options:@{
        MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
    }];
    
    NSError * _Nullable error = nil;
    CVPixelBufferRef maskPixelBuffer = [instanceMaskObservation generateScaledMaskForImageForInstances:allInstances fromRequestHandler:requestHandler error:&error];
    assert(error == nil);
    
    if (maskImage) {
        CIFilter<CIBlendWithMask> *blendWithMaskFilter = [CIFilter blendWithMaskFilter];
        
        CIImage *inputCIImage = image.CIImage;
        if (inputCIImage == nil) {
            inputCIImage = [[[CIImage alloc] initWithCGImage:image.CGImage options:nil] autorelease];
        }
        blendWithMaskFilter.inputImage = inputCIImage;
        
        CIImage *maskCIImage = [[CIImage alloc] initWithCVPixelBuffer:maskPixelBuffer options:nil];
        CVPixelBufferRelease(maskPixelBuffer);
        CGFloat scaleX = CGRectGetWidth(inputCIImage.extent) / CGRectGetWidth(maskCIImage.extent);
        CGFloat sclaeY = CGRectGetHeight(inputCIImage.extent) / CGRectGetHeight(maskCIImage.extent);
        CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, sclaeY);
        CIImage *transformedMaskCIImage = [maskCIImage imageByApplyingTransform:transform];
        [maskCIImage release];
        blendWithMaskFilter.maskImage = transformedMaskCIImage;
        
        CIImage *outputCIImage = [blendWithMaskFilter.outputImage imageByApplyingTransform:CGAffineTransformMakeScale(1., -1.)];
        CGImageRef outputCGImage = [self._ciContext createCGImage:outputCIImage fromRect:outputCIImage.extent];
        
        CGContextDrawImage(ctx, aspectBounds, outputCGImage);
        CGImageRelease(outputCGImage);
    } else {
        CIImage *maskCIImage = [[CIImage alloc] initWithCVPixelBuffer:maskPixelBuffer options:nil];
        CVPixelBufferRelease(maskPixelBuffer);
        CIImage *transformedMaskCIImage = [maskCIImage imageByApplyingTransform:CGAffineTransformMakeScale(1., -1.)];
        [maskCIImage release];
        
        CGImageRef maskCGImage = [self._ciContext createCGImage:transformedMaskCIImage fromRect:transformedMaskCIImage.extent];
        
        CGContextDrawImage(ctx, aspectBounds, maskCGImage);
        CGImageRelease(maskCGImage);
    }
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawBarcodeObservation:(VNBarcodeObservation *)barcodeObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    CGRect convertedBoundingBox;
    [self _drawDetectedObjectObservation:barcodeObservation aspectBounds:aspectBounds inContext:ctx convertedBoundingBox:&convertedBoundingBox];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    auto drawText = ^(NSString *string, CGPoint origin) {
        CGContextSaveGState(ctx);
        
        CATextLayer *textLayer = [CATextLayer new];
        
        textLayer.string = string;
        textLayer.wrapped = YES;
        textLayer.font = [UIFont systemFontOfSize:8.];
        textLayer.fontSize = 8.;
        
        CGColorRef foregroundColor = CGColorCreateGenericGray(1., 1.);
        textLayer.foregroundColor = foregroundColor;
        CGColorRelease(foregroundColor);
        
        CGColorRef backgroundColor = CGColorCreateGenericGray(0., 0.4);
        textLayer.backgroundColor = backgroundColor;
        CGColorRelease(backgroundColor);
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: (id)textLayer.font}];
        CGSize size = attributedString.size;
        [attributedString release];
        textLayer.frame = CGRectMake(0., 0., size.width, size.height);
        
        textLayer.contentsScale = self.contentsScale;
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation(origin.x - size.width * 0.5, origin.y - size.height * 0.5);
        
        CGContextConcatCTM(ctx, translation);
        
        [textLayer renderInContext:ctx];
        [textLayer release];
        
        CGContextRestoreGState(ctx);
    };
    
    if (NSString *payloadStringValue = barcodeObservation.payloadStringValue) {
        drawText(payloadStringValue, CGPointMake(CGRectGetMidX(convertedBoundingBox), CGRectGetMinY(convertedBoundingBox)));
    }
    
    if (NSString *supplementalPayloadString = barcodeObservation.supplementalPayloadString) {
        drawText(supplementalPayloadString, CGPointMake(CGRectGetMinX(convertedBoundingBox), CGRectGetMaxY(convertedBoundingBox)));
    }
    
    if (self.shouldDrawDetails) {
        NSString *string = [NSString stringWithFormat:@"symbology: %@\nisColorInverted: %d\nisGS1DataCarrier: %d", barcodeObservation.symbology, barcodeObservation.isColorInverted, barcodeObservation.isGS1DataCarrier];
        drawText(string, CGPointMake(CGRectGetMidX(convertedBoundingBox), CGRectGetMidY(convertedBoundingBox)));
    }
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawContoursObservation:(VNContoursObservation *)contoursObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    //
    
    CGContextSaveGState(ctx);
    
    CGContextSetRGBFillColor(ctx, 0., 0., 0., 0.7);
    CGContextFillRect(ctx, self.bounds);
    
    CGContextRestoreGState(ctx);
    
    //
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformTranslate(CGAffineTransformIdentity, CGRectGetMinX(aspectBounds), CGRectGetMinY(aspectBounds)), CGRectGetWidth(aspectBounds), CGRectGetHeight(aspectBounds)), 0., 1.), 1., -1.);
    
    if (self.shouldDrawContoursSeparately) {
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<> dis(0.5, 1.0);
        
        for (VNContour *topLevelContour in contoursObservation.topLevelContours) {
            CGFloat r = dis(gen);
            CGFloat g = dis(gen);
            CGFloat b = dis(gen);
            
            void (^__block drawChilldContours)(NSArray<VNContour *> * childContours, BOOL isTop) = ^(NSArray<VNContour *> * childContours, BOOL isTop) {
                for (VNContour *childContour in childContours) {
                    drawChilldContours(childContour.childContours, NO);
                    
                    if (self.shouldDrawDetails) {
                        NSError * _Nullable error = nil;
                        VNCircle *boundingCircle = [VNGeometryUtils boundingCircleForContour:childContour error:&error];
                        assert(error == nil);
                        
                        CGPoint convCenter = CGPointMake(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * boundingCircle.center.x,
                                                         CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds) * (1. - boundingCircle.center.y));
                        CGFloat convDiameter = CGRectGetWidth(aspectBounds) * boundingCircle.diameter;
                        
                        CGRect convRect = CGRectMake(convCenter.x - convDiameter * 0.5,
                                                     convCenter.y - convDiameter * 0.5,
                                                     convDiameter,
                                                     convDiameter);
                        
                        CGContextAddEllipseInRect(ctx, convRect);
                        CGContextAddEllipseInRect(ctx, CGRectInset(convRect, 3., 3.));
                        CGContextSetRGBFillColor(ctx, 1., 1., 1., 0.3);
                        CGContextEOFillPath(ctx);
                        
                        //
                        
                        VNContour *polygonApproximationContour = [childContour polygonApproximationWithEpsilon:0.01f error:&error];
                        assert(error == nil);
                        CGPathRef transformedPolygonApproximationPath = CGPathCreateCopyByTransformingPath(polygonApproximationContour.normalizedPath, &transform);
                        
                        CGContextAddPath(ctx, transformedPolygonApproximationPath);
                        CGPathRelease(transformedPolygonApproximationPath);
                        CGContextSetRGBStrokeColor(ctx, 1., 1., 1., 1.);
                        CGContextSetLineWidth(ctx, 3.);
                        CGContextStrokePath(ctx);
                    }
                    
                    CGPathRef transformedChildPath = CGPathCreateCopyByTransformingPath(childContour.normalizedPath, &transform);
                    
                    CGContextAddPath(ctx, transformedChildPath);
                    CGPathRelease(transformedChildPath);
                    CGContextSetRGBStrokeColor(ctx, r, g, b, isTop ? 1. : 0.3);
                    CGContextSetLineWidth(ctx, 3.);
                    CGContextStrokePath(ctx);
                }
            };
            
            drawChilldContours(@[topLevelContour], YES);
        }
    } else {
        CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(contoursObservation.normalizedPath, &transform);
        
        CGContextAddPath(ctx, transformedPath);
        CGPathRelease(transformedPath);
        CGContextSetRGBStrokeColor(ctx, 0., 1., 1., 1.);
        CGContextSetLineWidth(ctx, 3.);
        CGContextStrokePath(ctx);
        CGContextClosePath(ctx);
    }
    
    CGContextRestoreGState(ctx);
    [pool release];
}

@end
