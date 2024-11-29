//
//  PlayerLayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PlayerLayerViewController.h>
#import <CamPresentation/PlayerLayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface PlayerLayerViewController ()
@property (retain, nonatomic, readonly, nullable) AVPlayer *player;
@end

@implementation PlayerLayerViewController

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        _player = [player retain];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [super dealloc];
}

- (void)loadView {
    PlayerLayerView *playerView = [PlayerLayerView new];
    playerView.playerLayer.player = self.player;
    self.view = playerView;
    [playerView release];
}

@end
