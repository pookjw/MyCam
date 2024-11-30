//
//  PlayerControlView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerControlView.h>
#import <CamPresentation/TVSlider.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <TargetConditionals.h>

@interface PlayerControlView ()
@property (retain, nonatomic, readonly) UIStackView *_stackView;
@property (retain, nonatomic, readonly) UIButton *_playbackButton;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) TVSlider *_seekingSlider;
#else
@property (retain, nonatomic, readonly) UISlider *_seekingSlider;
#endif
@property (retain, nonatomic, readonly) MPVolumeView *_volumeView;
#if !TARGET_OS_VISION
@property (retain, nonatomic, readonly) AVRoutePickerView *_routePickerView;
#endif
@property (retain, nonatomic, readonly) UILabel *_reasonForWaitingToPlayLabel;
@property (retain, nonatomic, nullable) id _periodicTimeObserver;
@property (assign, nonatomic) BOOL _wasPlaying;
@end

@implementation PlayerControlView
@synthesize _stackView = __stackView;
@synthesize _playbackButton = __playbackButton;
@synthesize _seekingSlider = __seekingSlider;
@synthesize _volumeView = __volumeView;
#if !TARGET_OS_VISION
@synthesize _routePickerView = __routePickerView;
#endif
@synthesize _reasonForWaitingToPlayLabel = __reasonForWaitingToPlayLabel;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [__stackView release];
    [__playbackButton release];
    [__seekingSlider release];
    [__volumeView release];
    [__routePickerView release];
    [__reasonForWaitingToPlayLabel release];
    [super dealloc];
}

- (void)_commonInit {
    UIStackView *stackView = self._stackView;
    UILabel *reasonForWaitingToPlayLabel = self._reasonForWaitingToPlayLabel;
    
    [self addSubview:stackView];
    [self addSubview:reasonForWaitingToPlayLabel];
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), reasonForWaitingToPlayLabel);
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (_player) {
        [self _removeObserversForPlayer:_player];
        [_player release];
    }
    
    // TODO: Player 없으면 버튼들 disable 처리, 처음에도
    
    if (player) {
        _player = [player retain];
        [self _addObserversForPlayer:player];
    } else {
        _player = nil;
    }
}

