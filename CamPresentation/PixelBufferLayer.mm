//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <VideoToolbox/VideoToolbox.h>
#import <CamPresentation/lock_private.h>

@interface PixelBufferLayer ()
@property (assign, nonatomic, readonly) os_unfair_recursive_lock lock;
@end

@implementation PixelBufferLayer

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
    if (CVPixelBufferRef oldPixelBuffer = _pixelBuffer) {
        CVPixelBufferRelease(oldPixelBuffer);
    }
    [super dealloc];
}

- (void)commonInit_PixelBufferLayer {
    _lock = OS_UNFAIR_RECURSIVE_LOCK_INIT;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    
    if (CVPixelBufferRef oldPixelBuffer = _pixelBuffer) {
        CVPixelBufferRelease(oldPixelBuffer);
    }
    
    _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    [self setNeedsDisplay];
    [self display];
    
    os_unfair_recursive_lock_unlock(&_lock);
}

- (void)drawInContext:(CGContextRef)ctx {
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    
    
    CVPixelBufferRef pixelBuffer = _pixelBuffer;
    if (pixelBuffer == nullptr) {
        os_unfair_recursive_lock_unlock(&_lock);
        return;
    }
    
    CGImageRef image = nullptr;
#warning 잘 안 됨
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nullptr, &image);
    
    if (image) {
        CGContextDrawImage(ctx, self.bounds, image);
    }
    
    os_unfair_recursive_lock_unlock(&_lock);
}

@end
