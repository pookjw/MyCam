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
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreImage/CoreImage.h>
#import <Metal/Metal.h>
#import <CoreImage/CIFilterBuiltins.h>

OBJC_EXPORT void objc_setProperty_atomic(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);
OBJC_EXPORT void objc_setProperty_atomic_copy(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);

@interface ImageVisionLayer ()
@property (retain, nonatomic, readonly) CIContext *_ciContext;
@end

@implementation ImageVisionLayer

- (instancetype)init {
    if (self = [super init]) {
        id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        __ciContext = [[CIContext contextWithMTLDevice:mtlDevice] retain];
        [mtlDevice release];
        
        _shouldDrawImage = YES;
        _shouldDrawDetails = YES;
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
    objc_setProperty_atomic(self, _cmd, image, ivar_getOffset(ivar));
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setObservations:(NSArray<__kindof VNObservation *> *)observations {
#pragma clang diagnostic pop
    Ivar ivar = object_getInstanceVariable(self, "_observations", NULL);
    assert(ivar);
    objc_setProperty_atomic(self, _cmd, observations, ivar_getOffset(ivar));
    
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setShouldDrawImage:(BOOL)drawsImage {
#pragma clang diagnostic pop
    _shouldDrawImage = drawsImage;
    [self setNeedsDisplay];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Watomic-property-with-user-defined-accessor"
- (void)setShouldDrawDetails:(BOOL)shouldDrawDetails {
#pragma clang diagnostic pop
    _shouldDrawDetails = shouldDrawDetails;
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    UIImage *image = self.image;
    if (image == nil) return;
    
    CGRect aspectBounds = AVMakeRectWithAspectRatioInsideRect(image.size, self.bounds);
    
    if (self.shouldDrawImage) {
        UIGraphicsPushContext(ctx);
        [image drawInRect:AVMakeRectWithAspectRatioInsideRect(image.size, aspectBounds)];
        UIGraphicsPopContext();
    }
    
    for (__kindof VNObservation *observation in self.observations) {
        if ([observation isKindOfClass:[VNFaceObservation class]]) {
            auto faceObservation = static_cast<VNFaceObservation *>(observation);
            [self _drawFaceObservation:faceObservation aspectBounds:aspectBounds inContext:ctx];
        } else if ([observation isKindOfClass:[VNPixelBufferObservation class]]) {
            auto pixelBufferObservation = static_cast<VNPixelBufferObservation *>(observation);
            id originatingRequestSpecifier = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(pixelBufferObservation, sel_registerName("originatingRequestSpecifier"));
            NSString *requestClassName = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(originatingRequestSpecifier, sel_registerName("requestClassName"));
            
            if ([requestClassName isEqualToString:NSStringFromClass([VNGeneratePersonSegmentationRequest class])]) {
                [self _drawPixelBufferObservation:pixelBufferObservation aspectBounds:aspectBounds maskImage:YES inContext:ctx];
            } else {
                abort();
            }
        } else if ([observation isKindOfClass:[VNImageAestheticsScoresObservation class]]) {
            auto imageAestheticsScoresObservation = static_cast<VNImageAestheticsScoresObservation *>(observation);
            [self _drawImageAestheticsScoresObservation:imageAestheticsScoresObservation aspectBounds:aspectBounds inContext:ctx];
        } else {
            NSLog(@"%@", observation);
            abort();
        }
    }
}

- (void)_drawFaceObservation:(VNFaceObservation *)faceObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGContextSaveGState(ctx);
    
    CGContextSetRGBStrokeColor(ctx, 0., 1., 1., 1.);
    
    //
    
    CGRect boundingBox = faceObservation.boundingBox;
    CGRect convertedBoundingBox = CGRectMake(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * CGRectGetMinX(boundingBox),
                                             CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds) * (1. - CGRectGetMinY(boundingBox) - CGRectGetHeight(boundingBox)),
                                             CGRectGetWidth(aspectBounds) * CGRectGetWidth(boundingBox),
                                             CGRectGetHeight(aspectBounds) * CGRectGetHeight(boundingBox));
    CGContextStrokeRectWithWidth(ctx, convertedBoundingBox, 10.);
    
    //
    
    if (VNFaceLandmarkRegion2D *region = faceObservation.landmarks.allPoints) {
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
                                                    CGRectGetHeight(aspectBounds) - (CGRectGetMinY(aspectBounds) + point.y) - 3.,
                                                    1.,
                                                    1.),
                                         6.);
        }
    }
    
    //
    
    CGContextSaveGState(ctx);
    
    BOOL isBlinking = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(faceObservation, sel_registerName("isBlinking"));
    
    CATextLayer *textLayer = [CATextLayer new];
    textLayer.string = isBlinking ? @"😔" : @"😳";
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
    
    //
    
    CGContextRestoreGState(ctx);
    [pool release];
}

- (void)_drawPixelBufferObservation:(VNPixelBufferObservation *)pixelBufferObservation aspectBounds:(CGRect)aspectBounds maskImage:(BOOL)maskImage inContext:(CGContextRef)ctx {
    if (maskImage) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        CGContextSaveGState(ctx);
        
        CIFilter<CIBlendWithMask> *blendWithAlphaMaskFilter = [CIFilter blendWithMaskFilter];
        
        //
        
        CIImage *inputCIImage = self.image.CIImage;
        if (inputCIImage == nil) {
            inputCIImage = [[[CIImage alloc] initWithCGImage:self.image.CGImage options:nil] autorelease];
        }
        blendWithAlphaMaskFilter.inputImage = inputCIImage;
        
        //
        
        CVPixelBufferRef maskPixelBuffer = pixelBufferObservation.pixelBuffer;
        CIImage *maskCIImage = [[CIImage alloc] initWithCVPixelBuffer:maskPixelBuffer options:nil];
        CGFloat scaleX = CGRectGetWidth(inputCIImage.extent) / CGRectGetWidth(maskCIImage.extent);
        CGFloat sclaeY = CGRectGetHeight(inputCIImage.extent) / CGRectGetHeight(maskCIImage.extent);
        CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, sclaeY);
        CIImage *transformedCIImage = [maskCIImage imageByApplyingTransform:transform highQualityDownsample:YES];
        [maskCIImage release];
        blendWithAlphaMaskFilter.maskImage = transformedCIImage;
        
        //
        
        
        
        //
        
        CIImage *outputCIImage = [blendWithAlphaMaskFilter.outputImage imageByApplyingTransform:CGAffineTransformMakeScale(1., -1.)];
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
    
    abort();
    
    CGContextRestoreGState(ctx);
    [pool release];
}

@end
