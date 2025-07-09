//
//  CaptureDeviceExposureSlidersView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/23/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/CaptureDeviceExposureSlidersView.h>
#import <CamPresentation/TVSlider.h>
#import <CamPresentation/UIView+MenuElementDynamicHeight.h>

#warning TODO whitebalence (AVCaptureExposureDurationCurrent 같은 것들 모아보기)
#warning timesacle 통일

@interface CaptureDeviceExposureSlidersView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UILabel *exposureTargetBiasLabel;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *exposureTargetBiasSlider;
#else
@property (retain, nonatomic, readonly) UISlider *exposureTargetBiasSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *activeMaxExposureDurationLabel;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *activeMaxExposureDurationSlider;
#else
@property (retain, nonatomic, readonly) UISlider *activeMaxExposureDurationSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *exposureDurationLabel;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *exposureDurationSlider;
#else
@property (retain, nonatomic, readonly) UISlider *exposureDurationSlider;
#endif
@property (retain, nonatomic, readonly) UILabel *ISOLabel;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *ISOSlider;
#else
@property (retain, nonatomic, readonly) UISlider *ISOSlider;
#endif
@end

@implementation CaptureDeviceExposureSlidersView
@synthesize stackView = _stackView;
@synthesize exposureTargetBiasLabel = _exposureTargetBiasLabel;
@synthesize exposureTargetBiasSlider = _exposureTargetBiasSlider;
@synthesize activeMaxExposureDurationLabel = _activeMaxExposureDurationLabel;
@synthesize activeMaxExposureDurationSlider = _activeMaxExposureDurationSlider;
@synthesize exposureDurationLabel = _exposureDurationLabel;
@synthesize exposureDurationSlider = _exposureDurationSlider;
@synthesize ISOLabel = _ISOLabel;
@synthesize ISOSlider = _ISOSlider;

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
    [_exposureTargetBiasSlider release];
    [_activeMaxExposureDurationLabel release];
    [_activeMaxExposureDurationSlider release];
    [_exposureDurationLabel release];
    [_exposureDurationSlider release];
    [_ISOLabel release];
    [_ISOSlider release];
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

