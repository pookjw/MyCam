//
//  CinematicEditTimelineVideoTrackContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicEditTimelineVideoTrackContentView.h>

@implementation CinematicEditTimelineVideoTrackContentConfiguration

- (nonnull id)copyWithZone:(nullable NSZone *)zone { 
    return [self retain];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView { 
    return [[CinematicEditTimelineVideoTrackContentView new] autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state { 
    return self;
}

@end

@implementation CinematicEditTimelineVideoTrackContentView
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
    return [configuration isKindOfClass:[CinematicEditTimelineVideoTrackContentConfiguration class]];
}

@end
