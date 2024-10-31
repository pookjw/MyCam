//
//  CaptureDeviceWhiteBalanceChromaticitySlidersView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/CaptureDeviceWhiteBalanceChromaticitySlidersView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/AVCaptureDevice+ValidWhiteBalanceGains.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureDeviceWhiteBalanceChromaticitySlidersView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UISlider *xSlider;
@property (retain, nonatomic, readonly) UISlider *ySlider;
@end

@implementation CaptureDeviceWhiteBalanceChromaticitySlidersView
@synthesize stackView = _stackView;
@synthesize xSlider = _xSlider;
@synthesize ySlider = _ySlider;

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
    [_xSlider release];
    [_ySlider release];
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
        self.xSlider,
        self.ySlider
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UISlider *)xSlider {
    if (auto xSlider = _xSlider) return xSlider;
    
    UISlider *xSlider = [UISlider new];
    
    xSlider.minimumValue = 0.f;
    xSlider.maximumValue = 1.f;
    xSlider.continuous = YES;
    xSlider.enabled = self.captureDevice.lockingWhiteBalanceWithCustomDeviceGainsSupported;
    
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
            
            AVCaptureWhiteBalanceChromaticityValues chromaticityValues = [captureDevice chromaticityValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
            chromaticityValues.x = value;
            
            AVCaptureWhiteBalanceGains gains = [captureDevice deviceWhiteBalanceGainsForChromaticityValues:chromaticityValues];
            
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
    
    [xSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _xSlider = [xSlider retain];
    return [xSlider autorelease];
}

- (UISlider *)ySlider {
    if (auto ySlider = _ySlider) return ySlider;
    
    UISlider *ySlider = [UISlider new];
    
    ySlider.minimumValue = 0.f;
    ySlider.maximumValue = 1.f;
    ySlider.continuous = YES;
    ySlider.enabled = self.captureDevice.lockingWhiteBalanceWithCustomDeviceGainsSupported;
    
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
            
            AVCaptureWhiteBalanceChromaticityValues chromaticityValues = [captureDevice chromaticityValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
            chromaticityValues.y = value;
            
            AVCaptureWhiteBalanceGains gains = [captureDevice deviceWhiteBalanceGainsForChromaticityValues:chromaticityValues];
            
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
    
    [ySlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _ySlider = [ySlider retain];
    return [ySlider autorelease];
}

- (void)queue_updateAttributes {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    AVCaptureWhiteBalanceGains deviceWhiteBalanceGains = self.captureDevice.deviceWhiteBalanceGains;
    
    if (![self.captureDevice cp_isValidWhiteBalanceGains:deviceWhiteBalanceGains]) {
        NSLog(@"Out of range. Ignored.");
        return;
    }
    
    AVCaptureWhiteBalanceChromaticityValues chromaticityValues = [self.captureDevice chromaticityValuesForDeviceWhiteBalanceGains:deviceWhiteBalanceGains];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UISlider *xSlider = self.xSlider;
        UISlider *ySlider = self.ySlider;
        
        if (!xSlider.isTracking) {
            xSlider.value = chromaticityValues.x;
        }
        
        if (!ySlider.isTracking) {
            ySlider.value = chromaticityValues.y;
        }
    });
}

@end

#endif
