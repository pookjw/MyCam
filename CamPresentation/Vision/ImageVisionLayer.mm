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
#import <Accelerate/Accelerate.h>
#include <algorithm>

OBJC_EXPORT void objc_setProperty_atomic(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);
OBJC_EXPORT void objc_setProperty_atomic_copy(id _Nullable self, SEL _Nonnull _cmd, id _Nullable newValue, ptrdiff_t offset);

@implementation ImageVisionLayer

- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:[ImageVisionLayer class]]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<ImageVisionLayer *>(layer);
        _image = [casted.image retain];
        _observations = [casted.observations copy];
    }
    
    return self;
}

- (void)dealloc {
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

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    UIImage *image = self.image;
    if (image == nil) return;
    
    CGRect aspectBounds = AVMakeRectWithAspectRatioInsideRect(image.size, self.bounds);
    
    UIGraphicsPushContext(ctx);
    [image drawInRect:AVMakeRectWithAspectRatioInsideRect(image.size, aspectBounds)];
    UIGraphicsPopContext();
    
    for (__kindof VNObservation *observation in self.observations) {
        if ([observation isKindOfClass:[VNFaceObservation class]]) {
            auto faceObservation = static_cast<VNFaceObservation *>(observation);
            [self _drawFaceObservation:faceObservation aspectBounds:aspectBounds inContext:ctx];
        } else {
            abort();
        }
    }
}

- (void)_drawFaceObservation:(VNFaceObservation *)faceObservation aspectBounds:(CGRect)aspectBounds inContext:(CGContextRef)ctx {
    CGContextSaveGState(ctx);
    
    CGContextSetRGBStrokeColor(ctx, 0., 1., 1., 1.);
    
    CGRect boundingBox = faceObservation.boundingBox;
    CGContextStrokeRectWithWidth(ctx,
                                 CGRectMake(CGRectGetMinX(aspectBounds) + CGRectGetWidth(aspectBounds) * CGRectGetMinX(boundingBox),
                                            CGRectGetMinY(aspectBounds) + CGRectGetHeight(aspectBounds) * (1. - CGRectGetMinY(boundingBox) - CGRectGetHeight(boundingBox)),
                                            CGRectGetWidth(aspectBounds) * CGRectGetWidth(boundingBox),
                                            CGRectGetHeight(aspectBounds) * CGRectGetHeight(boundingBox)),
                                 10.);
    
    if (VNFaceLandmarkRegion2D *region = faceObservation.landmarks.allPoints) {
        NSUInteger pointCount = region.pointCount;
        const CGPoint *points = [region pointsInImageOfSize:aspectBounds.size];
        
#warning 이게 뭐임
        switch (region.pointsClassification) {
            case VNPointsClassificationClosedPath:
                break;
            case VNPointsClassificationDisconnected:
                break;
            case VNPointsClassificationOpenPath:
                break;
            default:
                abort();
        }
        
        //
        
#warning TODO
        NSArray<NSNumber*> *precisionEstimatesPerPoint = region.precisionEstimatesPerPoint;
        std::vector<float> precisionEstimatesPerPointVec {};
        
        if (precisionEstimatesPerPoint.count > 0) {
            precisionEstimatesPerPointVec.reserve(precisionEstimatesPerPoint.count);
            
            for (NSNumber *number in precisionEstimatesPerPoint) {
                precisionEstimatesPerPointVec.push_back(number.floatValue);
            }
            
            float minValue, maxValue;
            // stride (1) = 연속된 요소를 하나씩 접근. 배열의 모든 요소를 순차적으로 접근.
            vDSP_minv(precisionEstimatesPerPointVec.data(), 1, &minValue, precisionEstimatesPerPointVec.size());
            vDSP_maxv(precisionEstimatesPerPointVec.data(), 1, &maxValue, precisionEstimatesPerPointVec.size());
            
            
        }
        
        
        //
        
        for (NSUInteger idx : std::views::iota(0, (NSInteger)pointCount)) {
            const CGPoint point = points[idx];
            CGFloat precision;
#if CGFLOAT_IS_DOUBLE
            precision = region.precisionEstimatesPerPoint[idx].doubleValue;
#else
            precision = region.precisionEstimatesPerPoint[idx].floatValue;
#endif
            
            CGContextSetRGBStrokeColor(ctx, 1., 0.5, 0.5, precision);
            
            CGContextStrokeRectWithWidth(ctx,
                                         CGRectMake(CGRectGetMinX(aspectBounds) + point.x - 3.,
                                                    CGRectGetHeight(aspectBounds) - (CGRectGetMinY(aspectBounds) + point.y) - 3.,
                                                    1.,
                                                    1.),
                                         6.);
        }
    }
    
    CGContextRestoreGState(ctx);
}

@end
