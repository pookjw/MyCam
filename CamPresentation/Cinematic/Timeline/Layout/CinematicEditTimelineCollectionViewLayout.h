//
//  CinematicEditTimelineCollectionViewLayout.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * const CinematicEditTimelineCollectionViewLayoutVideoThumbnailSupplementaryElementKind;
CP_EXTERN NSString * const CinematicEditTimelineCollectionViewLayoutDetectionThumbnailSupplementaryElementKind;

__attribute__((objc_direct_members))
@interface CinematicEditTimelineCollectionViewLayout : UICollectionViewLayout
@property (assign, nonatomic) CGFloat pixelsForSecond;
- (CMTime)timeFromContentOffset:(CGPoint)contentOffset;
- (CGPoint)contentOffsetFromTime:(CMTime)time;
@end

NS_ASSUME_NONNULL_END
