//
//  CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h>

@implementation CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction

- (instancetype)initWithSnapshot:(CinematicSnapshot *)snapshot {
    if (self = [super init]) {
        _snapshot = [snapshot retain];
    }
    
    return self;
}

- (void)dealloc {
    [_snapshot release];
    [super dealloc];
}

- (CMTimeRange)timeRange {
    return _snapshot.compositionInfo.timeRange;
}

- (BOOL)enablePostProcessing {
    return NO;
}

- (BOOL)containsTweening {
    // 두 키프레임 사이에 중간 프레임을 만들어 부드러운 전환을 만드는 기법
    return NO;
}

- (NSArray<NSValue *> *)requiredSourceTrackIDs {
    return _snapshot.compositionInfo.videoCompositionTrackIDs;
//    return @[@(_snapshot.compositionInfo.cinematicDisparityTrack.trackID)];
}

- (CMPersistentTrackID)passthroughTrackID {
    return kCMPersistentTrackID_Invalid;
}

- (NSArray<NSNumber *> *)requiredSourceSampleDataTrackIDs {
    return @[];
}

@end
