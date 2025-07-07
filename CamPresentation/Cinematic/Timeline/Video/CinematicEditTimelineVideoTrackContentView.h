//
//  CinematicEditTimelineVideoTrackContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineVideoTrackContentConfiguration : NSObject <UIContentConfiguration>

@end

@interface CinematicEditTimelineVideoTrackContentView : UIView <UIContentView>

@end

NS_ASSUME_NONNULL_END

#endif
