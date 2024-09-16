//
//  CameraRootViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import <CamPresentation/CameraRootViewController.h>
#import <CamPresentation/CaptureService.h>
#import <CamPresentation/CaptureVideoPreviewView.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CameraRootViewController () <CaptureServiceDelegate>
@property (nonatomic, readonly) CaptureVideoPreviewView *captureVideoPreviewView;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureDevicesBarButtonItem;
@property (retain, nonatomic, readonly) UIDeferredMenuElement *captureDevicesMenuElement;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@end

@implementation CameraRootViewController
@synthesize captureBarButtonItem = _captureBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
@synthesize captureDevicesMenuElement = _captureDevicesMenuElement;
@synthesize captureService = _captureService;

- (void)dealloc {
    [_captureBarButtonItem release];
    [_captureDevicesBarButtonItem release];
    [_captureDevicesMenuElement release];
    [_captureService release];
    [super dealloc];
}

- (void)loadView {
    CaptureVideoPreviewView *captureVideoPreviewView = [CaptureVideoPreviewView new];
    self.view = captureVideoPreviewView;
    [captureVideoPreviewView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVCaptureEventInteraction *captureEventInteraction = [[AVCaptureEventInteraction alloc] initWithPrimaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        NSLog(@"Primary");
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        NSLog(@"Secondary");
    }];
    
    [self.view addInteraction:captureEventInteraction];
    [captureEventInteraction release];
    
    [self setToolbarItems:@[
        [UIBarButtonItem flexibleSpaceItem],
        self.captureDevicesBarButtonItem
    ]];
    
    //
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = self.captureVideoPreviewView.captureVideoPreviewLayer;
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_selectDefaultCaptureDevice];
        [self.captureService queue_registerCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        [self.captureService.captureSession startRunning];
    });
}

- (CaptureVideoPreviewView *)captureVideoPreviewView {
    return static_cast<CaptureVideoPreviewView *>(self.view);
}

- (UIBarButtonItem *)captureDevicesBarButtonItem {
    if (auto captureDevicesBarButtonItem = _captureDevicesBarButtonItem) return captureDevicesBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        self.captureDevicesMenuElement
    ]];
    
    UIBarButtonItem *captureDevicesBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] menu:menu];
    
    _captureDevicesBarButtonItem = [captureDevicesBarButtonItem retain];
    return [captureDevicesBarButtonItem autorelease];
}

- (UIDeferredMenuElement *)captureDevicesMenuElement {
    if (auto captureDevicesMenuElement = _captureDevicesMenuElement) return captureDevicesMenuElement;
    
    CaptureService *captureService = self.captureService;
    __weak auto weakSelf = self;
    
    UIDeferredMenuElement *captureDevicesMenuElement = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            AVCaptureDevice *selectedCaptureDevice = captureService.queue_selectedCaptureDevice;
            NSArray<AVCaptureDevice *> *devices = captureService.captureDeviceDiscoverySession.devices;
            NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:devices.count];
            
            for (AVCaptureDevice *captureDevice in devices) {
                UIImage *image;
                if (captureDevice.deviceType == AVCaptureDeviceTypeExternal) {
                    image = [UIImage systemImageNamed:@"web.camera"];
                } else {
                    image = [UIImage systemImageNamed:@"camera"];
                }
                
                UIAction *action = [UIAction actionWithTitle:captureDevice.localizedName
                                                       image:image
                                                  identifier:captureDevice.uniqueID
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        captureService.queue_selectedCaptureDevice = captureDevice;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(weakSelf.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
                        });
                    });
                }];
                
                action.state = ([captureDevice isEqual:selectedCaptureDevice] ? UIMenuElementStateOn : UIMenuElementStateOff);
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.subtitle = captureDevice.manufacturer;
                
                [actions addObject:action];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(actions);
            });
            
            [actions release];
        });
    }];
    
    _captureDevicesMenuElement = [captureDevicesMenuElement retain];
    return captureDevicesMenuElement;
}

- (CaptureService *)captureService {
    if (auto captureService = _captureService) return captureService;
    
    CaptureService *captureService = [CaptureService new];
    captureService.delegate = self;
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (void)didChangeCaptureDeviceStatus:(CaptureService *)captureService {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

@end
