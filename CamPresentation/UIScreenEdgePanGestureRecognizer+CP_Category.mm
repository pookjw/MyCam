//
//  UIScreenEdgePanGestureRecognizer+CP_Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/UIScreenEdgePanGestureRecognizer+CP_Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

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

@implementation UIScreenEdgePanGestureRecognizer (CP_Category)

+ (void)load {
    cp_UIScreenEdgePanGestureRecognizer::_supportsStylusTouches::swizzle();
}

@end
