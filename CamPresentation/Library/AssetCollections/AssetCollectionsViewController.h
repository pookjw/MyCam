//
//  AssetCollectionsViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/31/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class AssetCollectionsViewController;
@protocol AssetCollectionsViewControllerDelegate <NSObject>
- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets;
@end

@interface AssetCollectionsViewController : UIViewController
@property (assign, nonatomic, nullable) id<AssetCollectionsViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
