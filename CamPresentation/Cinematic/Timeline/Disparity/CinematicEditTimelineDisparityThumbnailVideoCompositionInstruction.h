//
//  CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <CamPresentation/CinematicSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDisparityThumbnailVideoCompositionInstruction : NSObject <AVVideoCompositionInstruction>
@property (retain, nonatomic, readonly) CinematicSnapshot *snapshot;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSnapshot:(CinematicSnapshot *)snapshot;
@end

NS_ASSUME_NONNULL_END

#endif
