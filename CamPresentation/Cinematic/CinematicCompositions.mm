//
//  CinematicCompositions.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicCompositions.h>

@implementation CinematicCompositions

- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition {
    if (self = [super init]) {
        _composition = [composition copy];
        _videoComposition = [videoComposition copy];
    }
    
    return self;
}

- (void)dealloc {
    [_composition release];
    [_videoComposition release];
    [super dealloc];
}

@end
