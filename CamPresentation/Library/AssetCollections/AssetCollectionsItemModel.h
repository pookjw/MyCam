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
@property (assign, nonatomic, readonly) PHImageRequestID requestID;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCollection:(PHAssetCollection *)collection;
- (void)cancelRequest;
- (void)requestImageWithTargetSize:(CGSize)targetSize resultHandler:(void (^ _Nullable)(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount))resultHandler;
@end

NS_ASSUME_NONNULL_END
