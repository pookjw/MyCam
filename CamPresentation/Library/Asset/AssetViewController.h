//
//  AssetViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class AssetViewController;
@protocol AssetViewControllerDelegate <NSObject>
- (void)assetViewController:(AssetViewController *)assetViewController didSelectAsset:(PHAsset *)selectedAsset;
@end

@interface AssetViewController : UIViewController
@property (assign, nonatomic, nullable) id<AssetViewControllerDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCollection:(PHAssetCollection *)collection asset:(PHAsset *)asset;
@end

NS_ASSUME_NONNULL_END
