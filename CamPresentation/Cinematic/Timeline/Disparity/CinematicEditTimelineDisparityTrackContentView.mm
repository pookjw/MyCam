//
//  CinematicEditTimelineDisparityTrackContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

#import <CamPresentation/CinematicEditTimelineDisparityTrackContentView.h>

@implementation CinematicEditTimelineDisparityTrackContentConfiguration

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [self retain];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView {
    return [[CinematicEditTimelineDisparityTrackContentView new] autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

@end

@implementation CinematicEditTimelineDisparityTrackContentView
@synthesize configuration = _configuration;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_configuration release];
    [super dealloc];
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:[CinematicEditTimelineDisparityTrackContentConfiguration class]];
}


@end
