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
#import <CamPresentation/CaptureDevicesMenuBuilder.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import <Symbols/Symbols.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

#if TARGET_OS_TV
@interface CameraRootViewController () <PhotoFormatMenuBuilderDelegate, CaptureDevicesMenuBuilderDelegate, AVContinuityDevicePickerViewControllerDelegate>
#else
@interface CameraRootViewController () <PhotoFormatMenuBuilderDelegate, CaptureDevicesMenuBuilderDelegate>
#endif
@property (class, assign, nonatomic, readonly) void *availablePhotoPixelFormatTypesKey;
@property (class, assign, nonatomic, readonly) void *availableRawPhotoPixelFormatTypesKey;
@property (nonatomic, readonly) CaptureVideoPreviewView *captureVideoPreviewView;
@property (retain, nonatomic, readonly) UIBarButtonItem *photosBarButtonItem;
@property (retain, nonatomic, readonly) UIButton *captureButton;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureBarButtonItem;
@property (retain, nonatomic, readonly) UIButton *recordButton;
@property (retain, nonatomic, readonly) UIBarButtonItem *recordBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureDevicesBarButtonItem;
@property (retain, nonatomic, readonly) UIDeferredMenuElement *captureDevicesMenuElement;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) UIBarButtonItem *continuityDevicePickerBarButtonItem;
#endif
@property (retain, nonatomic, readonly) UIBarButtonItem *formatBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic, nullable) PhotoFormatModel *restorationPhotoFormatModel;
@property (retain, nonatomic, nullable) PhotoFormatMenuBuilder *photoFormatMenuBuilder;
@property (retain ,nonatomic, nullable) CaptureDevicesMenuBuilder *captureDevicesMenuBuilder;
@end

@implementation CameraRootViewController
@synthesize photosBarButtonItem = _photosBarButtonItem;
@synthesize captureButton = _captureButton;
@synthesize captureBarButtonItem = _captureBarButtonItem;
@synthesize recordButton = _recordButton;
@synthesize recordBarButtonItem = _recordBarButtonItem;
@synthesize captureDevicesBarButtonItem = _captureDevicesBarButtonItem;
@synthesize captureDevicesMenuElement = _captureDevicesMenuElement;
#if TARGET_OS_TV
@synthesize continuityDevicePickerBarButtonItem = _continuityDevicePickerBarButtonItem;
#endif
@synthesize formatBarButtonItem = _formatBarButtonItem;
@synthesize reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView;
@synthesize reactionProgressBarButtonItem = _reactionProgressBarButtonItem;
@synthesize captureService = _captureService;
@synthesize captureDevicesMenuBuilder = _captureDevicesMenuBuilder;

+ (void *)availablePhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

+ (void *)availableRawPhotoPixelFormatTypesKey {
    static void *key = &key;
    return key;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:CaptureServiceDidChangeRecordingStatusNotificationName object:_captureService];
    [_photosBarButtonItem release];
    [_captureButton release];
    [_captureBarButtonItem release];
    [_recordButton release];
    [_recordBarButtonItem release];
    [_captureDevicesBarButtonItem release];
    [_captureDevicesMenuElement release];
#if TARGET_OS_TV
    [_continuityDevicePickerBarButtonItem release];
#endif
    [_formatBarButtonItem release];
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    [_captureService release];
    [_restorationPhotoFormatModel release];
    [_photoFormatMenuBuilder release];
    [_captureDevicesMenuBuilder release];
    [super dealloc];
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
        self.captureBarButtonItem,
        self.recordBarButtonItem,
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
    
#if TARGET_OS_VISION
    __kindof CALayer *captureVideoPreviewLayer = self.captureVideoPreviewView.captureVideoPreviewLayer;
