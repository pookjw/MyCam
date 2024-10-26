//
//  UIView+MenuElementDynamicHeight.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <CamPresentation/UIView+MenuElementDynamicHeight.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation UIView (MenuElementDynamicHeight)

- (BOOL)_cp_updateMenuElementHeight {
    [self invalidateIntrinsicContentSize];
    
    /* _UIContextMenuView * */
    __kindof UIView *menuView = self.superview.superview.superview.superview.superview.superview;
    if (![menuView isKindOfClass:objc_lookUpClass("_UIContextMenuView")]) {
        return NO;
    }
    
    /* _UIContextMenuUIController * */
    id delegate = ((id (*)(id, SEL))objc_msgSend)(menuView, sel_registerName("delegate"));
    if (![delegate isKindOfClass:objc_lookUpClass("_UIContextMenuUIController")]) {
        return NO;
    }
    
    [self.superview invalidateIntrinsicContentSize];
    [menuView layoutIfNeeded];
    
    reinterpret_cast<void (*)(id, SEL, BOOL, BOOL, BOOL)>(objc_msgSend)(delegate, sel_registerName("_updatePlatterAndActionViewLayoutForce:updateAttachment:adjustDetent:"), YES, NO, NO);
    return YES;
}


@end
