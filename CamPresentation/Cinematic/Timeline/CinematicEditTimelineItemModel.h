//
//  CinematicEditTimelineItemModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CoreMedia/CoreMedia.h>
#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CinematicEditTimelineItemModelType) {
    CinematicEditTimelineItemModelTypeVideoTrack,
    CinematicEditTimelineItemModelTypeDisparityTrack,
    CinematicEditTimelineItemModelTypeDetections,
    CinematicEditTimelineItemModelTypeDecision
};

@interface CinematicEditTimelineItemModel : NSObject
@property (assign, nonatomic, readonly) CinematicEditTimelineItemModelType type;

/* Detections */
@property (copy, nonatomic, readonly, nullable) NSArray<CNDetection *> *detections;

/* Decision */
@property (copy, nonatomic, readonly, nullable) CNDecision *decision;
@property (assign, nonatomic, readonly) CMTimeRange startTransitionTimeRange;
@property (assign, nonatomic, readonly) CMTimeRange endTransitionTimeRange;

/* Detections & Decision */
@property (assign, nonatomic, readonly) CMTimeRange timeRange;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (CinematicEditTimelineItemModel *)videoTrackItemModel;
+ (CinematicEditTimelineItemModel *)disparityTrackItemModel;
+ (CinematicEditTimelineItemModel *)detectionsItemModelWithDetections:(NSArray<CNDetection *> *)detections timeRange:(CMTimeRange)timeRange;
+ (CinematicEditTimelineItemModel *)decisionItemModelWithDecision:(CNDecision *)decision startTransitionTimeRange:(CMTimeRange)startTransitionTimeRange endTransitionTimeRange:(CMTimeRange)endTransitionTimeRange;
@end

NS_ASSUME_NONNULL_END

#endif
