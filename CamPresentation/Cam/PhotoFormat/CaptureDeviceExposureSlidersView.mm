//
//  CaptureDeviceExposureSlidersView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <CamPresentation/CaptureDeviceExposureSlidersView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIView+MenuElementDynamicHeight.h>

#warning TODO whitebalence (AVCaptureExposureDurationCurrent 같은 것들 모아보기)
#warning timesacle 통일

@interface CaptureDeviceExposureSlidersView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UILabel *exposureTargetBiasLabel;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *exposureTargetBiasSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *activeMaxExposureDurationLabel;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *activeMaxExposureDurationSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *exposureDurationLabel;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *exposureDurationSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *ISOLabel;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *ISOSlider;
#endif
@end

@implementation CaptureDeviceExposureSlidersView
@synthesize stackView = _stackView;
@synthesize exposureTargetBiasLabel = _exposureTargetBiasLabel;
#if !TARGET_OS_TV
@synthesize exposureTargetBiasSlider = _exposureTargetBiasSlider;
#endif
@synthesize activeMaxExposureDurationLabel = _activeMaxExposureDurationLabel;
#if !TARGET_OS_TV
@synthesize activeMaxExposureDurationSlider = _activeMaxExposureDurationSlider;
#endif
@synthesize exposureDurationLabel = _exposureDurationLabel;
#if !TARGET_OS_TV
@synthesize exposureDurationSlider = _exposureDurationSlider;
#endif
@synthesize ISOLabel = _ISOLabel;
#if !TARGET_OS_TV
@synthesize ISOSlider = _ISOSlider;
#endif

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
        
        [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"exposureMode" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"exposureTargetBias" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"exposureDuration" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"ISO" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"activeMaxExposureDuration" options:NSKeyValueObservingOptionNew context:nullptr];
        
        dispatch_async(captureService.captureSessionQueue, ^{
            [self queue_updateAttributes];
        });
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [_captureDevice removeObserver:self forKeyPath:@"exposureMode"];
    [_captureDevice removeObserver:self forKeyPath:@"exposureTargetBias"];
    [_captureDevice removeObserver:self forKeyPath:@"exposureDuration"];
    [_captureDevice removeObserver:self forKeyPath:@"ISO"];
    [_captureDevice removeObserver:self forKeyPath:@"activeMaxExposureDuration"];
    [_captureDevice release];
    [_stackView release];
    [_exposureTargetBiasLabel release];
#if !TARGET_OS_TV
    [_exposureTargetBiasSlider release];
#endif
    [_activeMaxExposureDurationLabel release];
#if !TARGET_OS_TV
    [_activeMaxExposureDurationSlider release];
#endif
    [_exposureDurationLabel release];
#if !TARGET_OS_TV
    [_exposureDurationSlider release];
#endif
    [_ISOLabel release];
#if !TARGET_OS_TV
    [_ISOSlider release];
