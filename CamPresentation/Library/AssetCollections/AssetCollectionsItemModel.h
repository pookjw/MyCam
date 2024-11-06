//
//  AssetCollectionsItemModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetCollectionsItemModel : NSObject
@property (retain, nonatomic, readonly) PHAssetCollection *collection;
@property (assign, nonatomic, readonly) CGSize targetSize;
@property (assign, nonatomic, readonly) PHImageRequestID requestID;
@property (copy, nonatomic, nullable) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount);

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCollection:(PHAssetCollection *)collection;
- (void)cancelRequest;
- (void)requestImageWithTargetSize:(CGSize)targetSize;
@end

NS_ASSUME_NONNULL_END
