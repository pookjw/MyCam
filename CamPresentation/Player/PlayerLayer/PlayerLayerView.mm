//
//  PlayerLayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/9/24.
//

#import <CamPresentation/PlayerLayerView.h>
#import <CamPresentation/PlayerControlView.h>
#import <TargetConditionals.h>

@interface PlayerLayerView ()
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerLayerView
@synthesize _controlView = __controlView;

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayerLayer *)playerLayer {
    return static_cast<AVPlayerLayer *>(self.layer);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
#if !TARGET_OS_TV
        self.backgroundColor = UIColor.systemBackgroundColor;
#endif
        
        PlayerControlView *controlView = self._controlView;
        controlView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:controlView];
        [NSLayoutConstraint activateConstraints:@[
            [controlView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [controlView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [controlView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor]
        ]];
        
        AVPlayerLayer *playerLayer = self.playerLayer;
        [playerLayer addObserver:self forKeyPath:@"player" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [self.playerLayer removeObserver:self forKeyPath:@"player"];
    [__controlView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.playerLayer]) {
        if ([keyPath isEqualToString:@"player"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayer *player = change[NSKeyValueChangeNewKey];
                if (player == nil) {
                    player = self.playerLayer.player;
                }
                
                self._controlView.player = player;
            });
            
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
