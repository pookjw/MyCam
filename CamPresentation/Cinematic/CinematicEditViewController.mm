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
#import <CamPresentation/PlayerLayerView.h>
#import <CamPresentation/PlayerControlView.h>

@interface CinematicEditViewController ()
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@property (retain, nonatomic, readonly, getter=_playerLayerView) PlayerLayerView *playerLayerView;
@property (retain, nonatomic, readonly, getter=_playerControlView) PlayerControlView *playerControlView;
@property (retain, nonatomic, readonly, getter=_timelineView) CinematicEditTimelineView *timelineView;
@property (retain, nonatomic, readonly, getter=_stackView) UIStackView *stackView;
@end

@implementation CinematicEditViewController
@synthesize playerLayerView = _playerLayerView;
@synthesize playerControlView = _playerControlView;
@synthesize timelineView = _timelineView;
@synthesize stackView = _stackView;

- (instancetype)initWithViewModel:(CinematicViewModel *)viewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [viewModel retain];
        [viewModel addObserver:self forKeyPath:@"isolated_snapshot" options:NSKeyValueObservingOptionNew context:NULL];
        [self _didChangeComposition];
    }
    
    return self;
}

- (void)dealloc {
    [_viewModel removeObserver:self forKeyPath:@"isolated_snapshot"];
    [_viewModel release];
    [_playerLayerView release];
    [_playerControlView release];
    [_timelineView release];
    [_stackView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.viewModel]) {
        if ([keyPath isEqualToString:@"isolated_snapshot"]) {
            [self _didChangeComposition];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    UIStackView *stackView = self.stackView;
    [self.view addSubview:stackView];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    PlayerControlView *controlView = self.playerControlView;
    [self.playerLayerView addSubview:controlView];
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.playerLayerView.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.playerLayerView.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.playerLayerView.layoutMarginsGuide.bottomAnchor]
    ]];
}

- (PlayerLayerView *)_playerLayerView {
    if (auto playerLayerView = _playerLayerView) return playerLayerView;
    
    PlayerLayerView *playerLayerView = [PlayerLayerView new];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTriggerSingleTapGestureRecognizer:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [playerLayerView addGestureRecognizer:singleTapGestureRecognizer];
    [singleTapGestureRecognizer release];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didTriggerDoubleTapGestureRecognizer:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [playerLayerView addGestureRecognizer:doubleTapGestureRecognizer];
    [doubleTapGestureRecognizer release];
    
    _playerLayerView = playerLayerView;
    
    return playerLayerView;
}

- (PlayerControlView *)_playerControlView {
    if (auto playerControlView = _playerControlView) return playerControlView;
    
    PlayerControlView *playerControlView = [PlayerControlView new];
    
    _playerControlView = playerControlView;
    return playerControlView;
}

- (CinematicEditTimelineView *)_timelineView {
    if (auto timelineView = _timelineView) return timelineView;
    
    CinematicEditTimelineView *timelineView = [[CinematicEditTimelineView alloc] initWithViewModel:self.viewModel];
    
    _timelineView = timelineView;
    return timelineView;
}

- (UIStackView *)_stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    [stackView addArrangedSubview:self.playerLayerView];
    [stackView addArrangedSubview:self.timelineView];
    
    _stackView = stackView;
    return stackView;
}

- (void)_didChangeComposition {
    dispatch_async(self.viewModel.queue, ^{
        AVPlayerItem * _Nullable playerItem;
        if (CinematicSnapshot *compositions = self.viewModel.isolated_snapshot) {
            playerItem = [[AVPlayerItem alloc] initWithAsset:compositions.composition];
            playerItem.videoComposition = compositions.videoComposition;
        } else {
            playerItem = nil;
        }
        
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerLayerView.playerLayer.player = player;
            self.playerControlView.player = player;
        });
        
        [playerItem release];
        [player release];
    });
}

- (void)_didTriggerSingleTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self _changeFocusWithGestureRecognizer:sender strongDecision:NO];
}

- (void)_didTriggerDoubleTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self _changeFocusWithGestureRecognizer:sender strongDecision:YES];
}

- (void)_changeFocusWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer strongDecision:(BOOL)strongDecision {
    CGPoint point = [gestureRecognizer locationInView:self.playerLayerView];
    CGPoint normalizedPoint = [self _normalizedVideoPointFromPoint:point];
    CMTime currentTime = self.playerLayerView.playerLayer.player.currentTime;
    
    dispatch_async(self.viewModel.queue, ^{
        [self.viewModel isolated_changeFocusAtNormalizedPoint:normalizedPoint atTime:currentTime strongDecision:strongDecision];
    });
}

- (CGPoint)_normalizedVideoPointFromPoint:(CGPoint)point {
    CGRect videoRect = self.playerLayerView.layer.visibleRect;
    return CGPointMake((point.x - videoRect.origin.x) / videoRect.size.width,
                       point.y / videoRect.size.height);
}

@end