#if TARGET_OS_TV
- (TVSlider *)exposureTargetBiasSlider
#else
- (UISlider *)exposureTargetBiasSlider
#endif
{
    if (auto exposureTargetBiasSlider = _exposureTargetBiasSlider) return exposureTargetBiasSlider;
    
#if TARGET_OS_TV
    TVSlider *exposureTargetBiasSlider = [TVSlider new];
#else
    UISlider *exposureTargetBiasSlider = [UISlider new];
#endif
    exposureTargetBiasSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
        auto sender = static_cast<TVSlider *>(action.sender);
#else
        auto sender = static_cast<UISlider *>(action.sender);
#endif
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
    
#if TARGET_OS_TV
    [exposureTargetBiasSlider addAction:action];
#else
    [exposureTargetBiasSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _exposureTargetBiasSlider = [exposureTargetBiasSlider retain];
    return [exposureTargetBiasSlider autorelease];
}

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

#if TARGET_OS_TV
- (TVSlider *)activeMaxExposureDurationSlider
#else
- (UISlider *)activeMaxExposureDurationSlider
#endif
{
    if (auto activeMaxExposureDurationSlider = _activeMaxExposureDurationSlider) return activeMaxExposureDurationSlider;
    
#if TARGET_OS_TV
    TVSlider *activeMaxExposureDurationSlider = [TVSlider new];
#else
    UISlider *activeMaxExposureDurationSlider = [UISlider new];
#endif
    activeMaxExposureDurationSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
        auto sender = static_cast<TVSlider *>(action.sender);
#else
        auto sender = static_cast<UISlider *>(action.sender);
#endif
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
    
#if TARGET_OS_TV
    [activeMaxExposureDurationSlider addAction:action];
#else
    [activeMaxExposureDurationSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _activeMaxExposureDurationSlider = [activeMaxExposureDurationSlider retain];
    return [activeMaxExposureDurationSlider autorelease];
}

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

#if TARGET_OS_TV
- (TVSlider *)exposureDurationSlider
#else
- (UISlider *)exposureDurationSlider
#endif
{
    if (auto exposureDurationSlider = _exposureDurationSlider) return exposureDurationSlider;
    
#if TARGET_OS_TV
    TVSlider *exposureDurationSlider = [TVSlider new];
#else
    UISlider *exposureDurationSlider = [UISlider new];
#endif
    exposureDurationSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
        auto sender = static_cast<TVSlider *>(action.sender);
#else
        auto sender = static_cast<UISlider *>(action.sender);
#endif
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
    
#if TARGET_OS_TV
    [exposureDurationSlider addAction:action];
#else
    [exposureDurationSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _exposureDurationSlider = [exposureDurationSlider retain];
    return [exposureDurationSlider autorelease];
}

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

#if TARGET_OS_TV
- (TVSlider *)ISOSlider
#else
- (UISlider *)ISOSlider
#endif
{
    if (auto ISOSlider = _ISOSlider) return ISOSlider;
    
#if TARGET_OS_TV
    TVSlider *ISOSlider = [TVSlider new];
#else
    UISlider *ISOSlider = [UISlider new];
#endif
    ISOSlider.continuous = YES;
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
        auto sender = static_cast<TVSlider *>(action.sender);
#else
        auto sender = static_cast<UISlider *>(action.sender);
#endif
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
    
#if TARGET_OS_TV
    [ISOSlider addAction:action];
#else
    [ISOSlider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
    
    _ISOSlider = [ISOSlider retain];
    return [ISOSlider autorelease];
}

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
        
#if TARGET_OS_TV
        TVSlider *exposureTargetBiasSlider = self.exposureTargetBiasSlider;
#else
        UISlider *exposureTargetBiasSlider = self.exposureTargetBiasSlider;
#endif
        exposureTargetBiasSlider.maximumValue = maxExposureTargetBias;
        exposureTargetBiasSlider.minimumValue = minExposureTargetBias;
        
#if TARGET_OS_TV
        if (!exposureTargetBiasSlider.editing)
#else
        if (!exposureTargetBiasSlider.tracking)
#endif
        {
            exposureTargetBiasSlider.value = exposureTargetBias;
        }
        
        if ([systemRecommendedExposureBiasRange containsExposureBias:exposureTargetBias]) {
            exposureTargetBiasSlider.tintColor = UIColor.systemGreenColor;
        } else {
            exposureTargetBiasSlider.tintColor = UIColor.systemRedColor;
        }
        exposureTargetBiasSlider.enabled = (exposureMode != AVCaptureExposureModeCustom);
        
        UILabel *activeMaxExposureDurationLabel = self.activeMaxExposureDurationLabel;
        activeMaxExposureDurationLabel.text = [NSString stringWithFormat:@"activeMaxExposureDuration : %lf", CMTimeGetSeconds(activeMaxExposureDuration)];
        
#if TARGET_OS_TV
        TVSlider *activeMaxExposureDurationSlider = self.activeMaxExposureDurationSlider;
#else
        UISlider *activeMaxExposureDurationSlider = self.activeMaxExposureDurationSlider;
#endif
        activeMaxExposureDurationSlider.maximumValue = CMTimeGetSeconds(maxExposureDuration);
        activeMaxExposureDurationSlider.minimumValue = CMTimeGetSeconds(minExposureDuration);
#if TARGET_OS_TV
        if (!activeMaxExposureDurationSlider.editing)
#else
        if (!activeMaxExposureDurationSlider.tracking)
#endif
        {
            activeMaxExposureDurationSlider.value = CMTimeGetSeconds(activeMaxExposureDuration);
        }
        activeMaxExposureDurationSlider.enabled = (exposureMode != AVCaptureExposureModeCustom);
        
        UILabel *exposureDurationLabel = self.exposureDurationLabel;
        exposureDurationLabel.text = [NSString stringWithFormat:@"exposureDuration : %lf", CMTimeGetSeconds(exposureDuration)];
        
#if TARGET_OS_TV
        TVSlider *exposureDurationSlider = self.exposureDurationSlider;
#else
        UISlider *exposureDurationSlider = self.exposureDurationSlider;
#endif
        exposureDurationSlider.maximumValue = CMTimeGetSeconds(maxExposureDuration);
        exposureDurationSlider.minimumValue = CMTimeGetSeconds(minExposureDuration);
#if TARGET_OS_TV
        if (!exposureDurationSlider.editing)
#else
        if (!exposureDurationSlider.tracking)
#endif
        {
            exposureDurationSlider.value = CMTimeGetSeconds(exposureDuration);
        }
        exposureDurationSlider.enabled = (exposureMode == AVCaptureExposureModeCustom);
        
        UILabel *ISOLabel = self.ISOLabel;
        ISOLabel.text = [NSString stringWithFormat:@"ISO : %lf", ISO];
        
#if TARGET_OS_TV
        TVSlider *ISOSlider = self.ISOSlider;
#else
        UISlider *ISOSlider = self.ISOSlider;
#endif
        ISOSlider.maximumValue = maxISO;
        ISOSlider.minimumValue = minISO;
#if TARGET_OS_TV
        if (!ISOSlider.editing)
#else
        if (!ISOSlider.tracking)
#endif
        {
            ISOSlider.value = ISO;
        }
        ISOSlider.enabled = (exposureMode == AVCaptureExposureModeCustom);
        
        [self _cp_updateMenuElementHeight];
    });
    
//    self.captureDevice.activeMaxExposureDuration;
//    self.captureDevice.activeVideoMinFrameDuration;
//    self.captureDevice.activeVideoMaxFrameDuration;
}

@end

#endif
