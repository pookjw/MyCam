//
//  AppDelegate.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import "AppDelegate.h"
#import "SceneDelegate.h"
#import <CamPresentation/CamPresentation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL *scCacheURL = [[NSFileManager.defaultManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:@"Saved Application State" isDirectory:YES];
    [NSFileManager.defaultManager removeItemAtURL:scCacheURL error:NULL];
    
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    if (UISceneConfiguration *cp_sceneConfiguration = [UISceneConfiguration cp_sceneConfigurationForConnectingSceneSession:connectingSceneSession options:options]) {
        return cp_sceneConfiguration;
    }
    
    UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
    configuration.delegateClass = SceneDelegate.class;
    return [configuration autorelease];
}


@end
