//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <CoreImage/CoreImage.h>
#import <CamPresentation/lock_private.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/SVRunLoop.hpp>

@interface PixelBufferLayer ()
@property (class, retain, nonatomic, readonly) CIContext *ciContext;
@property (assign, nonatomic, readonly) os_unfair_recursive_lock lock;
@property (assign, nonatomic, nullable) CGImageRef cgImageIsolated;
@end

@implementation PixelBufferLayer

+ (CIContext *)ciContext {
    static CIContext *ciContext = [[CIContext alloc] initWithOptions:nil];
    return ciContext;
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit_PixelBufferLayer];
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer]) {
        [self commonInit_PixelBufferLayer];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_PixelBufferLayer];
    }
    
    return self;
}

- (void)dealloc {
    if (CGImageRef cgImage = _cgImageIsolated) {
        CGImageRelease(cgImage);
    }
    
    [super dealloc];
}

- (void)commonInit_PixelBufferLayer {
    _lock = OS_UNFAIR_RECURSIVE_LOCK_INIT;
}

- (void)updateWithCIImage:(CIImage *)ciImage rotationAngle:(float)rotationAngle {
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        if (CGImageRef oldCGImage = _cgImageIsolated) {
            CGImageRelease(oldCGImage);
        }
        
        CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(CGRectGetMidX(ciImage.extent), CGRectGetMidY(ciImage.extent)), rotationAngle * M_PI / 180.f);
        CIImage *rotatedCIImage = [ciImage imageByApplyingTransform:transform highQualityDownsample:NO];
        
        // retained
        CGImageRef cgImage = [PixelBufferLayer.ciContext createCGImage:rotatedCIImage fromRect:rotatedCIImage.extent];
        
        os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
        _cgImageIsolated = cgImage;
        os_unfair_recursive_lock_unlock(&_lock);
        
        [self setNeedsDisplay];
    }];
}

- (void)drawInContext:(CGContextRef)ctx {
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    
    if (CGImageRef cgImage = _cgImageIsolated) {
        CGContextSetAlpha(ctx, 0.75);
        CGContextDrawImage(ctx, AVMakeRectWithAspectRatioInsideRect(CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), self.bounds), cgImage);
    }
    
    os_unfair_recursive_lock_unlock(&_lock);
}

@end
