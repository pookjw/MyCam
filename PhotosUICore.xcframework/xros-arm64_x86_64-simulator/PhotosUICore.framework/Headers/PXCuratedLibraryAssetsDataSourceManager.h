#import <PhotosUIFoundation/PXAssetsDataSourceManager.h>
#import <PhotosUICore/PXCuratedLibraryAssetsDataSourceManagerConfiguration.h>
#import <PhotosUICore/PXCuratedLibraryAssetsDataSourceManagerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryAssetsDataSourceManager : PXAssetsDataSourceManager
@property (nonatomic) BOOL canLoadData;
@property (weak, nonatomic) id<PXCuratedLibraryAssetsDataSourceManagerDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfiguration:(PXCuratedLibraryAssetsDataSourceManagerConfiguration *)configuration;
@end

NS_ASSUME_NONNULL_END