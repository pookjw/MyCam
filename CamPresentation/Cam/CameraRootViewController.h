//
//  CameraRootViewController.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/14/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface CameraRootViewController : UIViewController
@property (nonatomic, readonly) NSArray<UIGestureRecognizer *> *interactivePopAvoidanceGestureRecognizers;
@end

NS_ASSUME_NONNULL_END
