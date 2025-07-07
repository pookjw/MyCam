//
//  SceneDelegate.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import "SceneDelegate.h"
#import "CollectionViewController.h"
#include <objc/runtime.h>
#include <objc/message.h>
#import <TargetConditionals.h>
#import <CamPresentation/CameraRootViewController.h>

@interface SceneDelegate () <UIGestureRecognizerDelegate>
@end

@implementation SceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    
    CollectionViewController *rootViewController = [CollectionViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    [rootViewController release];
    
    navigationController.interactivePopGestureRecognizer.delegate = self;
    navigationController.interactiveContentPopGestureRecognizer.delegate = self;
    
    //
    
#if !TARGET_OS_TV
    UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
//    toolbarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    UIToolbar *toolbar = navigationController.toolbar;
    toolbar.compactAppearance = toolbarAppearance;
    toolbar.standardAppearance = toolbarAppearance;
    toolbar.scrollEdgeAppearance = toolbarAppearance;
    [toolbarAppearance release];
    
    //
    
    UINavigationBar *navigationBar = navigationController.navigationBar;
    UINavigationBarAppearance *navigationBarAppearance = [UINavigationBarAppearance new];
//    navigationBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    navigationBar.compactAppearance = navigationBarAppearance;
    navigationBar.standardAppearance = navigationBarAppearance;
    navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    [navigationBarAppearance release];
    
#if !TARGET_OS_VISION
    assert(object_setInstanceVariable(navigationController.interactivePopGestureRecognizer, "_recognizesWithoutEdge", reinterpret_cast<void *>(YES)));
#endif
    
#endif
    
    window.rootViewController = navigationController;
    [navigationController release];
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    UINavigationController *navigationController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(gestureRecognizer.view, sel_registerName("_viewControllerForAncestor"));
    if (![navigationController isKindOfClass:[UINavigationController class]]) return NO;
    if (![navigationController isEqual:self.window.rootViewController]) return NO;
    
    CameraRootViewController *cameraRootViewController = static_cast<CameraRootViewController *>(navigationController.topViewController);
    if (![cameraRootViewController isKindOfClass:[CameraRootViewController class]]) return NO;
    
    return [cameraRootViewController.interactivePopAvoidanceGestureRecognizers containsObject:otherGestureRecognizer];
}

@end
