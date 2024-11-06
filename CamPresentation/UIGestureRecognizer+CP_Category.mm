//
//  UIGestureRecognizer+CP_Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/UIGestureRecognizer+CP_Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace cp_UIParallaxTransitionPanGestureRecognizer {
namespace _recognizesWithoutEdge {

void *key = &key;

BOOL (*original)(__kindof UIScreenEdgePanGestureRecognizer *, SEL);
BOOL custom(__kindof UIScreenEdgePanGestureRecognizer *self, SEL _cmd) {
    if (auto number = static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_UIParallaxTransitionPanGestureRecognizer::_recognizesWithoutEdge::key))) {
        return number.boolValue;
    }
    
    return original(self, _cmd);
}

void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("_UIParallaxTransitionPanGestureRecognizer"), sel_registerName("_recognizesWithoutEdge"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

namespace cp_UIScreenEdgePanGestureRecognizer {
namespace _supportsStylusTouches {
BOOL custom(__kindof UIScreenEdgePanGestureRecognizer *self, SEL _cmd) {
    return YES;
}
void swizzle() {
    Method method = class_getClassMethod(UIScreenEdgePanGestureRecognizer.class, sel_registerName("_supportsStylusTouches"));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

@implementation UIGestureRecognizer (CP_Category)

+ (void)load {
    cp_UIParallaxTransitionPanGestureRecognizer::_recognizesWithoutEdge::swizzle();
    cp_UIScreenEdgePanGestureRecognizer::_supportsStylusTouches::swizzle();
}

- (BOOL)cp_recognizesWithoutEdge {
    assert([self isKindOfClass:objc_lookUpClass("_UIParallaxTransitionPanGestureRecognizer")]);
    
    if (auto number = static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_UIParallaxTransitionPanGestureRecognizer::_recognizesWithoutEdge::key))) {
        return number.boolValue;
    }
    
    return cp_UIParallaxTransitionPanGestureRecognizer::_recognizesWithoutEdge::original(self, sel_registerName("_recognizesWithoutEdge"));
}

- (void)cp_setRecognizesWithoutEdge:(BOOL)cp_recognizesWithoutEdge {
    assert([self isKindOfClass:objc_lookUpClass("_UIParallaxTransitionPanGestureRecognizer")]);
    
    objc_setAssociatedObject(self, cp_UIParallaxTransitionPanGestureRecognizer::_recognizesWithoutEdge::key, @(cp_recognizesWithoutEdge), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
