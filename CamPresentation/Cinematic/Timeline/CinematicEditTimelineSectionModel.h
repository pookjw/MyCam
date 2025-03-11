//
//  CinematicEditTimelineSectionModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CinematicEditTimelineSectionModelType) {
    CinematicEditTimelineSectionModelTypeVideoTrack,
//    CinematicEditTimelineSectionModelTypeDisparityTrack,
    CinematicEditTimelineSectionModelTypeDetectionTracks,
    CinematicEditTimelineSectionModelTypeDecisions
};

@interface CinematicEditTimelineSectionModel : NSObject
@property (assign, nonatomic, readonly) CinematicEditTimelineSectionModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(CinematicEditTimelineSectionModelType)type;
@end

NS_ASSUME_NONNULL_END
