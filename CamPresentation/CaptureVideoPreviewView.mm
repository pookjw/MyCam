//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <objc/runtime.h>

@implementation CaptureVideoPreviewView
@synthesize previewLayer = _previewLayer;
@synthesize depthMapLayer = _depthMapLayer;
@synthesize spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel;

- (instancetype)initWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer *)depthMapLayer {
    if (self = [super init]) {
        _previewLayer = [previewLayer retain];
        _depthMapLayer = [depthMapLayer retain];
        
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
    }
    
    return self;
}

- (void)dealloc {
    [_previewLayer release];
    [_depthMapLayer release];
    [_spatialCaptureDiscomfortReasonLabel release];
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

- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons {
    NSString *text = [reasons.allObjects componentsJoinedByString:@"\n"];
    self.spatialCaptureDiscomfortReasonLabel.text = text;
}

@end
