//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <objc/runtime.h>

@implementation CaptureVideoPreviewView

+ (Class)layerClass {
    return AVCaptureVideoPreviewLayer.class;
}

- (void)dealloc {
    [super dealloc];
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    return static_cast<AVCaptureVideoPreviewLayer *>(self.layer);
}

@end
