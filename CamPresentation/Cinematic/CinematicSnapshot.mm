//
//  CinematicSnapshot.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicSnapshot.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

@implementation CinematicSnapshot

- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionInfo:(CNCompositionInfo *)compositionInfo renderingSession:(CNRenderingSession *)renderingSession assetData:(CinematicAssetData *)assetData {
    if (self = [super init]) {
        _composition = [composition copy];
        _videoComposition = [videoComposition copy];
        _compositionInfo = [compositionInfo retain];
        _renderingSession = [renderingSession retain];
        _assetData = [assetData retain];
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

@end

#endif
