//
//  CameraRootViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

// TODO: Memory Leak Test
// +[AVCaptureDevice cinematicFramingControlMode]
// AVControlCenterModuleState
// Multi-cam

#import <CamPresentation/CameraRootViewController.h>
#import <CamPresentation/CaptureService.h>
#import <CamPresentation/CaptureVideoPreviewView.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/UIDeferredMenuElement+CaptureDevices.h>
#import <CamPresentation/UIDeferredMenuElement+PhotoFormat.h>
#import <CamPresentation/UIDeferredMenuElement+FileOutputs.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import <Symbols/Symbols.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

#if TARGET_OS_TV
@interface CameraRootViewController () <UIContextMenuInteractionDelegate, AVContinuityDevicePickerViewControllerDelegate>
#else
@interface CameraRootViewController () <UIContextMenuInteractionDelegate>
#endif
@property (class, assign, nonatomic, readonly) void *availablePhotoPixelFormatTypesKey;
@property (class, assign, nonatomic, readonly) void *availableRawPhotoPixelFormatTypesKey;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIBarButtonItem *photosBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureDevicesBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *fileOutputsBarButtonItem;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) UIBarButtonItem *continuityDevicePickerBarButtonItem;
#endif
@property (retain, nonatomic, readonly) UIActivityIndicatorView *captureProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureProgressBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
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
@synthesize captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView;
@synthesize captureProgressBarButtonItem = _captureProgressBarButtonItem;
@synthesize reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView;
@synthesize reactionProgressBarButtonItem = _reactionProgressBarButtonItem;
@synthesize captureService = _captureService;

+ (void *)availablePhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

+ (void *)availableRawPhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

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
    [_captureProgressActivityIndicatorView release];
    [_captureProgressBarButtonItem release];
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    
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

- (void)loadView {
    self.view = self.stackView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    
    CaptureService *captureService = self.captureService;
    
#if TARGET_OS_IOS
    AVCaptureEventInteraction *captureEventInteraction = [[AVCaptureEventInteraction alloc] initWithPrimaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            dispatch_async(captureService.captureSessionQueue, ^{
                AVCaptureDevice * _Nullable captureDevice = captureService.queue_addedCaptureDevices.lastObject;
                if (captureDevice == nil) return;
                
                [captureService queue_startPhotoCaptureWithCaptureDevice:captureDevice];
            });
        }
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            if (event.phase == AVCaptureEventPhaseBegan) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    AVCaptureDevice * _Nullable captureDevice = captureService.queue_addedCaptureDevices.lastObject;
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
        self.photosBarButtonItem,
        self.captureBarButtonItem,
        self.recordBarButtonItem,
        self.formatBarButtonItem,
        self.continuityDevicePickerBarButtonItem,
        self.captureDevicesBarButtonItem
    ];
#else
    [self setToolbarItems:@[
        self.photosBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.fileOutputsBarButtonItem,
        self.captureDevicesBarButtonItem
    ]];
    
    //
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.leftBarButtonItems = @[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem
    ];
#endif
    
    //
    
    
    dispatch_async(captureService.captureSessionQueue, ^{
        if (AVCaptureDevice *defaultCaptureDevice = captureService.defaultCaptureDevice) {
            [captureService queue_addCapureDevice:defaultCaptureDevice];
            [self.captureService.queue_captureSession startRunning];
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Memory Warning!" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:doneAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
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
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            if (captureService.queue_addedCaptureDevices.count > 0) {
                UIDeferredMenuElement *captureDevicesMenuElement = [UIDeferredMenuElement cp_multiCamDevicesElementWithCaptureService:self.captureService
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[captureDevicesMenuElement]);
                });
            } else {
                UIDeferredMenuElement *captureDevicesMenuElement = [UIDeferredMenuElement cp_captureDevicesElementWithCaptureService:self.captureService
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[captureDevicesMenuElement]);
                });
            }
        });
    }];
    
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        element
    ]];
    
    UIBarButtonItem *captureDevicesBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] menu:menu];
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

