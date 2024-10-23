//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <CamPresentation/UIDeferredMenuElement+PhotoFormat.h>
#import <CamPresentation/FocusRectLayer.h>
#import <objc/runtime.h>
#import <objc/message.h>

#warning 확대할 때 preview 뜨게 하기
#warning adjusting exposure

@interface CaptureVideoPreviewView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) UIBarButtonItem *menuBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *captureProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureProgressBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingFocusActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingFocusBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingExposureActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingExposureBarButtonItem;
@property (retain, nonatomic, readonly) UIToolbar *toolbar;
@property (retain, nonatomic, readonly) UIVisualEffectView *blurView;
@property (retain, nonatomic, readonly) FocusRectLayer *focusRectLayer;
@property (retain, nonatomic, readonly) id<UITraitChangeRegistration> displayScaleChangeRegistration;
@end

@implementation CaptureVideoPreviewView
@synthesize spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel;
@synthesize menuBarButtonItem = _menuBarButtonItem;
@synthesize captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView;
@synthesize captureProgressBarButtonItem = _captureProgressBarButtonItem;
@synthesize reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView;
@synthesize reactionProgressBarButtonItem = _reactionProgressBarButtonItem;
@synthesize adjustingFocusActivityIndicatorView = _adjustingFocusActivityIndicatorView;
@synthesize adjustingFocusBarButtonItem = _adjustingFocusBarButtonItem;
@synthesize adjustingExposureActivityIndicatorView = _adjustingExposureActivityIndicatorView;
@synthesize adjustingExposureBarButtonItem = _adjustingExposureBarButtonItem;
@synthesize toolbar = _toolbar;
@synthesize blurView = _blurView;

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer *)depthMapLayer visionLayer:(CALayer *)visionLayer metadataObjectsLayer:(CALayer *)metadataObjectsLayer {
    if (self = [super init]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        _previewLayer = [previewLayer retain];
        _depthMapLayer = [depthMapLayer retain];
        _visionLayer = [visionLayer retain];
        _metadataObjectsLayer = [metadataObjectsLayer retain];
        
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        CALayer *layer = self.layer;
        CGRect bounds = layer.bounds;
        
        previewLayer.frame = bounds;
        [layer addSublayer:previewLayer];
        
        if (depthMapLayer != nil) {
            depthMapLayer.frame = bounds;
            [layer addSublayer:depthMapLayer];
        }
        
        if (visionLayer != nil) {
            visionLayer.frame = bounds;
            [layer addSublayer:visionLayer];
        }
        
        if (metadataObjectsLayer != nil) {
            metadataObjectsLayer.frame = bounds;
            [layer addSublayer:metadataObjectsLayer];
        }
        
        FocusRectLayer *focusRectLayer = [[FocusRectLayer alloc] initWithCaptureDevice:captureDevice videoPreviewLayer:previewLayer];
        focusRectLayer.contentsScale = 3.f;
        [layer addSublayer:focusRectLayer];
        _focusRectLayer = focusRectLayer;
        
        //
        
        UILabel *spatialCaptureDiscomfortReasonLabel = self.spatialCaptureDiscomfortReasonLabel;
        spatialCaptureDiscomfortReasonLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:spatialCaptureDiscomfortReasonLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [spatialCaptureDiscomfortReasonLabel.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor],
            [spatialCaptureDiscomfortReasonLabel.centerYAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerYAnchor],
            [spatialCaptureDiscomfortReasonLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.topAnchor],
            [spatialCaptureDiscomfortReasonLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [spatialCaptureDiscomfortReasonLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
            [spatialCaptureDiscomfortReasonLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor]
        ]];
        
        //
        
        UIToolbar *toolbar = self.toolbar;
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:toolbar];
        [NSLayoutConstraint activateConstraints:@[
            [toolbar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [toolbar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [toolbar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        toolbar.layer.zPosition = previewLayer.zPosition + 1.f;
        
        //
        
        UITapGestureRecognizer *tapGestureRecogninzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewTapGestureRecognizer:)];
        [self addGestureRecognizer:tapGestureRecogninzer];
        [tapGestureRecogninzer release];
        
        UILongPressGestureRecognizer *longGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewLongGestureRecognizer:)];
        [self addGestureRecognizer:longGestureRecognizer];
        [longGestureRecognizer release];
        
        //
        
        [captureDevice addObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons" options:NSKeyValueObservingOptionNew context:nullptr];
        [self updateSpatialCaptureDiscomfortReasonLabelWithReasons:captureDevice.spatialCaptureDiscomfortReasons];
        
        id<UITraitChangeRegistration> displayScaleChangeRegistration = [self registerForTraitChanges:@[UITraitDisplayScale.class] withTarget:self action:@selector(didChangeDisplayScale:)];
        _displayScaleChangeRegistration = [displayScaleChangeRegistration retain];
        
        [self updateContentScale];
        
        //
        
        UIVisualEffectView *blurView = self.blurView;
        [self addSubview:blurView];
        blurView.frame = self.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.hidden = YES;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willBeginSnapshotSessionNotification:)
                                                   name:@"_UIApplicationWillBeginSnapshotSessionNotification"
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didEndSnapshotSessionNotification:)
                                                   name:@"_UIApplicationDidEndSnapshotSessionNotification"
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didChangeCaptureReadinessNotification:)
                                                   name:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                 object:captureService];
        
        [captureDevice addObserver:self forKeyPath:@"reactionEffectsInProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_displayScaleChangeRegistration release];
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons"];
    [_captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    [_captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    [_captureDevice removeObserver:self forKeyPath:@"adjustingExposure"];
    [_captureDevice release];
    [_previewLayer release];
    [_depthMapLayer release];
    [_visionLayer release];
    [_metadataObjectsLayer release];
    [_focusRectLayer release];
    [_spatialCaptureDiscomfortReasonLabel release];
    [_menuBarButtonItem release];
    [_captureProgressActivityIndicatorView release];
    [_captureProgressBarButtonItem release];
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    [_adjustingFocusActivityIndicatorView release];
    [_adjustingFocusBarButtonItem release];
    [_adjustingExposureActivityIndicatorView release];
    [_adjustingExposureBarButtonItem release];
    [_toolbar release];
    [_blurView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([_captureDevice isEqual:object]) {
        if ([keyPath isEqualToString:@"spatialCaptureDiscomfortReasons"]) {
            auto captureDevice = static_cast<AVCaptureDevice *>(object);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSpatialCaptureDiscomfortReasonLabelWithReasons:captureDevice.spatialCaptureDiscomfortReasons];
            });
            return;
        } else if ([keyPath isEqualToString:@"reactionEffectsInProgress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeReactionEffectsInProgress];
            });
            return;
        } else if ([keyPath isEqualToString:@"adjustingFocus"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeAdjustingFocus];
            });
            return;
        } else if ([keyPath isEqualToString:@"adjustingExposure"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeAdjustingExposure];
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.layer.bounds;
    self.previewLayer.frame = bounds;
    self.depthMapLayer.frame = bounds;
    self.visionLayer.frame = bounds;
    self.metadataObjectsLayer.frame = bounds;
    self.focusRectLayer.frame = bounds;
}

