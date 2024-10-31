//
//  CameraRootViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import <CamPresentation/CameraRootViewController.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/CaptureService.h>
#import <CamPresentation/CaptureVideoPreviewView.h>
#import <CamPresentation/PointCloudPreviewView.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/UIDeferredMenuElement+CaptureDevices.h>
#import <CamPresentation/UIDeferredMenuElement+PhotoFormat.h>
#import <CamPresentation/UIDeferredMenuElement+FileOutputs.h>
#import <CamPresentation/UIDeferredMenuElement+Audio.h>
#import <CamPresentation/UIDeferredMenuElement+CaptureSession.h>
#import <CamPresentation/NSStringFromAVCaptureSessionInterruptionReason.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import <CamPresentation/AuthorizationsService.h>
#import <objc/message.h>
#import <objc/runtime.h>=

#warning AVCaptureDeviceSubjectAreaDidChangeNotification, +[AVCaptureDevice cinematicFramingControlMode], Memory Leak Test, exposureMode

#if TARGET_OS_TV
@interface CameraRootViewController () <AVContinuityDevicePickerViewControllerDelegate>
#else
@interface CameraRootViewController ()
#endif
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIBarButtonItem *photosBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureDevicesBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *fileOutputsBarButtonItem;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) UIBarButtonItem *continuityDevicePickerBarButtonItem;
#endif
@property (retain, nonatomic, readonly) UIBarButtonItem *audioBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureSessionBarButton;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic) PhotoFormatModel *photoFormatModel;
@end

@implementation CameraRootViewController
@synthesize stackView = _stackView;
@synthesize photosBarButtonItem = _photosBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
@synthesize fileOutputsBarButtonItem = _fileOutputsBarButtonItem;
#if TARGET_OS_TV
@synthesize continuityDevicePickerBarButtonItem = _continuityDevicePickerBarButtonItem;
#endif
@synthesize captureService = _captureService;
@synthesize audioBarButtonItem = _audioBarButtonItem;
@synthesize captureSessionBarButton = _captureSessionBarButton;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_CameraRootViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_CameraRootViewController];
    }
    
    return self;
}

- (void)commonInit_CameraRootViewController {
    PhotoFormatModel *photoFormatModel = [PhotoFormatModel new];
    self.photoFormatModel = photoFormatModel;
    [photoFormatModel release];
}

- (void)dealloc {
    [_stackView release];
    [_photosBarButtonItem release];
    [_captureDevicesBarButtonItem release];
    [_fileOutputsBarButtonItem release];
#if TARGET_OS_TV
    [_continuityDevicePickerBarButtonItem release];
#endif
    [_audioBarButtonItem release];
    [_captureSessionBarButton release];
    
    if (auto captureService = _captureService) {
        [captureService removeObserver:self forKeyPath:@"queue_captureSession"];
        [captureService removeObserver:self forKeyPath:@"queue_fileOutput"];
        [captureService.captureDeviceDiscoverySession removeObserver:self forKeyPath:@"devices"];
        [captureService.externalStorageDeviceDiscoverySession removeObserver:self forKeyPath:@"externalStorageDevices"];
        [captureService release];
    }
    [_photoFormatModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureService]) {
        if ([keyPath isEqualToString:@"queue_captureSession"]) {
            __kindof AVCaptureSession *captureSession = change[NSKeyValueChangeNewKey];
            NSString *string = NSStringFromClass(captureSession.class);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = string;
            });
            
            return;
        } else if ([keyPath isEqualToString:@"queue_fileOutput"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.fileOutputsBarButtonItem, sel_registerName("_updateMenuInPlace"));
            });
            return;
        }
    } else if ([object isEqual:self.captureService.externalStorageDeviceDiscoverySession]) {
        if ([keyPath isEqualToString:@"externalStorageDevices"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.fileOutputsBarButtonItem, sel_registerName("_updateMenuInPlace"));
            });
            return;
        }
    } else if ([object isEqual:self.captureService.captureDeviceDiscoverySession]) {
        if ([keyPath isEqualToString:@"devices"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#if !TARGET_OS_TV
    [self.navigationController setToolbarHidden:NO animated:YES];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
#if !TARGET_OS_TV
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    // 이거 안해주면 UIBarButtonItem이 계속 살아 있음. -[UIViewController setToolbarItems:]도 소용 없음
    self.navigationController.toolbar.items = @[];
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = self.view;
    view.backgroundColor = UIColor.systemBackgroundColor;
    
    UIStackView *stackView = self.stackView;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    
    //
    
    CaptureService *captureService = self.captureService;
    
#if TARGET_OS_IOS
    AVCaptureEventInteraction *captureEventInteraction = [[AVCaptureEventInteraction alloc] initWithPrimaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            dispatch_async(captureService.captureSessionQueue, ^{
                AVCaptureDevice * _Nullable captureDevice = captureService.queue_addedVideoCaptureDevices.lastObject;
                if (captureDevice == nil) return;
                
                [captureService queue_startPhotoCaptureWithCaptureDevice:captureDevice];
            });
        }
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            if (event.phase == AVCaptureEventPhaseBegan) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    AVCaptureDevice * _Nullable captureDevice = captureService.queue_addedVideoCaptureDevices.lastObject;
                    if (captureDevice == nil) return;
                    
                    [captureService queue_startPhotoCaptureWithCaptureDevice:captureDevice];
                });
            }
        }
    }];
    
    [self.view addInteraction:captureEventInteraction];
    [captureEventInteraction release];
