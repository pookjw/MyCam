//
//  PlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PlayerViewController.h>
#import <CamPresentation/PlayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface PlayerViewController ()
@property (retain, nonatomic, readonly, nullable) AVPlayer *player;
@property (nonatomic, readonly) PlayerView *playerView;
@property (retain, nonatomic, readonly) UIBarButtonItem *doneBarButtonItem;
@property (retain, nonatomic, readonly) __kindof UIView *progressView;
@property (retain, nonatomic, readonly) UIBarButtonItem *progressBarButtonItem;
@end

@implementation PlayerViewController
@synthesize doneBarButtonItem = _doneBarButtonItem;
@synthesize progressView = _progressView;
@synthesize progressBarButtonItem = _progressBarButtonItem;

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        _player = [player retain];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [_doneBarButtonItem release];
    [_progressView release];
    [_progressBarButtonItem release];
    
    [super dealloc];
}

- (void)loadView {
    PlayerView *playerView = [PlayerView new];
    self.view = playerView;
    [playerView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
#if !TARGET_OS_TV
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
#endif
    navigationItem.rightBarButtonItems = @[self.doneBarButtonItem, self.progressBarButtonItem];
    
    self.playerView.playerLayer.player = self.player;
}

- (PlayerView *)playerView {
    return static_cast<PlayerView *>(self.view);
}

- (UIBarButtonItem *)doneBarButtonItem {
    if (auto doneBarButtonItem = _doneBarButtonItem) return doneBarButtonItem;
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerDoneBarButtonItem:)];
    
    _doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (__kindof UIView *)progressView {
    if (auto progressView = _progressView) return progressView;
    
    __kindof UIView *progressView = [objc_lookUpClass("_UICircleProgressView") new];
    
    [NSLayoutConstraint activateConstraints:@[
        [progressView.widthAnchor constraintEqualToConstant:44.],
        [progressView.heightAnchor constraintEqualToConstant:44.]
    ]];
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(progressView, sel_registerName("setShowProgressTray:"), YES);
    
    _progressView = [progressView retain];
    return [progressView autorelease];
}

- (UIBarButtonItem *)progressBarButtonItem {
    if (auto progressBarButtonItem = _progressBarButtonItem) return progressBarButtonItem;
    
    UIBarButtonItem *progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.progressView];
    
    _progressBarButtonItem = [progressBarButtonItem retain];
    return [progressBarButtonItem autorelease];
}

- (void)didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
