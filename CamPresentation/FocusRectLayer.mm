//
//  FocusRectLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/FocusRectLayer.h>
#import <CamPresentation/SVRunLoop.hpp>

@interface FocusRectLayer ()
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@end

@implementation FocusRectLayer

- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice videoPreviewLayer:(nonnull AVCaptureVideoPreviewLayer *)videoPreviewLayer {
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
        CGColorRef color;
        switch (captureDevice.focusMode) {
            case AVCaptureFocusModeLocked:
                color = CGColorCreateSRGB(1., 0., 0., 1.);
                break;
            case AVCaptureFocusModeAutoFocus:
                color = CGColorCreateSRGB(0., 1., 0., 1.);
                break;
            case AVCaptureFocusModeContinuousAutoFocus:
                color = CGColorCreateSRGB(0., 0., 1., 1.);
                break;
            default:
                abort();
        }
        
        CGPoint point = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:captureDevice.focusPointOfInterest];
        
        CGContextSaveGState(ctx);
        
        CGContextSetStrokeColorWithColor(ctx, color);
        CGColorRelease(color);
        
        CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(-50., -50.));
        CGContextStrokeRectWithWidth(ctx, CGRectMake(point.x, point.y, 100., 100.), 10.);
        
        CGContextRestoreGState(ctx);
    }
}

@end
