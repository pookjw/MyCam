//
//  CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.h>

@implementation CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction

- (instancetype)initWithSnapshot:(CinematicSnapshot *)snapshot detection:(CNDetection *)detection {
    if (self = [super init]) {
        _snapshot = [snapshot retain];
        _detection = [detection copy];
    }
    
    return self;
}

- (void)dealloc {
    [_snapshot release];
    [_detection release];
    [super dealloc];
}

- (CMTimeRange)timeRange {
    return _snapshot.compositionInfo.timeRange;
    
    // 1프레임 Duration을 넣어줘야 할 수도 있음. Seek시 tolerance도 고려해야함
//    return CMTimeRangeMake(_detection.time, kCMTimeZero);
}

- (BOOL)enablePostProcessing {
    return NO;
}

- (BOOL)containsTweening {
    // 두 키프레임 사이에 중간 프레임을 만들어 부드러운 전환을 만드는 기법
    return YES;
}

- (NSArray<NSValue *> *)requiredSourceTrackIDs {
    return _snapshot.compositionInfo.videoCompositionTrackIDs;
}

- (CMPersistentTrackID)passthroughTrackID {
    return kCMPersistentTrackID_Invalid;
}

- (NSArray<NSNumber *> *)requiredSourceSampleDataTrackIDs {
    return _snapshot.compositionInfo.sampleDataTrackIDs;
}

@end
