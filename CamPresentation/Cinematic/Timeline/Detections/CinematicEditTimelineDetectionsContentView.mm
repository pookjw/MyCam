//
//  CinematicEditTimelineDetectionsContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelineDetectionsContentView.h>

@implementation CinematicEditTimelineDetectionsContentConfiguration

- (nonnull id)copyWithZone:(nullable NSZone *)zone { 
    return [self retain];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView { 
    return [[CinematicEditTimelineDetectionsContentView new] autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state { 
    return self;
}

@end

@implementation CinematicEditTimelineDetectionsContentView
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
    return [configuration isKindOfClass:[CinematicEditTimelineDetectionsContentConfiguration class]];
}

@end
