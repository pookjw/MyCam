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
@property (class, assign, nonatomic, getter=isDeferredStartEnabled) BOOL deferredStartEnabled API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0));
@property (nonatomic, readonly) NSArray<UIGestureRecognizer *> *interactivePopAvoidanceGestureRecognizers;
@end

NS_ASSUME_NONNULL_END
