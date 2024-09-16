//
//  CameraRootViewController.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraRootViewController : UIViewController
@property (nonatomic, readonly, nullable) NSUserActivity *stateRestorationActivity;
- (void)restoreStateWithUserActivity:(NSUserActivity *)userActivity;
@end

NS_ASSUME_NONNULL_END
