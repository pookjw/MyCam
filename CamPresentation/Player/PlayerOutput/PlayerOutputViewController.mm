//
//  PlayerOutputViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerOutputViewController.h>
#import <CamPresentation/PlayerOutputView.h>
#import <CamPresentation/PlayerControlView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

typedef NS_ENUM(NSUInteger, PlayerOutputViewType) {
    PlayerOutputViewTypeNone,
    PlayerOutputViewTypeSingle,
    PlayerOutputViewTypeMulti
};

@interface PlayerOutputViewController ()
@property (retain, nonatomic, nullable) PlayerOutputView *_outputView;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerOutputViewController
@synthesize player = _player;
@synthesize _outputView = __outputView;
@synthesize _controlView = __controlView;

- (void)dealloc {
    [_player release];
    [__outputView release];
    [__controlView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    PlayerOutputView *outputView = self._outputView;
    PlayerControlView *controlView = self._controlView;
    
    outputView.translatesAutoresizingMaskIntoConstraints = NO;
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:outputView];
    [self.view addSubview:controlView];
    
    [NSLayoutConstraint activateConstraints:@[
        [outputView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [outputView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [outputView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [outputView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [controlView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    _player = [player retain];
    self._outputView.player = player;
    self._controlView.player = player;
}

- (PlayerOutputView *)_outputView {
    if (auto outputView = __outputView) return outputView;
    
    PlayerOutputView *outputView = [PlayerOutputView new];
    
    __outputView = [outputView retain];
    return [outputView autorelease];
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