#endif
    
#if TARGET_OS_TV
    UINavigationItem *navigationItem = self.navigationItem;
    
    navigationItem.rightBarButtonItems = @[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem,
        self.photosBarButtonItem,
        self.audioBarButtonItem,
        self.fileOutputsBarButtonItem,
        self.captureSessionBarButton,
        self.continuityDevicePickerBarButtonItem,
        self.captureDevicesBarButtonItem
    ];
#else
    [self setToolbarItems:@[
        self.photosBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.captureSessionBarButton,
        self.audioBarButtonItem,
        self.fileOutputsBarButtonItem,
        self.captureDevicesBarButtonItem
    ]];
#endif
    
    //
    
    AuthorizationsService *authorizationsService = [AuthorizationsService new];
    
    [authorizationsService requestAuthorizationsWithCompletionHandler:^(BOOL authorized) {
        if (authorized) {
            CaptureService *captureService = self.captureService;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                if (AVCaptureDevice *defaultVideoCaptureDevice = captureService.defaultVideoCaptureDevice) {
                    [captureService queue_addCapureDevice:defaultVideoCaptureDevice];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window.windowScene openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
                    exit(EXIT_FAILURE);
                }];
            });
        }
    }];
    
    [authorizationsService release];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
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

#if TARGET_OS_TV
- (UIBarButtonItem *)continuityDevicePickerBarButtonItem {
    if (auto continuityDevicePickerBarButtonItem = _continuityDevicePickerBarButtonItem) return continuityDevicePickerBarButtonItem;
    
    UIBarButtonItem *continuityDevicePickerBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"iphone"] style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerContinuityDevicePickerBarButtonItem:)];
    
    _continuityDevicePickerBarButtonItem = [continuityDevicePickerBarButtonItem retain];
    return [continuityDevicePickerBarButtonItem autorelease];
}
#endif

- (UIBarButtonItem *)captureDevicesBarButtonItem {
    if (auto captureDevicesBarButtonItem = _captureDevicesBarButtonItem) return captureDevicesBarButtonItem;
    
    CaptureService *captureService = self.captureService;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement cp_captureDevicesElementWithCaptureService:self.captureService
                                                                                                         selectionHandler:^(AVCaptureDevice * _Nonnull captureDevice) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureService queue_addCapureDevice:captureDevice];
        });
    }
                                                                                                       deselectionHandler:^(AVCaptureDevice * _Nonnull captureDevice) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureService queue_removeCaptureDevice:captureDevice];
        });
    }];
    
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        element
    ]];
    
    UIBarButtonItem *captureDevicesBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] menu:menu];
    captureDevicesBarButtonItem.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevicesBarButtonItem, sel_registerName("_setShowsChevron:"), YES);
    
    _captureDevicesBarButtonItem = [captureDevicesBarButtonItem retain];
    return [captureDevicesBarButtonItem autorelease];
}

