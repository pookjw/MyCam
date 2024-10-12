//
//  CameraRootViewController.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

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

#warning AVCaptureDeviceSubjectAreaDidChangeNotification, +[AVCaptureDevice cinematicFramingControlMode], Memory Leak Test, exposureMode

#if TARGET_OS_TV
@interface CameraRootViewController () <AVContinuityDevicePickerViewControllerDelegate>
#else
@interface CameraRootViewController ()
#endif
@property (class, assign, nonatomic, readonly) void *availablePhotoPixelFormatTypesKey;
@property (class, assign, nonatomic, readonly) void *availableRawPhotoPixelFormatTypesKey;
@property (retain, nonatomic, readonly) UIVisualEffectView *blurView;
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
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingFocusActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingFocusBarButtonItem;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic) PhotoFormatModel *photoFormatModel;
@end

@implementation CameraRootViewController
@synthesize blurView = _blurView;
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
@synthesize adjustingFocusActivityIndicatorView = _adjustingFocusActivityIndicatorView;
@synthesize adjustingFocusBarButtonItem = _adjustingFocusBarButtonItem;
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
    [_blurView release];
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
    [_adjustingFocusActivityIndicatorView release];
    [_adjustingFocusBarButtonItem release];
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = self.view;
    UIStackView *stackView = self.stackView;
    UIVisualEffectView *blurView = self.blurView;
    
    [view addSubview:stackView];
    [view addSubview:blurView];
    
    stackView.frame = view.bounds;
    blurView.frame = view.bounds;
    
    stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    blurView.hidden = YES;
    
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
    
    UINavigationItem *navigationItem = self.navigationItem;
    
#if TARGET_OS_TV
    navigationItem.rightBarButtonItems = @[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem,
        self.photosBarButtonItem,
        self.fileOutputsBarButtonItem,
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
    
    navigationItem.leftBarButtonItems = @[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem
    ];
#endif
    
    //
    
    dispatch_async(captureService.captureSessionQueue, ^{
        if (AVCaptureDevice *defaultCaptureDevice = captureService.defaultCaptureDevice) {
            [captureService queue_addCapureDevice:defaultCaptureDevice];
            [self.captureService.queue_captureSession startRunning];
        }
    });
    
    //
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(willBeginSnapshotSessionNotification:)
                                               name:@"_UIApplicationWillBeginSnapshotSessionNotification"
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didEndSnapshotSessionNotification:)
                                               name:@"_UIApplicationDidEndSnapshotSessionNotification"
                                             object:nil];
}

- (void)willBeginSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.view.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = NO;
        }
    }
}

- (void)didEndSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.view.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = YES;
        }
    }
}

- (UIVisualEffectView *)blurView {
    if (auto blurView = _blurView) return blurView;
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
    
    _blurView = [blurView retain];
    return [blurView autorelease];
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

- (UIActivityIndicatorView *)adjustingFocusActivityIndicatorView {
    if (auto adjustingFocusActivityIndicatorView = _adjustingFocusActivityIndicatorView) return adjustingFocusActivityIndicatorView;
    
    UIActivityIndicatorView *adjustingFocusActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    adjustingFocusActivityIndicatorView.hidesWhenStopped = YES;
    
    _adjustingFocusActivityIndicatorView = [adjustingFocusActivityIndicatorView retain];
    return [adjustingFocusActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)adjustingFocusBarButtonItem {
    if (auto adjustingFocusBarButtonItem = _adjustingFocusBarButtonItem) return adjustingFocusBarButtonItem;
    
    UIActivityIndicatorView *adjustingFocusActivityIndicatorView = self.adjustingFocusActivityIndicatorView;
    UIBarButtonItem *adjustingFocusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:adjustingFocusActivityIndicatorView];
    adjustingFocusBarButtonItem.hidden = YES;
    adjustingFocusBarButtonItem.enabled = NO;
    
    _adjustingFocusBarButtonItem = [adjustingFocusBarButtonItem retain];
    return [adjustingFocusBarButtonItem autorelease];
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
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveCaptureSessionRuntimeErrorNotification:)
                                               name:CaptureServiceCaptureSessionRuntimeErrorNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveAdjustingFocusDidChangeNotification:)
                                               name:CaptureServiceAdjustingFocusDidChangeNotificationName
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
        NSMapTable<AVCaptureDevice *, __kindof CALayer *> *depthMapLayersByCaptureDeviceCopiedMapTable = captureService.queue_depthMapLayersByCaptureDeviceCopiedMapTable;
        
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
                __kindof CALayer * _Nullable depthMapLayer = [depthMapLayersByCaptureDeviceCopiedMapTable objectForKey:captureDevice];
                
                CaptureVideoPreviewView *previewView = [self newCaptureVideoPreviewViewWithPreviewLayer:previewLayer depthMapLayer:depthMapLayer captureDevice:captureDevice];
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

