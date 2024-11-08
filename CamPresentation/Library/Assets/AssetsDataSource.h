//
//  AssetsDataSource.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetsDataSource : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView cellRegistration:(UICollectionViewCellRegistration *)cellRegistration requestMaximumSize:(BOOL)requestMaximumSize;
- (void)updateCollection:(PHAssetCollection * _Nullable)collection completionHandler:(void (^ _Nullable)(void))completionHandler;
- (PHAsset * _Nullable)assetAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath * _Nullable)indexPathFromAsset:(PHAsset *)asset;
@end

NS_ASSUME_NONNULL_END
