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
#import <CamPresentation/UIDeferredMenuElement+XRVideoDeviceConfiguration.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface XRCamMenuViewController ()
@property (retain, nonatomic, readonly) XRCaptureService *captureService;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *capturePhotoButton;
@property (retain, nonatomic, readonly) UIButton *devicesButton;
@property (retain, nonatomic, readonly) UIButton *deviceConfigurationButton;
@end

@implementation XRCamMenuViewController
@synthesize stackView = _stackView;
@synthesize capturePhotoButton = _capturePhotoButton;
@synthesize devicesButton = _devicesButton;
@synthesize deviceConfigurationButton = _deviceConfigurationButton;

- (instancetype)initWithCaptureService:(XRCaptureService *)captureService {
    if (self = [super init]) {
        _captureService = [captureService retain];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didReceiveAddedCaptureDeviceNotification:) name:XRCaptureServiceAddedCaptureDeviceNotificationName object:captureService];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didReceiveRemovedCaptureDeviceNotification:) name:XRCaptureServiceRemovedCaptureDeviceNotificationName object:captureService];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_captureService release];
    [_stackView release];
    [_capturePhotoButton release];
    [_devicesButton release];
    [_deviceConfigurationButton release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.stackView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self _captureSessionQueue_updateButtons];
    });
    
    reinterpret_cast<void (*)(id, SEL, UIBlurEffectStyle)>(objc_msgSend)(self.view, sel_registerName("sws_enablePlatter:"), UIBlurEffectStyleSystemMaterial);
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return [[stackView retain] autorelease];
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.capturePhotoButton,
        self.devicesButton,
        self.deviceConfigurationButton
    ]];
    
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)capturePhotoButton {
    if (auto capturePhotoButton = _capturePhotoButton) return [[capturePhotoButton retain] autorelease];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"camera.shutter.button.fill"];
    
    UIButton *capturePhotoButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    capturePhotoButton.enabled = NO;
    [capturePhotoButton addTarget:self action:@selector(_didTriggerCapturePhotoButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _capturePhotoButton = [capturePhotoButton retain];
    return capturePhotoButton;
}

- (UIButton *)devicesButton {
    if (auto devicesButton = _devicesButton) return [[devicesButton retain] autorelease];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"arrow.trianglehead.2.clockwise.rotate.90.camera.fill"];
    
    UIButton *devicesButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    devicesButton.menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_xr_captureDevicesElementWithCaptureService:self.captureService selectionHandler:nil deselectionHandler:nil]
    ]];
    devicesButton.showsMenuAsPrimaryAction = YES;
    devicesButton.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _devicesButton = [devicesButton retain];
    return devicesButton;
}

- (UIButton *)deviceConfigurationButton {
    if (auto deviceConfigurationButton = _deviceConfigurationButton) return [[deviceConfigurationButton retain] autorelease];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"gearshape.fill"];
    
    UIButton *deviceConfigurationButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    deviceConfigurationButton.enabled = NO;
    deviceConfigurationButton.showsMenuAsPrimaryAction = YES;
    deviceConfigurationButton.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _deviceConfigurationButton = [deviceConfigurationButton retain];
    return deviceConfigurationButton;
}

- (void)_didReceiveAddedCaptureDeviceNotification:(NSNotification *)notification {
    [self _captureSessionQueue_updateButtons];
}

- (void)_didReceiveRemovedCaptureDeviceNotification:(NSNotification *)notification {
    [self _captureSessionQueue_updateButtons];
}

- (void)_captureSessionQueue_updateButtons {
    NSSet<AVCaptureDevice *> *videoDevices = self.captureService.queue_addedVideoDevices;
    assert(videoDevices.count == 0 or videoDevices.count == 1);
    
    if (videoDevices.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.capturePhotoButton.enabled = NO;
            self.deviceConfigurationButton.menu = nil;
            self.deviceConfigurationButton.enabled = NO;
        });
    } else {
        AVCaptureDevice *videoDevice = videoDevices.allObjects[0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.capturePhotoButton.enabled = YES;
            self.deviceConfigurationButton.menu = [UIMenu menuWithChildren:@[
                [UIDeferredMenuElement cp_xr_videoDeviceConfigurationElementWithCaptureService:self.captureService videoDevice:videoDevice didChangeHandler:nil]
            ]];
            self.deviceConfigurationButton.enabled = YES;
        });
    }
}

- (void)_didTriggerCapturePhotoButton:(UIButton *)sender {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        for (AVCaptureDevice *videoDevice in self.captureService.queue_addedVideoDevices) {
            [self.captureService queue_startPhotoCaptureWithVideoDevice:videoDevice];
        }
    });
}

@end

#endif