- (UILabel *)spatialCaptureDiscomfortReasonLabel {
    if (auto spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel) return spatialCaptureDiscomfortReasonLabel;
    
    UILabel *spatialCaptureDiscomfortReasonLabel = [UILabel new];
    spatialCaptureDiscomfortReasonLabel.textAlignment = NSTextAlignmentCenter;
    spatialCaptureDiscomfortReasonLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    spatialCaptureDiscomfortReasonLabel.numberOfLines = 0;
    
#warning TODO Blur + Vibrancy
    spatialCaptureDiscomfortReasonLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    spatialCaptureDiscomfortReasonLabel.textColor = UIColor.whiteColor;
    
    _spatialCaptureDiscomfortReasonLabel = [spatialCaptureDiscomfortReasonLabel retain];
    return [spatialCaptureDiscomfortReasonLabel autorelease];
}

- (UIBarButtonItem *)menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_photoFormatElementWithCaptureService:self.captureService captureDevice:self.captureDevice didChangeHandler:nil]
    ]];
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"list.bullet"] menu:menu];
    menuBarButtonItem.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _menuBarButtonItem = [menuBarButtonItem retain];
    return [menuBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)captureProgressActivityIndicatorView {
    if (auto captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView) return captureProgressActivityIndicatorView;
    
    UIActivityIndicatorView *captureProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    captureProgressActivityIndicatorView.hidesWhenStopped = YES;
    captureProgressActivityIndicatorView.color = UIColor.systemRedColor;
    
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
    reactionProgressActivityIndicatorView.color = UIColor.systemOrangeColor;
    
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
    adjustingFocusActivityIndicatorView.color = UIColor.systemYellowColor;
    
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

- (UIActivityIndicatorView *)adjustingExposureActivityIndicatorView {
    if (auto adjustingExposureActivityIndicatorView = _adjustingExposureActivityIndicatorView) return adjustingExposureActivityIndicatorView;
    
    UIActivityIndicatorView *adjustingExposureActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    adjustingExposureActivityIndicatorView.hidesWhenStopped = YES;
    adjustingExposureActivityIndicatorView.color = UIColor.systemGreenColor;
    
    _adjustingExposureActivityIndicatorView = [adjustingExposureActivityIndicatorView retain];
    return [adjustingExposureActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)adjustingExposureBarButtonItem {
    if (auto adjustingExposureBarButtonItem = _adjustingExposureBarButtonItem) return adjustingExposureBarButtonItem;
    
    UIActivityIndicatorView *adjustingExposureActivityIndicatorView = self.adjustingExposureActivityIndicatorView;
    UIBarButtonItem *adjustingExposureBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:adjustingExposureActivityIndicatorView];
    adjustingExposureBarButtonItem.hidden = YES;
    adjustingExposureBarButtonItem.enabled = NO;
    
    _adjustingExposureBarButtonItem = [adjustingExposureBarButtonItem retain];
    return [adjustingExposureBarButtonItem autorelease];
}

- (UIToolbar *)toolbar {
    if (auto toolbar = _toolbar) return toolbar;
    
    UIToolbar *toolbar = [UIToolbar new];
    
    [toolbar setItems:@[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem,
        self.adjustingExposureBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.menuBarButtonItem
    ]
             animated:NO];
    
    _toolbar = [toolbar retain];
    return [toolbar autorelease];
}

- (UIVisualEffectView *)blurView {
    if (auto blurView = _blurView) return blurView;
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
    
    _blurView = [blurView retain];
    return [blurView autorelease];
}

- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons {
    NSString *text = [reasons.allObjects componentsJoinedByString:@"\n"];
    self.spatialCaptureDiscomfortReasonLabel.text = text;
}

#warning deprecated
- (void)reloadMenu {
    UIMenu *menu = [self.menuBarButtonItem.menu copy];
    self.menuBarButtonItem.menu = menu;
    [menu release];
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

- (void)didChangeDisplayScale:(CaptureVideoPreviewView *)sender {
    [self updateContentScale];
}

- (void)updateContentScale {
    CGFloat displayScale = self.traitCollection.displayScale;
    
    self.previewLayer.contentsScale = displayScale;
    self.depthMapLayer.contentsScale = displayScale;
    self.visionLayer.contentsScale = displayScale;
    self.metadataObjectsLayer.contentsScale = displayScale;
    self.focusRectLayer.contentsScale = displayScale;
}

- (void)willBeginSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = NO;
        }
    }
}

