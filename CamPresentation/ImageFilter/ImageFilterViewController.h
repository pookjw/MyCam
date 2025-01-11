//
//  ImageFilterViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/11/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageFilterViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (nullable instancetype)initWithFilterName:(NSString *)filterName;
@end

NS_ASSUME_NONNULL_END
