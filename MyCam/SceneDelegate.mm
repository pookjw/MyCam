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
#import <objc/message.h>
#import <TargetConditionals.h>
#if TARGET_OS_VISION
#endif
#import <AVFAudio/AVFAudio.h>

@interface SceneDelegate () <CLLocationManagerDelegate>
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@property (class, nonatomic, readonly) void *didChangeAuthorizationKey;
@end

@implementation SceneDelegate
@synthesize locationManager = _locationManager;

+ (void *)didChangeAuthorizationKey {
    static void *key = &key;
    return key;
}

- (void)dealloc {
    [_window release];
    [_locationManager release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    
    UINavigationController *navigationController = [UINavigationController new];
    CameraRootViewController *cameraRootViewController = [CameraRootViewController new];
    
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
#endif
    
    window.rootViewController = navigationController;
    [navigationController release];
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

- (void)requestAuthorizationsWithCompletionHandler:(void (^ _Nonnull)(BOOL granted))completionHandler {
#if !TARGET_OS_VISION
    void (^requestLocationAuthorization)() = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CLLocationManager *locationManager = self.locationManager;
            
            switch (locationManager.authorizationStatus) {
                case kCLAuthorizationStatusNotDetermined:
                    locationManager.delegate = self;
                    
                    // https://x.com/_silgen_name/status/1845680145451065794
                    objc_setAssociatedObject(locationManager,
                                             SceneDelegate.didChangeAuthorizationKey,
                                             ^(CLLocationManager *locationManager) {
                        switch (locationManager.authorizationStatus) {
                            case kCLAuthorizationStatusAuthorizedAlways:
                            case kCLAuthorizationStatusAuthorizedWhenInUse:
                                objc_setAssociatedObject(locationManager, SceneDelegate.didChangeAuthorizationKey, nil, OBJC_ASSOCIATION_ASSIGN);
                                completionHandler(YES);
                                break;
                            case kCLAuthorizationStatusNotDetermined:
                                break;
                            default:
                                objc_setAssociatedObject(locationManager, SceneDelegate.didChangeAuthorizationKey, nil, OBJC_ASSOCIATION_ASSIGN);
                                completionHandler(NO);
                                break;
                        }
                    },
                                             static_cast<objc_AssociationPolicy>(OBJC_ASSOCIATION_COPY_NONATOMIC | (1 << 8) | (2 << 8)));
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
        });
    };
#endif
    
    void (^requestRecordPermission)() = ^{
        AVAudioApplicationRecordPermission recordPermission = AVAudioApplication.sharedInstance.recordPermission;
        
        switch (recordPermission) {
            case AVAudioApplicationRecordPermissionUndetermined:
                [AVAudioApplication requestRecordPermissionWithCompletionHandler:^(BOOL granted) {
#if TARGET_OS_VISION
                    completionHandler(granted);
#else
                    if (granted) {
                        requestLocationAuthorization();
                    } else {
                        completionHandler(NO);
                    }
#endif
                }];
                break;
            case AVAudioApplicationRecordPermissionGranted:
#if TARGET_OS_VISION
                completionHandler(YES);
#else
                requestLocationAuthorization();
#endif
                break;
            case AVAudioApplicationRecordPermissionDenied:
                completionHandler(NO);
                break;
        }
    };
    
    void (^requestPhotoLibraryAuthorization)() = ^{
        switch ([PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite]) {
            case PHAuthorizationStatusNotDetermined:
                [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                    switch (status) {
                        case PHAuthorizationStatusAuthorized:
                        case PHAuthorizationStatusLimited:
                            requestRecordPermission();
                            break;
                        default:
                            completionHandler(NO);
                            break;
                    }
                }];
                break;
            case PHAuthorizationStatusAuthorized:
            case PHAuthorizationStatusLimited:
                requestRecordPermission();
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

- (CLLocationManager *)locationManager {
    if (auto locationManager = _locationManager) return locationManager;
    
    CLLocationManager *locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    
    _locationManager = [locationManager retain];
    return [locationManager autorelease];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    auto block = (void (^ _Nullable)(id))(objc_getAssociatedObject(manager, SceneDelegate.didChangeAuthorizationKey));
    
    if (block) {
        block(manager);
    }
}

@end
