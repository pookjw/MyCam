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
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) UIBarButtonItem *continuityDevicePickerBarButtonItem;
#endif
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic) PhotoFormatModel *photoFormatModel;
@end

@implementation CameraRootViewController
@synthesize stackView = _stackView;
@synthesize photosBarButtonItem = _photosBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
#if TARGET_OS_TV
@synthesize continuityDevicePickerBarButtonItem = _continuityDevicePickerBarButtonItem;
#endif
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
#if TARGET_OS_TV
    [_continuityDevicePickerBarButtonItem release];
#endif
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    
    if (auto captureService = _captureService) {
        [captureService removeObserver:self forKeyPath:@"queue_captureSession"];
        [captureService.captureDeviceDiscoverySession removeObserver:self forKeyPath:@"devices"];
        [captureService release];
    }
    [_photoFormatModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureService]) {
        __kindof AVCaptureSession *captureSession = change[NSKeyValueChangeNewKey];
        NSString *string = NSStringFromClass(captureSession.class);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = string;
        });
        
        return;
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
    
    CaptureService *captureService = self.captureService;
    __weak auto weakSelf = self;
    
#if TARGET_OS_IOS
    AVCaptureEventInteraction *captureEventInteraction = [[AVCaptureEventInteraction alloc] initWithPrimaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
#warning TODO
            abort();
        }
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
#warning TODO
            abort();
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
        self.captureDevicesBarButtonItem
    ]];
    
    //
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.leftBarButtonItems = @[
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

- (UIActivityIndicatorView *)reactionProgressActivityIndicatorView {
    if (auto reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView) return reactionProgressActivityIndicatorView;
    
    UIActivityIndicatorView *reactionProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
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
    
    [captureService addObserver:self forKeyPath:@"queue_captureSession" options:NSKeyValueObservingOptionNew context:nullptr];
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
    auto reactionEffectsInProgress = static_cast<NSArray<AVCaptureReactionEffectState *> *>(notification.userInfo[CaptureServiceReactionEffectsInProgressKey]);
    if (reactionEffectsInProgress == nil) return;
    
    BOOL hasReaction = reactionEffectsInProgress.count > 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (hasReaction) {
            [self.reactionProgressActivityIndicatorView startAnimating];
            self.reactionProgressBarButtonItem.hidden = NO;
        } else {
            [self.reactionProgressActivityIndicatorView stopAnimating];
            self.reactionProgressBarButtonItem.hidden = YES;
        }
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
        NSMutableArray<AVCaptureVideoPreviewLayer *> *previewLayers = [[NSMutableArray alloc] initWithCapacity:captureService.queue_addedCaptureDevices.count];
        
        for (AVCaptureDevice *captureDeivce in captureService.queue_addedCaptureDevices) {
            [previewLayers addObject:[captureService queue_previewLayerFromCaptureDevice:captureDeivce]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStackView *stackView = self.stackView;
            
            for (CaptureVideoPreviewView *captureVideoPreviewView in stackView.arrangedSubviews) {
                if (![captureVideoPreviewView isKindOfClass:CaptureVideoPreviewView.class]) continue;
                
                NSInteger index = [previewLayers indexOfObject:captureVideoPreviewView.previewLayer];
                
                if (index == NSNotFound) {
                    // 삭제된 Layer - View 제거
                    [captureVideoPreviewView removeFromSuperview];
                } else {
                    // 이미 존재하는 Layer
                    [previewLayers removeObjectAtIndex:index];
                }
            }
            
            for (AVCaptureVideoPreviewLayer *previewLayer in previewLayers) {
                CaptureVideoPreviewView *previewView = [self newCaptureVideoPreviewViewWithPreviewLayer:previewLayer];
                [stackView addArrangedSubview:previewView];
                [previewView release];
            }
            
            [stackView updateConstraintsIfNeeded];
        });
        
        [previewLayers release];
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
