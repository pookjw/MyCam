//
//  SceneDelegate.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import "SceneDelegate.h"
#import "CameraRootViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import <CamPresentation/CameraRootViewController.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface SceneDelegate () <CLLocationManagerDelegate>
@property (class, nonatomic, readonly) void *didChangeAuthorizationKey;
@end

@implementation SceneDelegate

+ (void *)didChangeAuthorizationKey {
    static void *key = &key;
    return key;
}

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
    
    [self requestAuthorizationsWithCompletionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [navigationController setViewControllers:@[cameraRootViewController] animated:NO];
            } else {
                [scene openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
                    exit(EXIT_FAILURE);
                }];
            }
        });
    }];
    [cameraRootViewController release];
    
    //
    
#if !TARGET_OS_TV
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
#endif
    
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

- (void)requestAuthorizationsWithCompletionHandler:(void (^ _Nullable)(BOOL granted))completionHandler {
    void (^requestLocationAuthorization)() = ^{
        CLLocationManager *locationManager = [CLLocationManager new];
        
        switch (locationManager.authorizationStatus) {
            case kCLAuthorizationStatusNotDetermined:
                locationManager.delegate = self;
                
                objc_setAssociatedObject(locationManager,
                                         SceneDelegate.didChangeAuthorizationKey,
                                         ^(CLLocationManager *locationManager) {
                    switch (locationManager.authorizationStatus) {
                        case kCLAuthorizationStatusAuthorizedAlways:
                        case kCLAuthorizationStatusAuthorizedWhenInUse:
                            completionHandler(YES);
                            break;
                        default:
                            completionHandler(NO);
                            break;
                    }
                },
                                         OBJC_ASSOCIATION_COPY_NONATOMIC);
                
                [locationManager requestWhenInUseAuthorization];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                completionHandler(YES);
                break;
            default:
                completionHandler(NO);
                break;
        }
        
        [locationManager release];
    };
    
    void (^requestPhotoLibraryAuthorization)() = ^{
        switch ([PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite]) {
            case PHAuthorizationStatusNotDetermined:
                [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                    switch (status) {
                        case PHAuthorizationStatusAuthorized:
                        case PHAuthorizationStatusLimited:
                            requestLocationAuthorization();
                            break;
                        default:
                            completionHandler(NO);
                            break;
                    }
                }];
                break;
            case PHAuthorizationStatusAuthorized:
            case PHAuthorizationStatusLimited:
//                requestLocationAuthorization();
                completionHandler(YES);
                break;
            default:
                completionHandler(NO);
                break;
        }
        
       
    };
    
    void (^requestCameraAuthorization)() = ^{
        switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
            case AVAuthorizationStatusAuthorized: {
                requestPhotoLibraryAuthorization();
                break;
            }
            case AVAuthorizationStatusNotDetermined: {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (!granted) {
                        completionHandler(NO);
                        return;
                    }
                    
                    requestPhotoLibraryAuthorization();
                }];
                break;
            }
            default:
                completionHandler(NO);
                break;
        }
    };
    
    requestCameraAuthorization();
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    auto block = (void (^ _Nullable)(id))(objc_getAssociatedObject(manager, SceneDelegate.didChangeAuthorizationKey));
    
    if (block) {
        block(manager);
//        objc_setAssociatedObject(manager, SceneDelegate.didChangeAuthorizationKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

@end
