//
//  CinematicEditTimelineDetectionThumbnailView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <UIKit/UIKit.h>
#import <Cinematic/Cinematic.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicEditTimelineDetectionThumbnailView : UICollectionReusableView
- (void)updateWithScript:(CNScript *)script asset:(AVAsset *)asset;
@end

NS_ASSUME_NONNULL_END
