//
//  UISceneConfiguration+CamPresentation.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <TargetConditionals.h>
#import <CamPresentation/UISceneConfiguration+CamPresentation.h>
#import <CamPresentation/ARPlayerSceneDelegate_Vision.h>
#import <CamPresentation/Constants.h>
#import <CamPresentation/ARPlayerWindowScene_Vision.h>

@implementation UISceneConfiguration (CamPresentation)

+ (UISceneConfiguration *)cp_sceneConfigurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
#if TARGET_OS_VISION
    for (NSUserActivity *userActivity in options.userActivities) {
        if ([userActivity.activityType isEqualToString:CPSceneActivityType]) {
            if ([userActivity.userInfo[CPSceneTypeKey] isEqualToString:CPARPlayerScene]) {
                UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
                configuration.sceneClass = ARPlayerWindowScene_Vision.class;
                configuration.delegateClass = ARPlayerSceneDelegate_Vision.class;
                return [configuration autorelease];
            } else {
                abort();
            }
        }
    }
    
    return nil;
#else
    return nil;
#endif
}

@end
