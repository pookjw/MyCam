//
//  CinematicEditViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditViewController.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/CinematicEditTimelineView.h>
#import <CamPresentation/PlayerLayerView.h>
#import <CamPresentation/PlayerControlView.h>
#import <CamPresentation/TVSlider.h>
#import <CamPresentation/NSStringFromCNSpatialAudioRenderingStyle.h>
#include <ranges>
#include <vector>

@interface CinematicEditViewController () <CinematicEditTimelineViewDelegate>
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@property (retain, nonatomic, readonly, getter=_playerLayerView) PlayerLayerView *playerLayerView;
@property (retain, nonatomic, readonly, getter=_playerControlView) PlayerControlView *playerControlView;
@property (retain, nonatomic, readonly, getter=_timelineView) CinematicEditTimelineView *timelineView;
@property (retain, nonatomic, readonly, getter=_stackView) UIStackView *stackView;
@property (retain, nonatomic, readonly, getter=_activityIndicatorView) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic, readonly, getter=_editButton) UIButton *editButton;

#if TARGET_OS_TV
@property (retain, nonatomic, readonly, getter=_fNumberSlider) TVSlider *fNumberSlider;
@property (retain, nonatomic, readonly, getter=_spatialAudioMixEffectIntensitySlider) TVSlider *spatialAudioMixEffectIntensitySlider API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
#else
@property (retain, nonatomic, readonly, getter=_fNumberSlider) UISlider *fNumberSlider;
@property (retain, nonatomic, readonly, getter=_spatialAudioMixEffectIntensitySlider) UISlider *spatialAudioMixEffectIntensitySlider API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0));
#endif
@property (retain, nonatomic, readonly, getter=_player) AVQueuePlayer *player;
@property (retain, nonatomic, nullable, getter=_playerLooper, setter=_setPlayerLooper:) AVPlayerLooper *playerLooper;
@property (retain, nonatomic, readonly, getter=_periodicTimeObserver) id periodicTimeObserver;
@end

@implementation CinematicEditViewController
@synthesize playerLayerView = _playerLayerView;
@synthesize playerControlView = _playerControlView;
@synthesize timelineView = _timelineView;
@synthesize stackView = _stackView;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize editButton = _editButton;
@synthesize fNumberSlider = _fNumberSlider;
@synthesize spatialAudioMixEffectIntensitySlider = _spatialAudioMixEffectIntensitySlider;
@synthesize player = _player;
@synthesize playerLooper = _playerLooper;
@synthesize periodicTimeObserver = _periodicTimeObserver;

- (instancetype)initWithViewModel:(CinematicViewModel *)viewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [viewModel retain];
        [viewModel addObserver:self forKeyPath:@"isolated_snapshot" options:NSKeyValueObservingOptionNew context:NULL];
        [self _didChangeComposition];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didUpdateScript:) name:CinematicViewModelDidUpdateScriptNotification object:viewModel];
        
        if (@available(macOS 26.0, iOS 26.0, tvOS 26.0, *)) {
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didUpdateSpatialAudioMixInfo:) name:CinematicViewModelDidUpdateSpatioAudioMixInfoNotification object:viewModel];
        }
        
        [self _updateFNumberSlider];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_viewModel removeObserver:self forKeyPath:@"isolated_snapshot"];
    [_viewModel release];
    [_playerLayerView release];
    [_playerControlView release];
    [_timelineView release];
    [_stackView release];
    [_editButton release];
    [_fNumberSlider release];
    [_spatialAudioMixEffectIntensitySlider release];
    [_activityIndicatorView release];
    
    if (id periodicTimeObserver = _periodicTimeObserver) {
        [_player removeTimeObserver:periodicTimeObserver];
        [_periodicTimeObserver release];
    }
    
    [_player release];
    [_playerLooper release];
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
#if !TARGET_OS_TV
    self.view.backgroundColor = UIColor.systemBackgroundColor;
#endif
    
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
    
    UIActivityIndicatorView *activityIndicatorView = self.activityIndicatorView;
    [self.view addSubview:activityIndicatorView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), activityIndicatorView);
    
    [self _periodicTimeObserver];
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
    
    CinematicEditTimelineView *timelineView = [[CinematicEditTimelineView alloc] initWithParentViewModel:self.viewModel];
    timelineView.delegate = self;
    
    _timelineView = timelineView;
    return timelineView;
}

- (UIStackView *)_stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    [stackView addArrangedSubview:self.playerLayerView];
    [stackView addArrangedSubview:self.editButton];
    [stackView addArrangedSubview:self.timelineView];
    
    [self.playerLayerView.heightAnchor constraintEqualToAnchor:self.timelineView.heightAnchor].active = YES;
    
    _stackView = stackView;
    return stackView;
}

