//
//  CinematicEditTimelineVideoThumbnailView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineVideoThumbnailView : UICollectionReusableView
@property (retain, nonatomic, nullable) AVAsset *asset;
@end

NS_ASSUME_NONNULL_END

#endif
