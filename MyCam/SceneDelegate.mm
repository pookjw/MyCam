//
//  SceneDelegate.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import "SceneDelegate.h"
#import "CameraRootViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CameraRootViewController.h>

@implementation SceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    
    UINavigationController *navigationController = [UINavigationController new];
    CameraRootViewController *cameraRootViewController = [CameraRootViewController new];
    
    if (NSUserActivity * _Nullable stateRestorationActivity = session.stateRestorationActivity) {
        [cameraRootViewController restoreStateWithUserActivity:stateRestorationActivity];
    }
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: {
            [navigationController setViewControllers:@[cameraRootViewController] animated:NO];
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                assert(granted);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [navigationController setViewControllers:@[cameraRootViewController] animated:NO];
                });
            }];
            break;
        }
        default:
            abort();
    }
    [cameraRootViewController release];
    
    //
    
    [navigationController setToolbarHidden:NO animated:NO];
    
    UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
    toolbarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    UIToolbar *toolbar = navigationController.toolbar;
    toolbar.compactAppearance = toolbarAppearance;
    toolbar.standardAppearance = toolbarAppearance;
    toolbar.scrollEdgeAppearance = toolbarAppearance;
    [toolbarAppearance release];
    
    //
    
    UINavigationBar *navigationBar = navigationController.navigationBar;
    UINavigationBarAppearance *navigationBarAppearance = [UINavigationBarAppearance new];
    navigationBarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    navigationBar.compactAppearance = navigationBarAppearance;
    navigationBar.standardAppearance = navigationBarAppearance;
    navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    [navigationBarAppearance release];
    
    window.rootViewController = navigationController;
    [navigationController release];
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

- (NSUserActivity *)stateRestorationActivityForScene:(UIScene *)scene {
    auto navigationController = static_cast<UINavigationController *>(self.window.rootViewController);
    if (![navigationController isKindOfClass:UINavigationController.class]) return nil;
    
    auto cameraRootViewController = static_cast<CameraRootViewController *>(navigationController.topViewController);
    if (![cameraRootViewController isKindOfClass:CameraRootViewController.class]) return nil;
    
    return cameraRootViewController.stateRestorationActivity;
}

@end