- (UIActivityIndicatorView *)_activityIndicatorView {
    if (auto activityIndicatorView = _activityIndicatorView) return activityIndicatorView;
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    activityIndicatorView.hidesWhenStopped = YES;
#if TARGET_OS_TV
    activityIndicatorView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
#else
    activityIndicatorView.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.3];
#endif
    
    _activityIndicatorView = activityIndicatorView;
    return activityIndicatorView;
}

- (UIButton *)_editButton {
    if (auto editButton = _editButton) return editButton;
    
    UIButton *editButton = [UIButton new];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration borderedTintedButtonConfiguration];
    configuration.title = @"Edit";
    editButton.configuration = configuration;
    
    editButton.showsMenuAsPrimaryAction = YES;
    editButton.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    editButton.menu = [self _makeEditMenu];
    
    _editButton = editButton;
    return editButton;
}

- (UIMenu *)_makeEditMenu {
    CinematicViewModel *viewModel = self.viewModel;
#if TARGET_OS_TV
    TVSlider *fNumberSlider = self.fNumberSlider;
#else
    UISlider *fNumberSlider = self.fNumberSlider;
#endif
    
#if TARGET_OS_TV
    TVSlider * _Nullable spatialAudioMixEffectIntensitySlider;
#else
    UISlider * _Nullable spatialAudioMixEffectIntensitySlider;
#endif
    if (@available(macOS 26.0, iOS 26.0, tvOS 26.0, *)) {
        spatialAudioMixEffectIntensitySlider = self.spatialAudioMixEffectIntensitySlider;
    } else {
        spatialAudioMixEffectIntensitySlider = nil;
    }
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(viewModel.queue, ^{
            NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
            
            {
                __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
                    return fNumberSlider;
                });
                
                UIMenu *menu = [UIMenu menuWithTitle:@"fNumber" children:@[element]];
                [elements addObject:menu];
            }
            
            if (@available(macOS 26.0, iOS 26.0, tvOS 26.0, *)) {
                if (!CNAssetSpatialAudioInfo.isSupported) {
                    UIAction *action = [UIAction actionWithTitle:@"Spatial Audio Mix" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
                    action.attributes = UIMenuElementAttributesDisabled;
                    action.subtitle = @"This device not supported";
                    [elements addObject:action];
                } else if (viewModel.isolated_snapshot.assetData.spatialAudioInfo != nil) {
                    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
                    
                    if (viewModel.isolated_snapshot.spatialAudioMixEnabled) {
                        {
                            UIAction *action = [UIAction actionWithTitle:@"Disable" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                                dispatch_async(viewModel.queue, ^{
                                    [viewModel isolated_disableSpatialAudioMix];
                                });
                            }];
                            action.attributes = UIMenuOptionsDestructive;
                            [children addObject:action];
                        }
                        
                        {
                            NSUInteger count;
                            const CNSpatialAudioRenderingStyle *allStyles = allCNSpatialAudioRenderingStyles(&count);
                            
                            auto actionsVec = std::views::iota(allStyles, allStyles + count)
                            | std::views::transform([](const CNSpatialAudioRenderingStyle *ptr) { return *ptr; })
                            | std::views::transform([viewModel](const CNSpatialAudioRenderingStyle style) -> UIAction * {
                                UIAction *action = [UIAction actionWithTitle:NSStringFromCNSpatialAudioRenderingStyle(style) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                                    dispatch_async(viewModel.queue, ^{
                                        [viewModel isolated_setSpatialAudioMixRenderingStyle:style];
                                    });
                                }];
                                
                                action.state = (viewModel.isolated_snapshot.spatialAudioMixRenderingStyle == style) ? UIMenuElementStateOn : UIMenuElementStateOff;
                                return action;
                            })
                            | std::ranges::to<std::vector<UIAction *>>();
                            
                            NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
                            UIMenu *menu = [UIMenu menuWithTitle:@"Rendering Style" children:actions];
                            [actions release];
                            [children addObject:menu];
                        }
                        
                        {
                            __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
                                assert(spatialAudioMixEffectIntensitySlider != nil);
                                return spatialAudioMixEffectIntensitySlider;
                            });
                            
                            UIMenu *menu = [UIMenu menuWithTitle:@"Effect Intensity" children:@[element]];
                            [children addObject:menu];
                        }
                    } else {
                        UIAction *action = [UIAction actionWithTitle:@"Enable" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                            dispatch_async(viewModel.queue, ^{
                                [viewModel isolated_enableSpatialAudioMix];
                            });
                        }];
                        
                        [children addObject:action];
                    }
                    
                    UIMenu *menu = [UIMenu menuWithTitle:@"Spatial Audio Mix" children:children];
                    [children release];
                    [elements addObject:menu];
                } else {
                    UIAction *action = [UIAction actionWithTitle:@"Spatial Audio Mix" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
                    action.attributes = UIMenuElementAttributesDisabled;
                    action.subtitle = @"Asset does not contain Spatial Audio Info";
                    [elements addObject:action];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            [elements release];
        });
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[element]];
    return menu;
}

