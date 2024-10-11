//
//  PixelBufferLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/11/24.
//

#import <CamPresentation/PixelBufferLayer.h>
#import <CoreImage/CoreImage.h>
#import <CamPresentation/lock_private.h>

@interface PixelBufferLayer ()
@property (class, retain, nonatomic, readonly) CIContext *ciContext;
@property (assign, nonatomic, readonly) os_unfair_recursive_lock lock;
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
    if (CVPixelBufferRef oldPixelBuffer = _pixelBuffer) {
        CVPixelBufferRelease(oldPixelBuffer);
    }
    [super dealloc];
}

- (void)commonInit_PixelBufferLayer {
    _lock = OS_UNFAIR_RECURSIVE_LOCK_INIT;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSLog(@"%s", sel_getName(_cmd));
    
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    
    if (CVPixelBufferRef oldPixelBuffer = _pixelBuffer) {
        CVPixelBufferRelease(oldPixelBuffer);
    }
    
    _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    
    os_unfair_recursive_lock_unlock(&_lock);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

- (void)drawInContext:(CGContextRef)ctx {
    os_unfair_recursive_lock_lock_with_options(&_lock, OS_UNFAIR_LOCK_NONE);
    
    
    CVPixelBufferRef pixelBuffer = _pixelBuffer;
    if (pixelBuffer == nullptr) {
        os_unfair_recursive_lock_unlock(&_lock);
        return;
    }
    
//    NSLog(@"%s", CVPixelBufferGetPixelFormatType(pixelBuffer));
//    assert(CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32ARGB || CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_422YpCbCr8 || CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA);
    
    CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:pixelBuffer options:@{kCIImageAuxiliaryDisparity: @YES}];
    
    CGImageRef cgImage = [PixelBufferLayer.ciContext createCGImage:ciImage fromRect:ciImage.extent];
    
    if (cgImage) {
        CGContextSetAlpha(ctx, 0.5);
        CGContextDrawImage(ctx, self.bounds, cgImage);
        NSLog(@"Drawn!");
    } else {
        NSLog(@"Failed!");
    }
    
    os_unfair_recursive_lock_unlock(&_lock);
}

@end
