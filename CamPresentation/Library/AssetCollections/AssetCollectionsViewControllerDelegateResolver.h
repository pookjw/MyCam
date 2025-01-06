//
//  AssetCollectionsViewControllerDelegateResolver.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/AssetCollectionsViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionsViewControllerDelegateResolver : NSObject <AssetCollectionsViewControllerDelegate>
@property (copy, nonatomic, nullable) void (^didSelectAssetsHandler)(AssetCollectionsViewController *assetCollectionsViewController, NSSet<PHAsset *> *selectedAssets);
@end

NS_ASSUME_NONNULL_END
