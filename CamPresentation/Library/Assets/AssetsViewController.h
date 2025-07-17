//
//  AssetsViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class AssetsViewController;
@protocol AssetsViewControllerDelegate <NSObject>
- (void)assetsViewController:(AssetsViewController *)assetsViewController didSelectAssets:(NSArray<PHAsset *> *)selectedAssets;
@end

@interface AssetsViewController : UIViewController
@property (retain, nonatomic, nullable) PHAssetCollection *collection;
@property (assign, nonatomic, nullable) id<AssetsViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
