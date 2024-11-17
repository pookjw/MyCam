//
//  XRCaptureVideoPreviewView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCaptureVideoPreviewView.h>

@interface XRCaptureVideoPreviewView ()
@end

@implementation XRCaptureVideoPreviewView

- (void)dealloc {
    [_previewLayer release];
    [super dealloc];
}

- (void)setPreviewLayer:(__kindof CALayer *)previewLayer {
    if (_previewLayer) {
        [_previewLayer release];
        [_previewLayer removeFromSuperlayer];
    }
    
    _previewLayer = [previewLayer retain];
    
    if (previewLayer) {
        [self.layer addSublayer:previewLayer];
        previewLayer.frame = self.layer.bounds;
        previewLayer.contentsScale = self.layer.contentsScale;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.layer.bounds;
    self.previewLayer.contentsScale = self.layer.contentsScale;
}

@end

#endif
