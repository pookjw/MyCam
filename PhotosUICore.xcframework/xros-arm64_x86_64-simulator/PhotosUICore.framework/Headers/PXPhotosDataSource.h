#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXPhotosDataSource : NSObject
- (NSIndexPath *)indexPathForFirstAsset;
- (NSIndexPath *)indexPathForLastAsset;
@end

NS_ASSUME_NONNULL_END