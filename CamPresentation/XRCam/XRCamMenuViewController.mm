//
//  XRCamMenuViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCamMenuViewController.h>
#import <CamPresentation/UIDeferredMenuElement+XRCaptureDevices.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface XRCamMenuViewController ()
@property (retain, nonatomic, readonly) XRCaptureService *captureService;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *devicesButton;
@end

@implementation XRCamMenuViewController
@synthesize stackView = _stackView;
@synthesize devicesButton = _devicesButton;

- (instancetype)initWithCaptureService:(XRCaptureService *)captureService {
    if (self = [super init]) {
        _captureService = [captureService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_stackView release];
    [_devicesButton release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.stackView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    reinterpret_cast<void (*)(id, SEL, UIBlurEffectStyle)>(objc_msgSend)(self.view, sel_registerName("sws_enablePlatter:"), UIBlurEffectStyleSystemMaterial);
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return [[stackView retain] autorelease];
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.devicesButton
    ]];
    
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)devicesButton {
    if (auto devicesButton = _devicesButton) return [[devicesButton retain] autorelease];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"arrow.trianglehead.2.clockwise.rotate.90.camera"];
    
    UIButton *devicesButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    devicesButton.menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_xr_captureDevicesElementWithCaptureService:self.captureService selectionHandler:nil deselectionHandler:nil]
    ]];
    devicesButton.showsMenuAsPrimaryAction = YES;
    devicesButton.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _devicesButton = [devicesButton retain];
    return devicesButton;
}

@end

#endif