- (UIActivityIndicatorView *)captureProgressActivityIndicatorView {
    if (auto captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView) return captureProgressActivityIndicatorView;
    
    UIActivityIndicatorView *captureProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    captureProgressActivityIndicatorView.hidesWhenStopped = YES;
    
    _captureProgressActivityIndicatorView = [captureProgressActivityIndicatorView retain];
    return [captureProgressActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)captureProgressBarButtonItem {
    if (auto captureProgressBarButtonItem = _captureProgressBarButtonItem) return captureProgressBarButtonItem;
    
    UIActivityIndicatorView *captureProgressActivityIndicatorView = self.captureProgressActivityIndicatorView;
    UIBarButtonItem *captureProgressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:captureProgressActivityIndicatorView];
    captureProgressBarButtonItem.hidden = YES;
    captureProgressBarButtonItem.enabled = NO;
    
    _captureProgressBarButtonItem = [captureProgressBarButtonItem retain];
    return [captureProgressBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)reactionProgressActivityIndicatorView {
    if (auto reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView) return reactionProgressActivityIndicatorView;
    
    UIActivityIndicatorView *reactionProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    reactionProgressActivityIndicatorView.hidesWhenStopped = YES;
    
    _reactionProgressActivityIndicatorView = [reactionProgressActivityIndicatorView retain];
    return [reactionProgressActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)reactionProgressBarButtonItem {
    if (auto reactionProgressBarButtonItem = _reactionProgressBarButtonItem) return reactionProgressBarButtonItem;
    
    UIActivityIndicatorView *reactionProgressActivityIndicatorView = self.reactionProgressActivityIndicatorView;
    UIBarButtonItem *reactionProgressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reactionProgressActivityIndicatorView];
    reactionProgressBarButtonItem.hidden = YES;
    reactionProgressBarButtonItem.enabled = NO;
    
    _reactionProgressBarButtonItem = [reactionProgressBarButtonItem retain];
    return [reactionProgressBarButtonItem autorelease];
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
                                           selector:@selector(didChangeReactionEffectsInProgressNotification:)
                                               name:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
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
                                           selector:@selector(didChangeCaptureReadinessNotification:)
                                               name:CaptureServiceDidChangeCaptureReadinessNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didChangeSpatialCaptureDiscomfortReasonNotification:)
                                               name:CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName
                                             object:captureService];
    
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

- (void)didChangeReactionEffectsInProgressNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        BOOL hasReaction = NO;
        for (AVCaptureDevice *captureDevice in captureService.queue_addedCaptureDevices) {
            if (captureDevice.reactionEffectsInProgress.count > 0) {
                hasReaction = YES;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (hasReaction) {
                [self.reactionProgressActivityIndicatorView startAnimating];
                self.reactionProgressBarButtonItem.hidden = NO;
            } else {
                [self.reactionProgressActivityIndicatorView stopAnimating];
                self.reactionProgressBarButtonItem.hidden = YES;
            }
        });
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
                
                for (UIContextMenuInteraction *interaction in captureVideoPreviewView.interactions) {
                    if (![interaction isKindOfClass:UIContextMenuInteraction.class]) {
                        continue;
                    }
                    
                    if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(interaction, sel_registerName("_hasVisibleMenu"))) {
                        [interaction dismissMenu];
                        reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(interaction, sel_registerName("_presentMenuAtLocation:"), CGPointZero);
                    }
                }
            }
        });
    });
}

- (void)didUpdatePreviewLayersNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDeviceCopiedMapTable = captureService.queue_previewLayersByCaptureDeviceCopiedMapTable;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStackView *stackView = self.stackView;
            
            for (CaptureVideoPreviewView *captureVideoPreviewView in stackView.arrangedSubviews) {
                if (![captureVideoPreviewView isKindOfClass:CaptureVideoPreviewView.class]) continue;
                
                AVCaptureDevice * _Nullable captureDevice = nil;
                for (AVCaptureDevice * _captureDevice in previewLayersByCaptureDeviceCopiedMapTable.keyEnumerator) {
                    AVCaptureVideoPreviewLayer *previewLayer = [previewLayersByCaptureDeviceCopiedMapTable objectForKey:_captureDevice];
                    
                    if ([captureVideoPreviewView.previewLayer isEqual:previewLayer]) {
                        captureDevice = _captureDevice;
                        break;
                    }
                }
                
                if (captureDevice != nil) {
                    // 이미 존재하는 Layer
                    [previewLayersByCaptureDeviceCopiedMapTable removeObjectForKey:captureDevice];;
                } else {
                    // 삭제된 Layer - View 제거
                    [captureVideoPreviewView removeFromSuperview];
                }
            }
            
            for (AVCaptureDevice * captureDevice in previewLayersByCaptureDeviceCopiedMapTable.keyEnumerator) {
                AVCaptureVideoPreviewLayer *previewLayer = [previewLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                CaptureVideoPreviewView *previewView = [self newCaptureVideoPreviewViewWithPreviewLayer:previewLayer];
                [previewView updateSpatialCaptureDiscomfortReasonLabelWithReasons:captureDevice.spatialCaptureDiscomfortReasons];
                [stackView addArrangedSubview:previewView];
                [previewView release];
            }
            
            [stackView updateConstraintsIfNeeded];
        });
    });
}

- (void)didChangeCaptureReadinessNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    dispatch_assert_queue(captureService.captureSessionQueue);
    
    BOOL isLoading = NO;
    for (AVCaptureDevice *captureDevice in captureService.queue_addedCaptureDevices) {
        AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [captureService queue_readinessCoordinatorFromCaptureDevice:captureDevice];
        
        if (readinessCoordinator.captureReadiness != AVCapturePhotoOutputCaptureReadinessReady) {
            isLoading = YES;
            break;
        }
    }
    
    auto captureDevice = static_cast<AVCaptureDevice *>(notification.userInfo[CaptureServiceCaptureDeviceKey]);
    AVCaptureVideoPreviewLayer *previewLayer = [captureService queue_previewLayerFromCaptureDevice:captureDevice];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isLoading) {
            [self.captureProgressActivityIndicatorView startAnimating];
            self.captureProgressBarButtonItem.hidden = NO;
        } else {
            [self.captureProgressActivityIndicatorView stopAnimating];
            self.captureProgressBarButtonItem.hidden = YES;
        }
        
        for (CaptureVideoPreviewView *videoPreviewView in self.stackView.arrangedSubviews) {
            if (![videoPreviewView isKindOfClass:CaptureVideoPreviewView.class]) continue;
            
            if ([videoPreviewView.previewLayer isEqual:previewLayer]) {
                for (UIContextMenuInteraction *interaction in videoPreviewView.interactions) {
                    if (![interaction isKindOfClass:UIContextMenuInteraction.class]) {
                        continue;
                    }
                    
                    if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(interaction, sel_registerName("_hasVisibleMenu"))) {
                        [interaction dismissMenu];
                        reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(interaction, sel_registerName("_presentMenuAtLocation:"), CGPointZero);
                    }
                }
            }
        }
    });
}

- (void)didChangeSpatialCaptureDiscomfortReasonNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        auto captureDevice = static_cast<AVCaptureDevice *>(notification.userInfo[CaptureServiceCaptureDeviceKey]);
        assert(captureDevice != nil);
        AVCaptureVideoPreviewLayer *previewLayer = [captureService queue_previewLayerFromCaptureDevice:captureDevice];
        assert(previewLayer != nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSpatialCaptureDiscomfortReasonLabelWithCaptureDevice:captureDevice previewLayer:previewLayer];
        });
    });
}

