//
//  DeviceInputSimulatedApertureSliderView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/DeviceInputSimulatedApertureSliderView.h>
#import <CamPresentation/TVSlider.h>

@interface DeviceInputSimulatedApertureSliderView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDeviceInput *deviceInput;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *simulatedApertureSlider;
#else
@property (retain, nonatomic, readonly) UISlider *simulatedApertureSlider;
#endif
@end

@implementation DeviceInputSimulatedApertureSliderView
@synthesize simulatedApertureSlider = _simulatedApertureSlider;

- (instancetype)initWithCaptureService:(CaptureService *)captureService deviceInput:(AVCaptureDeviceInput *)deviceInput {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _deviceInput = [deviceInput retain];
        
        [self addSubview:self.simulatedApertureSlider];
        self.simulatedApertureSlider.frame = self.bounds;
        self.simulatedApertureSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addKeyValueObservers];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_deviceInput release];
    [_simulatedApertureSlider release];
    [self removeKeyValueObservers];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (([keyPath isEqualToString:@"simulatedAperture"]) && ([object isEqual:self.deviceInput])) {
        [self nonisolated_simulatedApertureDidChange];
        return;
    } else if ([keyPath isEqualToString:@"activeFormat"] && ([object isEqual:self.deviceInput.device])) {
        [self nonisolated_activeFormatDidChange];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#if TARGET_OS_TV
- (TVSlider *)simulatedApertureSlider
#else
- (UISlider *)simulatedApertureSlider
#endif
{
    if (auto simulatedApertureSlider = _simulatedApertureSlider) return simulatedApertureSlider;
    
#if TARGET_OS_TV
    TVSlider *simulatedApertureSlider = [TVSlider new];
#else
    UISlider *simulatedApertureSlider = [UISlider new];
#endif
    
    __block auto unretained = self;
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained sliderValueDidChange];
    }];
    
#if TARGET_OS_TV
    [simulatedApertureSlider addAction:action];
#else
    [simulatedApertureSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _simulatedApertureSlider = simulatedApertureSlider;
    return simulatedApertureSlider;
}

- (void)sliderValueDidChange {
    float value = self.simulatedApertureSlider.value;
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService.queue_captureSession beginConfiguration];
        self.deviceInput.simulatedAperture = value;
        [self.captureService.queue_captureSession commitConfiguration];
    });
}

- (void)addKeyValueObservers {
    [self.deviceInput addObserver:self forKeyPath:@"simulatedAperture" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [self.deviceInput.device addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeKeyValueObservers {
    [self.deviceInput removeObserver:self forKeyPath:@"simulatedAperture"];
    [self.deviceInput.device removeObserver:self forKeyPath:@"activeFormat"];
}

- (void)nonisolated_simulatedApertureDidChange {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        float simulatedAperture = self.deviceInput.simulatedAperture;
        
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_TV
            if (self.simulatedApertureSlider.editing)
#else
            if (self.simulatedApertureSlider.tracking)
#endif
            {
                self.simulatedApertureSlider.value = simulatedAperture;
            }
        });
    });
}

- (void)nonisolated_activeFormatDidChange {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDeviceFormat *activeFormat = self.deviceInput.device.activeFormat;
        float minSimulatedAperture = activeFormat.minSimulatedAperture;
        float maxSimulatedAperture = activeFormat.maxSimulatedAperture;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.simulatedApertureSlider.minimumValue = minSimulatedAperture;
            self.simulatedApertureSlider.maximumValue = maxSimulatedAperture;
        });
    });
}

- (void)setToDefaultSimulatedAperture {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDeviceFormat *activeFormat = self.deviceInput.device.activeFormat;
        float defaultSimulatedAperture = activeFormat.defaultSimulatedAperture;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.simulatedApertureSlider.value = defaultSimulatedAperture;
        });
    });
}

@end

#endif