- (UIBarButtonItem *)fileOutputsBarButtonItem {
    if (auto fileOutputsBarButtonItem = _fileOutputsBarButtonItem) return fileOutputsBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_fileOutputsElementWithCaptureService:self.captureService]
    ]];
    
    UIBarButtonItem *fileOutputsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"externaldrive"] menu:menu];
    
    _fileOutputsBarButtonItem = [fileOutputsBarButtonItem retain];
    return [fileOutputsBarButtonItem autorelease];
}

- (UIBarButtonItem *)audioBarButtonItem {
    if (auto audioBarButtonItem = _audioBarButtonItem) return audioBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_audioElementWithDidChangeHandler:nil]
    ]];
    
    UIBarButtonItem *audioBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"music.note"] menu:menu];
    
    _audioBarButtonItem = [audioBarButtonItem retain];
    return [audioBarButtonItem autorelease];
}

- (UIBarButtonItem *)captureSessionBarButton {
    if (auto captureSessionBarButton = _captureSessionBarButton) return captureSessionBarButton;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_captureSessionConfigurationElementWithCaptureService:self.captureService didChangeHandler:nil]
    ]];
    
    UIBarButtonItem *captureSessionBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"camera.badge.ellipsis.fill"] menu:menu];
    
    _captureSessionBarButton = [captureSessionBarButton retain];
    return [captureSessionBarButton autorelease];
    
}

- (CaptureService *)captureService {
    if (auto captureService = _captureService) return captureService;
    
    CaptureService *captureService = [CaptureService new];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didAddDeviceNotification:)
                                               name:CaptureServiceDidAddDeviceNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didRemoveDeviceNotification:)
                                               name:CaptureServiceDidRemoveDeviceNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveReloadingPhotoFormatMenuNeededNotification:)
                                               name:CaptureServiceReloadingPhotoFormatMenuNeededNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUpdatePreviewLayersNotification:)
                                               name:CaptureServiceDidUpdatePreviewLayersNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUpdatePointCloudLayersNotification:)
                                               name:CaptureServiceDidUpdatePointCloudLayersNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveCaptureSessionRuntimeErrorNotification:)
                                               name:AVCaptureSessionRuntimeErrorNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveCaptureSessionWasInterruptedNotification:)
                                               name:AVCaptureSessionWasInterruptedNotification
                                             object:nil];
    
    [captureService addObserver:self forKeyPath:@"queue_captureSession" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureService addObserver:self forKeyPath:@"queue_fileOutput" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureService.externalStorageDeviceDiscoverySession addObserver:self forKeyPath:@"externalStorageDevices" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureService.captureDeviceDiscoverySession addObserver:self forKeyPath:@"devices" options:NSKeyValueObservingOptionNew context:nullptr];
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (void)didTriggerPhotosBarButtonItem:(UIBarButtonItem *)sender {
    NSLog(@"TODO");
}

- (void)didAddDeviceNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

- (void)didRemoveDeviceNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

- (void)didReceiveReloadingPhotoFormatMenuNeededNotification:(NSNotification *)notification {
    auto captureDevice = static_cast<AVCaptureDevice *>(notification.userInfo[CaptureServiceCaptureDeviceKey]);
    if (captureDevice == nil) return;
    
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        AVCaptureVideoPreviewLayer *previewLayer = [captureService queue_previewLayerFromCaptureDevice:captureDevice];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (CaptureVideoPreviewView *captureVideoPreviewView in self.stackView.arrangedSubviews) {
                if (![captureVideoPreviewView isKindOfClass:CaptureVideoPreviewView.class]) {
                    continue;
                }
                
                if (![captureVideoPreviewView.previewLayer isEqual:previewLayer]) {
                    continue;
                }
                
                [captureVideoPreviewView reloadMenu];
            }
        });
    });
}

- (void)didUpdatePreviewLayersNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDeviceCopiedMapTable = captureService.queue_previewLayersByCaptureDeviceCopiedMapTable;
        NSMapTable<AVCaptureDevice *, __kindof CALayer *> *depthMapLayersByCaptureDeviceCopiedMapTable = captureService.queue_depthMapLayersByCaptureDeviceCopiedMapTable;
        NSMapTable<AVCaptureDevice *, __kindof CALayer *> *visionLayersByCaptureDeviceCopiedMapTable = captureService.queue_visionLayersByCaptureDeviceCopiedMapTable;
        NSMapTable<AVCaptureDevice *, __kindof CALayer *> *metadataObjectsLayersByCaptureDeviceCopiedMapTable = captureService.queue_metadataObjectsLayersByCaptureDeviceCopiedMapTable;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStackView *stackView = self.stackView;
            
            for (CaptureVideoPreviewView *captureVideoPreviewView in stackView.arrangedSubviews) {
                if (![captureVideoPreviewView isKindOfClass:CaptureVideoPreviewView.class]) continue;
                
                BOOL isRemoved = YES;
                for (AVCaptureVideoPreviewLayer *previewLayer in previewLayersByCaptureDeviceCopiedMapTable.objectEnumerator) {
                    if ([captureVideoPreviewView.previewLayer isEqual:previewLayer]) {
                        isRemoved = NO;
                        break;
                    }
                }
                
                if (isRemoved) {
                    // 삭제된 Layer - View 제거
                    [captureVideoPreviewView removeFromSuperview];
                } else {
                    // 이미 존재하는 Layer
                    [previewLayersByCaptureDeviceCopiedMapTable removeObjectForKey:captureVideoPreviewView.captureDevice];
                }
            }
            
            for (AVCaptureDevice * captureDevice in previewLayersByCaptureDeviceCopiedMapTable.keyEnumerator) {
                AVCaptureVideoPreviewLayer *previewLayer = [previewLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                __kindof CALayer * _Nullable depthMapLayer = [depthMapLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                __kindof CALayer * _Nullable visionLayer = [visionLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                __kindof CALayer * _Nullable metadataObjectsLayer = [metadataObjectsLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                
                CaptureVideoPreviewView *previewView = [self newCaptureVideoPreviewViewWithCaptureDevice:captureDevice previewLayer:previewLayer depthMapLayer:depthMapLayer visionLayer:visionLayer metadataObjectsLayer:metadataObjectsLayer];
                [stackView addArrangedSubview:previewView];
                [previewView release];
            }
            
            [stackView updateConstraintsIfNeeded];
        });
    });
}

- (void)didUpdatePointCloudLayersNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        NSMapTable<AVCaptureDevice *,__kindof CALayer *> *pointCloudLayersByCaptureDeviceCopiedMapTable = captureService.queue_pointCloudLayersByCaptureDeviceCopiedMapTable;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStackView *stackView = self.stackView;
            
            for (PointCloudPreviewView *pointCloudPreviewView in stackView.arrangedSubviews) {
                if (![pointCloudPreviewView isKindOfClass:PointCloudPreviewView.class]) continue;
                
                AVCaptureDevice * _Nullable captureDevice = nil;
                for (AVCaptureDevice * _captureDevice in pointCloudLayersByCaptureDeviceCopiedMapTable.keyEnumerator) {
                    CALayer *pointCloudLayer = [pointCloudLayersByCaptureDeviceCopiedMapTable objectForKey:_captureDevice];
                    
                    if ([pointCloudPreviewView.pointCloudLayer isEqual:pointCloudLayer]) {
                        captureDevice = _captureDevice;
                        break;
                    }
                }
                
                if (captureDevice != nil) {
                    // 이미 존재하는 Layer
                    [pointCloudLayersByCaptureDeviceCopiedMapTable removeObjectForKey:captureDevice];;
                } else {
                    // 삭제된 Layer - View 제거
                    [pointCloudPreviewView removeFromSuperview];
                }
            }
            
            for (AVCaptureDevice * captureDevice in pointCloudLayersByCaptureDeviceCopiedMapTable.keyEnumerator) {
                CALayer *pointCloudLayer = [pointCloudLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                
                PointCloudPreviewView *pointCloudPreviewView = [[PointCloudPreviewView alloc] initWithPointCloudLayer:pointCloudLayer];
                [stackView addArrangedSubview:pointCloudPreviewView];
                [pointCloudPreviewView release];
            }
            
            [stackView updateConstraintsIfNeeded];
        });
    });
}

- (void)didReceiveCaptureSessionRuntimeErrorNotification:(NSNotification *)notification {
    NSError * _Nullable error = notification.userInfo[AVCaptureSessionErrorKey];
    
    if (error != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.userInfo.description preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil];
            
            [alertController addAction:doneAction];
            
            __kindof UIViewController *topViewController = self;
            while (__kindof UIViewController *presentedViewController = topViewController.presentedViewController) {
                topViewController = presentedViewController;
            }
            [topViewController presentViewController:alertController animated:YES completion:nil];
        });
    }
}

- (void)didReceiveCaptureSessionWasInterruptedNotification:(NSNotification *)notification {
    NSNumber * _Nullable reasonNumber = notification.userInfo[AVCaptureSessionInterruptionReasonKey];
    if (reasonNumber == nil) return;
    auto reason = static_cast<AVCaptureSessionInterruptionReason>(reasonNumber.integerValue);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Interrupted" message:NSStringFromAVCaptureSessionInterruptionReason(reason) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil];
        
        [alertController addAction:doneAction];
        
        __kindof UIViewController *topViewController = self;
        while (__kindof UIViewController *presentedViewController = topViewController.presentedViewController) {
            topViewController = presentedViewController;
        }
        [topViewController presentViewController:alertController animated:YES completion:nil];
    });
}

- (CaptureVideoPreviewView *)newCaptureVideoPreviewViewWithCaptureDevice:(AVCaptureDevice *)captureDevice previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer * _Nullable)depthMapLayer visionLayer:(CALayer * _Nullable)visionLayer metadataObjectsLayer:(CALayer * _Nullable)metadataObjectsLayer {
    CaptureVideoPreviewView *captureVideoPreviewView = [[CaptureVideoPreviewView alloc] initWithCaptureService:self.captureService captureDevice:captureDevice previewLayer:previewLayer depthMapLayer:depthMapLayer visionLayer:visionLayer metadataObjectsLayer:metadataObjectsLayer];
    
    return captureVideoPreviewView;
}

#if TARGET_OS_TV
- (void)didTriggerContinuityDevicePickerBarButtonItem:(UIBarButtonItem *)sender {
    assert(AVContinuityDevicePickerViewController.isSupported);
    AVContinuityDevicePickerViewController *viewController = [AVContinuityDevicePickerViewController new];
    viewController.delegate = self;

//    assert(reinterpret_cast<BOOL (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("AVContinuityDevicePickerViewController"), sel_registerName("supported")));
//    __kindof UIViewController *viewController = [objc_lookUpClass("AVContinuityDevicePickerViewController") new];
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(viewController, sel_registerName("setDelegate:"), self);
    
    [self presentViewController:viewController animated:YES completion:nil];
    [viewController release];
}

- (void)continuityDevicePicker:(AVContinuityDevicePickerViewController *)pickerViewController didConnectDevice:(AVContinuityDevice *)device {
    NSLog(@"%@", device);
}
#endif

@end

#endif
