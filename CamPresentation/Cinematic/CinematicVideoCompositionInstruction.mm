//
//  CinematicVideoCompositionInstruction.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicVideoCompositionInstruction.h>

@implementation CinematicVideoCompositionInstruction

- (instancetype)initWithRenderingSession:(CNRenderingSession *)renderingSession compositionInfo:(CNCompositionInfo *)compositionInfo script:(CNScript *)script fNumber:(float)fNumber editMode:(BOOL)editMode {
    if (self = [super init]) {
        _renderingSession = [renderingSession retain];
        _compositionInfo = [compositionInfo retain];
        _script = [script retain];
        _fNumber = fNumber;
        _editMode = editMode;
    }
    
    return self;
}

- (void)dealloc {
    [_renderingSession release];
    [_compositionInfo release];
    [_script release];
    [super dealloc];
}

- (CMTimeRange)timeRange {
    return _compositionInfo.timeRange;
}

- (BOOL)enablePostProcessing {
    return NO;
}

- (BOOL)containsTweening {
    // 두 키프레임 사이에 중간 프레임을 만들어 부드러운 전환을 만드는 기법
    return YES;
}

- (NSArray<NSValue *> *)requiredSourceTrackIDs {
    return _compositionInfo.videoCompositionTrackIDs;
}

- (CMPersistentTrackID)passthroughTrackID {
    return kCMPersistentTrackID_Invalid;
}

- (NSArray<NSNumber *> *)requiredSourceSampleDataTrackIDs {
    return _compositionInfo.sampleDataTrackIDs;
}

@end