- (void)didReceiveAdjustingFocusDidChangeNotification:(NSNotification *)notification {
    dispatch_assert_queue(self.captureService.captureSessionQueue);
    
    BOOL adjustingFocus = NO;
    for (AVCaptureDevice *captureDevice in self.captureService.queue_addedCaptureDevices) {
        if (captureDevice.adjustingFocus) {
            adjustingFocus = YES;
            break;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (adjustingFocus) {
            [self.adjustingFocusActivityIndicatorView startAnimating];
            self.adjustingFocusBarButtonItem.hidden = NO;
        } else {
            [self.adjustingFocusActivityIndicatorView stopAnimating];
            self.adjustingFocusBarButtonItem.hidden = YES;
        }
    });
}

- (CaptureVideoPreviewView *)newCaptureVideoPreviewViewWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer * _Nullable)depthMapLayer captureDevice:(AVCaptureDevice *)captureDevice {
    CaptureVideoPreviewView *captureVideoPreviewView = [[CaptureVideoPreviewView alloc] initWithPreviewLayer:previewLayer depthMapLayer:depthMapLayer];
    
    UITapGestureRecognizer *tapGestureRecogninzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewTapGestureRecognizer:)];
    [captureVideoPreviewView addGestureRecognizer:tapGestureRecogninzer];
    [tapGestureRecogninzer release];
    
    UILongPressGestureRecognizer *longGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewLongGestureRecognizer:)];
    [captureVideoPreviewView addGestureRecognizer:longGestureRecognizer];
    [longGestureRecognizer release];
    
    captureVideoPreviewView.menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_photoFormatElementWithCaptureService:self.captureService captureDevice:captureDevice didChangeHandler:nil]
    ]];
    
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
    auto previewView = static_cast<CaptureVideoPreviewView *>(sender.view);
    AVCaptureVideoPreviewLayer *previewLayer = previewView.previewLayer;
    CGPoint viewPoint = [sender locationInView:previewView];
    CGPoint captureDevicePoint = [previewLayer captureDevicePointOfInterestForPoint:viewPoint];
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDevice *captureDevice = [self.captureService queue_captureDeviceFromPreviewLayer:previewLayer];
        
        if (!captureDevice.isFocusPointOfInterestSupported) return;
        
        NSError * _Nullable error = nil;
        [captureDevice lockForConfiguration:&error];
        assert(error == nil);
        
        captureDevice.focusPointOfInterest = captureDevicePoint;
        
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        } else if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        [captureDevice unlockForConfiguration];
    });
}

- (void)didTriggerCaptureVideoPreviewViewLongGestureRecognizer:(UILongPressGestureRecognizer *)sender {
    auto previewView = static_cast<CaptureVideoPreviewView *>(sender.view);
    AVCaptureVideoPreviewLayer *previewLayer = previewView.previewLayer;
    CGPoint viewPoint = [sender locationInView:previewView];
    CGPoint captureDevicePoint = [previewLayer captureDevicePointOfInterestForPoint:viewPoint];
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDevice *captureDevice = [self.captureService queue_captureDeviceFromPreviewLayer:previewLayer];
        
        if (!captureDevice.isFocusPointOfInterestSupported) return;
        if (![captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) return;
        
        NSError * _Nullable error = nil;
        [captureDevice lockForConfiguration:&error];
        assert(error == nil);
        captureDevice.focusPointOfInterest = captureDevicePoint;
        captureDevice.focusMode = AVCaptureFocusModeLocked;
        [captureDevice unlockForConfiguration];
    });
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
