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
    
    VNFaceLandmarkRegion2D *region = faceObservation.landmarks.allPoints;
    
    NSUInteger pointCount = region.pointCount;
    const CGPoint *points = [region pointsInImageOfSize:aspectBounds.size];
    
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
    
    CGColorRef color = CGColorCreateGenericRGB(1., 0., 0., 1.);
    CGContextSetStrokeColorWithColor(ctx, color);
    CGColorRelease(color);
    
    for (const CGPoint *ptr : std::ranges::views::iota(points, points + pointCount)) {
        const CGPoint point = *ptr;
        CGContextStrokeRectWithWidth(ctx, CGRectMake(CGRectGetMinX(aspectBounds) + point.x, CGRectGetMinY(aspectBounds) + point.y, 10., 10.), 10.);
    }
    
    CGContextRestoreGState(ctx);
}

@end