#endif
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([self.captureDevice isEqual:object]) {
        if ([keyPath isEqualToString:@"activeFormat"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"exposureMode"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"exposureTargetBias"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"exposureDuration"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"ISO"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"activeMaxExposureDuration"]) {
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
        self.exposureTargetBiasLabel,
#if !TARGET_OS_TV
        self.exposureTargetBiasSlider,
#endif
        self.activeMaxExposureDurationLabel,
#if !TARGET_OS_TV
        self.activeMaxExposureDurationSlider,
#endif
        self.exposureDurationLabel,
#if !TARGET_OS_TV
        self.exposureDurationSlider,
#endif
        self.ISOLabel,
#if !TARGET_OS_TV
        self.ISOSlider
#endif
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UILabel *)exposureTargetBiasLabel {
    if (auto exposureTargetBiasLabel = _exposureTargetBiasLabel) return exposureTargetBiasLabel;
    
    UILabel *exposureTargetBiasLabel = [UILabel new];
    exposureTargetBiasLabel.textAlignment = NSTextAlignmentCenter;
    exposureTargetBiasLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    exposureTargetBiasLabel.adjustsFontSizeToFitWidth = YES;
    exposureTargetBiasLabel.minimumScaleFactor = 0.001;
    
    _exposureTargetBiasLabel = [exposureTargetBiasLabel retain];
    return [exposureTargetBiasLabel autorelease];
}

#if !TARGET_OS_TV
- (UISlider *)exposureTargetBiasSlider {
    if (auto exposureTargetBiasSlider = _exposureTargetBiasSlider) return exposureTargetBiasSlider;
    
    UISlider *exposureTargetBiasSlider = [UISlider new];
    exposureTargetBiasSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto sender = static_cast<UISlider *>(action.sender);
        float value = sender.value;
        
        AVExposureBiasRange *systemRecommendedExposureBiasRange = captureDevice.activeFormat.systemRecommendedExposureBiasRange;
        if ([systemRecommendedExposureBiasRange containsExposureBias:value]) {
            sender.tintColor = UIColor.systemGreenColor;
        } else {
            sender.tintColor = UIColor.systemRedColor;
        }
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            [captureDevice setExposureTargetBias:value completionHandler:^(CMTime syncTime) {
                
            }];
            
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [exposureTargetBiasSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _exposureTargetBiasSlider = [exposureTargetBiasSlider retain];
    return [exposureTargetBiasSlider autorelease];
}
#endif

- (UILabel *)activeMaxExposureDurationLabel {
    if (auto activeMaxExposureDurationLabel = _activeMaxExposureDurationLabel) return activeMaxExposureDurationLabel;
    
    UILabel *activeMaxExposureDurationLabel = [UILabel new];
    activeMaxExposureDurationLabel.textAlignment = NSTextAlignmentCenter;
    activeMaxExposureDurationLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    activeMaxExposureDurationLabel.adjustsFontSizeToFitWidth = YES;
    activeMaxExposureDurationLabel.minimumScaleFactor = 0.001;
    
    _activeMaxExposureDurationLabel = [activeMaxExposureDurationLabel retain];
    return [activeMaxExposureDurationLabel autorelease];
}

#if !TARGET_OS_TV
- (UISlider *)activeMaxExposureDurationSlider {
    if (auto activeMaxExposureDurationSlider = _activeMaxExposureDurationSlider) return activeMaxExposureDurationSlider;
    
    UISlider *activeMaxExposureDurationSlider = [UISlider new];
    activeMaxExposureDurationSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto sender = static_cast<UISlider *>(action.sender);
        float value = sender.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            CMTime time = CMTimeMakeWithSeconds(value, captureDevice.activeMaxExposureDuration.timescale);
            
            // 소숫점을 상실해서 min 보다 작아짐
            if (CMTimeCompare(time, captureDevice.activeFormat.minExposureDuration) == -1) {
                time = captureDevice.activeFormat.minExposureDuration;
            }
            
            captureDevice.activeMaxExposureDuration = time;
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [activeMaxExposureDurationSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _activeMaxExposureDurationSlider = [activeMaxExposureDurationSlider retain];
    return [activeMaxExposureDurationSlider autorelease];
}
#endif

- (UILabel *)exposureDurationLabel {
    if (auto exposureDurationLabel = _exposureDurationLabel) return exposureDurationLabel;
    
    UILabel *exposureDurationLabel = [UILabel new];
    exposureDurationLabel.textAlignment = NSTextAlignmentCenter;
    exposureDurationLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    exposureDurationLabel.adjustsFontSizeToFitWidth = YES;
    exposureDurationLabel.minimumScaleFactor = 0.001;
    
    _exposureDurationLabel = [exposureDurationLabel retain];
    return [exposureDurationLabel autorelease];
}

#if !TARGET_OS_TV
- (UISlider *)exposureDurationSlider {
    if (auto exposureDurationSlider = _exposureDurationSlider) return exposureDurationSlider;
    
    UISlider *exposureDurationSlider = [UISlider new];
    exposureDurationSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto sender = static_cast<UISlider *>(action.sender);
        float value = sender.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            CMTime time = CMTimeMakeWithSeconds(value, captureDevice.exposureDuration.timescale);
            
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            [captureDevice setExposureModeCustomWithDuration:time ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                
            }];
            
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [exposureDurationSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _exposureDurationSlider = [exposureDurationSlider retain];
    return [exposureDurationSlider autorelease];
}
#endif

- (UILabel *)ISOLabel {
    if (auto ISOLabel = _ISOLabel) return ISOLabel;
    
    UILabel *ISOLabel = [UILabel new];
    ISOLabel.textAlignment = NSTextAlignmentCenter;
    ISOLabel.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    ISOLabel.adjustsFontSizeToFitWidth = YES;
    ISOLabel.minimumScaleFactor = 0.001;
    
    _ISOLabel = [ISOLabel retain];
    return [ISOLabel autorelease];
}

#if !TARGET_OS_TV
- (UISlider *)ISOSlider {
    if (auto ISOSlider = _ISOSlider) return ISOSlider;
    
    UISlider *ISOSlider = [UISlider new];
    ISOSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto sender = static_cast<UISlider *>(action.sender);
        float value = sender.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            [captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:value completionHandler:^(CMTime syncTime) {
                
            }];
            
            [captureDevice unlockForConfiguration];
        });
    }];
    
    [ISOSlider addAction:action forControlEvents:UIControlEventValueChanged];
    
    _ISOSlider = [ISOSlider retain];
    return [ISOSlider autorelease];
}
#endif