#else
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = self.captureVideoPreviewView.captureVideoPreviewLayer;
#endif
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_selectDefaultCaptureDevice];
        [self.captureService queue_registerCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        [self.captureService.captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PhotoFormatModel *photoFormatModel;
            if (PhotoFormatModel *restorationPhotoFormatModel = self.restorationPhotoFormatModel) {
                photoFormatModel = [restorationPhotoFormatModel retain];
                self.restorationPhotoFormatModel = nil;
            } else {
                photoFormatModel = [PhotoFormatModel new];
            }
            
            PhotoFormatMenuBuilder *photoFormatMenuService = [[PhotoFormatMenuBuilder alloc] initWithPhotoFormatModel:photoFormatModel captureService:self.captureService delegate:self];
            [photoFormatModel release];
            
            self.photoFormatMenuBuilder = photoFormatMenuService;
            [photoFormatMenuService release];
        });
    });
    
    self.view.backgroundColor = UIColor.systemOrangeColor;
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
    if (self.restorationPhotoFormatModel != nil) return;
    
    if (![userActivity.activityType isEqualToString:@"com.pookjw.MyCam.CameraRootViewController"]) return;
    
    NSData * _Nullable photoFormatModelData = userActivity.userInfo[@"photoFormatModelData"];
    if (photoFormatModelData == nil) return;
    
    NSError * _Nullable error = nil;
    NSKeyedUnarchiver *keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:photoFormatModelData error:&error];
    assert(error == nil);
    
    PhotoFormatModel *restorationPhotoFormatModel = [[PhotoFormatModel alloc] initWithCoder:keyedUnarchiver];
    [keyedUnarchiver release];
    
    self.restorationPhotoFormatModel = restorationPhotoFormatModel;
    [restorationPhotoFormatModel release];
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

- (UIButton *)captureButton {
    if (auto captureButton = _captureButton) return captureButton;
    
    UIButton *captureButton = [UIButton new];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.showsActivityIndicator = YES;
    
    captureButton.configuration = configuration;
    [captureButton addTarget:self action:@selector(didTriggerCaptureButton:) forControlEvents:UIControlEventTouchDown];
    
    _captureButton = [captureButton retain];
    return [captureButton autorelease];
}

- (UIBarButtonItem *)captureBarButtonItem {
    if (auto captureBarButtonItem = _captureBarButtonItem) return captureBarButtonItem;
    
    UIBarButtonItem *captureBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.captureButton];
    captureBarButtonItem.enabled = NO;
    
    _captureBarButtonItem = [captureBarButtonItem retain];
    return [captureBarButtonItem autorelease];
}

- (UIButton *)recordButton {
    if (auto recordButton = _recordButton) return recordButton;
    
    UIButton *recordButton = [UIButton new];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.showsActivityIndicator = YES;
    
    recordButton.configuration = configuration;
    
    _recordButton = [recordButton retain];
    return [recordButton autorelease];
}

- (UIBarButtonItem *)recordBarButtonItem {
    if (auto recordBarButtonItem = _recordBarButtonItem) return recordBarButtonItem;
    
    UIBarButtonItem *recordBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.recordButton];
    recordBarButtonItem.enabled = NO;
    
    _recordBarButtonItem = [recordBarButtonItem retain];
    return [recordBarButtonItem autorelease];
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
    
    __weak auto weakSelf = self;
    
    UIDeferredMenuElement *captureDevicesMenuElement = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [weakSelf.captureDevicesMenuBuilder menuElementsWithCompletionHandler:^(NSArray<__kindof UIMenuElement *> * _Nonnull menuElements) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(menuElements);
            });
        }];
    }];
    
    _captureDevicesMenuElement = [captureDevicesMenuElement retain];
    return captureDevicesMenuElement;
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
                                           selector:@selector(didChangeRecordingStatusNotification:)
                                               name:CaptureServiceDidChangeRecordingStatusNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didChangeCaptureReadinessNotification:)
                                               name:CaptureServiceDidChangeCaptureReadinessNotificationName
                                             object:captureService];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didChangeReactionEffectsInProgressNotification:)
                                               name:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
                                             object:captureService];
    
    _captureService = [captureService retain];
    return [captureService autorelease];
}

