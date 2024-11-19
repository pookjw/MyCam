//
//  UISceneConfiguration+CamPresentation.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <TargetConditionals.h>
#import <CamPresentation/UISceneConfiguration+CamPresentation.h>
#import <CamPresentation/CPImmersiveSceneDelegate.h>
#import <CamPresentation/Constants.h>

@implementation UISceneConfiguration (CamPresentation)

+ (UISceneConfiguration *)cp_sceneConfigurationWithOptions:(UISceneConnectionOptions *)options {
#if TARGET_OS_VISION
    for (NSUserActivity *userActivity in options.userActivities) {
        if ([userActivity.activityType isEqualToString:CPSceneActivityType]) {
            UISceneConfiguration *configuration = [UISceneConfiguration new];
            configuration.delegateClass = CPImmersiveSceneDelegate.class;
            return [configuration autorelease];
        }
    }
    
    return nil;
#else
    return nil;
#endif
}

@end
