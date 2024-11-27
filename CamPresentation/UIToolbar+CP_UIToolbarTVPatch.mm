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

namespace cp_UIToolbarButton {

namespace preferredFocusEnvironments /* Legacy */ {
NSArray<id<UIFocusEnvironment>> * impl(__kindof UIControl *self, SEL _cmd) {
    __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_info"));
    
    if ([_info isKindOfClass:objc_lookUpClass("UINavigationButton")]) {
        return @[_info];
    }
    
    objc_super superInfo = { self, [self superclass] };
    return reinterpret_cast<id (*)(objc_super *, SEL)>(objc_msgSendSuper2)(&superInfo, _cmd);
}
void addImpl() {
    assert(class_addMethod(objc_lookUpClass("UIToolbarButton"), @selector(preferredFocusEnvironments), reinterpret_cast<IMP>(impl), @encode(id)));
}
}
}


namespace cp_UIButtonBarButton {
namespace preferredFocusEnvironments /* Modern */ {
NSArray<id<UIFocusEnvironment>> * impl(__kindof UIControl *self, SEL _cmd) {
    for (__kindof UIButton *subview in self.subviews) {
        if ([subview isKindOfClass:objc_lookUpClass("_UIModernBarButton")]) {
            return @[subview];
        }
    }
    
    objc_super superInfo = { self, [self superclass] };
    return reinterpret_cast<id (*)(objc_super *, SEL)>(objc_msgSendSuper2)(&superInfo, _cmd);
}
void addImpl() {
    assert(class_addMethod(objc_lookUpClass("_UIButtonBarButton"), @selector(preferredFocusEnvironments), reinterpret_cast<IMP>(impl), @encode(id)));
}
}

}


