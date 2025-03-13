//
//  CinematicEditTimelineSectionModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CoreMedia/CoreMedia.h>
#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CinematicEditTimelineSectionModelType) {
    CinematicEditTimelineSectionModelTypeVideoTrack,
    CinematicEditTimelineSectionModelTypeDisparityTrack,
    CinematicEditTimelineSectionModelTypeDetectionTrack,
};

@interface CinematicEditTimelineSectionModel : NSObject
@property (assign, nonatomic, readonly) CinematicEditTimelineSectionModelType type;

/* VideoTrack & Disparity & DetectionTrack */
@property (assign, nonatomic, readonly) CMPersistentTrackID trackID;

/* DetectionTrack */
@property (assign, nonatomic, readonly) CNDetectionID detectionTrackID;

/* VideoTrack & Disparity & DetectionTrack */
@property (assign, nonatomic, readonly) CMTimeRange timeRange;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (CinematicEditTimelineSectionModel *)videoTrackSectionModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange;
+ (CinematicEditTimelineSectionModel *)disparityTrackSectionModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange;
+ (CinematicEditTimelineSectionModel *)detectionTrackSectionModelWithDetectionTrackID:(CNDetectionID)detectionTrackID trackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange;
@end

NS_ASSUME_NONNULL_END