#if TARGET_OS_TV
- (TVSlider *)_fNumberSlider
#else
- (UISlider *)_fNumberSlider
#endif
{
    if (auto fNumberSlider = _fNumberSlider) return fNumberSlider;
    
#if TARGET_OS_TV
    TVSlider *fNumberSlider = [TVSlider new];
#else
    UISlider *fNumberSlider = [UISlider new];
#endif
    fNumberSlider.minimumValue = 2.f;
    fNumberSlider.maximumValue = 16.f;
    fNumberSlider.continuous = NO;
    
#if TARGET_OS_TV
    __block auto weakSelf = self;
    [fNumberSlider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf _didChangeFNumberSliderValue:action.sender];
    }]];
#else
    [fNumberSlider addTarget:self action:@selector(_didChangeFNumberSliderValue:) forControlEvents:UIControlEventValueChanged];
#endif
    
    _fNumberSlider = fNumberSlider;
    return fNumberSlider;
}

#if TARGET_OS_TV
- (TVSlider *)_spatialAudioMixEffectIntensitySlider
#else
- (UISlider *)_spatialAudioMixEffectIntensitySlider
#endif
{
    if (auto spatialAudioMixEffectIntensitySlider = _spatialAudioMixEffectIntensitySlider) return spatialAudioMixEffectIntensitySlider;
    
#if TARGET_OS_TV
    TVSlider *spatialAudioMixEffectIntensitySlider = [TVSlider new];
#else
    UISlider *spatialAudioMixEffectIntensitySlider = [UISlider new];
#endif
    spatialAudioMixEffectIntensitySlider.minimumValue = 0.1f;
    spatialAudioMixEffectIntensitySlider.maximumValue = 1.f;
    spatialAudioMixEffectIntensitySlider.continuous = YES;
    
#if TARGET_OS_TV
    __block auto weakSelf = self;
    [spatialAudioMixEffectIntensitySlider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf _didChangeSpatialAudioMixEffectIntensitySliderValue:action.sender];
    }]];
#else
    [spatialAudioMixEffectIntensitySlider addTarget:self action:@selector(_didChangeSpatialAudioMixEffectIntensitySliderValue:) forControlEvents:UIControlEventValueChanged];
#endif
    
    _spatialAudioMixEffectIntensitySlider = spatialAudioMixEffectIntensitySlider;
    return spatialAudioMixEffectIntensitySlider;
}

- (AVQueuePlayer *)_player {
    dispatch_assert_queue(dispatch_get_main_queue());
    if (auto player = _player) return player;
    
    AVQueuePlayer *player = [AVQueuePlayer new];
    
    _player = player;
    return player;
}

- (id)_periodicTimeObserver {
    dispatch_assert_queue(dispatch_get_main_queue());
    if (id periodicTimeObserver = _periodicTimeObserver) return periodicTimeObserver;
    
    CinematicEditTimelineView *timelineView = self.timelineView;
    
    id periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [timelineView scrollToTime:time];
    }];
    
    _periodicTimeObserver = [periodicTimeObserver retain];
    return periodicTimeObserver;
}

- (void)_didChangeComposition {
    dispatch_async(self.viewModel.queue, ^{
        AVPlayerItem * _Nullable playerItem;
        if (CinematicSnapshot *snapshot = self.viewModel.isolated_snapshot) {
            playerItem = [[AVPlayerItem alloc] initWithAsset:snapshot.composition];
            playerItem.videoComposition = snapshot.videoComposition;
        } else {
            playerItem = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AVQueuePlayer *player = self.player;
            [player replaceCurrentItemWithPlayerItem:playerItem];
            
            if (playerItem == nil) {
                self.playerLooper = nil;
            } else {
                AVPlayerLooper *playerLooper = [[AVPlayerLooper alloc] initWithPlayer:player templateItem:playerItem timeRange:CMTimeRangeMake(kCMTimeZero, playerItem.duration)];
                self.playerLooper = playerLooper;
                [playerLooper release];
            }
            
            self.playerLayerView.playerLayer.player = player;
            self.playerControlView.player = player;
            
            if (playerItem != nil) {
                if (@available(macOS 26.0, iOS 26.0, tvOS 26.0, *)) {
                    [self _didUpdateSpatialAudioMixInfo:nil];
                }
            }
        });
        
        [playerItem release];
    });
}

