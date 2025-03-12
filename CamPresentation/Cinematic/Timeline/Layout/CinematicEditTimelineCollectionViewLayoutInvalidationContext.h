//
//  CinematicEditTimelineCollectionViewLayoutInvalidationContext.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CinematicEditTimelineCollectionViewLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext
@property (assign, nonatomic) CGRect oldBounds;
@property (assign, nonatomic) CGRect newBounds;
@end

NS_ASSUME_NONNULL_END
