//
//  CinematicEditTimelineDetectionsThumbnailView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CinematicSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDetectionsThumbnailView : UICollectionReusableView
- (void)updateWithSnapshot:(CinematicSnapshot *)snapshot;
@end

NS_ASSUME_NONNULL_END
