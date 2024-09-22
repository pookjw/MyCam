//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <TargetConditionals.h>
#import <objc/runtime.h>

@implementation CaptureVideoPreviewView

#if TARGET_OS_VISION
+ (Class)layerClass {
    return objc_lookUpClass("AVCaptureVideoPreviewLayer");
}

- (__kindof CALayer *)captureVideoPreviewLayer {
    return self.layer;
}
#else
+ (Class)layerClass {
    return AVCaptureVideoPreviewLayer.class;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    return static_cast<AVCaptureVideoPreviewLayer *>(self.layer);
}
#endif

@end
