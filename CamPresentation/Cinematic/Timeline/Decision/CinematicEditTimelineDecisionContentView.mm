//
//  CinematicEditTimelineDecisionContentView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/12/25.
//

#import <CamPresentation/CinematicEditTimelineDecisionContentView.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

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
    CinematicEditTimelineDecisionContentView *contentView = [CinematicEditTimelineDecisionContentView new];
    contentView.configuration = self;
    return [contentView autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

@end

@interface CinematicEditTimelineDecisionContentView ()
@property (copy, nonatomic, getter=_contentConfiguration, setter=_setContentConfiguration:) CinematicEditTimelineDecisionContentConfiguration *contentConfiguration;
@property (retain, nonatomic, getter=_leftGradientLayer) CAGradientLayer *leftGradientLayer;
@property (retain, nonatomic, getter=_centerLayer) CALayer *centerLayer;
@property (retain, nonatomic, getter=_rightGradientLayer) CAGradientLayer *rightGradientLayer;
@end

@implementation CinematicEditTimelineDecisionContentView
@synthesize contentConfiguration = _contentConfiguration;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CALayer *layer = self.layer;
        CAGradientLayer *leftGradientLayer = self.leftGradientLayer;
        CALayer *centerLayer = self.centerLayer;
        CAGradientLayer *rightGradientLayer = self.rightGradientLayer;
        
        [layer addSublayer:leftGradientLayer];
        [layer addSublayer:centerLayer];
        [layer addSublayer:rightGradientLayer];
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_leftGradientLayer release];
    [_centerLayer release];
    [_rightGradientLayer release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CAGradientLayer *leftGradientLayer = self.leftGradientLayer;
    CALayer *centerLayer = self.centerLayer;
    CAGradientLayer *rightGradientLayer = self.rightGradientLayer;
    
    [self.traitCollection performAsCurrentTraitCollection:^{
        CGColorRef clearColor = UIColor.clearColor.CGColor;
        CGColorRef pinkColor = UIColor.systemPinkColor.CGColor;
        NSArray<id> *colors = @[(id)clearColor, (id)pinkColor];
        
        leftGradientLayer.colors = colors;
        centerLayer.backgroundColor = pinkColor;
        rightGradientLayer.colors = colors;
    }];
    
    CinematicEditTimelineItemModel *itemModel = self.contentConfiguration.itemModel;
    CMTimeRange timeRange = itemModel.timeRange;
    CMTimeRange startTransitionTimeRange = itemModel.startTransitionTimeRange;
    CMTimeRange endTransitionTimeRange = itemModel.endTransitionTimeRange;
    
    CMTime duration = timeRange.duration;
    CMTime convertedStartDuration = CMTimeConvertScale(startTransitionTimeRange.duration, duration.timescale, kCMTimeRoundingMethod_Default);
    CMTime convertedEndDuration = CMTimeConvertScale(endTransitionTimeRange.duration, duration.timescale, kCMTimeRoundingMethod_Default);
    
    CGRect bounds = self.layer.bounds;
    
    CGFloat leftGradientLayerWidth = bounds.size.width * static_cast<CGFloat>(convertedStartDuration.value) / static_cast<CGFloat>(duration.value);
    CGFloat rightGradientLayerWidth = bounds.size.width * static_cast<CGFloat>(convertedEndDuration.value) / static_cast<CGFloat>(duration.value);
    CGFloat centerLayerWidth = bounds.size.width - leftGradientLayerWidth - rightGradientLayerWidth;
    
    leftGradientLayer.frame = CGRectMake(bounds.origin.x,
                                         bounds.origin.y,
                                         leftGradientLayerWidth,
                                         bounds.size.height);
    
    centerLayer.frame = CGRectMake(bounds.origin.x + leftGradientLayerWidth,
                                   bounds.origin.y,
                                   centerLayerWidth,
                                   bounds.size.height);
    
    rightGradientLayer.frame = CGRectMake(bounds.origin.x + leftGradientLayerWidth + centerLayerWidth,
                                          bounds.origin.y,
                                          rightGradientLayerWidth,
                                          bounds.size.height);
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
    
    CAGradientLayer *leftGradientLayer = [CAGradientLayer new];
    leftGradientLayer.locations = @[@(0.), @(1.)];
    leftGradientLayer.startPoint = CGPointMake(0., 1.);
    leftGradientLayer.endPoint = CGPointMake(1., 1.);
    
    _leftGradientLayer = leftGradientLayer;
    return leftGradientLayer;
}

- (CALayer *)_centerLayer {
    if (auto centerLayer = _centerLayer) return centerLayer;
    
    CALayer *centerLayer = [CALayer new];
    
    _centerLayer = centerLayer;
    return centerLayer;
}

- (CAGradientLayer *)_rightGradientLayer {
    if (auto rightGradientLayer = _rightGradientLayer) return rightGradientLayer;
    
    CAGradientLayer *rightGradientLayer = [CAGradientLayer new];
    rightGradientLayer.locations = @[@(0.), @(1.)];
    rightGradientLayer.startPoint = CGPointMake(1., 1.);
    rightGradientLayer.endPoint = CGPointMake(0., 1.);
    
    _rightGradientLayer = rightGradientLayer;
    return rightGradientLayer;
}

@end

#endif
