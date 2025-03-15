//
//  CinematicEditTimelineDecisionContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelineDecisionContentView.h>

@implementation CinematicEditTimelineDecisionContentConfiguration

- (instancetype)initWithItemModel:(CinematicEditTimelineItemModel *)itemModel {
    if (self = [super init]) {
        assert(itemModel != nil);
        _itemModel = [itemModel retain];
    }
    
    return self;
}

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

@interface CinematicEditTimelineDecisionContentView ()
@property (copy, nonatomic, getter=_contentConfiguration, setter=_setContentConfiguration:) CinematicEditTimelineDecisionContentConfiguration *contentConfiguration;
@property (retain, nonatomic, getter=_leftGradientLayer) CAGradientLayer *leftGradientLayer;
@property (retain, nonatomic, getter=_rightGradientLayer) CAGradientLayer *rightGradientLayer;
@end

@implementation CinematicEditTimelineDecisionContentView
@synthesize contentConfiguration = _contentConfiguration;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor.systemGreenColor colorWithAlphaComponent:0.3];
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_leftGradientLayer release];
    [_rightGradientLayer release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:[CinematicEditTimelineDecisionContentConfiguration class]];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = static_cast<CinematicEditTimelineDecisionContentConfiguration *>(configuration);
}

- (void)_setContentConfiguration:(CinematicEditTimelineDecisionContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    
}

- (CAGradientLayer *)_leftGradientLayer {
    if (auto leftGradientLayer = _leftGradientLayer) return leftGradientLayer;
    
    abort();
}

- (CAGradientLayer *)_rightGradientLayer {
    if (auto rightGradientLayer = _rightGradientLayer) return rightGradientLayer;
    
    abort();
}

@end