- (CaptureDevicesMenuBuilder *)captureDevicesMenuBuilder {
    if (auto captureDevicesMenuBuilder = _captureDevicesMenuBuilder) return captureDevicesMenuBuilder;
    
    CaptureDevicesMenuBuilder *captureDevicesMenuBuilder = [[CaptureDevicesMenuBuilder alloc] initWithCaptureService:self.captureService delegate:self];
    
    _captureDevicesMenuBuilder = [captureDevicesMenuBuilder retain];
    return [captureDevicesMenuBuilder autorelease];
}

- (void)updateRecordButtonWithRecording:(BOOL)recording {
    UIImage *image;
    if (recording) {
        image = [UIImage systemImageNamed:@"stop.fill"];
    } else {
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPaletteColors:@[
            UIColor.systemRedColor,
            UIColor.tintColor
        ]];
        
        image = [UIImage systemImageNamed:@"circle.inset.filled" withConfiguration:configuration];
    }
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = image;
    self.recordButton.configuration = configuration;
}

- (void)didTriggerPhotosBarButtonItem:(UIBarButtonItem *)sender {
    
}

- (void)didTriggerCaptureButton:(UIButton *)sender {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        [self.captureService queue_startPhotoCaptureWithPhotoModel:self.photoFormatMenuBuilder.photoFormatModel];
    });
}

- (void)didTriggerRecordButton:(UIButton *)sender {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        if (captureService.queue_isRecording) {
            [captureService queue_startVideoRecording];
        } else {
            [captureService queue_stopVideoRecording];
        }
    });
}

- (void)didChangeRecordingStatusNotification:(NSNotification *)notification {
    NSNumber *isRecordingNumber = notification.userInfo[CaptureServiceRecordingKey];
    if (isRecordingNumber == nil) return;
    BOOL isRecording = isRecordingNumber.boolValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRecordButtonWithRecording:isRecording];
    });
}

- (void)didChangeCaptureReadinessNotification:(NSNotification *)notification {
    NSNumber * _Nullable captureReadinessNumber = notification.userInfo[CaptureServiceCaptureReadinessKey];
    assert(captureReadinessNumber != nil);
    
    auto captureReadiness = static_cast<AVCapturePhotoOutputCaptureReadiness>(captureReadinessNumber.integerValue);
    
    switch (captureReadiness) {
        case AVCapturePhotoOutputCaptureReadinessReady: {
            UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.image = [UIImage systemImageNamed:@"camera.aperture"];
            self.captureButton.configuration = configuration;
            self.captureBarButtonItem.enabled = YES;
            break;
        }
        default: {
            UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.showsActivityIndicator = YES;
            self.captureBarButtonItem.enabled = NO;
            self.captureButton.configuration = configuration;
            break;
        }
    }
    
    //
    
    //    self.recordBarButtonItem.enabled = YES;
    //    [self updateRecordButtonWithRecording:isRecording];
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
#endif

- (void)photoFormatMenuBuilderElementsDidChange:(PhotoFormatMenuBuilder *)photoFormatMenuBuilder {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.formatBarButtonItem, sel_registerName("_updateMenuInPlace"));
        
        __kindof UIScene * _Nullable scene = self.view.window.windowScene;
        if (scene != nil) {
            NSDictionary<NSString *, id> *_registeredComponents;
            assert(object_getInstanceVariable(scene, "_registeredComponents", reinterpret_cast<void **>(&_registeredComponents)) != nullptr);
            id userActivitySceneComponentKey = _registeredComponents[@"UIUserActivitySceneComponentKey"];
            reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(userActivitySceneComponentKey, sel_registerName("_saveSceneRestorationState"));
        }
    });
}

- (void)captureDevicesMenuBuilderElementsDidChange:(CaptureDevicesMenuBuilder *)captureDevicesMenuBuilder {
    dispatch_async(dispatch_get_main_queue(), ^{
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.captureDevicesBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

#if TARGET_OS_TV
- (void)continuityDevicePicker:(AVContinuityDevicePickerViewController *)pickerViewController didConnectDevice:(AVContinuityDevice *)device {
    NSLog(@"%@", device);
}
#endif

@end