namespace cp_UINavigationButton {
namespace sizeThatFits /* Legacy */ {
CGSize (*original)(__kindof UIControl *self, SEL _cmd, CGSize size);
CGSize custom(__kindof UIControl *self, SEL _cmd, CGSize size) {
    CGSize result = original(self, _cmd, size);
    
    __kindof UIView *_enclosingBar = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_enclosingBar"));
    
    if ([_enclosingBar isKindOfClass:objc_lookUpClass("UIToolbar")]) {
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

namespace cp_UIButtonBarButtonVisualProviderIOS {

namespace _configureTextWithOffset_additionalPadding /* Modern */ {
void (*original)(id self, SEL _cmd, UIOffset offset, UIEdgeInsets additionalPadding);
void custom(id self, SEL _cmd, UIOffset offset, UIEdgeInsets additionalPadding) {
    id _appearanceDelegate;
    assert(object_getInstanceVariable(self, "_appearanceDelegate", reinterpret_cast<void **>(&_appearanceDelegate)));
    if (![_appearanceDelegate isKindOfClass:objc_lookUpClass("_UIToolbarContentView")]) {
        original(self, _cmd, offset, additionalPadding);
        return;
    }
    
    original(self, _cmd, UIOffsetZero, UIEdgeInsetsZero);
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("_UIButtonBarButtonVisualProviderIOS"), sel_registerName("_configureTextWithOffset:additionalPadding:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

namespace _configureImageWithInsets_paddingEdges_additionalPadding /* Modern */ {
void (*original)(id self, SEL _cmd, UIOffset offset, NSUInteger paddingEdges, UIEdgeInsets additionalPadding);
void custom(id self, SEL _cmd, UIOffset offset, NSUInteger paddingEdges, UIEdgeInsets additionalPadding) {
    id _appearanceDelegate;
    assert(object_getInstanceVariable(self, "_appearanceDelegate", reinterpret_cast<void **>(&_appearanceDelegate)));
    if (![_appearanceDelegate isKindOfClass:objc_lookUpClass("_UIToolbarContentView")]) {
        original(self, _cmd, offset, paddingEdges, additionalPadding);
        return;
    }
    
    // Text와 달리 Image는 Greater Than으로 Constraint을 설정하기 때문에 기존꺼를 지우고 직접 설정해준다.
    NSMutableDictionary<NSString *, NSLayoutConstraint *> *_currentConstraints;
    assert(object_getInstanceVariable(self, "_currentConstraints", reinterpret_cast<void **>(&_currentConstraints)));
    [NSLayoutConstraint deactivateConstraints:_currentConstraints.allValues];
    [_currentConstraints removeAllObjects];
    
    __kindof UIControl *button = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("button"));
    __kindof UIButton *imageButton = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("imageButton"));
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(button, sel_registerName("_addBoundsMatchingConstraintsForView:"), imageButton);
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("_UIButtonBarButtonVisualProviderIOS"), sel_registerName("_configureImageWithInsets:paddingEdges:additionalPadding:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

}


namespace cp_UIButtonBar {

namespace _updatedViewForBarButtonItem_withView /* Modern */ {
__kindof UIView * (*original)(__kindof UIView *self, SEL _cmd, UIBarButtonItem *barButtonItem, UIView *view);
__kindof UIView * custom(__kindof UIView *self, SEL _cmd, UIBarButtonItem *barButtonItem, UIView *view) {
    __kindof UIView *result = original(self, _cmd, barButtonItem, view);
    
    if ([result isKindOfClass:objc_lookUpClass("_UIButtonBarButton")]) {
        for (__kindof UIButton *subview in result.subviews) {
            if (![subview isKindOfClass:objc_lookUpClass("_UIModernBarButton")]) continue;
            subview.userInteractionEnabled = YES;
        }
    }
    
    return result;
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("_UIButtonBar"), sel_registerName("_updatedViewForBarButtonItem:withView:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}

}


namespace cp_UIBarButtonItem {

namespace createViewForToolbar /* Legacy */ {
const UIActionIdentifier actionIdentifier = @"cp_actionIdentifier";
__kindof UIView * (*original)(UIBarButtonItem *self, SEL _cmd, __kindof UIView *toolbar);
__kindof UIView * custom(UIBarButtonItem *self, SEL _cmd, __kindof UIView *toolbar) {
    __kindof UIControl *result = original(self, _cmd, toolbar);
    
    __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(result, sel_registerName("_info"));
    
    if (![_info isKindOfClass:objc_lookUpClass("UINavigationButton")]) {
        return result;
    }
    
    [_info removeActionForIdentifier:actionIdentifier forControlEvents:UIControlEventPrimaryActionTriggered];
    
    __weak auto weakResult = result;
    UIAction *action = [UIAction actionWithTitle:@"" image:nil identifier:actionIdentifier handler:^(__kindof UIAction * _Nonnull action) {
        [weakResult sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
    }];
    
    [_info addAction:action forControlEvents:UIControlEventPrimaryActionTriggered];
    _info.menu = self.menu;
    _info.preferredMenuElementOrder = self.preferredMenuElementOrder;
    _info.showsMenuAsPrimaryAction = YES;
    
    return result;
}
void swizzle() {
    Method mehtod = class_getInstanceMethod(UIBarButtonItem.class, sel_registerName("createViewForToolbar:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(mehtod));
    method_setImplementation(mehtod, reinterpret_cast<IMP>(custom));
}
}

namespace setMenu /* Legacy */ {
void (*original)(UIBarButtonItem *self, SEL _cmd, UIMenu *menu);
void custom(UIBarButtonItem *self, SEL _cmd, UIMenu *menu) {
    original(self, _cmd, menu);
    
    __kindof UIControl *view = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("view"));
    
    if ([view isKindOfClass:objc_lookUpClass("UIToolbarButton")]) {
        // Legacy
        __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(view, sel_registerName("_info"));
        if ([_info isKindOfClass:UIButton.class]) {
            _info.menu = menu;
        }
    }
}
void swizzle() {
    Method mehtod = class_getInstanceMethod(UIBarButtonItem.class, @selector(setMenu:));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(mehtod));
    method_setImplementation(mehtod, reinterpret_cast<IMP>(custom));
}
}

namespace setPreferredMenuElementOrder /* Legacy */ {
void (*original)(UIBarButtonItem *self, SEL _cmd, UIContextMenuConfigurationElementOrder preferredMenuElementOrder);
void custom(UIBarButtonItem *self, SEL _cmd, UIContextMenuConfigurationElementOrder preferredMenuElementOrder) {
    original(self, _cmd, preferredMenuElementOrder);
    
    __kindof UIControl *view = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("view"));
    
    if ([view isKindOfClass:objc_lookUpClass("UIToolbarButton")]) {
        // Legacy
        __kindof UIButton *_info = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(view, sel_registerName("_info"));
        if ([_info isKindOfClass:UIButton.class]) {
            _info.preferredMenuElementOrder = preferredMenuElementOrder;
        }
    }
}
void swizzle() {
    Method mehtod = class_getInstanceMethod(UIBarButtonItem.class, @selector(setPreferredMenuElementOrder:));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(mehtod));
    method_setImplementation(mehtod, reinterpret_cast<IMP>(custom));
}
}

}

namespace cp_UIToolbar {

namespace _forceLegacyVisualProvider {
BOOL (*original)(Class self, SEL _cmd);
BOOL custom(Class self, SEL _cmd) {
    return NO;
//    return original(self, _cmd);
}
void swizzle() {
    Method mehtod = class_getClassMethod(objc_lookUpClass("UIToolbar"), sel_registerName("_forceLegacyVisualProvider"));
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
    cp_UIButtonBarButton::preferredFocusEnvironments::addImpl();
    cp_UINavigationButton::sizeThatFits::swizzle();
    cp_UIButtonBar::_updatedViewForBarButtonItem_withView::swizzle();
    cp_UIBarButtonItem::createViewForToolbar::swizzle();
    cp_UIBarButtonItem::setMenu::swizzle();
    cp_UIBarButtonItem::setPreferredMenuElementOrder::swizzle();
    cp_UIButtonBarButtonVisualProviderIOS::_configureTextWithOffset_additionalPadding::swizzle();
    cp_UIButtonBarButtonVisualProviderIOS::_configureImageWithInsets_paddingEdges_additionalPadding::swizzle();
    cp_UIToolbar::_forceLegacyVisualProvider::swizzle();
}

@end

#endif
