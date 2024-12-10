//
//  ARPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <CamPresentation/ARPlayerViewController.h>
#import <CamPresentation/UIApplication+mrui_requestSceneWrapper.hpp>
#import <CamPresentation/ARPlayerViewControllerVisualProvider.h>
#import <CamPresentation/ARPlayerViewControllerVisualProvider_IOS.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <ARKit/ARKit.h>

@interface ARPlayerViewController ()
@property (retain, nonatomic, readonly) __kindof ARPlayerViewControllerVisualProvider *_visualProvider;
#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) UIButton *toggleImmersiveSceneButton;
@property (readonly, nullable) UIScene *immersiveSpaceScene;
#endif
@end

@implementation ARPlayerViewController
@synthesize _visualProvider = __visualProvider;
#if TARGET_OS_VISION
@synthesize toggleImmersiveSceneButton = _toggleImmersiveSceneButton;
#endif

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
        id defaultRegistry = reinterpret_cast<id (*)(id, SEL, UIUserInterfaceIdiom)>(objc_msgSend)(objc_lookUpClass("_UIVisualStyleRegistry"), sel_registerName("defaultRegistry"), UIUserInterfaceIdiomPhone);
        
        reinterpret_cast<void (*)(id, SEL, Class, Class)>(objc_msgSend)(defaultRegistry, sel_registerName("registerVisualStyleClass:forStylableClass:"), ARPlayerViewControllerVisualProvider_IOS.class, self);
    });
#elif TARGET_OS_VISION
    abort();
#else
    abort();
#endif
}

- (void)dealloc {
    [__visualProvider release];
#if TARGET_OS_VISION
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_toggleImmersiveSceneButton release];
#endif
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self._visualProvider viewDidLoad];
    
#if TARGET_OS_VISION
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
    
    [self updateToggleImmersiveSceneButton];
#endif
}

- (AVPlayer *)player {
    return self._visualProvider.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self._visualProvider.player = player;
}

- (AVSampleBufferVideoRenderer *)videoRenderer {
    return self._visualProvider.videoRenderer;
}

- (void)setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    self._visualProvider.videoRenderer = videoRenderer;
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

#if TARGET_OS_VISION
- (UIButton *)toggleImmersiveSceneButton {
    if (auto toggleImmersiveSceneButton = _toggleImmersiveSceneButton) return [[toggleImmersiveSceneButton retain] autorelease];
    
    UIButton *toggleImmersiveSceneButton = [UIButton new];
    [toggleImmersiveSceneButton addTarget:self action:@selector(didTriggerToggleImmersiveSceneButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _toggleImmersiveSceneButton = [toggleImmersiveSceneButton retain];
    return [toggleImmersiveSceneButton autorelease];
}

- (void)didTriggerToggleImmersiveSceneButton:(UIButton *)sender {
    
}

- (UIScene *)immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
            return scene;
        }
    }
    
    return nil;
}

- (void)receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    [self updateToggleImmersiveSceneButton];
}

- (void)receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    [self updateToggleImmersiveSceneButton];
}

- (void)updateToggleImmersiveSceneButton {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    
    if (self.immersiveSpaceScene == nil) {
        configuration.image = [UIImage systemImageNamed:@"visionpro"];
    } else {
        configuration.image = [UIImage systemImageNamed:@"visionpro.fill"];
    }
    
    self.toggleImmersiveSceneButton.configuration = configuration;
}
#endif

- (void)attachPlayerView {
#if TARGET_OS_IOS
    
#elif TARGET_OS_VISION
    UIButton *toggleImmersiveSceneButton = self.toggleImmersiveSceneButton;
    toggleImmersiveSceneButton.frame = self.view.bounds;
    toggleImmersiveSceneButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:toggleImmersiveSceneButton];
#endif
}

@end

#endif
