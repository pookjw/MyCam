//
//  PHImageManager+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHImageManager (Category)
- (NSProgress *)cp_requestAVAssetForAssets:(NSArray<PHAsset *> *)assets optionsByAsset:(NSDictionary<PHAsset *, PHVideoRequestOptions *> * _Nullable)optionsByAsset resultHandler:(BOOL (^)(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info, BOOL isLast)) resultHandler;
- (NSProgress *)cp_requestAVAssetForAssets:(NSArray<PHAsset *> *)assets options:(PHVideoRequestOptions * _Nullable)options resultHandler:(BOOL (^)(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info, BOOL isLast)) resultHandler;
@end

NS_ASSUME_NONNULL_END
