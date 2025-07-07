//
//  FocusRectLayer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/FocusRectLayer.h>

#if !TARGET_OS_VISION

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
        [self addKeyValueObservers];
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:FocusRectLayer.class]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<FocusRectLayer *>(self);
        _captureDevice = [casted->_captureDevice retain];
        _videoPreviewLayer = [casted->_videoPreviewLayer retain];
        [self addKeyValueObservers];
    }
    
    return self;
}

- (void)dealloc {
    [_captureDevice removeObserver:self forKeyPath:@"focusPointOfInterest"];
    [_captureDevice removeObserver:self forKeyPath:@"focusMode"];
    if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
        [_captureDevice removeObserver:self forKeyPath:@"focusRectOfInterest"];
    }
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
        } else if ([keyPath isEqualToString:@"focusRectOfInterest"]) {
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
        
        CGRect rect;
        if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
            CGRect defaultRect = [self.captureDevice defaultRectForFocusPointOfInterest:self.captureDevice.focusPointOfInterest];
            CGPoint minOrigin = CGPointMake(CGRectGetMinX(defaultRect), CGRectGetMinY(defaultRect));
            CGPoint maxOrigin = CGPointMake(CGRectGetMaxX(defaultRect), CGRectGetMaxY(defaultRect));
            
            minOrigin = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:minOrigin];
            maxOrigin = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:maxOrigin];
            
            CGRect r1 = CGRectMake(minOrigin.x, minOrigin.y, 0., 0.);
            CGRect r2 = CGRectMake(maxOrigin.x, maxOrigin.y, 0., 0.);
            rect = CGRectUnion(r1, r2);
        } else {
            CGPoint point = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:captureDevice.focusPointOfInterest];
            rect = CGRectMake(point.x - 50., point.y - 50., 100., 100.);
        }
        
        
        CGContextSaveGState(ctx);
        
        CGContextSetStrokeColorWithColor(ctx, color);
        CGContextStrokeRectWithWidth(ctx, rect, 10.);
        
        CATextLayer *textLayer = [CATextLayer new];
        textLayer.string = @"Focus (P)";
        textLayer.foregroundColor = color;
        CGColorRelease(color);
        textLayer.fontSize = 15.;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.contentsScale = self.contentsScale;
        textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(rect), 30.);
        CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetWidth(textLayer.frame) * 0.5, CGRectGetMidY(rect) - CGRectGetHeight(textLayer.frame) * 0.5));
        [textLayer renderInContext:ctx];
        [textLayer release];
        
        CGContextRestoreGState(ctx);
    }
    
    if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
        if (captureDevice.isFocusRectOfInterestSupported) {
            CGRect focusRectOfInterest = self.captureDevice.focusRectOfInterest;
            if (!CGRectIsNull(focusRectOfInterest) && !CGRectIsEmpty(focusRectOfInterest)) {
                CGPoint minOrigin = CGPointMake(CGRectGetMinX(focusRectOfInterest), CGRectGetMinY(focusRectOfInterest));
                CGPoint maxOrigin = CGPointMake(CGRectGetMaxX(focusRectOfInterest), CGRectGetMaxY(focusRectOfInterest));
                
                minOrigin = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:minOrigin];
                maxOrigin = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:maxOrigin];
                
                CGRect r1 = CGRectMake(minOrigin.x, minOrigin.y, 0., 0.);
                CGRect r2 = CGRectMake(maxOrigin.x, maxOrigin.y, 0., 0.);
                CGRect rect = CGRectUnion(r1, r2);
                
                CGContextSaveGState(ctx);
                
                CGColorRef color = CGColorCreateGenericRGB(1., 0., 0., 1.);
                CGContextSetStrokeColorWithColor(ctx, color);
                CGContextStrokeRectWithWidth(ctx, rect, 10.);
                
                CATextLayer *textLayer = [CATextLayer new];
                textLayer.string = @"Focus (R)";
                textLayer.foregroundColor = color;
                CGColorRelease(color);
                textLayer.fontSize = 15.;
                textLayer.alignmentMode = kCAAlignmentCenter;
                textLayer.contentsScale = self.contentsScale;
                textLayer.frame = CGRectMake(0., 0., CGRectGetWidth(rect), 30.);
                CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetWidth(textLayer.frame) * 0.5, CGRectGetMidY(rect) - CGRectGetHeight(textLayer.frame) * 0.5));
                [textLayer renderInContext:ctx];
                [textLayer release];
                
                CGContextRestoreGState(ctx);
            }
        }
    }
}

- (void)addKeyValueObservers {
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    [captureDevice addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"focusMode" options:NSKeyValueObservingOptionNew context:nullptr];
    
    if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
        [captureDevice addObserver:self forKeyPath:@"focusRectOfInterest" options:NSKeyValueObservingOptionNew context:nullptr];
    }
}

@end

#endif
