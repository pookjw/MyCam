//
//  CinematicEditTimelineDetectionsContentView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineDetectionsContentConfiguration : NSObject <UIContentConfiguration>

@end

@interface CinematicEditTimelineDetectionsContentView : UIView <UIContentView>

@end

NS_ASSUME_NONNULL_END

#endif
