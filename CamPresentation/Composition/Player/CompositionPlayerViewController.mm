//
//  CompositionPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <CamPresentation/CompositionPlayerViewController.h>
#import <AVKit/AVKit.h>
#import <CamPresentation/AVPlayerViewController+Category.h>

@interface CompositionPlayerViewController ()
@property (retain, nonatomic, readonly, getter=_playerViewController) AVPlayerViewController *playerViewController;
@property (retain, nonatomic, readonly, getter=_player) AVPlayer *player;
@property (retain, nonatomic, readonly, getter=_compositionService) CompositionService *compositionService;
@end

@implementation CompositionPlayerViewController
@synthesize playerViewController = _playerViewController;
@synthesize player = _player;

- (instancetype)initWithCompositionService:(CompositionService *)compositionService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _compositionService = [compositionService retain];
        
        [compositionService addObserver:self forKeyPath:@"queue_composition" options:NSKeyValueObservingOptionNew context:NULL];
        [self _nonisolated_compositionDidChange];
    }
    
    return self;
}

- (void)dealloc {
    [_playerViewController release];
    [_player release];
    [_compositionService release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.compositionService]) {
        if ([keyPath isEqualToString:@"queue_composition"]) {
            [self _nonisolated_compositionDidChange];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addChildViewController:self.playerViewController];
    self.playerViewController.view.frame = self.view.bounds;
    self.playerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.playerViewController.view];
    [self.playerViewController didMoveToParentViewController:self];
}

- (AVPlayerViewController *)_playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = self.player;
#if TARGET_OS_VISION
    playerViewController.cp_overrideEffectivelyFullScreen = NO;
#endif
    
    _playerViewController = playerViewController;
    return playerViewController;
}

- (AVPlayer *)_player {
    if (auto player = _player) return player;
    
    AVPlayer *player = [[AVPlayer alloc] init];
    
    _player = player;
    return player;
}

- (void)_nonisolated_compositionDidChange {
    dispatch_async(self.compositionService.queue, ^{
        AVComposition *composition = self.compositionService.queue_composition;
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [playerItem release];
    });
}

@end
