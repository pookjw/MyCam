#import <PhotosUICore/PXAssetsDataSource.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXPhotoKitAssetsDataSource : PXAssetsDataSource
+ (PXPhotoKitAssetsDataSource *)dataSourceWithAssetCollections:(PHFetchResult<PHAssetCollection *> *)assetCollections;
+ (PXPhotoKitAssetsDataSource *)dataSourceWithAsset:(id)arg1;
+ (PXPhotoKitAssetsDataSource *)dataSourceWithAssets:(PHFetchResult<PHAsset *> *)arg1;
@end

NS_ASSUME_NONNULL_END