//
//  CinematicEditTimelineDisparityTrackContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDisparityTrackContentConfiguration : NSObject <UIContentConfiguration>

@end

@interface CinematicEditTimelineDisparityTrackContentView : UIView <UIContentView>

@end

NS_ASSUME_NONNULL_END

#endif