- (CaptureVideoPreviewView *)newCaptureVideoPreviewViewWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    CaptureVideoPreviewView *captureVideoPreviewView = [[CaptureVideoPreviewView alloc] initWithPreviewLayer:previewLayer];

    UIContextMenuInteraction *contextMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [captureVideoPreviewView addInteraction:contextMenuInteraction];
    [contextMenuInteraction release];
    
    UITapGestureRecognizer *tapGestureRecogninzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewTapGestureRecognizer:)];
    [captureVideoPreviewView addGestureRecognizer:tapGestureRecogninzer];
    [tapGestureRecogninzer release];
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = captureVideoPreviewView.previewLayer;
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    return captureVideoPreviewView;
}

- (void)updateSpatialCaptureDiscomfortReasonLabelWithCaptureDevice:(AVCaptureDevice *)captureDevice previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    NSSet<AVSpatialCaptureDiscomfortReason> *reasons = captureDevice.spatialCaptureDiscomfortReasons;
    
    for (CaptureVideoPreviewView *previewView in self.stackView.arrangedSubviews) {
        if (![previewView isKindOfClass:CaptureVideoPreviewView.class]) continue;
        if (![previewView.previewLayer isEqual:previewLayer]) continue;
        
        [previewView updateSpatialCaptureDiscomfortReasonLabelWithReasons:reasons];
    }
}

- (void)didTriggerCaptureVideoPreviewViewTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    auto captureVideoPreviewView = static_cast<CaptureVideoPreviewView *>(sender.view);
    
    for (UIContextMenuInteraction *contextMenuInteraction in captureVideoPreviewView.interactions) {
        if (![contextMenuInteraction isKindOfClass:UIContextMenuInteraction.class]) continue;
        
        CGPoint location = [sender locationInView:captureVideoPreviewView];
        reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(contextMenuInteraction, sel_registerName("_presentMenuAtLocation:"), location);
        break;
    }
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    auto previewView = static_cast<CaptureVideoPreviewView *>(interaction.view);
    assert([previewView isKindOfClass:CaptureVideoPreviewView.class]);
    
    AVCaptureVideoPreviewLayer *previewLayer = previewView.previewLayer;
    
    AVCaptureVideoPreviewLayerInternal *_internal;
    assert(object_getInstanceVariable(previewLayer, "_internal", reinterpret_cast<void **>(&_internal)) != nullptr);
    
    AVCaptureConnection *connection;
    assert(object_getInstanceVariable(_internal, "connection", reinterpret_cast<void **>(&connection)));
    
    AVCaptureDeviceInput * _Nullable deviceInput = nil;;
    for (AVCaptureInputPort *inputPort in connection.inputPorts) {
        if ([inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) {
            deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            break;
        }
    }
    
    if (deviceInput == nil) return nil;
    
    AVCaptureDevice *captureDevice = deviceInput.device;
    __weak auto weakSelf = self;
    
    //
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:^UIViewController * _Nullable{
        return nil;
    }
                                                                                         actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        auto loaded = weakSelf;
        if (loaded == nil) return nil;
        
        UIDeferredMenuElement *element = [UIDeferredMenuElement cp_photoFormatElementWithCaptureService:loaded.captureService captureDevice:captureDevice didChangeHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [interaction dismissMenu];
                reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(interaction, sel_registerName("_presentMenuAtLocation:"), CGPointZero);
            });
        }];
        
        UIMenu *menu = [UIMenu menuWithChildren:@[element]];
        return menu;
    }];
    
    return configuration;
}

- (UITargetedPreview *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configuration:(UIContextMenuConfiguration *)configuration highlightPreviewForItemWithIdentifier:(id<NSCopying>)identifier {
    UIPreviewParameters *parameters = [UIPreviewParameters new];
    parameters.backgroundColor = UIColor.clearColor;
    
    UITargetedPreview *preview = [[UITargetedPreview alloc] initWithView:interaction.view parameters:parameters];
    [parameters release];
    
    return [preview autorelease];
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
