//
//  CinematicSnapshot+Private.h
//  MyCam
//
//  Created by Jinwoo Kim on 7/12/25.
//

#import <CamPresentation/CinematicSnapshot.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

@interface CinematicSnapshot (Private)
@property (assign, nonatomic, getter=isSpatialAudioMixEnabled) BOOL spatialAudioMixEnabled API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
@property (assign, nonatomic) float spatialAudioMixEffectIntensity API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
@property (assign, nonatomic) CNSpatialAudioRenderingStyle spatialAudioMixRenderingStyle API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
@end

NS_ASSUME_NONNULL_END

#endif
