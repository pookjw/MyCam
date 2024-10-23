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

#warning 확대할 때 preview 뜨게 하기

@interface CaptureVideoPreviewView ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) UIButton *menuButton;
@property (retain, nonatomic, readonly) FocusRectLayer *focusRectLayer;
@property (retain, nonatomic, readonly) id<UITraitChangeRegistration> displayScaleChangeRegistration;
@end

@implementation CaptureVideoPreviewView
@synthesize spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel;
@synthesize menuButton = _menuButton;

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
        
        UIButton *menuButton = self.menuButton;
        menuButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:menuButton];
        [NSLayoutConstraint activateConstraints:@[
            [menuButton.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [menuButton.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor]
        ]];
        
        menuButton.layer.zPosition = previewLayer.zPosition + 1.f;
        
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
    }
    
    return self;
}

- (void)dealloc {
    [_displayScaleChangeRegistration release];
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons"];
    [_captureDevice release];
    [_previewLayer release];
    [_depthMapLayer release];
    [_visionLayer release];
    [_metadataObjectsLayer release];
    [_focusRectLayer release];
    [_spatialCaptureDiscomfortReasonLabel release];
    [_menuButton release];
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
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

- (UIButton *)menuButton {
    if (auto menuButton = _menuButton) return menuButton;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"list.bullet"];
    
    UIButton *menuButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    menuButton.showsMenuAsPrimaryAction = YES;
    menuButton.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    menuButton.menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_photoFormatElementWithCaptureService:self.captureService captureDevice:self.captureDevice didChangeHandler:nil]
    ]];
    
    _menuButton = [menuButton retain];
    return menuButton;
}

- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons {
    NSString *text = [reasons.allObjects componentsJoinedByString:@"\n"];
    self.spatialCaptureDiscomfortReasonLabel.text = text;
}

#warning deprecated
- (void)reloadMenu {
    UIMenu *menu = [self.menuButton.menu copy];
    self.menuButton.menu = menu;
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

@end
