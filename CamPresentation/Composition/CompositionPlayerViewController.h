//
//  CompositionPlayerViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CompositionService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompositionPlayerViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCompositionService:(CompositionService *)compositionService;
@end

NS_ASSUME_NONNULL_END
