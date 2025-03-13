//
//  CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction : NSObject <AVVideoCompositionInstruction>
@property (retain, nonatomic, readonly) CinematicSnapshot *snapshot;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSnapshot:(CinematicSnapshot *)snapshot;
@end

NS_ASSUME_NONNULL_END
