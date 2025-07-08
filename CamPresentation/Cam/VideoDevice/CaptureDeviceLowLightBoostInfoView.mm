//
//  CaptureDeviceLowLightBoostInfoView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/CaptureDeviceLowLightBoostInfoView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIView+MenuElementDynamicHeight.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureDeviceLowLightBoostInfoView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) UILabel *label;
@end

@implementation CaptureDeviceLowLightBoostInfoView
@synthesize label = _label;

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    if (self = [super initWithFrame:CGRectNull]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        
        UILabel *label = self.label;
        [self addSubview:label];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), label);
        
        [captureDevice addObserver:self forKeyPath:@"lowLightBoostEnabled" options:NSKeyValueObservingOptionNew context:nullptr];
        [self updateLabel];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"lowLightBoostEnabled"];
    [_captureDevice release];
    [_label release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"lowLightBoostEnabled"]) {
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
    label.font = [UIFont monospacedDigitSystemFontOfSize:17.0 weight:UIFontWeightRegular];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.001;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)updateLabel {
    self.label.text = [NSString stringWithFormat:@"lowLightBoostEnabled : %d", self.captureDevice.lowLightBoostEnabled];
    [self _cp_updateMenuElementHeight];
}

@end

#endif
