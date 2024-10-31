//
//  CaptureDeviceWhiteBalanceInfoView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/CaptureDeviceWhiteBalanceInfoView.h>
#import <CamPresentation/UIView+MenuElementDynamicHeight.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureDeviceWhiteBalanceInfoView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UILabel *label;
@end

@implementation CaptureDeviceWhiteBalanceInfoView
@synthesize label = _label;

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        
        UILabel *label = self.label;
        [self addSubview:label];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), label);
        [captureDevice addObserver:self forKeyPath:@"deviceWhiteBalanceGains" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"grayWorldDeviceWhiteBalanceGains" options:NSKeyValueObservingOptionNew context:nullptr];
        
        [self updateLabel];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_captureDevice release];
    [_label release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"deviceWhiteBalanceGains"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"grayWorldDeviceWhiteBalanceGains"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.001;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)updateLabel {
    NSMutableString *string = [NSMutableString new];
    
    AVCaptureWhiteBalanceGains deviceWhiteBalanceGains = self.captureDevice.deviceWhiteBalanceGains;
    [string appendFormat:@"deviceWhiteBalanceGains : (r: %lf, g: %lf, b: %lf)", deviceWhiteBalanceGains.redGain, deviceWhiteBalanceGains.greenGain, deviceWhiteBalanceGains.blueGain];
    
    AVCaptureWhiteBalanceTemperatureAndTintValues deviceWhiteTemperatureAndTintValues = [self.captureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:self.captureDevice.deviceWhiteBalanceGains];
    [string appendString:@"\n"];
    [string appendFormat:@"temperature (dw): %lfK", deviceWhiteTemperatureAndTintValues.temperature];
    [string appendString:@"\n"];
    [string appendFormat:@"tint (dw): %lfK", deviceWhiteTemperatureAndTintValues.tint];
    
    [string appendString:@"\n-----"];
    
    AVCaptureWhiteBalanceGains grayWorldDeviceWhiteBalanceGains = self.captureDevice.grayWorldDeviceWhiteBalanceGains;
    [string appendString:@"\n"];
    [string appendFormat:@"grayWorldDeviceWhiteBalanceGains : (r: %lf, g: %lf, b: %lf)", grayWorldDeviceWhiteBalanceGains.redGain, grayWorldDeviceWhiteBalanceGains.greenGain, grayWorldDeviceWhiteBalanceGains.blueGain];
    
    AVCaptureWhiteBalanceTemperatureAndTintValues grayWorldDeviceWhiteTemperatureAndTintValues = [self.captureDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:self.captureDevice.grayWorldDeviceWhiteBalanceGains];
    [string appendString:@"\n"];
    [string appendFormat:@"temperature (gwdw): %lfK", grayWorldDeviceWhiteTemperatureAndTintValues.temperature];
    [string appendString:@"\n"];
    [string appendFormat:@"tint (gwdw): %lfK", grayWorldDeviceWhiteTemperatureAndTintValues.tint];
    
    [string appendString:@"\n-----\n"];
    [string appendFormat:@"maxWhiteBalanceGain : %lf", self.captureDevice.maxWhiteBalanceGain];
    
    
    self.label.text = string;
    [string release];
    
    [self _cp_updateMenuElementHeight];
}

@end