#if TARGET_OS_TV
- (void)_didChangeFNumberSliderValue:(TVSlider *)sender
#else
- (void)_didChangeFNumberSliderValue:(UISlider *)sender
#endif
{
    float value = sender.value;
    
    dispatch_async(self.viewModel.queue, ^{
        [self.viewModel isolated_changeFNumber:value];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _refreshCurrentFrameWithCompletionHandler:nil];
        });
    });
}

#if TARGET_OS_TV
- (void)_didChangeSpatialAudioMixEffectIntensitySliderValue:(TVSlider *)sender
#else
- (void)_didChangeSpatialAudioMixEffectIntensitySliderValue:(UISlider *)sender
#endif
API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0)) {
    float value = sender.value;
    
    dispatch_async(self.viewModel.queue, ^{
        [self.viewModel isolated_setSpatialAudioMixEffectIntensity:value];
    });
}

- (void)_didUpdateScript:(NSNotification *)notification {
    [self _updateFNumberSlider];
}

- (void)_didUpdateSpatialAudioMixInfo:(NSNotification * _Nullable)notification API_AVAILABLE(macos(26.0), ios(26.0), tvos(26.0)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        AVPlayerItem * _Nullable playerItem = self.player.currentItem;
        assert(playerItem != nil);
        
        dispatch_async(self.viewModel.queue, ^{
            if (CinematicSnapshot *snapshot = self.viewModel.isolated_snapshot) {
                if (snapshot.spatialAudioMixEnabled) {
                    playerItem.audioMix = [snapshot.assetData.spatialAudioInfo audioMixWithEffectIntensity:snapshot.spatialAudioMixEffectIntensity renderingStyle:snapshot.spatialAudioMixRenderingStyle];
                    assert(playerItem.audioMix != nil);
                } else {
                    playerItem.audioMix = nil;
                }
                
                float spatialAudioMixEffectIntensity = snapshot.spatialAudioMixEffectIntensity;
                dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_TV
                        if (!self.spatialAudioMixEffectIntensitySlider.editing)
#else
                        if (!self.spatialAudioMixEffectIntensitySlider.tracking)
#endif
                        {
                            self.spatialAudioMixEffectIntensitySlider.value = spatialAudioMixEffectIntensity;
                        }
                });
            }
        });
    });
}

- (void)_updateFNumberSlider {
    dispatch_async(self.viewModel.queue, ^{
        float fNumber = self.viewModel.isolated_snapshot.assetData.cnScript.fNumber;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.fNumberSlider.value = fNumber;
        });
    });
}

- (void)_didTriggerSingleTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self _changeFocusWithGestureRecognizer:sender strongDecision:NO];
}

- (void)_didTriggerDoubleTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self _changeFocusWithGestureRecognizer:sender strongDecision:YES];
}

- (void)_changeFocusWithGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer strongDecision:(BOOL)strongDecision {
    [self.activityIndicatorView startAnimating];
    
    CGPoint point = [gestureRecognizer locationInView:self.playerLayerView];
    CGPoint normalizedPoint = [self _normalizedVideoPointFromPoint:point];
    [self.playerLayerView.playerLayer.player pause];
    CMTime currentTime = self.playerLayerView.playerLayer.player.currentItem.currentTime;
    
    dispatch_async(self.viewModel.queue, ^{
        [self.viewModel isolated_changeFocusAtNormalizedPoint:normalizedPoint atTime:currentTime strongDecision:strongDecision];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _refreshCurrentFrameWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicatorView stopAnimating];
                });
            }];
        });
    });
}

- (CGPoint)_normalizedVideoPointFromPoint:(CGPoint)point {
    CGRect videoRect = self.playerLayerView.layer.visibleRect;
    return CGPointMake((point.x - videoRect.origin.x) / videoRect.size.width,
                       point.y / videoRect.size.height);
}

- (void)_refreshCurrentFrameWithCompletionHandler:(void (^)(void))completionHandler {
    AVPlayer *player = self.playerLayerView.playerLayer.player;
    if (player == nil) return;
    AVPlayerItem *currentItem = player.currentItem;
    if (currentItem == nil) return;
    
    switch (player.timeControlStatus) {
        case AVPlayerTimeControlStatusPaused:
        case AVPlayerTimeControlStatusPlaying: {
            BOOL original = currentItem.seekingWaitsForVideoCompositionRendering;
            currentItem.seekingWaitsForVideoCompositionRendering = YES;
            [player seekToTime:currentItem.currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                currentItem.seekingWaitsForVideoCompositionRendering = original;
                
                if (completionHandler) {
                    completionHandler();
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)cinematicEditTimelineView:(CinematicEditTimelineView *)cinematicEditTimelineView didRequestSeekingTime:(CMTime)time {
    AVPlayer *player = self.player;
    [player pause];
    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
    }];
}

@end

#endif
