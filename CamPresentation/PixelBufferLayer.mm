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
@property (assign, nonatomic) BOOL fillIsolated;
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

- (void)updateWithCIImage:(CIImage *)ciImage rotationAngle:(float)rotationAngle fill:(BOOL)fill {
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        if (CGImageRef oldCGImage = _cgImageIsolated) {
            CGImageRelease(oldCGImage);
        }
        
        CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformRotate(CGAffineTransformMakeTranslation(CGRectGetMidX(ciImage.extent), CGRectGetMidY(ciImage.extent)), rotationAngle * M_PI / 180.f), -1.f, 1.f);
        CIImage *rotatedCIImage = [ciImage imageByApplyingTransform:transform highQualityDownsample:NO];
        
        // retained
        CGImageRef cgImage = [PixelBufferLayer.ciContext createCGImage:rotatedCIImage fromRect:rotatedCIImage.extent];
        
        os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
        _cgImageIsolated = cgImage;
        _fillIsolated = fill;
        os_unfair_recursive_lock_unlock(&_lock);
        
        [self setNeedsDisplay];
    }];
}

- (void)updateWithCIImage:(CIImage *)ciImage fill:(BOOL)fill {
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        if (CGImageRef oldCGImage = _cgImageIsolated) {
            CGImageRelease(oldCGImage);
        }
        
        // retained
        CGImageRef cgImage = [PixelBufferLayer.ciContext createCGImage:ciImage fromRect:ciImage.extent];
        
        os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
        _cgImageIsolated = cgImage;
        _fillIsolated = fill;
        os_unfair_recursive_lock_unlock(&_lock);
        
        [self setNeedsDisplay];
    }];
}

- (void)updateWithCGImage:(CGImageRef)cgImage fill:(BOOL)fill {
    id casted = (id)cgImage;
    
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        CGImageRef cgImage = (CGImageRef)casted;
        
        if (CGImageRef oldCGImage = _cgImageIsolated) {
            CGImageRelease(oldCGImage);
        }
        
        os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
        _cgImageIsolated = CGImageRetain(cgImage);
        _fillIsolated = fill;
        os_unfair_recursive_lock_unlock(&_lock);
        
        [self setNeedsDisplay];
    }];
}

- (void)drawInContext:(CGContextRef)ctx {
    CGImageRef cgImage;
    BOOL fiil;
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    cgImage = _cgImageIsolated;
    if (cgImage != nullptr) {
        CGImageRetain(cgImage);
    }
    fiil = _fillIsolated;
    os_unfair_recursive_lock_unlock(&_lock);
    
    if (cgImage != nil) {
        CGContextSetAlpha(ctx, self.opacity);
        
        CGRect rect;
        if (fiil) {
            rect = CGRectMake(0., 0., CGBitmapContextGetWidth(ctx), CGBitmapContextGetHeight(ctx));
        } else {
            rect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), CGRectMake(0., 0., CGBitmapContextGetWidth(ctx), CGBitmapContextGetHeight(ctx)));
        }
        
        CGContextDrawImage(ctx, rect, cgImage);
        CGImageRelease(cgImage);
    }
}

@end
