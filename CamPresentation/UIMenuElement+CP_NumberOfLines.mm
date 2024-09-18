//
//  UIMenuElement+CP_NumberOfLines.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace cp_UIContextMenuListView {
    namespace _configureCell_inCollectionView_atIndexPath_forElement_section_size {
        void (*original)(id, SEL, id, id, id, id, NSInteger);
        void custom(__kindof UIView *self, SEL _cmd, __kindof UICollectionViewCell *cell, UICollectionView *collectionView, NSIndexPath *indexPath, __kindof UIMenuElement *element, NSInteger size) {
            original(self, _cmd, cell, collectionView, indexPath, element, size);
            
            if (NSNumber *overrideNumberOfTitleLines = element.cp_overrideNumberOfTitleLines) {
                __kindof UIView *actionView = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(cell, sel_registerName("actionView"));
                
                reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(actionView, sel_registerName("setOverrideNumberOfTitleLines:"), overrideNumberOfTitleLines.unsignedIntegerValue);
                reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(actionView, sel_registerName("_updateTitleLabelNumberOfLines"));
            }
            
            if (NSNumber *overrideNumberOfSubtitleLines = element.cp_overrideNumberOfSubtitleLines) {
                __kindof UIView *actionView = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(cell, sel_registerName("actionView"));
                
                reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(actionView, sel_registerName("setOverrideNumberOfSubtitleLines:"), overrideNumberOfSubtitleLines.unsignedIntegerValue);
                reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(actionView, sel_registerName("_updateSubtitleLabelNumberOfLines"));
            }
        }
        void swizzle() {
            Method method = class_getInstanceMethod(objc_lookUpClass("_UIContextMenuListView"), sel_registerName("_configureCell:inCollectionView:atIndexPath:forElement:section:size:"));
            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
}

namespace cp_UIMenuElement {
    namespace copyWithZone {
        id (*original)(id, SEL, NSZone *);
        id custom(UIMenuElement *self, SEL _cmd, NSZone *zone) {
            auto copy = static_cast<__kindof UIMenuElement *>(original(self, _cmd, zone));
            copy.cp_overrideNumberOfSubtitleLines = self.cp_overrideNumberOfSubtitleLines;
            return copy;
        }
        void swizzle() {
            Method method = class_getInstanceMethod(UIMenuElement.class, @selector(copyWithZone:));
            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
    
    namespace _immutableCopy {
        id (*original)(id, SEL);
        id custom(UIMenuElement *self, SEL _cmd) {
            auto copy = static_cast<__kindof UIMenuElement *>(original(self, _cmd));
            copy.cp_overrideNumberOfSubtitleLines = self.cp_overrideNumberOfSubtitleLines;
            return copy;
        }
        void swizzle() {
            Method method = class_getInstanceMethod(UIMenuElement.class, sel_registerName("_immutableCopy"));
            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
}

@implementation UIMenuElement (CP_NumberOfLines)

+ (void)load {
    /*
     -[_UIContextMenuListView _configureCell:inCollectionView:atIndexPath:forElement:section:size:]
     -[UIMenuElement copyWithZone:]
     -[UIMenuElement _immutableCopy]
     */
    cp_UIContextMenuListView::_configureCell_inCollectionView_atIndexPath_forElement_section_size::swizzle();
    cp_UIMenuElement::copyWithZone::swizzle();
    cp_UIMenuElement::_immutableCopy::swizzle();
}

+ (void *)cp_overrideNumberOfTitleLines {
    static void *key = &key;
    return key;
}

+ (void *)cp_overrideNumberOfSubtitleLinesKey {
    static void *key = &key;
    return key;
}

- (NSNumber *)cp_overrideNumberOfTitleLines {
    return objc_getAssociatedObject(self, [UIMenuElement cp_overrideNumberOfTitleLines]);
}

- (void)cp_setOverrideNumberOfTitleLines:(NSNumber *)cp_overrideNumberOfTitleLines {
    objc_setAssociatedObject(self, [UIMenuElement cp_overrideNumberOfTitleLines], cp_overrideNumberOfTitleLines, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)cp_overrideNumberOfSubtitleLines {
    return objc_getAssociatedObject(self, [UIMenuElement cp_overrideNumberOfSubtitleLinesKey]);
}

- (void)cp_setOverrideNumberOfSubtitleLines:(NSNumber *)cp_overrideNumberOfSubtitleLines {
    objc_setAssociatedObject(self, [UIMenuElement cp_overrideNumberOfSubtitleLinesKey], cp_overrideNumberOfSubtitleLines, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
