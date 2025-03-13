//
//  CinematicEditTimelineDecisionContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelineDecisionContentView.h>

@implementation CinematicEditTimelineDecisionContentConfiguration

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [self retain];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView {
    return [[CinematicEditTimelineDecisionContentView new] autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

@end

@implementation CinematicEditTimelineDecisionContentView
@synthesize configuration = _configuration;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.systemGreenColor;
    }
    
    return self;
}

- (void)dealloc {
    [_configuration release];
    [super dealloc];
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:[CinematicEditTimelineDecisionContentConfiguration class]];
}

@end
