//
//  CinematicAssetData.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <Cinematic/Cinematic.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * CinematicAssetDataErrorKey;

@interface CinematicAssetData : NSObject
@property (retain, nonatomic, readonly) AVAsset *avAsset;
@property (retain, nonatomic, readonly) CNAssetInfo *cnAssetInfo;
@property (retain, nonatomic, readonly) CNScript *cnScript;
@property (retain, nonatomic, readonly) CNRenderingSessionAttributes *renderingSessionAttributes;
@property (assign, nonatomic, readonly) float nominalFrameRate;
@property (assign, nonatomic, readonly) CMTimeScale naturalTimeScale;
+ (NSProgress *)loadDataFromPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(CinematicAssetData * _Nullable data, NSError * _Nullable error))completionHandler;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAVAsset:(AVAsset *)avAsset cnAssetInfo:(CNAssetInfo *)cnAssetInfo cnScript:(CNScript *)cnScript renderingSessionAttributes:(CNRenderingSessionAttributes *)renderingSessionAttributes nominalFrameRate:(float)nominalFrameRate naturalTimeScale:(CMTimeScale)naturalTimeScale;
@end

NS_ASSUME_NONNULL_END
