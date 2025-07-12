//
//  CinematicSnapshot.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicSnapshot.h>
#import <CamPresentation/CinematicSnapshot+Private.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

@interface CinematicSnapshot () {
    BOOL _spatialAudioMixEnabled API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
    float _spatialAudioMixEffectIntensity API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
    CNSpatialAudioRenderingStyle _spatialAudioMixRenderingStyle API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
}
@end

@implementation CinematicSnapshot

- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionInfo:(CNCompositionInfo *)compositionInfo renderingSession:(CNRenderingSession *)renderingSession assetData:(CinematicAssetData *)assetData {
    if (self = [super init]) {
        _composition = [composition copy];
        _videoComposition = [videoComposition copy];
        _compositionInfo = [compositionInfo retain];
        _renderingSession = [renderingSession retain];
        _assetData = [assetData retain];
        _spatialAudioMixEnabled = NO;
    }
    
    return self;
}

- (void)dealloc {
    [_composition release];
    [_videoComposition release];
    [_compositionInfo release];
    [_renderingSession release];
    [_assetData release];
    [super dealloc];
}

- (BOOL)isSpatialAudioMixEnabled {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    return _spatialAudioMixEnabled;
}

- (void)setSpatialAudioMixEnabled:(BOOL)spatialAudioMixEnabled {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    _spatialAudioMixEnabled = spatialAudioMixEnabled;
}

- (float)spatialAudioMixEffectIntensity {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    return _spatialAudioMixEffectIntensity;
}

- (void)setSpatialAudioMixEffectIntensity:(float)spatialAudioMixEffectIntensity {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    _spatialAudioMixEffectIntensity = spatialAudioMixEffectIntensity;
}

- (CNSpatialAudioRenderingStyle)spatialAudioMixRenderingStyle {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    return _spatialAudioMixRenderingStyle;
}

- (void)setSpatialAudioMixRenderingStyle:(CNSpatialAudioRenderingStyle)spatialAudioMixRenderingStyle {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    _spatialAudioMixRenderingStyle = spatialAudioMixRenderingStyle;
}

@end

#endif
