//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <objc/runtime.h>

#warning 확대할 때 preview 뜨게 하기

@interface CaptureVideoPreviewView ()
@property (retain, nonatomic, readonly) UIButton *menuButton;
@end

@implementation CaptureVideoPreviewView
@synthesize previewLayer = _previewLayer;
@synthesize depthMapLayer = _depthMapLayer;
@synthesize spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel;
@synthesize menuButton = _menuButton;

- (instancetype)initWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer *)depthMapLayer {
    if (self = [super init]) {
        _previewLayer = [previewLayer retain];
        _depthMapLayer = [depthMapLayer retain];
        
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        CALayer *layer = self.layer;
        CGRect bounds = layer.bounds;
        
        previewLayer.frame = bounds;
        [layer addSublayer:previewLayer];
        
        if (depthMapLayer != nil) {
            depthMapLayer.frame = bounds;
            [layer addSublayer:depthMapLayer];
        }
        
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
    }
    
    return self;
}

- (void)dealloc {
    [_previewLayer release];
    [_depthMapLayer release];
    [_spatialCaptureDiscomfortReasonLabel release];
    [_menuButton release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.layer.bounds;
    self.previewLayer.frame = bounds;
    self.depthMapLayer.frame = bounds;
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
    
    _menuButton = [menuButton retain];
    return menuButton;
}

- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons {
    NSString *text = [reasons.allObjects componentsJoinedByString:@"\n"];
    self.spatialCaptureDiscomfortReasonLabel.text = text;
}

- (void)reloadMenu {
    UIMenu *menu = [self.menu copy];
    self.menu = menu;
    [menu release];
}

- (UIMenu *)menu {
    return self.menuButton.menu;
}

- (void)setMenu:(UIMenu *)menu {
    self.menuButton.menu = menu;
}

@end
