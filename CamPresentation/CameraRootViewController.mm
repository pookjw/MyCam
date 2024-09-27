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
#import <CamPresentation/PhotoFormatMenuBuilder.h>
#import <CamPresentation/CaptureActionsMenuElement.h>
#import <CamPresentation/CaptureDevicesMenuElement.h>
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
@property (retain, nonatomic, readonly) UIBarButtonItem *formatBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic) PhotoFormatModel *photoFormatModel;
@property (retain, nonatomic, nullable) PhotoFormatMenuBuilder *photoFormatMenuBuilder;
@end

@implementation CameraRootViewController
@synthesize stackView = _stackView;
@synthesize photosBarButtonItem = _photosBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
#if TARGET_OS_TV
@synthesize continuityDevicePickerBarButtonItem = _continuityDevicePickerBarButtonItem;
#endif
@synthesize formatBarButtonItem = _formatBarButtonItem;
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
    [_formatBarButtonItem release];
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    [_captureService release];
    [_photoFormatModel release];
    [_photoFormatMenuBuilder release];
    [super dealloc];
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
            PhotoFormatModel *photoFormatModel = weakSelf.photoFormatMenuBuilder.photoFormatModel;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startPhotoCaptureWithPhotoModel:photoFormatModel];
            });
        }
    }
                                                                                                  secondaryEventHandler:^(AVCaptureEvent * _Nonnull event) {
        if (event.phase == AVCaptureEventPhaseBegan) {
            PhotoFormatModel *photoFormatModel = weakSelf.photoFormatMenuBuilder.photoFormatModel;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startPhotoCaptureWithPhotoModel:photoFormatModel];
            });
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
    navigationItem.rightBarButtonItems = @[
        self.formatBarButtonItem
    ];
#endif
    
    //
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didRemoveDeviceNotification:)
                                               name:CaptureServiceDidRemoveDeviceNotificationName
                                             object:captureService];
    
    //
    
    AVCaptureDevice * _Nullable defaultCaptureDevice = captureService.defaultCaptureDevice;
    AVCaptureVideoPreviewLayer * _Nullable previewLayer;
    if (defaultCaptureDevice != nil) {
        CaptureVideoPreviewView *previewView = [self newCaptureVideoPreviewView];
        [self.stackView addArrangedSubview:previewView];
        previewLayer = [previewView.captureVideoPreviewLayer retain];
        [previewView release];
    } else {
        previewLayer = nil;
    }
    
    dispatch_async(captureService.captureSessionQueue, ^{
        if (defaultCaptureDevice != nil) {
            [captureService queue_addCapureDevice:defaultCaptureDevice captureVideoPreviewLayer:previewLayer];
        }
        
        [self.captureService.captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            PhotoFormatMenuBuilder *photoFormatMenuService = [[PhotoFormatMenuBuilder alloc] initWithPhotoFormatModel:self.photoFormatModel captureService:self.captureService captureDevice:captureDevice needsReloadHandler:^{
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(weakSelf.formatBarButtonItem, sel_registerName("_updateMenuInPlace"));
//                    
//                    __kindof UIScene * _Nullable scene = weakSelf.view.window.windowScene;
//                    if (scene != nil) {
//                        NSDictionary<NSString *, id> *_registeredComponents;
//                        assert(object_getInstanceVariable(scene, "_registeredComponents", reinterpret_cast<void **>(&_registeredComponents)) != nullptr);
//                        id userActivitySceneComponentKey = _registeredComponents[@"UIUserActivitySceneComponentKey"];
//                        reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(userActivitySceneComponentKey, sel_registerName("_saveSceneRestorationState"));
//                    }
//                });
//            }];
        });
    });
    
    [previewLayer release];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Memory Warning!" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:doneAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSUserActivity *)stateRestorationActivity {
#if TARGET_OS_VISION
    return nil;
#else
    auto userActivityTypes = static_cast<NSArray<NSString *> *>(NSBundle.mainBundle.infoDictionary[@"NSUserActivityTypes"]);
    if (userActivityTypes == nil) return nil;
    if (![userActivityTypes containsObject:@"com.pookjw.MyCam.CameraRootViewController"]) return nil;
    
    PhotoFormatModel * _Nullable photoFormatModel = self.photoFormatMenuBuilder.photoFormatModel;
    
    if (photoFormatModel == nil) return nil;
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"com.pookjw.MyCam.CameraRootViewController"];
    
    NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
    keyedArchiver.outputFormat = NSPropertyListBinaryFormat_v1_0;
    [photoFormatModel encodeWithCoder:keyedArchiver];
    
    [keyedArchiver finishEncoding];
    
    [userActivity addUserInfoEntriesFromDictionary:@{
        @"photoFormatModelData": keyedArchiver.encodedData
    }];
    
    [keyedArchiver release];
    
    return [userActivity autorelease];
#endif
}

