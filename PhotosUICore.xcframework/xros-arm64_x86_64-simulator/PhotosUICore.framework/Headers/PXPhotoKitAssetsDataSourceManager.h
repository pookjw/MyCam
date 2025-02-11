#import <PhotosUIFoundation/PXAssetsDataSourceManager.h>
#import <PhotosUICore/PXPhotoKitAssetsDataSource.h>
#import <PhotosUICore/PXCuratedLibraryZoomLevelDataConfiguration.h>
#import <PhotosUICore/PXPhotosDataSource.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXPhotoKitAssetsDataSourceManager : PXAssetsDataSourceManager
@property (retain, nonatomic) PXPhotosDataSource *photosDataSource;
@property (readonly, nonatomic, nullable) PXPhotosDataSource *photosDataSourceIfExists;
@property (readonly, nonatomic) PXPhotoKitAssetsDataSource *dataSource;
@property (readonly, nonatomic) PHPhotoLibrary *photoLibrary;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (PXPhotoKitAssetsDataSourceManager *)dataSourceManagerForAssetCollection:(PHAssetCollection *)assetCollection;
- (instancetype)initWithPhotosDataSource:(PXPhotoKitAssetsDataSource *)photosDataSource;
- (instancetype)initWithPhotosDataSourceProvider:(PXCuratedLibraryZoomLevelDataConfiguration *)configuration;
@end

NS_ASSUME_NONNULL_END