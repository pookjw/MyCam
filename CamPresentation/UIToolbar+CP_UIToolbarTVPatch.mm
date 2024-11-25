//
//  UIToolbar+CP_UIToolbarTVPatch.m
//  MyApp
//
//  Created by Jinwoo Kim on 11/25/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_TV

#import <CamPresentation/UIToolbar+CP_UIToolbarTVPatch.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void);

void * cp_getUIToolbarTVPatchKey(void) {
    static void *key = &key;
    return key;
}

namespace cp_UIToolbarButton {

const UIActionIdentifier actionIdentifier = @"cp_actionIdentifier";

namespace preferredFocusEnvironments {
NSArray<id<UIFocusEnvironment>> * impl(__kindof UIControl *self, SEL _cmd) {
    __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_info"));
    
    if (![_info isKindOfClass:objc_lookUpClass("UINavigationButton")]) {
        objc_super superInfo = { self, [self superclass] };
        return reinterpret_cast<id (*)(objc_super *, SEL)>(objc_msgSendSuper2)(&superInfo, _cmd);
    }
    
    __kindof UIView *_enclosingBar = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(_info, sel_registerName("_enclosingBar"));
    
    if (objc_getAssociatedObject(_enclosingBar, cp_getUIToolbarTVPatchKey()) == nil) {
        objc_super superInfo = { self, [self superclass] };
        return reinterpret_cast<id (*)(objc_super *, SEL)>(objc_msgSendSuper2)(&superInfo, _cmd);
    }
    
    return @[_info];
}
void addImpl() {
    assert(class_addMethod(objc_lookUpClass("UIToolbarButton"), @selector(preferredFocusEnvironments), reinterpret_cast<IMP>(impl), @encode(id)));
}
}
}

namespace UINavigationButton {

namespace sizeThatFits {
CGSize (*original)(__kindof UIControl *self, SEL _cmd, CGSize size);
CGSize custom(__kindof UIControl *self, SEL _cmd, CGSize size) {
    CGSize result = original(self, _cmd, size);
    
    __kindof UIView *_enclosingBar = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_enclosingBar"));
    
    if (objc_getAssociatedObject(_enclosingBar, cp_getUIToolbarTVPatchKey())) {
        // -[UIButtonLegacyVisualProvider alignmentRectInsets]에서 주는 값으로 추정
        result.width -= 70.;
    }
    
    return result;
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("UINavigationButton"), @selector(sizeThatFits:));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

}


namespace cp_UIBarButtonItem {

namespace createViewForToolbar {
__kindof UIView * (*original)(UIBarButtonItem *self, SEL _cmd, __kindof UIView *toolbar);
__kindof UIView * custom(UIBarButtonItem *self, SEL _cmd, __kindof UIView *toolbar) {
    __kindof UIView *result = original(self, _cmd, toolbar);
    
    if (objc_getAssociatedObject(toolbar, cp_getUIToolbarTVPatchKey())) {
        __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(result, sel_registerName("_info"));
        
        if (![_info isKindOfClass:objc_lookUpClass("UINavigationButton")]) {
            return result;
        }
        
        [_info removeActionForIdentifier:cp_UIToolbarButton::actionIdentifier forControlEvents:UIControlEventPrimaryActionTriggered];
        
        __weak auto weakResult = result;
        UIAction *action = [UIAction actionWithTitle:@"" image:nil identifier:cp_UIToolbarButton::actionIdentifier handler:^(__kindof UIAction * _Nonnull action) {
            [weakResult sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
        }];
        
        [_info addAction:action forControlEvents:UIControlEventPrimaryActionTriggered];
        _info.menu = self.menu;
        _info.showsMenuAsPrimaryAction = YES;
        _info.preferredMenuElementOrder = self.preferredMenuElementOrder;
    }
    
    return result;
}
void swizzle() {
    Method mehtod = class_getInstanceMethod(UIBarButtonItem.class, sel_registerName("createViewForToolbar:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(mehtod));
    method_setImplementation(mehtod, reinterpret_cast<IMP>(custom));
}
}

}


@interface UIView (CP_UIToolbarTVPatch)
@end

@implementation UIView (CP_UIToolbarTVPatch)

+ (void)load {
    cp_UIToolbarButton::preferredFocusEnvironments::addImpl();
    UINavigationButton::sizeThatFits::swizzle();
    cp_UIBarButtonItem::createViewForToolbar::swizzle();
}

@end

#endif
