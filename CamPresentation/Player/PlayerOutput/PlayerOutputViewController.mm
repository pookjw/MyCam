//
//  PlayerOutputViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerOutputViewController.h>
#import <CamPresentation/PlayerOutputSingleView.h>
#import <CamPresentation/PlayerOutputMultiView.h>
#import <CamPresentation/PlayerControlView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface PlayerOutputViewController ()
@property (retain, nonatomic, readonly) AVPlayer *_player;
@property (retain, nonatomic, readonly, nullable) PlayerOutputSingleView *_outputSingleView;
@property (retain, nonatomic, readonly, nullable) PlayerOutputMultiView *_outputMultiView;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerOutputViewController
@synthesize _outputMultiView = __outputMultiView;
@synthesize _controlView = __controlView;

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        __player = [player retain];
    }
    
    return self;
}

- (void)dealloc {
    [__player release];
    [__outputSingleView release];
    [__outputMultiView release];
    [__controlView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
    PlayerOutputMultiView *outputView = self._outputMultiView;
    PlayerControlView *controlView = self._controlView;
    
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:outputView];
    [self.view addSubview:controlView];
    
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), outputView);
    outputView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [outputView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [outputView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [outputView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [outputView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification {
    [self._outputMultiView updateWithPlayer:player specification:specification];
    self._controlView.player = player;
}

- (PlayerOutputMultiView *)_outputMultiView {
    if (auto outputMultiView = __outputMultiView) return outputMultiView;
    
    PlayerOutputMultiView *outputMultiView = [PlayerOutputMultiView new];
    
    __outputMultiView = [outputMultiView retain];
    return [outputMultiView autorelease];
}

- (PlayerControlView *)_controlView {
    if (auto controlView = __controlView) return controlView;
    
    PlayerControlView *controlView = [PlayerControlView new];
    controlView.player = self._player;
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
