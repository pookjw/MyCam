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

@interface PlayerOutputViewController ()
@property (retain, nonatomic, readonly) AVPlayer *_player;
@property (retain, nonatomic, readonly) PlayerOutputView *_outputView;
@property (retain, nonatomic, readonly) PlayerControlView *_controlView;
@end

@implementation PlayerOutputViewController
@synthesize _outputView = __outputView;
@synthesize _controlView = __controlView;

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        __player = [player retain];
    }
    
    return self;
}

- (void)dealloc {
    [__player release];
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
    
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:outputView];
    [self.view addSubview:controlView];
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), outputView);
    
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification {
    [self._outputView updateWithPlayer:player specification:specification];
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
    controlView.player = self._player;
    
    __controlView = [controlView retain];
    return [controlView autorelease];
}

@end
