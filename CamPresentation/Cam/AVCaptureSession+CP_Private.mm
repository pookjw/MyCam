//
//  AVCaptureSession+CP_Private.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/21/24.
//

#import <CamPresentation/AVCaptureSession+CP_Private.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <objc/message.h>
#import <objc/runtime.h>

@implementation AVCaptureSession (CP_Private)

- (id)cp_controlsOverlay {
    id _internal;
    assert(object_getInstanceVariable(self, "_internal", reinterpret_cast<void **>(&_internal)) != NULL);
    
    id controlsOverlay;
    assert(object_getInstanceVariable(_internal, "controlsOverlay", reinterpret_cast<void **>(&controlsOverlay)) != NULL);
    
    return controlsOverlay;
}

@end

#endif