- (void)queue_updateAttributes {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    AVCaptureDevice *captureDevice = self.captureDevice;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    AVExposureBiasRange *systemRecommendedExposureBiasRange = activeFormat.systemRecommendedExposureBiasRange;
    
    AVCaptureExposureMode exposureMode = captureDevice.exposureMode;
    
    float maxExposureTargetBias = captureDevice.maxExposureTargetBias;
    float minExposureTargetBias = captureDevice.minExposureTargetBias;
    float exposureTargetBias = captureDevice.exposureTargetBias;
    
    CMTime activeMaxExposureDuration = captureDevice.activeMaxExposureDuration;
    
    CMTime maxExposureDuration = activeFormat.maxExposureDuration;
    CMTime minExposureDuration = activeFormat.minExposureDuration;
    CMTime exposureDuration = captureDevice.exposureDuration;
    
    float maxISO = activeFormat.maxISO;
    float minISO = activeFormat.minISO;
    float ISO = captureDevice.ISO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *exposureTargetBiasLabel = self.exposureTargetBiasLabel;
        exposureTargetBiasLabel.text = [NSString stringWithFormat:@"exposureTargetBias : %lf", exposureTargetBias];
        
#if !TARGET_OS_TV
        UISlider *exposureTargetBiasSlider = self.exposureTargetBiasSlider;
        exposureTargetBiasSlider.maximumValue = maxExposureTargetBias;
        exposureTargetBiasSlider.minimumValue = minExposureTargetBias;
        if (!exposureTargetBiasSlider.isTracking) {
            exposureTargetBiasSlider.value = exposureTargetBias;
        }
        if ([systemRecommendedExposureBiasRange containsExposureBias:exposureTargetBias]) {
            exposureTargetBiasSlider.tintColor = UIColor.systemGreenColor;
        } else {
            exposureTargetBiasSlider.tintColor = UIColor.systemRedColor;
        }
        exposureTargetBiasSlider.enabled = (exposureMode != AVCaptureExposureModeCustom);
#endif
        
        UILabel *activeMaxExposureDurationLabel = self.activeMaxExposureDurationLabel;
        activeMaxExposureDurationLabel.text = [NSString stringWithFormat:@"activeMaxExposureDuration : %lf", CMTimeGetSeconds(activeMaxExposureDuration)];
        
#if !TARGET_OS_TV
        UISlider *activeMaxExposureDurationSlider = self.activeMaxExposureDurationSlider;
        activeMaxExposureDurationSlider.maximumValue = CMTimeGetSeconds(maxExposureDuration);
        activeMaxExposureDurationSlider.minimumValue = CMTimeGetSeconds(minExposureDuration);
        if (!activeMaxExposureDurationSlider.isTracking) {
            activeMaxExposureDurationSlider.value = CMTimeGetSeconds(activeMaxExposureDuration);
        }
        activeMaxExposureDurationSlider.enabled = (exposureMode != AVCaptureExposureModeCustom);
#endif
        
        UILabel *exposureDurationLabel = self.exposureDurationLabel;
        exposureDurationLabel.text = [NSString stringWithFormat:@"exposureDuration : %lf", CMTimeGetSeconds(exposureDuration)];
        
#if !TARGET_OS_TV
        UISlider *exposureDurationSlider = self.exposureDurationSlider;
        exposureDurationSlider.maximumValue = CMTimeGetSeconds(maxExposureDuration);
        exposureDurationSlider.minimumValue = CMTimeGetSeconds(minExposureDuration);
        if (!exposureDurationSlider.isTracking) {
            exposureDurationSlider.value = CMTimeGetSeconds(exposureDuration);
        }
        exposureDurationSlider.enabled = (exposureMode == AVCaptureExposureModeCustom);
#endif
        
        UILabel *ISOLabel = self.ISOLabel;
        ISOLabel.text = [NSString stringWithFormat:@"ISO : %lf", ISO];
        
#if !TARGET_OS_TV
        UISlider *ISOSlider = self.ISOSlider;
        ISOSlider.maximumValue = maxISO;
        ISOSlider.minimumValue = minISO;
        if (!ISOSlider.isTracking) {
            ISOSlider.value = ISO;
        }
        ISOSlider.enabled = (exposureMode == AVCaptureExposureModeCustom);
#endif
        
        [self _cp_updateMenuElementHeight];
    });
    
//    self.captureDevice.activeMaxExposureDuration;
//    self.captureDevice.activeVideoMinFrameDuration;
//    self.captureDevice.activeVideoMaxFrameDuration;
}

@end

#endif
