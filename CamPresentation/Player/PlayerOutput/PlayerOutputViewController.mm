//
//  PlayerOutputViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerOutputViewController.h>
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
@property (assign, nonatomic, readonly) PlayerOutputLayerType _layerType;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerOutputViewController
@synthesize outputView = _outputView;
@synthesize _controlView = __controlView;

- (instancetype)initWithLayerType:(PlayerOutputLayerType)layerType {
    if (self = [super initWithNibName:nil bundle:nil]) {
        __layerType = layerType;
    }
    
    return self;
}

- (void)dealloc {
    [_outputView release];
    [__controlView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    PlayerOutputView *outputView = self.outputView;
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

- (AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    assert([self.outputView.player isEqual:self._controlView.player]);
    return self.outputView.player;
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    self.outputView.player = player;
    self._controlView.player = player;
}

- (PlayerOutputView *)outputView {
    if (auto outputView = _outputView) return outputView;
    
    PlayerOutputView *outputView = [[PlayerOutputView alloc] initWithFrame:CGRectNull layerType:self._layerType];
    
    _outputView = [outputView retain];
    return [outputView autorelease];
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
