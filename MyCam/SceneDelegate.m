//
//  SceneDelegate.m
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import "SceneDelegate.h"
#import "CameraRootViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation SceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    
    UINavigationController *navigationController = [UINavigationController new];
    CameraRootViewController *cameraRootViewController = [CameraRootViewController new];
    
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
    
    [navigationController setToolbarHidden:NO animated:NO];
    
    UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
    toolbarAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    UIToolbar *toolbar = navigationController.toolbar;
    toolbar.compactAppearance = toolbarAppearance;
    toolbar.standardAppearance = toolbarAppearance;
    toolbar.scrollEdgeAppearance = toolbarAppearance;
    [toolbarAppearance release];
    
    window.rootViewController = navigationController;
    [navigationController release];
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

@end
