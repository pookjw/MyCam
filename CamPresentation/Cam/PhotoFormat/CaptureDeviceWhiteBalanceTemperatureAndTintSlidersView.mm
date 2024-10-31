//
//  CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/AVCaptureDevice+ValidWhiteBalanceGains.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UISlider *temperatureSlider;
@property (retain, nonatomic, readonly) UISlider *tintSlider;
@end

@implementation CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView
@synthesize stackView = _stackView;
@synthesize temperatureSlider = _temperatureSlider;
@synthesize tintSlider = _tintSlider;

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        
        UIStackView *stackView = self.stackView;
        [self addSubview:stackView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
        
        [captureDevice addObserver:self forKeyPath:@"deviceWhiteBalanceGains" options:NSKeyValueObservingOptionNew context:nullptr];
        
        dispatch_async(captureService.captureSessionQueue, ^{
            [self queue_updateAttributes];
        });
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"deviceWhiteBalanceGains"];
    [_captureDevice release];
    [_stackView release];
    [_temperatureSlider release];
    [_tintSlider release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"deviceWhiteBalanceGains"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.temperatureSlider,
        self.tintSlider
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UISlider *)temperatureSlider {
    if (auto temperatureSlider = _temperatureSlider) return temperatureSlider;
    
    UISlider *temperatureSlider = [UISlider new];
    
    temperatureSlider.minimumValue = 2000.f;
    temperatureSlider.maximumValue = 10000.f;
    temperatureSlider.continuous = YES;
    temperatureSlider.enabled = self.captureDevice.lockingWhiteBalanceWithCustomDeviceGainsSupported;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto slider = static_cast<UISlider *>(action.sender);
        float value = slider.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            AVCaptureWhiteBalanceGains deviceWhiteBalanceGains = captureDevice.deviceWhiteBalanceGains;
            
            AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTintValues = [captureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
            temperatureAndTintValues.temperature = value;
            
            AVCaptureWhiteBalanceGains gains = [captureDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTintValues];
            
            if (![captureDevice cp_isValidWhiteBalanceGains:gains]) {
                NSLog(@"Out of range. Ignored.");
                [captureDevice unlockForConfiguration];
                return;
            }
            
            [captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:^(CMTime syncTime) {
                
            }];
            
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [temperatureSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _temperatureSlider = [temperatureSlider retain];
    return [temperatureSlider autorelease];
}

- (UISlider *)tintSlider {
    if (auto tintSlider = _tintSlider) return tintSlider;
    
    UISlider *tintSlider = [UISlider new];
    
    tintSlider.minimumValue = -150.f;
    tintSlider.maximumValue = 150.f;
    tintSlider.continuous = YES;
    tintSlider.enabled = self.captureDevice.lockingWhiteBalanceWithCustomDeviceGainsSupported;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto slider = static_cast<UISlider *>(action.sender);
        float value = slider.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            AVCaptureWhiteBalanceGains deviceWhiteBalanceGains = captureDevice.deviceWhiteBalanceGains;
            
            AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTintValues = [captureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
            temperatureAndTintValues.tint = value;
            
            AVCaptureWhiteBalanceGains gains = [captureDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTintValues];
            
            if (![captureDevice cp_isValidWhiteBalanceGains:gains]) {
                NSLog(@"Out of range. Ignored.");
                [captureDevice unlockForConfiguration];
                return;
            }
            
            [captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:^(CMTime syncTime) {
                
            }];
            
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [tintSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _tintSlider = [tintSlider retain];
    return [tintSlider autorelease];
}

- (void)queue_updateAttributes {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    AVCaptureWhiteBalanceGains deviceWhiteBalanceGains = self.captureDevice.deviceWhiteBalanceGains;
    
    if (![self.captureDevice cp_isValidWhiteBalanceGains:deviceWhiteBalanceGains]) {
        NSLog(@"Out of range. Ignored.");
        return;
    }
    
    AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTintValues = [self.captureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UISlider *temperatureSlider = self.temperatureSlider;
        UISlider *tintSlider = self.tintSlider;
        
        if (!temperatureSlider.isTracking) {
            temperatureSlider.value = temperatureAndTintValues.temperature;
        }
        
        if (!tintSlider.isTracking) {
            tintSlider.value = temperatureAndTintValues.tint;
        }
    });
}

@end

#endif
