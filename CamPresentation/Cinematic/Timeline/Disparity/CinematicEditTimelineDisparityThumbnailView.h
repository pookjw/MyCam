//
//  CinematicEditTimelineDisparityThumbnailView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDisparityThumbnailView : UICollectionReusableView
- (void)updateWithSnapshot:(CinematicSnapshot *)snapshot;
@end

NS_ASSUME_NONNULL_END

#endif