- (void)didEndSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = YES;
        }
    }
}

- (void)didChangeCaptureReadinessNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    dispatch_assert_queue(captureService.captureSessionQueue);
    
    auto captureDevice = static_cast<AVCaptureDevice *>(notification.userInfo[CaptureServiceCaptureDeviceKey]);
    
    if (![self.captureDevice isEqual:captureDevice]) {
        return;
    }
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [captureService queue_readinessCoordinatorFromCaptureDevice:captureDevice];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (readinessCoordinator.captureReadiness == AVCapturePhotoOutputCaptureReadinessReady) {
            [self.captureProgressActivityIndicatorView stopAnimating];
            self.captureProgressBarButtonItem.hidden = YES;
        } else {
            [self.captureProgressActivityIndicatorView startAnimating];
            self.captureProgressBarButtonItem.hidden = NO;
        }
        
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.menuBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

- (void)didChangeReactionEffectsInProgress {
    NSUInteger reactionEffectsInProgressCount = self.captureDevice.reactionEffectsInProgress.count;
    
    if (reactionEffectsInProgressCount > 0) {
        [self.reactionProgressActivityIndicatorView startAnimating];
        self.reactionProgressBarButtonItem.hidden = NO;
    } else {
        [self.reactionProgressActivityIndicatorView stopAnimating];
        self.reactionProgressBarButtonItem.hidden = YES;
    }
}

- (void)didChangeAdjustingFocus {
    BOOL adjustingFocus = self.captureDevice.adjustingFocus;
    
    if (adjustingFocus) {
        [self.adjustingFocusActivityIndicatorView startAnimating];
        self.adjustingFocusBarButtonItem.hidden = NO;
    } else {
        [self.adjustingFocusActivityIndicatorView stopAnimating];
        self.adjustingFocusBarButtonItem.hidden = YES;
    }
}

- (void)didChangeAdjustingExposure {
    BOOL adjustingExposure = self.captureDevice.adjustingExposure;
    
    if (adjustingExposure) {
        [self.adjustingExposureActivityIndicatorView startAnimating];
        self.adjustingExposureBarButtonItem.hidden = NO;
    } else {
        [self.adjustingExposureActivityIndicatorView stopAnimating];
        self.adjustingExposureBarButtonItem.hidden = YES;
    }
}

@end
