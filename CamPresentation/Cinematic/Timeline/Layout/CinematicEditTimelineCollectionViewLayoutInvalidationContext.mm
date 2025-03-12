//
//  CinematicEditTimelineCollectionViewLayoutInvalidationContext.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelineCollectionViewLayoutInvalidationContext.h>

@implementation CinematicEditTimelineCollectionViewLayoutInvalidationContext

- (instancetype)init {
    if (self = [super init]) {
        _oldBounds = CGRectNull;
        _newBounds = CGRectNull;
    }
    
    return self;
}

@end