- (UIStackView *)stackView {
    if (auto stackView = __stackView) return stackView;
    
    MPVolumeView *volumeView = self._volumeView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self._playbackButton,
        self._seekingSlider,
        volumeView,
#if !TARGET_OS_VISION
        self._routePickerView
#endif
    ]];
    
    [volumeView.widthAnchor constraintEqualToConstant:100.].active = YES;
    
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 8.;
    
    __stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)playbackButton {
    if (auto playbackButton = __playbackButton) return playbackButton;
    
    UIButton *playbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [playbackButton addTarget:self action:@selector(_didTriggerPlaybackButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    __playbackButton = [playbackButton retain];
    return playbackButton;
}

#if TARGET_OS_TV
- (TVSlider *)seekingSlider {
    abort();
}
#else
- (UISlider *)seekingSlider {
    if (auto seekingSlider = __seekingSlider) return seekingSlider;
    
    UISlider *seekingSlider = [UISlider new];
    seekingSlider.continuous = YES;
    
    [seekingSlider addTarget:self action:@selector(_didTouchDownSeekingSlider:) forControlEvents:UIControlEventTouchDown];
    [seekingSlider addTarget:self action:@selector(_didChangeSeekingSliderValue:) forControlEvents:UIControlEventValueChanged];
    [seekingSlider addTarget:self action:@selector(_didTouchUpSeekingSlider:) forControlEvents:UIControlEventTouchUpInside];
    [seekingSlider addTarget:self action:@selector(_didTouchUpSeekingSlider:) forControlEvents:UIControlEventTouchUpOutside];
    
    __seekingSlider = [seekingSlider retain];
    return [seekingSlider autorelease];
}
#endif

- (MPVolumeView *)volumeView {
    if (auto volumeView = __volumeView) return volumeView;
    
    MPVolumeView *volumeView = [MPVolumeView new];
    
    __volumeView = [volumeView retain];
    return [volumeView autorelease];
}

#if !TARGET_OS_VISION
- (AVRoutePickerView *)routePickerView {
    if (auto routePickerView = __routePickerView) return routePickerView;
    
    AVRoutePickerView *routePickerView = [AVRoutePickerView new];
    
    __routePickerView = [routePickerView retain];
    return [routePickerView autorelease];
}
#endif

- (UILabel *)reasonForWaitingToPlayLabel {
    if (auto reasonForWaitingToPlayLabel = __reasonForWaitingToPlayLabel) return reasonForWaitingToPlayLabel;
    
    UILabel *reasonForWaitingToPlayLabel = [UILabel new];
    reasonForWaitingToPlayLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    reasonForWaitingToPlayLabel.textColor = UIColor.labelColor;
#if !TARGET_OS_TV
    reasonForWaitingToPlayLabel.backgroundColor = UIColor.systemBackgroundColor;
#endif
    reasonForWaitingToPlayLabel.textAlignment = NSTextAlignmentCenter;
    
    __reasonForWaitingToPlayLabel = [reasonForWaitingToPlayLabel retain];
    return [reasonForWaitingToPlayLabel autorelease];
}

- (void)_updateAttributes {
    UIButtonConfiguration *configuration;
    BOOL isEnabled;
    
    if (AVPlayer *player = self.player) {
        if (player.status == AVPlayerStatusReadyToPlay) {
            float rate = player.rate;
            
            configuration = [UIButtonConfiguration borderedTintedButtonConfiguration];
            configuration.image = [UIImage systemImageNamed:(rate > 0.) ? @"pause.fill" : @"play.fill"];
            isEnabled = YES;
        } else {
            configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.showsActivityIndicator = YES;
            isEnabled = NO;
        }
    } else {
        configuration = [UIButtonConfiguration plainButtonConfiguration];
        configuration.showsActivityIndicator = YES;
        isEnabled = NO;
    }
    
    UIButton *playbackButton = self._playbackButton;
    playbackButton.configuration = configuration;
    playbackButton.enabled = isEnabled;
}

- (void)_updateReasonForWaitingToPlay {
    AVPlayerWaitingReason reasonForWaitingToPlay = self.player.reasonForWaitingToPlay;
    UILabel *reasonForWaitingToPlayLabel = self._reasonForWaitingToPlayLabel;
    
    reasonForWaitingToPlayLabel.text = self.player.reasonForWaitingToPlay;
    reasonForWaitingToPlayLabel.hidden = (reasonForWaitingToPlay == nil);
}

- (void)_removeObserversForPlayer:(AVPlayer *)player {
    [player removeObserver:self forKeyPath:@"rate"];
    [player removeObserver:self forKeyPath:@"status"];
    [player removeObserver:self forKeyPath:@"reasonForWaitingToPlay"];
    
    assert(self._periodicTimeObserver != nil);
    [player removeTimeObserver:self._periodicTimeObserver];
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"reasonForWaitingToPlay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
    auto seekingSlider = self._seekingSlider;
    
    self._periodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [PlayerControlView _updateSeekingSlider:seekingSlider player:player];
    }];
}

- (void)_didTriggerPlaybackButton:(UIButton *)sender {
    AVPlayer * _Nullable player = self.player;
    if (player == nil) return;
    
    if (player.rate > 0.) {
        [player pause];
    } else {
        NSError * _Nullable error = nil;
        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
        assert(error == nil);
        [AVAudioSession.sharedInstance setActive:YES error:&error];
        assert(error == nil);
        [player play];
    }
}

#if !TARGET_OS_TV
- (void)_didTouchDownSeekingSlider:(UISlider *)sender {
    AVPlayer * _Nullable player = self.player;
    if (player == nil) return;
    
    self._wasPlaying = (player.rate > 0.);
    [player pause];
}

- (void)_didChangeSeekingSliderValue:(UISlider *)sender {
    AVPlayer * _Nullable player = self.player;
    if (player == nil) return;
    
    CMTime time = CMTimeMake(sender.value, 1000000UL);
    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)_didTouchUpSeekingSlider:(UISlider *)sender {
    AVPlayer * _Nullable player = self.player;
    if (player == nil) return;
    
    if (self._wasPlaying) {
        [player play];
    }
}
#endif

#if TARGET_OS_TV
+ (void)_updateSeekingSlider:(TVSlider *)seekingSlider player:(AVPlayer * _Nullable)player
#else
+ (void)_updateSeekingSlider:(UISlider *)seekingSlider player:(AVPlayer * _Nullable)player
#endif
{
    if (player == nil) {
        seekingSlider.enabled = NO;
        return;
    }
    
    seekingSlider.minimumValue = 0.;
    seekingSlider.maximumValue = CMTimeConvertScale(player.currentItem.duration, 1000000UL, kCMTimeRoundingMethod_Default).value;
    
#if TARGET_OS_TV
    seekingSlider.value = CMTimeConvertScale(player.currentTime, 1000000UL, kCMTimeRoundingMethod_Default).value;
#else
    if (!seekingSlider.isTracking) {
        seekingSlider.value = CMTimeConvertScale(player.currentTime, 1000000UL, kCMTimeRoundingMethod_Default).value;
    }
#endif
    
    seekingSlider.enabled = YES;
}

@end
