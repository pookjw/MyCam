//
//  ARPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <CamPresentation/ARPlayerViewController.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider_IOS.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider_Vision.h>
#import <CamPresentation/AVPlayerVideoOutput+Category.h>
#import <CamPresentation/SVRunLoop.hpp>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>

CA_EXTERN_C_BEGIN
BOOL CAFrameRateRangeIsValid(CAFrameRateRange range);
CA_EXTERN_C_END

@interface ARPlayerViewController ()
@property (retain, nonatomic, readonly) __kindof ARPlayerViewControllerVisualProvider *_visualProvider;
@end

@implementation ARPlayerViewController
@synthesize _visualProvider = __visualProvider;

+ (void)load {
    Protocol *_UIVisualStyleStylable = NSProtocolFromString(@"_UIVisualStyleStylable");
    assert(_UIVisualStyleStylable != NULL);
    assert(class_addProtocol(self, _UIVisualStyleStylable));
}

+ (id)visualStyleRegistryIdentity {
    return self;
}

+ (void)_registerDefaultStylesIfNeeded {
#if TARGET_OS_IOS
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id defaultRegistry = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"));
        
        reinterpret_cast<void (*)(id, SEL, Class, Class)>(objc_msgSend)(defaultRegistry, sel_registerName("registerVisualStyleClass:forStylableClass:"), ARPlayerViewControllerVisualProvider_IOS.class, self);
    });
#elif TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id defaultRegistry = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"));
        
        reinterpret_cast<void (*)(id, SEL, Class, Class)>(objc_msgSend)(defaultRegistry, sel_registerName("registerVisualStyleClass:forStylableClass:"), ARPlayerViewControllerVisualProvider_Vision.class, self);
    });
#else
    abort();
#endif
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [__visualProvider release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self._visualProvider viewDidLoad];
}

- (void)_commonInit {
    
}

- (AVPlayer *)player {
    return self._visualProvider.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self._visualProvider.player = player;
}

- (__kindof ARPlayerViewControllerVisualProvider *)_visualProvider {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (auto visualProvider = __visualProvider) return visualProvider;
    
    [ARPlayerViewController _registerDefaultStylesIfNeeded];
    
    id defaultRegistry = reinterpret_cast<id (*)(id, SEL, UIUserInterfaceIdiom)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"), UIUserInterfaceIdiomPhone);
    
    Class providerClass = reinterpret_cast<Class (*)(id, SEL, id)>(objc_msgSend)(defaultRegistry, sel_registerName("visualStyleClassForStylableClass:"), [ARPlayerViewController class]);
    
    assert(providerClass != nil);
    
    __kindof ARPlayerViewControllerVisualProvider *visualProvider = [(__kindof ARPlayerViewControllerVisualProvider *)[providerClass alloc] initWithPlayerViewController:self];
    
    __visualProvider = [visualProvider retain];
    return [visualProvider autorelease];
}

@end

#endif
