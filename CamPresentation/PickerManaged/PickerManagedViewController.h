//
//  PickerManagedViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 2/14/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PickerManagedViewController : UIViewController

@end

NS_ASSUME_NONNULL_END

#endif
