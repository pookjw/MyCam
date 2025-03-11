//
//  CinematicEditTimelineItemModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CinematicEditTimelineItemModelType) {
    CinematicEditTimelineItemModelTypeVideoTrack,
    CinematicEditTimelineItemModelTypeDetectionTrack,
    CinematicEditTimelineItemModelTypeDecision
};

@interface CinematicEditTimelineItemModel : NSObject
@property (assign, nonatomic, readonly) CinematicEditTimelineItemModelType type;

/* CinematicEditTimelineItemModelTypeVideoTrack */
@property (assign, nonatomic, readonly) CMPersistentTrackID trackID;
@property (assign, nonatomic, readonly) CMTimeRange trackTimeRange;

/* CinematicEditTimelineItemModelTypeDetectionTrack */
@property (copy, nonatomic, readonly, nullable) __kindof CNDetectionTrack *detectionTrack;

/* CinematicEditTimelineItemModelTypeDecision */
@property (copy, nonatomic, readonly, nullable) CNDecision *decision;
@property (assign, nonatomic, readonly) CMTimeRange decisionTimeRange;
@property (assign, nonatomic, readonly) CMTimeRange startTransitionTimeRange;
@property (assign, nonatomic, readonly) CMTimeRange endTransitionTimeRange;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (CinematicEditTimelineItemModel *)videoTrackItemModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange;
+ (CinematicEditTimelineItemModel *)detectionTrackItemModelWithDetectionTrack:(CNDetectionTrack *)detectionTrack;
+ (CinematicEditTimelineItemModel *)decisionItemModelWithDecision:(CNDecision *)decision timeRange:(CMTimeRange)timeRange startTransitionTimeRange:(CMTimeRange)startTransitionTimeRange endTransitionTimeRange:(CMTimeRange)endTransitionTimeRange;
@end

NS_ASSUME_NONNULL_END
