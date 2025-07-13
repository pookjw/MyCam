//
//  VideoDeviceZoomFactorSliderView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/10/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/VideoDeviceZoomFactorSliderView.h>
#import <CamPresentation/TVSlider.h>

@interface VideoDeviceZoomFactorSliderView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *videoDevice;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *zoomFactorSlider;
#else
@property (retain, nonatomic, readonly) UISlider *zoomFactorSlider;
#endif
@property (retain, nonatomic, nullable) AVZoomRange *systemRecommendedVideoZoomRange;
@end

@implementation VideoDeviceZoomFactorSliderView
@synthesize zoomFactorSlider = _zoomFactorSlider;

- (instancetype)initWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _videoDevice = [videoDevice retain];
        [self addKeyValueObservsers];
        
        [self addSubview:self.zoomFactorSlider];
        self.zoomFactorSlider.frame = self.bounds;
        self.zoomFactorSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [self removeKeyValueObservers];
    [_videoDevice release];
    [_zoomFactorSlider release];
    [_systemRecommendedVideoZoomRange release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.videoDevice]) {
        if ([keyPath isEqualToString:@"videoZoomFactor"]) {
            [self nonisolated_videoZoomFactorDidChange];
            return;
        } else if ([keyPath isEqualToString:@"activeFormat"]) {
            [self nonisolated_activeFormatDidChange];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#if TARGET_OS_TV
- (TVSlider *)zoomFactorSlider
#else
- (UISlider *)zoomFactorSlider
#endif
{
    if (auto zoomFactorSlider = _zoomFactorSlider) return zoomFactorSlider;
    
#if TARGET_OS_TV
    TVSlider *zoomFactorSlider = [TVSlider new];
#else
    UISlider *zoomFactorSlider = [UISlider new];
#endif
    
    __block auto unretained = self;
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained zoomFactorSliderDidChangeValue];
    }];
    
#if TARGET_OS_TV
    [zoomFactorSlider addAction:action];
#else
    [zoomFactorSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _zoomFactorSlider = zoomFactorSlider;
    return zoomFactorSlider;
}

- (CGFloat)minZoomFactor {
    return self.zoomFactorSlider.minimumValue;
}

- (void)setMinZoomFactor:(CGFloat)minZoomFactor {
    self.zoomFactorSlider.minimumValue = minZoomFactor;
}

- (CGFloat)maxZoomFactor {
    return self.zoomFactorSlider.maximumValue;
}

- (void)setMaxZoomFactor:(CGFloat)maxZoomFactor {
    self.zoomFactorSlider.maximumValue = maxZoomFactor;
}

- (void)zoomFactorSliderDidChangeValue {
    float value = self.zoomFactorSlider.value;
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDevice *videoDevice = self.videoDevice;
        
        NSError * _Nullable error = nil;
        [videoDevice lockForConfiguration:&error];
        assert(error == nil);
        videoDevice.videoZoomFactor = value;
        [videoDevice unlockForConfiguration];
    });
    
    [self updateSliderTintColor];
}

- (void)nonisolated_videoZoomFactorDidChange {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        CGFloat videoZoomFactor = self.videoDevice.videoZoomFactor;
        
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_TV
            if (!self.zoomFactorSlider.editing)
#else
            if (!self.zoomFactorSlider.tracking)
#endif
            {          
                self.zoomFactorSlider.value = videoZoomFactor;
            }
        });
    });
}

- (void)nonisolated_activeFormatDidChange {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVZoomRange * _Nullable systemRecommendedVideoZoomRange = self.videoDevice.activeFormat.systemRecommendedVideoZoomRange;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.systemRecommendedVideoZoomRange = systemRecommendedVideoZoomRange;
            [self updateSliderTintColor];
        });
    });
}

- (void)updateSliderTintColor {
    BOOL containsZoomFactor = [self.systemRecommendedVideoZoomRange containsZoomFactor:self.zoomFactorSlider.value];
    self.zoomFactorSlider.tintColor = containsZoomFactor ? UIColor.systemGreenColor : UIColor.systemOrangeColor;
}

- (void)addKeyValueObservsers {
    AVCaptureDevice *videoDevice = self.videoDevice;
    
    [videoDevice addObserver:self forKeyPath:@"videoZoomFactor" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [videoDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeKeyValueObservers {
    AVCaptureDevice *videoDevice = self.videoDevice;
    
    [videoDevice removeObserver:self forKeyPath:@"videoZoomFactor"];
    [videoDevice removeObserver:self forKeyPath:@"activeFormat"];
}

@end

#endif
