#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryViewConfiguration : NSObject <NSCopying>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary;
@end

NS_ASSUME_NONNULL_END