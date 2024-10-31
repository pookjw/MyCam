//
//  CaptureDeviceZoomInfoView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/13/24.
//

#import <CamPresentation/CaptureDeviceZoomInfoView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

@interface CaptureDeviceZoomInfoView ()
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UILabel *label;
@end

@implementation CaptureDeviceZoomInfoView
@synthesize label = _label;

- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureDevice = [captureDevice retain];
        
        UILabel *label = self.label;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:self.topAnchor],
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        [captureDevice addObserver:self forKeyPath:@"videoZoomFactor" options:NSKeyValueObservingOptionNew context:nil];
        [captureDevice addObserver:self forKeyPath:@"isRampingVideoZoom" options:NSKeyValueObservingOptionNew context:nil];
        [captureDevice addObserver:self forKeyPath:@"displayVideoZoomFactorMultiplier" options:NSKeyValueObservingOptionNew context:nil];
        
        [self updateLabel];
    }
    
    return self;
}

- (void)dealloc {
    if (AVCaptureDevice *captureDevice = _captureDevice) {
        [captureDevice removeObserver:self forKeyPath:@"videoZoomFactor"];
        [captureDevice removeObserver:self forKeyPath:@"isRampingVideoZoom"];
        [captureDevice removeObserver:self forKeyPath:@"displayVideoZoomFactorMultiplier"];
    }
    
    [_label release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"videoZoomFactor"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"isRampingVideoZoom"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"displayVideoZoomFactorMultiplier"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    
    _label = [label retain];
    return [label autorelease];
}

- (void)updateLabel {
    AVCaptureDevice *captureDevice = self.captureDevice;
    
    CGFloat videoZoomFactor = captureDevice.videoZoomFactor;
    BOOL isRampingVideoZoom = captureDevice.isRampingVideoZoom;
    CGFloat displayVideoZoomFactorMultiplier = captureDevice.displayVideoZoomFactorMultiplier;
    
    self.label.text = [NSString stringWithFormat:@"Zoom Factor : %lf\nRamping : %d\nDisplay Video Zoom Factor Multiplier : %lf", videoZoomFactor, isRampingVideoZoom, displayVideoZoomFactorMultiplier];
}

@end

#endif
