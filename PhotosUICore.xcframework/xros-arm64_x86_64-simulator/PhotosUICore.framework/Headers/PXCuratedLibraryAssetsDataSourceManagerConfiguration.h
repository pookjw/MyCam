#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryAssetsDataSourceManagerConfiguration : NSObject
+ (PXCuratedLibraryAssetsDataSourceManagerConfiguration *)configurationWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary enableDays:(BOOL)enableDays;
- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary;
@end

NS_ASSUME_NONNULL_END