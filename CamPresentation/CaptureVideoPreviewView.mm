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

- (instancetype)initWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    if (self = [super init]) {
        _previewLayer = [previewLayer retain];
        
        CALayer *layer = self.layer;
        previewLayer.frame = layer.bounds;
        [layer addSublayer:previewLayer];
    }
    
    return self;
}

- (void)dealloc {
    [_previewLayer release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.layer.bounds;
}

@end