- (void)restoreStateWithUserActivity:(NSUserActivity *)userActivity {
    if (self.photoFormatModel != nil) return;
    
    if (![userActivity.activityType isEqualToString:@"com.pookjw.MyCam.CameraRootViewController"]) return;
    
    NSData * _Nullable photoFormatModelData = userActivity.userInfo[@"photoFormatModelData"];
    if (photoFormatModelData == nil) return;
    
    NSError * _Nullable error = nil;
    NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:photoFormatModelData error:&error];
    assert(error == nil);
    
    PhotoFormatModel *photoFormatModel = [[PhotoFormatModel alloc] initWithCoder:keyedUnarchiver];
    [keyedUnarchiver release];
    
    self.photoFormatModel = photoFormatModel;
    [photoFormatModel release];
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
    
    __weak auto weakSelf = self;
    
    CaptureDevicesMenuElement *captureDevicesMenuElement = [CaptureDevicesMenuElement elementWithCaptureDevice:self.captureService
                                                                                              selectionHandler:^(AVCaptureDevice * _Nonnull captureDevice) {
        dispatch_async(dispatch_get_main_queue(), ^{
            auto loaded = weakSelf;
            if (loaded == nil) return;
            
            CaptureService *captureService = loaded.captureService;
            CaptureVideoPreviewView *captureVideoPreviewView = [loaded newCaptureVideoPreviewView];
            [loaded.stackView addArrangedSubview:captureVideoPreviewView];
            AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [captureVideoPreviewView.captureVideoPreviewLayer retain];
            [captureVideoPreviewView release];
            
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_addCapureDevice:captureDevice captureVideoPreviewLayer:captureVideoPreviewLayer];
            });
            
            [captureVideoPreviewLayer release];
        });
    }
                                                                                            deselectionHandler:^(AVCaptureDevice * _Nonnull captureDevice) {
        abort();
    }
                                                                                                 reloadHandler:^{
        auto loaded = weakSelf;
        if (loaded == nil) return;
        
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(loaded->_captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        captureDevicesMenuElement
    ]];
    
    UIBarButtonItem *captureDevicesBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath"] menu:menu];
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevicesBarButtonItem, sel_registerName("_setShowsChevron:"), YES);
    
    _captureDevicesBarButtonItem = [captureDevicesBarButtonItem retain];
    return [captureDevicesBarButtonItem autorelease];
}

- (UIBarButtonItem *)formatBarButtonItem {
    if (auto formatBarButtonItem = _formatBarButtonItem) return formatBarButtonItem;
    
    __weak auto weakSelf = self;
    
    //
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        assert(weakSelf.photoFormatMenuBuilder != nil);
        [weakSelf.photoFormatMenuBuilder menuElementsWithCompletionHandler:^(NSArray<__kindof UIMenuElement *> * _Nonnull menuElements) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(menuElements);
            });
        }];
    }];
    
    //
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    
    UIBarButtonItem *formatBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Format" menu:menu];
    
    _formatBarButtonItem = [formatBarButtonItem retain];
    return [formatBarButtonItem autorelease];
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
                                           selector:@selector(didChangeReactionEffectsInProgressNotification:)
                                               name:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
                                             object:captureService];
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (void)didTriggerPhotosBarButtonItem:(UIBarButtonItem *)sender {
    
}

- (void)didTriggerCaptureButton:(UIButton *)sender {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_startPhotoCaptureWithPhotoModel:self.photoFormatMenuBuilder.photoFormatModel];
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

- (void)didRemoveDeviceNotification:(NSNotification *)notification {
    
}

- (CaptureVideoPreviewView *)newCaptureVideoPreviewView {
    CaptureVideoPreviewView *captureVideoPreviewView = [CaptureVideoPreviewView new];

    UIContextMenuInteraction *contextMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [captureVideoPreviewView addInteraction:contextMenuInteraction];
    [contextMenuInteraction release];
    
    UITapGestureRecognizer *tapGestureRecogninzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewTapGestureRecognizer:)];
    [captureVideoPreviewView addGestureRecognizer:tapGestureRecogninzer];
    [tapGestureRecogninzer release];
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = captureVideoPreviewView.captureVideoPreviewLayer;
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
    auto previewLayer = static_cast<AVCaptureVideoPreviewLayer *>(interaction.view.layer);
    
    if (![previewLayer isKindOfClass:AVCaptureVideoPreviewLayer.class]) return nil;
    
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
        
        CaptureActionsMenuElement *element = [CaptureActionsMenuElement elementWithCaptureService:self.captureService
                                                                                    captureDevice:captureDevice
                                                                                 photoFormatModel:loaded.photoFormatModel
                                                                                completionHandler:^(PhotoFormatModel * _Nonnull photoFormatModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                auto loaded = weakSelf;
                if (loaded == nil) return;
                
                __kindof UIScene * _Nullable scene = loaded.view.window.windowScene;
                if (scene != nil) {
                    NSDictionary<NSString *, id> *_registeredComponents;
                    assert(object_getInstanceVariable(scene, "_registeredComponents", reinterpret_cast<void **>(&_registeredComponents)) != nullptr);
                    id userActivitySceneComponentKey = _registeredComponents[@"UIUserActivitySceneComponentKey"];
                    reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(userActivitySceneComponentKey, sel_registerName("_saveSceneRestorationState"));
                }
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
