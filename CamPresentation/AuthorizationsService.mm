//
//  AuthorizationsService.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <CamPresentation/AuthorizationsService.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface AuthorizationsService () <CLLocationManagerDelegate>
#if !TARGET_OS_VISION
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@property (class, nonatomic, readonly) void *didChangeAuthorizationKey;
#endif
@end

@implementation AuthorizationsService
#if !TARGET_OS_VISION
@synthesize locationManager = _locationManager;
#endif

#if !TARGET_OS_VISION
+ (void *)didChangeAuthorizationKey {
    static void *key = &key;
    return key;
}
#endif

- (void)dealloc {
#if !TARGET_OS_VISION
    [_locationManager release];
#endif
    [super dealloc];
}

- (void)requestAuthorizationsWithCompletionHandler:(void (^)(BOOL authorized))completionHandler {
#if !TARGET_OS_VISION
    void (^requestLocationAuthorization)() = ^{
        CLLocationManager *locationManager = self.locationManager;
        CLAuthorizationStatus authorizationStatus = locationManager.authorizationStatus;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (authorizationStatus) {
                case kCLAuthorizationStatusNotDetermined:
                    locationManager.delegate = self;
                    
                    // https://x.com/_silgen_name/status/1845680145451065794
                    objc_setAssociatedObject(locationManager,
                                             AuthorizationsService.didChangeAuthorizationKey,
                                             ^(CLLocationManager *locationManager) {
                        switch (locationManager.authorizationStatus) {
                            case kCLAuthorizationStatusAuthorizedAlways:
                            case kCLAuthorizationStatusAuthorizedWhenInUse:
                                objc_setAssociatedObject(locationManager, AuthorizationsService.didChangeAuthorizationKey, nil, OBJC_ASSOCIATION_ASSIGN);
                                completionHandler(YES);
                                break;
                            case kCLAuthorizationStatusNotDetermined:
                                break;
                            default:
                                objc_setAssociatedObject(locationManager, AuthorizationsService.didChangeAuthorizationKey, nil, OBJC_ASSOCIATION_ASSIGN);
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
    
#if !TARGET_OS_TV
    void (^requestMicrophoneInjectionPermission)() = ^{
        AVAudioApplicationMicrophoneInjectionPermission permission = AVAudioApplication.sharedInstance.microphoneInjectionPermission;
        
        switch (permission) {
            case AVAudioApplicationMicrophoneInjectionPermissionDenied:
                completionHandler(NO);
                break;
            case AVAudioApplicationMicrophoneInjectionPermissionGranted:
#if TARGET_OS_VISION
                completionHandler(YES);
#else
                requestLocationAuthorization();
#endif
                break;
            case AVAudioApplicationMicrophoneInjectionPermissionServiceDisabled:
#if TARGET_OS_VISION
                completionHandler(YES);
#else
                requestLocationAuthorization();
#endif
                break;
            case AVAudioApplicationMicrophoneInjectionPermissionUndetermined:
                [AVAudioApplication requestMicrophoneInjectionPermissionWithCompletionHandler:^(AVAudioApplicationMicrophoneInjectionPermission permission) {
                    switch (permission) {
                        case AVAudioApplicationMicrophoneInjectionPermissionDenied:
                            completionHandler(NO);
                            break;
                        case AVAudioApplicationMicrophoneInjectionPermissionGranted:
#if TARGET_OS_VISION
                            completionHandler(YES);
#else
                            requestLocationAuthorization();
#endif
                            break;
                        case AVAudioApplicationMicrophoneInjectionPermissionServiceDisabled:
#if TARGET_OS_VISION
                            completionHandler(YES);
#else
                            requestLocationAuthorization();
#endif
                            break;
                        case AVAudioApplicationMicrophoneInjectionPermissionUndetermined:
                            abort();
                        default:
                            break;
                    }
                }];
            default:
                abort();
        }
    };
#endif
    
    void (^requestRecordPermission)() = ^{
#if TARGET_OS_SIMULATOR
        
#if TARGET_OS_TV
                        requestLocationAuthorization();
#else
                        requestMicrophoneInjectionPermission();
#endif
        
#else
        AVAudioApplicationRecordPermission recordPermission = AVAudioApplication.sharedInstance.recordPermission;
        
        switch (recordPermission) {
            case AVAudioApplicationRecordPermissionUndetermined:
                [AVAudioApplication requestRecordPermissionWithCompletionHandler:^(BOOL granted) {
#if TARGET_OS_VISION
                    requestMicrophoneInjectionPermission();
#else
                    if (granted) {
#if TARGET_OS_TV
                        requestLocationAuthorization();
#else
                        requestMicrophoneInjectionPermission();
#endif
                    } else {
                        completionHandler(NO);
                    }
#endif
                }];
                break;
            case AVAudioApplicationRecordPermissionGranted:
#if TARGET_OS_TV
                requestLocationAuthorization();
#else
                requestMicrophoneInjectionPermission();
#endif
                break;
            case AVAudioApplicationRecordPermissionDenied:
                completionHandler(NO);
                break;
        }
#endif
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

#if !TARGET_OS_VISION
- (CLLocationManager *)locationManager {
    if (auto locationManager = _locationManager) return locationManager;
    
    CLLocationManager *locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    
    _locationManager = [locationManager retain];
    return [locationManager autorelease];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    auto block = (void (^ _Nullable)(id))(objc_getAssociatedObject(manager, AuthorizationsService.didChangeAuthorizationKey));
    
    if (block) {
        block(manager);
    }
}
#endif

@end
