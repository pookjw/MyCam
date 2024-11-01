//
//  AssetItemModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/*
 - Request 도중 Cell이 떠야 핳 떄
 - Request 할 때의 targetSize와 Cell이 뜰 때의 targetSize가 다를 떄
 - Request 도중 targetSize가 바뀔 때 (일괄 취소?)
 - Degraded Image가 나오고 Full Image를 요청하는 중에 Cell이 떠야 할 떄
 */

@interface AssetItemModel : NSObject
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (assign, nonatomic, readonly, getter=isPrefetchingModel) BOOL prefetchingModel;
@property (assign, nonatomic, readonly) CGSize targetSize;
@property (assign, nonatomic, readonly) PHImageRequestID requestID;
@property (copy, nonatomic, nullable) void (^resultHandler)(UIImage *result, NSDictionary *info);

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)modelWithAsset:(PHAsset *)asset;
+ (instancetype)prefetchingModelWithWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
- (void)cancelRequest;
- (void)requestImageWithTargetSize:(CGSize)targetSize;
@end

NS_ASSUME_NONNULL_END
