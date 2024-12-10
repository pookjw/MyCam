//
//  CPImmersiveSceneDelegate.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/19/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/CPImmersiveSceneDelegate.h>

@implementation CPImmersiveSceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    abort();
}

@end

#endif
