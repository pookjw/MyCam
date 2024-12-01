//
//  PlayerLayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PlayerLayerViewController.h>
#import <CamPresentation/PlayerLayerView.h>
#import <CamPresentation/PlayerControlView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface PlayerLayerViewController ()
@property (retain, nonatomic, readonly, nullable) AVPlayer *_player;
@property (retain, nonatomic, readonly) PlayerLayerView *_layerView;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerLayerViewController
@synthesize _layerView = __layerView;
@synthesize _controlView = __controlView;

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        __player = [player retain];
    }
    
    return self;
}

- (void)dealloc {
    [__player release];
    [__layerView release];
    [__controlView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
        self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    PlayerLayerView *layerView = self._layerView;
    PlayerControlView *controlView = self._controlView;
    
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:layerView];
    [self.view addSubview:controlView];
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), layerView);
    
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (PlayerLayerView *)_layerView {
    if (auto layerView = __layerView) return layerView;
    
    PlayerLayerView *layerView = [PlayerLayerView new];
    layerView.playerLayer.player = self._player;
    
    __layerView = [layerView retain];
    return [layerView autorelease];
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    controlView.player = self._player;
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
