//
//  CaptureDeviceFrameRateRangeSlidersView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/25/24.
//

#import <CamPresentation/CaptureDeviceFrameRateRangeSlidersView.h>

@interface CaptureDeviceFrameRateRangeSlidersView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) AVFrameRateRange *frameRateRange;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UILabel *label;
@property (retain, nonatomic, readonly) UISlider *minSlider;
@property (retain, nonatomic, readonly) UISlider *maxSlider;
@end

@implementation CaptureDeviceFrameRateRangeSlidersView
@synthesize stackView = _stackView;
@synthesize label = _label;
@synthesize minSlider = _minSlider;
@synthesize maxSlider = _maxSlider;

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
    [_minSlider release];
    [_maxSlider release];
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
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.label,
        self.minSlider,
        self.maxSlider
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
    label.text = @"\n\n";
    label.numberOfLines = 0;
    label.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.001;
    
    _label = [label retain];
    return [label autorelease];
}

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
            
            captureDevice.activeVideoMinFrameDuration = CMTimeMakeWithSeconds(value, captureDevice.activeVideoMinFrameDuration.timescale);
            
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
            
            captureDevice.activeVideoMaxFrameDuration = CMTimeMakeWithSeconds(value, captureDevice.activeVideoMaxFrameDuration.timescale);
            
            [captureDevice unlockForConfiguration];
        });
    }]
        forControlEvents:UIControlEventValueChanged];
    
    _maxSlider = [maxSlider retain];
    return [maxSlider autorelease];
}

- (void)queue_updateAttributes {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    CMTime activeVideoMinFrameDuration = captureDevice.activeVideoMinFrameDuration;
    CMTime activeVideoMaxFrameDuration = captureDevice.activeVideoMaxFrameDuration;
    
    AVFrameRateRange *frameRateRange = self.frameRateRange;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = self.label;
        label.text = [NSString stringWithFormat:@"%@ : %lf / %lf", frameRateRange, CMTimeGetSeconds(activeVideoMinFrameDuration), CMTimeGetSeconds(activeVideoMaxFrameDuration)];
        
        UISlider *minSlider = self.minSlider;
        minSlider.minimumValue = CMTimeGetSeconds(frameRateRange.minFrameDuration);
        minSlider.maximumValue = CMTimeGetSeconds(activeVideoMaxFrameDuration);
        if (!minSlider.isTracking) {
            minSlider.value = CMTimeGetSeconds(activeVideoMinFrameDuration);
        }
        
        UISlider *maxSlider = self.maxSlider;
        maxSlider.minimumValue = CMTimeGetSeconds(activeVideoMinFrameDuration);
        maxSlider.maximumValue = CMTimeGetSeconds(frameRateRange.maxFrameDuration);
        
        if (!maxSlider.isTracking) {
            maxSlider.value = CMTimeGetSeconds(activeVideoMaxFrameDuration);
        }
    });
}

@end
