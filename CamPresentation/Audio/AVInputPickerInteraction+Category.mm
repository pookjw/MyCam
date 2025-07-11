//
//  AVInputPickerInteraction+Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <CamPresentation/AVInputPickerInteraction+Category.h>
#include <objc/message.h>
#include <objc/runtime.h>

namespace cp_AVInputPickerInteraction {

namespace present {
void (*original)(AVInputPickerInteraction *self, SEL _cmd) API_AVAILABLE(ios(26.0));
void custom(AVInputPickerInteraction *self, SEL _cmd) API_AVAILABLE(ios(26.0)) {
    UIViewController *presentedViewController = self.view.window.rootViewController;
    while (presentedViewController.presentedViewController != nil) {
        presentedViewController = presentedViewController.presentedViewController;
    }
    
    original(self, _cmd);
    
    Ivar ivar = object_getInstanceVariable(self, "_modalViewController", NULL);
    assert(ivar != NULL);
    assert(presentedViewController.presentedViewController != nil);
    *reinterpret_cast<id *>(reinterpret_cast<uintptr_t>(self) + ivar_getOffset(ivar)) = [presentedViewController.presentedViewController retain];
}
void swizzle() API_AVAILABLE(ios(26.0)) {
    Method method = class_getInstanceMethod([AVInputPickerInteraction class], sel_registerName("present"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

namespace _beginDismissingProcess {
void (*original)(AVInputPickerInteraction *self, SEL _cmd) API_AVAILABLE(ios(26.0));
void custom(AVInputPickerInteraction *self, SEL _cmd) API_AVAILABLE(ios(26.0)) {
    Ivar ivar = object_getInstanceVariable(self, "_modalViewController", NULL);
    assert(ivar != NULL);
    __kindof UIViewController *_modalViewController = [*reinterpret_cast<id *>(reinterpret_cast<uintptr_t>(self) + ivar_getOffset(ivar)) retain];
    
    original(self, _cmd);
    
    reinterpret_cast<void (*)(id, SEL, BOOL, BOOL, id)>(objc_msgSend)(_modalViewController, sel_registerName("transitionToVisible:animated:completion:"), NO, YES, nil);
}
void swizzle() API_AVAILABLE(ios(26.0)) {
    Method method = class_getInstanceMethod([AVInputPickerInteraction class], sel_registerName("_beginDismissingProcess"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

}

@implementation AVInputPickerInteraction (Category)

+ (void)load {
    if (@available(iOS 26.0, *)) {
        cp_AVInputPickerInteraction::present::swizzle();
        cp_AVInputPickerInteraction::_beginDismissingProcess::swizzle();
    }
}

@end
