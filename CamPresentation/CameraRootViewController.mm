//
//  CameraRootViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import <CamPresentation/CameraRootViewController.h>
#import <CamPresentation/CaptureService.h>
#import <CamPresentation/CaptureVideoPreviewView.h>
#import <CamPresentation/CameraRootPhotoModel.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CameraRootViewController () <CaptureServiceDelegate>
@property (class, assign, nonatomic, readonly) void *availablePhotoPixelFormatTypesKey;
@property (class, assign, nonatomic, readonly) void *availableRawPhotoPixelFormatTypesKey;
@property (nonatomic, readonly) CaptureVideoPreviewView *captureVideoPreviewView;
@property (retain, nonatomic, readonly) UIBarButtonItem *photosBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureDevicesBarButtonItem;
@property (retain, nonatomic, readonly) UIDeferredMenuElement *captureDevicesMenuElement;
@property (retain, nonatomic, readonly) UIBarButtonItem *formatBarButtonItem;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) CameraRootPhotoModel *photoModel;
@end

@implementation CameraRootViewController
@synthesize photosBarButtonItem = _photosBarButtonItem;
@synthesize captureBarButtonItem = _captureBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
@synthesize captureDevicesMenuElement = _captureDevicesMenuElement;
@synthesize formatBarButtonItem = _formatBarButtonItem;
@synthesize captureService = _captureService;
@synthesize photoModel = _photoModel;

+ (void *)availablePhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

+ (void *)availableRawPhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

- (void)dealloc {
    [_photosBarButtonItem release];
    [_captureBarButtonItem release];
    [_captureDevicesBarButtonItem release];
    [_captureDevicesMenuElement release];
    [_formatBarButtonItem release];
    [_captureService release];
    [_photoModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == CameraRootViewController.availablePhotoPixelFormatTypesKey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.formatBarButtonItem, sel_registerName("_updateMenuInPlace"));
        });
    } else if (context == CameraRootViewController.availableRawPhotoPixelFormatTypesKey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.formatBarButtonItem, sel_registerName("_updateMenuInPlace"));
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)loadView {
    CaptureVideoPreviewView *captureVideoPreviewView = [CaptureVideoPreviewView new];
    self.view = captureVideoPreviewView;
    [captureVideoPreviewView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CaptureService *captureService = self.captureService;
    __weak auto weakSelf = self;
    
    AVCaptureEventInteraction *captureEventInteraction = [[AVCaptureEventInteraction alloc] initWithPrimaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            CameraRootPhotoModel *photoModel = weakSelf.photoModel;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startPhotoCaptureWithPhotoModel:photoModel];
            });
        }
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            CameraRootPhotoModel *photoModel = weakSelf.photoModel;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startPhotoCaptureWithPhotoModel:photoModel];
            });
        }
    }];
    
    [self.view addInteraction:captureEventInteraction];
    [captureEventInteraction release];
    
    [self setToolbarItems:@[
        self.photosBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.captureBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.captureDevicesBarButtonItem
    ]];
    
    //
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItems = @[
        self.formatBarButtonItem
    ];
    
    //
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = self.captureVideoPreviewView.captureVideoPreviewLayer;
    
    [self.captureService.capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoPixelFormatTypes" options:NSKeyValueObservingOptionNew context:CameraRootViewController.availablePhotoPixelFormatTypesKey];
    [self.captureService.capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes" options:NSKeyValueObservingOptionNew context:CameraRootViewController.availableRawPhotoPixelFormatTypesKey];
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_selectDefaultCaptureDevice];
        [self.captureService queue_registerCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        [self.captureService.captureSession startRunning];
    });
}

- (CaptureVideoPreviewView *)captureVideoPreviewView {
    return static_cast<CaptureVideoPreviewView *>(self.view);
}

- (UIBarButtonItem *)photosBarButtonItem {
    if (auto photosBarButtonItem = _photosBarButtonItem) return photosBarButtonItem;
    
    UIBarButtonItem *photosBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"photo"]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(didTriggerPhotosBarButtonItem:)];
    
    _photosBarButtonItem = [photosBarButtonItem retain];
    return [photosBarButtonItem autorelease];
}

- (UIBarButtonItem *)captureBarButtonItem {
    if (auto captureBarButtonItem = _captureBarButtonItem) return captureBarButtonItem;
    
    UIButton *captureButton = [UIButton new];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"circle.inset.filled"];
    captureButton.configuration = configuration;
    
    [captureButton addTarget:self action:@selector(didTriggerCaptureBarButton:) forControlEvents:UIControlEventTouchDown];
    
    UIBarButtonItem *captureBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:captureButton];
    [captureButton release];
    
    _captureBarButtonItem = [captureBarButtonItem retain];
    return [captureBarButtonItem autorelease];
}

- (UIBarButtonItem *)captureDevicesBarButtonItem {
    if (auto captureDevicesBarButtonItem = _captureDevicesBarButtonItem) return captureDevicesBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        self.captureDevicesMenuElement
    ]];
    
    UIBarButtonItem *captureDevicesBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] menu:menu];
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevicesBarButtonItem, sel_registerName("_setShowsChevron:"), YES);
    
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

- (UIBarButtonItem *)formatBarButtonItem {
    if (auto formatBarButtonItem = _formatBarButtonItem) return formatBarButtonItem;
    
    CaptureService *captureService = self.captureService;
    CameraRootPhotoModel *photoModel = self.photoModel;
    __weak auto weakSelf = self;
    
    //
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        completion([photoModel configurationMenuElementsWithSelectionHandler:^{
            reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(weakSelf.formatBarButtonItem, sel_registerName("_updateMenuInPlace"));
        }]);
    }];
    
    //
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIBarButtonItem *formatBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Format" menu:menu];
    
    _formatBarButtonItem = [formatBarButtonItem retain];
    return [formatBarButtonItem autorelease];
}

- (CaptureService *)captureService {
    if (auto captureService = _captureService) return captureService;
    
    CaptureService *captureService = [CaptureService new];
    captureService.delegate = self;
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (CameraRootPhotoModel *)photoModel {
    if (auto photoModel = _photoModel) return photoModel;
    
    CameraRootPhotoModel *photoModel = [CameraRootPhotoModel new];
    photoModel.captureService = self.captureService;
    
    _photoModel = [photoModel retain];
    return [photoModel autorelease];
}

- (void)didChangeCaptureDeviceStatus:(CaptureService *)captureService {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

- (void)didTriggerPhotosBarButtonItem:(UIBarButtonItem *)sender {
    
}

- (void)didTriggerCaptureBarButton:(UIButton *)sender {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_startPhotoCaptureWithPhotoModel:self.photoModel];
    });
}

@end
