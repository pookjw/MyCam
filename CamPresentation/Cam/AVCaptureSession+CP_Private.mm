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

/*
 wzr, [x8, #0x171]
 */

namespace cp_AVCaptureSession {

namespace isApplicationOptedOutByDefaultToSmartStyles {
BOOL (*original)(__kindof AVCaptureSession *self, SEL _cmd);
BOOL custom(__kindof AVCaptureSession *self, SEL _cmd) {
    id _internal;
    assert(object_getInstanceVariable(self, "_internal", reinterpret_cast<void **>(&_internal)) != NULL);
//    assert(object_setInstanceVariable(_internal, "smartStyleInVideoModeEnabled", reinterpret_cast<void *>(YES)) != NULL);
    
    if (@available(iOS 26.0, *)) {
        assert(object_setInstanceVariable(_internal, "smartStyleRenderingSupported", reinterpret_cast<void *>(YES)) != NULL);
        assert(object_setInstanceVariable(_internal, "smartStyleRenderingEnabled", reinterpret_cast<void *>(YES)) != NULL);
        // 이 method를 호출만 하고 값은 무시하고 있음. `-[AVCaptureSession isSystemStyleEnabled]`의 값이 중요함
        return YES;
    } else {
        assert(object_setInstanceVariable(_internal, "smartStyleInThirdPartyAppsEnabled", reinterpret_cast<void *>(YES)) != NULL);
        return original(self, _cmd);
    }
}
void swizzle() {
    Method method = class_getInstanceMethod([AVCaptureSession class], sel_registerName("isApplicationOptedOutByDefaultToSmartStyles"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

namespace isSystemStyleEnabled {
BOOL (*original)(__kindof AVCaptureSession *self, SEL _cmd);
BOOL custom(__kindof AVCaptureSession *self, SEL _cmd) {
    return YES;
}
void swizzle() {
    Method method = class_getInstanceMethod([AVCaptureSession class], sel_registerName("isSystemStyleEnabled"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
} 
}

}

@implementation AVCaptureSession (CP_Private)

+ (void)load {
    cp_AVCaptureSession::isApplicationOptedOutByDefaultToSmartStyles::swizzle();
    
    if (@available(iOS 26, *)) {
        cp_AVCaptureSession::isSystemStyleEnabled::swizzle();
    }
}

- (id)cp_controlsOverlay {
    id _internal;
    assert(object_getInstanceVariable(self, "_internal", reinterpret_cast<void **>(&_internal)) != NULL);
    
    id controlsOverlay;
    assert(object_getInstanceVariable(_internal, "controlsOverlay", reinterpret_cast<void **>(&controlsOverlay)) != NULL);
    
    return controlsOverlay;
}

@end

#endif
