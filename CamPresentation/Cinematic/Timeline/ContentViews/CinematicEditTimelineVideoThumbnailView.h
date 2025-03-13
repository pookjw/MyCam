//
//  CinematicEditTimelineVideoThumbnailView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineVideoThumbnailView : UICollectionReusableView
@property (retain, nonatomic, nullable) AVAsset *asset;
@end

NS_ASSUME_NONNULL_END
