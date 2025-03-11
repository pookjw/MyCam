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
//    CinematicEditTimelineSectionModelTypeDisparityTrack,
    CinematicEditTimelineSectionModelTypeDetectionTrack,
};

@interface CinematicEditTimelineSectionModel : NSObject
@property (assign, nonatomic, readonly) CinematicEditTimelineSectionModelType type;

/* VideoTrack */
@property (assign, nonatomic, readonly) CMPersistentTrackID trackID;

/* DetectionTrack */
@property (copy, nonatomic, readonly, nullable) CNDetectionTrack *detectionTrack;

/* VideoTrack & DetectionTrack */
@property (assign, nonatomic, readonly) CMTimeRange timeRange;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (CinematicEditTimelineSectionModel *)videoTrackSectionModelWithTrackID:(CMPersistentTrackID)trackID timeRange:(CMTimeRange)timeRange;
+ (CinematicEditTimelineSectionModel *)detectionTrackSectionModelWithDetectionTrack:(CNDetectionTrack *)detectionTrack timeRange:(CMTimeRange)timeRange;
@end

NS_ASSUME_NONNULL_END
