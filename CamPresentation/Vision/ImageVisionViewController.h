//
//  ImageVisionViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionViewController : UIViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithAsset:(PHAsset *)asset;
@end

NS_ASSUME_NONNULL_END
