//
//  CinematicEditTimelinePlayheadView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelinePlayheadView.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

@implementation CinematicEditTimelinePlayheadView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.tintColor;
    }
    
    return self;
}

@end

#endif
