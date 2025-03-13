//
//  CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDetectionThumbnailVideoCompositioninstruction : NSObject <AVVideoCompositionInstruction>
@property (retain, nonatomic, readonly) CinematicSnapshot *snapshot;
@property (copy, nonatomic, readonly) CNDetection *detection;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSnapshot:(CinematicSnapshot *)snapshot detection:(CNDetection *)detection;
@end

NS_ASSUME_NONNULL_END
