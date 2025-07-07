//
//  CinematicEditTimelineCollectionViewLayoutInvalidationContext.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (assign, nonatomic) CGRect oldBounds;
@property (assign, nonatomic) CGRect newBounds;
@end

NS_ASSUME_NONNULL_END

#endif
