//
//  VisionKitDemoViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/8/25.
//

#import <TargetConditionals.h>

/*
 #if TARGET_OS_TV
         TVSlider *slider = [TVSlider new];
 #else
         UISlider *slider = [UISlider new];
 #endif
 
 #if TARGET_OS_TV
             auto slider = static_cast<TVSlider *>(action.sender);
 #else
             auto slider = static_cast<UISlider *>(action.sender);
 #endif
 
 #if TARGET_OS_TV
         [slider addAction:action];
 #else
         [slider addAction:action forControlEvents:UIControlEventValueChanged];
 #endif
 
 BOOL isTracking;
#if TARGET_OS_TV
 isTracking = NO;
#else
 isTracking = slider.isTracking;
#endif
 
 if (!isTracking) {
 
 
 
 #if TARGET_OS_TV
         TVStepper *stepper = [TVStepper new];
 #else
         UIStepper *stepper = [UIStepper new];
 #endif
 
 #if TARGET_OS_TV
             auto stepper = static_cast<TVStepper *>(action.sender);
 #else
             auto stepper = static_cast<UIStepper *>(action.sender);
 #endif
 
 #if TARGET_OS_TV
         [stepper addAction:action];
 #else
         [stepper addAction:action forControlEvents:UIControlEventValueChanged];
 #endif
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VisionKitDemoViewController : UICollectionViewController

@end

NS_ASSUME_NONNULL_END

#endif
