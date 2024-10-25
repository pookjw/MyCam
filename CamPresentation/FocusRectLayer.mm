//
//  FocusRectLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/FocusRectLayer.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>

@interface FocusRectLayer ()
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) __kindof CALayer *videoPreviewLayer;
#else
@property (retain, nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
#endif
@end

@implementation FocusRectLayer

#if TARGET_OS_VISION
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(__kindof CALayer *)videoPreviewLayer
#else
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(nonnull AVCaptureVideoPreviewLayer *)videoPreviewLayer
#endif
{
    if (self = [super init]) {
        _captureDevice = [captureDevice retain];
        _videoPreviewLayer = [videoPreviewLayer retain];
        
        [captureDevice addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"focusMode" options:NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:FocusRectLayer.class]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<FocusRectLayer *>(self);
        AVCaptureDevice *captureDevice = casted->_captureDevice;
        
        _captureDevice = [captureDevice retain];
        
        [captureDevice addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"focusMode" options:NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (void)dealloc {
    [_captureDevice removeObserver:self forKeyPath:@"focusPointOfInterest"];
    [_captureDevice removeObserver:self forKeyPath:@"focusMode"];
    [_captureDevice release];
    [_videoPreviewLayer release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([self.captureDevice isEqual:object]) {
        if ([keyPath isEqualToString:@"focusPointOfInterest"]) {
            [SVRunLoop.globalRenderRunLoop runBlock:^{
                [self setNeedsDisplay];
            }];
            return;
        } else if ([keyPath isEqualToString:@"focusMode"]) {
            [SVRunLoop.globalRenderRunLoop runBlock:^{
                [self setNeedsDisplay];
            }];
            return;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawInContext:(CGContextRef)ctx {
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    if (captureDevice.isFocusPointOfInterestSupported) {
        CGContextSaveGState(ctx);
        
        CGColorRef color;
        switch (captureDevice.focusMode) {
#if TARGET_OS_VISION
            case 0:  
#else
            case AVCaptureFocusModeLocked:
#endif
                color = CGColorCreateSRGB(1., 0., 0., 1.);
                break;
#if TARGET_OS_VISION
            case 1:
#else
            case AVCaptureFocusModeAutoFocus:
#endif
                color = CGColorCreateSRGB(0., 1., 0., 1.);
                break;
#if TARGET_OS_VISION
            case 2:
#else
            case AVCaptureFocusModeContinuousAutoFocus:
#endif
                color = CGColorCreateSRGB(0., 0., 1., 1.);
                break;
            default:
                abort();
        }
        
        CGPoint point;
#if TARGET_OS_VISION
        point = reinterpret_cast<CGPoint (*)(id, SEL, CGPoint)>(objc_msgSend)(self.videoPreviewLayer, sel_registerName("pointForCaptureDevicePointOfInterest:"), captureDevice.focusPointOfInterest);
#else
        point = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:captureDevice.focusPointOfInterest];
#endif
        
        CGRect rect = CGRectMake(point.x - 50., point.y - 50., 100., 100.);
        
        CGContextSetStrokeColorWithColor(ctx, color);
        CGContextStrokeRectWithWidth(ctx, rect, 10.);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = @"Focus";
        textLayer.foregroundColor = color;
        CGColorRelease(color);
        textLayer.fontSize = 30.;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.contentsScale = self.contentsScale;
        textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(rect), 30.);
        CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetWidth(textLayer.frame) * 0.5, CGRectGetMidY(rect) - CGRectGetHeight(textLayer.frame) * 0.5));
        [textLayer renderInContext:ctx];
        [textLayer release];
        
        CGContextRestoreGState(ctx);
    }
}

@end
