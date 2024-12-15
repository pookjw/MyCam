//
//  AVPlayerViewController+Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/15/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/AVPlayerViewController+Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace cp_AVPlayerViewController {
namespace avkit_isEffectivelyFullScreen {
void *key = &key;
BOOL (*original)(AVPlayerViewController *self, SEL _cmd);
BOOL custom(AVPlayerViewController *self, SEL _cmd) {
    NSNumber * _Nullable value = objc_getAssociatedObject(self, key);
    if (value) {
        return value.boolValue;
    }
    
    return original(self, _cmd);
}
void swizzle() {
    Method method = class_getInstanceMethod(AVPlayerViewController.class, sel_registerName("avkit_isEffectivelyFullScreen"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

@implementation AVPlayerViewController (Category)

+ (void)load {
    cp_AVPlayerViewController::avkit_isEffectivelyFullScreen::swizzle();
}

- (std::optional<BOOL>)cp_overrideEffectivelyFullScreen {
    NSNumber * _Nullable value = objc_getAssociatedObject(self, cp_AVPlayerViewController::avkit_isEffectivelyFullScreen::key);
    if (value == nil) {
        return std::nullopt;
    }
    
    return value.boolValue;
}

- (void)cp_setOverrideEffectivelyFullScreen:(std::optional<BOOL>)cp_overrideEffectivelyFullScreen {
    NSNumber * _Nullable value;
    if (auto ptr = cp_overrideEffectivelyFullScreen) {
        value = @(*ptr);
    } else {
        value = nil;
    }
    
    objc_setAssociatedObject(self, cp_AVPlayerViewController::avkit_isEffectivelyFullScreen::key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#endif
