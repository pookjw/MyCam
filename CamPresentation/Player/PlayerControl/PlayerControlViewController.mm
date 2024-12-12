//
//  PlayerControlViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/12/24.
//

#import <CamPresentation/PlayerControlViewController.h>
#import <CamPresentation/PlayerControlView.h>

@implementation PlayerControlViewController

- (void)loadView {
    PlayerControlView *controlView = [PlayerControlView new];
    self.view = controlView;
    [controlView release];
}

- (AVPlayer *)player {
    return self.controlView.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self.controlView.player = player;
}

- (PlayerControlView *)controlView {
    return static_cast<PlayerControlView *>(self.view);
}

@end
