//
//  CinematicSnapshot.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CinematicAssetData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicSnapshot : NSObject
@property (copy, nonatomic, readonly, direct) AVComposition *composition;
@property (copy, nonatomic, readonly, direct) AVVideoComposition *videoComposition;
@property (retain, nonatomic, readonly, direct) CNCompositionInfo *compositionInfo;
@property (retain, nonatomic, readonly, direct) CNRenderingSession *renderingSession;

@property (assign, nonatomic, readonly, getter=isSpatialAudioMixEnabled) BOOL spatialAudioMixEnabled API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
@property (assign, nonatomic, readonly) float spatialAudioMixEffectIntensity API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
@property (assign, nonatomic, readonly) CNSpatialAudioRenderingStyle spatialAudioMixRenderingStyle API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));

@property (retain, nonatomic, readonly) CinematicAssetData *assetData;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionInfo:(CNCompositionInfo *)compositionInfo renderingSession:(CNRenderingSession *)renderingSession assetData:(CinematicAssetData *)assetData;
@end

NS_ASSUME_NONNULL_END

#endif
