//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import "CaptureVideoPreviewView.h"

@implementation CaptureVideoPreviewView

+ (Class)layerClass {
    return AVCaptureVideoPreviewLayer.class;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    return static_cast<AVCaptureVideoPreviewLayer *>(self.layer);
}

@end
