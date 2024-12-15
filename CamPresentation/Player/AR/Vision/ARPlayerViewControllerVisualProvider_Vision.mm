//
//  ARPlayerViewControllerVisualProvider_Vision.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/ARPlayerViewControllerVisualProvider_Vision.h>
#import <CamPresentation/UIApplication+mrui_requestSceneWrapper.hpp>
#import <CamPresentation/ARPlayerWindowScene_Vision.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <CamPresentation/Constants.h>
#import <CamPresentation/PlayerControlViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface ARPlayerViewControllerVisualProvider_Vision ()
@property (retain, nonatomic, readonly) UIBarButtonItem *_toggleImmersiveSceneBarButtonItem;
@property (readonly, nullable) ARPlayerWindowScene_Vision *_immersiveSpaceScene;
@property (retain, nonatomic, readonly) __kindof UIViewController *_arPlayerHostingController;
@property (retain, nonatomic, readonly) PlayerControlViewController *_controlViewController;
@end

@implementation ARPlayerViewControllerVisualProvider_Vision
@synthesize _toggleImmersiveSceneBarButtonItem = __toggleImmersiveSceneBarButtonItem;
@synthesize _arPlayerHostingController = __arPlayerHostingController;
@synthesize _controlViewController = __controlViewController;

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [__toggleImmersiveSceneBarButtonItem release];
    [__arPlayerHostingController release];
    [__controlViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ARPlayerViewController *playerViewController = self.playerViewController;
    
    UINavigationItem *navigationItem = playerViewController.navigationItem;
    navigationItem.rightBarButtonItem = self._toggleImmersiveSceneBarButtonItem;
    
    __kindof UIViewController *arPlayerHostingController = self._arPlayerHostingController;
    
    UIView *view = playerViewController.view;
    __kindof UIView *hostingView = arPlayerHostingController.view;
    
    [playerViewController addChildViewController:arPlayerHostingController];
    [view addSubview:hostingView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(view, sel_registerName("_addBoundsMatchingConstraintsForView:"), hostingView);
    [arPlayerHostingController didMoveToParentViewController:playerViewController];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
    
    [self _updateToggleImmersiveSceneBarButtonItem];
}

- (AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    return CamPresentation::avPlayerFromRealityPlayerHostingController_Vision(self._arPlayerHostingController);
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    CamPresentation::setAVPlayer_Vision(player, self._arPlayerHostingController);
    self._immersiveSpaceScene.player = player;
    self._controlViewController.controlView.player = player;
}

- (UIBarButtonItem *)_toggleImmersiveSceneBarButtonItem {
    if (auto toggleImmersiveSceneBarButtonItem = __toggleImmersiveSceneBarButtonItem) return toggleImmersiveSceneBarButtonItem;
    
    UIBarButtonItem *toggleImmersiveSceneBarButtonItem = [[UIBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerToggleImmersiveSceneBarButtonItem:)];
    
    __toggleImmersiveSceneBarButtonItem = [toggleImmersiveSceneBarButtonItem retain];
    return [toggleImmersiveSceneBarButtonItem autorelease];
}

- (ARPlayerWindowScene_Vision *)_immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role != UISceneSessionRoleImmersiveSpaceApplication) {
            continue;
        }
        
        if (![scene isKindOfClass:ARPlayerWindowScene_Vision.class]) {
            continue;
        }
        
        return static_cast<ARPlayerWindowScene_Vision *>(scene);
    }
    
    return nil;
}

- (__kindof UIViewController *)_arPlayerHostingController {
    if (auto arPlayerHostingController = __arPlayerHostingController) return arPlayerHostingController;
    
    __kindof UIViewController *arPlayerHostingController = CamPresentation::newRealityPlayerHostingController_Vision();
    
    __arPlayerHostingController = [arPlayerHostingController retain];
    return [arPlayerHostingController autorelease];
}

- (PlayerControlViewController *)_controlViewController {
    if (auto controlViewController = __controlViewController) return controlViewController;
    
    PlayerControlViewController *controlViewController = [PlayerControlViewController new];
    
    __controlViewController = [controlViewController retain];
    return [controlViewController autorelease];
}

- (void)_didTriggerToggleImmersiveSceneBarButtonItem:(UIBarButtonItem *)sender {
    if (UIScene *immersiveSpaceScene = self._immersiveSpaceScene) {
        [UIApplication.sharedApplication requestSceneSessionDestruction:immersiveSpaceScene.session options:nil errorHandler:^(NSError * _Nonnull error) {
            abort();
        }];
    } else {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:CPSceneActivityType];
        
        userActivity.userInfo = @{
            CPSceneTypeKey: CPARPlayerScene
        };
        
        [UIApplication.sharedApplication mruiw_requestMixedImmersiveSceneWithUserActivity:userActivity completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
            
            ARPlayerWindowScene_Vision *scene = self._immersiveSpaceScene;
            assert(scene != nil);
            scene.player = self.player;
        }];
        
        [userActivity release];
    }
}

- (void)_receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    [self _updateToggleImmersiveSceneBarButtonItem];
}

- (void)_receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    [self _updateToggleImmersiveSceneBarButtonItem];
}

- (void)_updateToggleImmersiveSceneBarButtonItem {
    UIImage * _Nullable image;
    if (self._immersiveSpaceScene == nil) {
        image = [UIImage systemImageNamed:@"visionpro"];
    } else {
        image = [UIImage systemImageNamed:@"visionpro.fill"];
    }
    
    self._toggleImmersiveSceneBarButtonItem.image = image;
}

@end

#endif
