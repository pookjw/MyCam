//
//  TVSwitch.m
//  MyApp
//
//  Created by Jinwoo Kim on 11/24/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_TV

#import <CamPresentation/TVSwitch.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void);

namespace _TVSwitch {
namespace visualElementForTraitCollection {
id (*original)(Class self, SEL _cmd, UITraitCollection *traitCollection);
id custom(Class self, SEL _cmd, UITraitCollection *traitCollection) {
    return [[objc_lookUpClass("UISwitchModernVisualElement") new] autorelease];
}
void swizzle() {
    Method method = class_getClassMethod(objc_lookUpClass("UISwitch"), sel_registerName("visualElementForTraitCollection:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

@interface TVSwitch ()
@property (retain, nonatomic, readonly, direct) __kindof UIView *floatingContentView;
@end

@implementation TVSwitch

+ (void)load {
    _TVSwitch::visualElementForTraitCollection::swizzle();
    [self class];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [[self class] allocWithZone:zone];
}

+ (Class)class {
    static Class isa;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class _isa = objc_allocateClassPair(objc_lookUpClass("UISwitch"), "_TVSwitch", 0);
        
        IMP initWithFrame = class_getMethodImplementation(self, @selector(initWithFrame:));
        assert(class_addMethod(_isa, @selector(initWithFrame:), initWithFrame, NULL));
        
        IMP initWithCoder = class_getMethodImplementation(self, @selector(initWithCoder:));
        assert(class_addMethod(_isa, @selector(initWithCoder:), initWithCoder, NULL));
        
        IMP dealloc = class_getMethodImplementation(self, @selector(dealloc));
        assert(class_addMethod(_isa, @selector(dealloc), dealloc, NULL));
        
        IMP setEnabled = class_getMethodImplementation(self, @selector(setEnabled:));
        assert(class_addMethod(_isa, @selector(setEnabled:), setEnabled, NULL));
        
        IMP didUpdateFocusInContext_withAnimationCoordinator = class_getMethodImplementation(self, @selector(didUpdateFocusInContext:withAnimationCoordinator:));
        assert(class_addMethod(_isa, @selector(didUpdateFocusInContext:withAnimationCoordinator:), didUpdateFocusInContext_withAnimationCoordinator, NULL));
        
        IMP _refreshVisualElementForTraitCollection_populatingAPIProperties = class_getMethodImplementation(self, @selector(_refreshVisualElementForTraitCollection:populatingAPIProperties:));
        assert(class_addMethod(_isa, @selector(_refreshVisualElementForTraitCollection:populatingAPIProperties:), _refreshVisualElementForTraitCollection_populatingAPIProperties, NULL));
        
        assert(class_addIvar(_isa, "_floatingContentView", sizeof(id), sizeof(id), @encode(id)));
        
        objc_registerClassPair(_isa);
        isa = _isa;
    });
    
    return isa;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithFrame:(CGRect)frame {
    objc_super superInfo = { self, [self class] };
    self = reinterpret_cast<id (*)(objc_super *, SEL, CGRect)>(objc_msgSendSuper2)(&superInfo, _cmd, frame);
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)coder {
    objc_super superInfo = { self, [self class] };
    self = reinterpret_cast<id (*)(objc_super *, SEL, id)>(objc_msgSendSuper2)(&superInfo, _cmd, coder);
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)dealloc {
    [self.floatingContentView release];
    
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL)>(objc_msgSendSuper2)(&superInfo, _cmd);
}
#pragma clang diagnostic pop

- (void)setEnabled:(BOOL)enabled {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, BOOL)>(objc_msgSendSuper2)(&superInfo, _cmd, enabled);
    
    [self.superview setNeedsFocusUpdate];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, id, id)>(objc_msgSendSuper2)(&superInfo, _cmd, context, coordinator);
    
    if ([context.nextFocusedView isEqual:self]) {
        reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self.floatingContentView, sel_registerName("setControlState:animated:"), 8, YES);
    } else {
        reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self.floatingContentView, sel_registerName("setControlState:animated:"), 0, YES);
    }
}

- (void)_refreshVisualElementForTraitCollection:(UITraitCollection *)traitCollection populatingAPIProperties:(BOOL)populatingAPIProperties {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, id, BOOL)>(objc_msgSendSuper2)(&superInfo, _cmd, traitCollection, populatingAPIProperties);
    
    __kindof UIView *_visualElement;
    assert(object_getInstanceVariable(self, "_visualElement", reinterpret_cast<void **>(&_visualElement)));
    assert(_visualElement != nil);
    assert(_visualElement.superview != nil);
    
    [_visualElement removeFromSuperview];
    
    __kindof UIView *floatingContentView = self.floatingContentView;
    
    if (floatingContentView.superview == nil) {
        [self addSubview:floatingContentView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), floatingContentView);
    }
    
    UIView *contentView = ((id (*)(id, SEL))objc_msgSend)(floatingContentView, sel_registerName("contentView"));
    assert(contentView != nil);
    
    [contentView addSubview:_visualElement];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(floatingContentView, sel_registerName("_addBoundsMatchingConstraintsForView:"), _visualElement);
}

- (void)commonInit __attribute__((objc_direct)) {
    
}

- (__kindof UIView *)floatingContentView __attribute__((objc_direct)) {
    __kindof UIView *floatingContentView;
    assert(object_getInstanceVariable(self, "_floatingContentView", reinterpret_cast<void **>(&floatingContentView)));
    
    if (floatingContentView) return floatingContentView;
    
    floatingContentView = reinterpret_cast<id (*)(id, SEL, CGRect)>(objc_msgSend)([objc_lookUpClass("_UIFloatingContentView") alloc], @selector(initWithFrame:), self.bounds);
    
    reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(floatingContentView, sel_registerName("setFocusScaleAnchorPoint:"), CGPointMake(0.5, 1.));
    
    assert(object_setInstanceVariable(self, "_floatingContentView", reinterpret_cast<void *>([floatingContentView retain])));
    return [floatingContentView autorelease];
}

@end

#endif
