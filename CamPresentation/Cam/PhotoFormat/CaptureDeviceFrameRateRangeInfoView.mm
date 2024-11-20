//
//  CaptureDeviceFrameRateRangeInfoView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/25/24.
//

#import <CamPresentation/CaptureDeviceFrameRateRangeInfoView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIView+MenuElementDynamicHeight.h>

@interface CaptureDeviceFrameRateRangeInfoView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) AVFrameRateRange *frameRateRange;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UILabel *label;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *minSlider;
@property (retain, nonatomic, readonly) UISlider *maxSlider;
#endif
@end

@implementation CaptureDeviceFrameRateRangeInfoView
@synthesize stackView = _stackView;
@synthesize label = _label;
#if !TARGET_OS_TV
@synthesize minSlider = _minSlider;
@synthesize maxSlider = _maxSlider;
#endif

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice frameRateRange:(AVFrameRateRange *)frameRateRange {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        _frameRateRange = [frameRateRange retain];
        
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        [captureDevice addObserver:self forKeyPath:@"activeVideoMinFrameDuration" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"activeVideoMaxFrameDuration" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"autoVideoFrameRateEnabled" options:NSKeyValueObservingOptionNew context:nullptr];
        
        dispatch_async(captureService.captureSessionQueue, ^{
            [self queue_updateAttributes];
        });
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"activeVideoMinFrameDuration"];
    [_captureDevice removeObserver:self forKeyPath:@"activeVideoMaxFrameDuration"];
    [_captureDevice release];
    [_frameRateRange release];
    [_stackView release];
    [_label release];
#if !TARGET_OS_TV
    [_minSlider release];
    [_maxSlider release];
#endif
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"activeVideoMinFrameDuration"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"activeVideoMaxFrameDuration"]) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                [self queue_updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"autoVideoFrameRateEnabled"]) {
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
        self.label,
#if !TARGET_OS_TV
        self.minSlider,
        self.maxSlider
#endif
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillProportionally;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.001;
    
    _label = [label retain];
    return [label autorelease];
}

#if !TARGET_OS_TV
- (UISlider *)minSlider {
    if (auto minSlider = _minSlider) return minSlider;
    
    UISlider *minSlider = [UISlider new];
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    AVFrameRateRange *frameRateRange = self.frameRateRange;
    
    [minSlider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto slider = static_cast<UISlider *>(action.sender);
        float value = slider.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            CMTime duration = CMTimeMakeWithSeconds(value, 1000000UL);
            if (CMTimeCompare(duration, frameRateRange.minFrameDuration) == -1) {
                duration = frameRateRange.minFrameDuration;
            } else if (CMTimeCompare(captureDevice.activeVideoMaxFrameDuration, duration) == -1) {
                duration = captureDevice.activeVideoMaxFrameDuration;
            }
            
            captureDevice.activeVideoMinFrameDuration = duration;
            
            [captureDevice unlockForConfiguration];
        });
    }]
        forControlEvents:UIControlEventValueChanged];
    
    _minSlider = [minSlider retain];
    return [minSlider autorelease];
}

- (UISlider *)maxSlider {
    if (auto maxSlider = _maxSlider) return maxSlider;
    
    UISlider *maxSlider = [UISlider new];
    
    CaptureService *captureService = self.captureService;
    AVCaptureDevice *captureDevice = self.captureDevice;
    AVFrameRateRange *frameRateRange = self.frameRateRange;
    
    [maxSlider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto slider = static_cast<UISlider *>(action.sender);
        float value = slider.value;
        
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            CMTime duration = CMTimeMakeWithSeconds(value, 1000000UL);
            if (CMTimeCompare(frameRateRange.maxFrameDuration, duration) == -1) {
                duration = frameRateRange.maxFrameDuration;
            } else if (CMTimeCompare(duration, captureDevice.activeVideoMinFrameDuration) == -1) {
                duration = captureDevice.activeVideoMinFrameDuration;
            }
            
            captureDevice.activeVideoMaxFrameDuration = duration;
            
            [captureDevice unlockForConfiguration];
        });
    }]
        forControlEvents:UIControlEventValueChanged];
    
    _maxSlider = [maxSlider retain];
    return [maxSlider autorelease];
}
#endif

- (void)queue_updateAttributes {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    CMTime activeVideoMinFrameDuration = captureDevice.activeVideoMinFrameDuration;
    CMTime activeVideoMaxFrameDuration = captureDevice.activeVideoMaxFrameDuration;
    
    AVFrameRateRange *frameRateRange = self.frameRateRange;
    BOOL isAutoVideoFrameRateEnabled = captureDevice.isAutoVideoFrameRateEnabled;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = self.label;
        label.text = [NSString stringWithFormat:@"%@ : %lf / %lf", frameRateRange, CMTimeGetSeconds(activeVideoMinFrameDuration), CMTimeGetSeconds(activeVideoMaxFrameDuration)];
        
#if !TARGET_OS_TV
        UISlider *minSlider = self.minSlider;
        minSlider.minimumValue = CMTimeGetSeconds(frameRateRange.minFrameDuration);
        minSlider.maximumValue = CMTimeGetSeconds(activeVideoMaxFrameDuration);
        if (!minSlider.isTracking) {
            minSlider.value = CMTimeGetSeconds(activeVideoMinFrameDuration);
        }
        minSlider.enabled = !isAutoVideoFrameRateEnabled;
        
        UISlider *maxSlider = self.maxSlider;
        maxSlider.minimumValue = CMTimeGetSeconds(activeVideoMinFrameDuration);
        maxSlider.maximumValue = CMTimeGetSeconds(frameRateRange.maxFrameDuration);
        maxSlider.enabled = !isAutoVideoFrameRateEnabled;
        
        if (!maxSlider.isTracking) {
            maxSlider.value = CMTimeGetSeconds(activeVideoMaxFrameDuration);
        }
#endif
        
        [self _cp_updateMenuElementHeight];
    });
}

#warning videoMinFrameDurationOverride

@end

#endif
