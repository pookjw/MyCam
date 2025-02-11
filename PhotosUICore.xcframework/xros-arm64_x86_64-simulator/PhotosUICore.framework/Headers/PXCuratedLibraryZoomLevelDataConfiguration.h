#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryZoomLevelDataConfiguration : NSObject
@property (retain, nonatomic) PHPhotoLibrary *photoLibrary;
@property (nonatomic) BOOL enableDays;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithZoomLevel:(NSInteger)zoomLevel;
@end

NS_ASSUME_NONNULL_END