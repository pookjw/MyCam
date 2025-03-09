//
//  CinematicEditViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditViewController.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicEditTimelineView.h>

@interface CinematicEditViewController ()
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@property (retain, nonatomic, readonly, getter=_playerViewController) AVPlayerViewController *playerViewController;
@property (retain, nonatomic, readonly, getter=_timelineView) CinematicEditTimelineView *timelineView;
@property (retain, nonatomic, readonly, getter=_stackView) UIStackView *stackView;
@end

@implementation CinematicEditViewController
@synthesize playerViewController = _playerViewController;
@synthesize timelineView = _timelineView;
@synthesize stackView = _stackView;

- (instancetype)initWithViewModel:(CinematicViewModel *)viewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [viewModel retain];
        [viewModel addObserver:self forKeyPath:@"isolated_compositions" options:NSKeyValueObservingOptionNew context:NULL];
        [self _didChangeComposition];
    }
    
    return self;
}

- (void)dealloc {
    [_viewModel removeObserver:self forKeyPath:@"isolated_compositions"];
    [_viewModel release];
    [_playerViewController release];
    [_timelineView release];
    [_stackView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.viewModel]) {
        if ([keyPath isEqualToString:@"isolated_compositions"]) {
            [self _didChangeComposition];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStackView *stackView = self.stackView;
    [self.view addSubview:stackView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
    
    AVPlayerViewController *playerViewController = self.playerViewController;
    [self addChildViewController:playerViewController];
    [stackView addArrangedSubview:playerViewController.view];
    [stackView addArrangedSubview:self.timelineView];
    [playerViewController didMoveToParentViewController:self];
}

- (AVPlayerViewController *)_playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    
    _playerViewController = playerViewController;
    return playerViewController;
}

- (CinematicEditTimelineView *)_timelineView {
    if (auto timelineView = _timelineView) return timelineView;
    
    CinematicEditTimelineView *timelineView = [CinematicEditTimelineView new];
    
    _timelineView = timelineView;
    return timelineView;
}

- (UIStackView *)_stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = stackView;
    return stackView;
}

- (void)_didChangeComposition {
    dispatch_async(self.viewModel.queue, ^{
        AVPlayerItem * _Nullable playerItem;
        if (CinematicCompositions *compositions = self.viewModel.isolated_compositions) {
            playerItem = [[AVPlayerItem alloc] initWithAsset:compositions.composition];
            playerItem.videoComposition = compositions.videoComposition;
        } else {
            playerItem = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (AVPlayer *player = self.playerViewController.player) {
                [player replaceCurrentItemWithPlayerItem:playerItem];
            } else {
                AVPlayer *_player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
                self.playerViewController.player = _player;
                [_player release];
            }
        });
        
        [playerItem release];
    });
}

@end
