//
//  CinematicEditViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithViewModel:(CinematicViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END

#endif
