//
//  ARPlayerSceneDelegate.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/ARPlayerSceneDelegate.h>
#import <CamPresentation/ARPlayerWindowScene.h>
#import <CamPresentation/CamPresentation-Swift.h>

@implementation ARPlayerSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    auto windowScene = static_cast<ARPlayerWindowScene *>(scene);
    assert([windowScene isKindOfClass:[ARPlayerWindowScene class]]);
    
    __kindof UIViewController *rootViewController = CamPresentation::newRealityPlayerHostingController_Vision();
    
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    window.rootViewController = rootViewController;
    [rootViewController release];
    
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

@end

#endif
