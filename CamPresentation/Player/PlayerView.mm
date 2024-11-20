//
//  PlayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/9/24.
//

#import <CamPresentation/PlayerView.h>
#import <MediaPlayer/MediaPlayer.h>
#import <TargetConditionals.h>

@interface PlayerView ()
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *playbackButton;
#if !TARGET_OS_TV
@property (retain, nonatomic, readonly) UISlider *seekingSlider;
#endif
@property (retain, nonatomic, readonly) MPVolumeView *volumeView;
#if !TARGET_OS_VISION
@property (retain, nonatomic, readonly) AVRoutePickerView *routePickerView;
#endif
@property (retain, nonatomic, readonly) UILabel *reasonForWaitingToPlayLabel;
#if !TARGET_OS_TV
@property (retain, nonatomic, nullable) id periodicTimeObserver;
#endif
@property (assign, nonatomic) BOOL wasPlaying;
@end

@implementation PlayerView
@synthesize stackView = _stackView;
@synthesize playbackButton = _playbackButton;
#if !TARGET_OS_TV
@synthesize seekingSlider = _seekingSlider;
#endif
@synthesize volumeView = _volumeView;
#if !TARGET_OS_VISION
@synthesize routePickerView = _routePickerView;
#endif
@synthesize reasonForWaitingToPlayLabel = _reasonForWaitingToPlayLabel;

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayerLayer *)playerLayer {
    return static_cast<AVPlayerLayer *>(self.layer);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
#if !TARGET_OS_TV
        self.backgroundColor = UIColor.systemBackgroundColor;
#endif
        
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
            [stackView.heightAnchor constraintEqualToConstant:44.]
        ]];
        
        UILabel *reasonForWaitingToPlayLabel = self.reasonForWaitingToPlayLabel;
        reasonForWaitingToPlayLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:reasonForWaitingToPlayLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [reasonForWaitingToPlayLabel.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor],
            [reasonForWaitingToPlayLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [reasonForWaitingToPlayLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [reasonForWaitingToPlayLabel.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor]
        ]];
        
        [self updatePlaybackButton];
#if !TARGET_OS_TV
        [self updateSeekingSlider];
#endif
        [self updateReasonForWaitingToPlay];
        
        AVPlayerLayer *playerLayer = self.playerLayer;
        [playerLayer addObserver:self forKeyPath:@"player" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    if (AVPlayer *player = self.playerLayer.player) {
        [self removeObserverForPlayer:player];
    }
    
    [self.playerLayer removeObserver:self forKeyPath:@"player"];
    
    [_stackView release];
    [_playbackButton release];
#if !TARGET_OS_TV
    [_seekingSlider release];
#endif
    [_volumeView release];
#if !TARGET_OS_VISION
    [_routePickerView release];
#endif
    [_reasonForWaitingToPlayLabel release];
#if !TARGET_OS_TV
    [_periodicTimeObserver release];
#endif
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.playerLayer]) {
        if ([keyPath isEqualToString:@"player"]) {
            if (id oldPlayer = change[NSKeyValueChangeOldKey]) {
                if ([oldPlayer isKindOfClass:AVPlayer.class]) {
                    [self removeObserverForPlayer:static_cast<AVPlayer *>(oldPlayer)];
                }
            }
            
            if (id newPlayer = change[NSKeyValueChangeNewKey]) {
                if ([newPlayer isKindOfClass:AVPlayer.class]) {
                    [self addObserverForPlayer:static_cast<AVPlayer *>(newPlayer)];
                }
            }
            
            return;
        }
    } else if ([object isKindOfClass:AVPlayer.class]) {
        if ([keyPath isEqualToString:@"rate"] or [keyPath isEqualToString:@"status"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePlaybackButton];
            });
            
            return;
        } else if ([keyPath isEqualToString:@"reasonForWaitingToPlay"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateReasonForWaitingToPlay];
            });
            
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    MPVolumeView *volumeView = self.volumeView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.playbackButton,
#if !TARGET_OS_TV
        self.seekingSlider,
#endif
        volumeView,
#if !TARGET_OS_VISION
        self.routePickerView
#endif
    ]];
    
    [volumeView.widthAnchor constraintEqualToConstant:100.].active = YES;
    
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 8.;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)playbackButton {
    if (auto playbackButton = _playbackButton) return playbackButton;
    
    UIButton *playbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [playbackButton addTarget:self action:@selector(didTriggerPlaybackButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _playbackButton = [playbackButton retain];
    return playbackButton;
}

#if !TARGET_OS_TV
- (UISlider *)seekingSlider {
    if (auto seekingSlider = _seekingSlider) return seekingSlider;
    
    UISlider *seekingSlider = [UISlider new];
    seekingSlider.continuous = YES;
    
    [seekingSlider addTarget:self action:@selector(didTouchDownSeekingSlider:) forControlEvents:UIControlEventTouchDown];
    [seekingSlider addTarget:self action:@selector(didChangeSeekingSliderValue:) forControlEvents:UIControlEventValueChanged];
    [seekingSlider addTarget:self action:@selector(didTouchUpSeekingSlider:) forControlEvents:UIControlEventTouchUpInside];
    [seekingSlider addTarget:self action:@selector(didTouchUpSeekingSlider:) forControlEvents:UIControlEventTouchUpOutside];
    
    _seekingSlider = [seekingSlider retain];
    return [seekingSlider autorelease];
}
#endif

- (MPVolumeView *)volumeView {
    if (auto volumeView = _volumeView) return volumeView;
    
    MPVolumeView *volumeView = [MPVolumeView new];
    
    _volumeView = [volumeView retain];
    return [volumeView autorelease];
}

#if !TARGET_OS_VISION
- (AVRoutePickerView *)routePickerView {
    if (auto routePickerView = _routePickerView) return routePickerView;
    
    AVRoutePickerView *routePickerView = [AVRoutePickerView new];
    
    _routePickerView = [routePickerView retain];
    return [routePickerView autorelease];
}
#endif

- (UILabel *)reasonForWaitingToPlayLabel {
    if (auto reasonForWaitingToPlayLabel = _reasonForWaitingToPlayLabel) return reasonForWaitingToPlayLabel;
    
    UILabel *reasonForWaitingToPlayLabel = [UILabel new];
    reasonForWaitingToPlayLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    reasonForWaitingToPlayLabel.textColor = UIColor.labelColor;
#if !TARGET_OS_TV
    reasonForWaitingToPlayLabel.backgroundColor = UIColor.systemBackgroundColor;
#endif
    reasonForWaitingToPlayLabel.textAlignment = NSTextAlignmentCenter;
    
    _reasonForWaitingToPlayLabel = [reasonForWaitingToPlayLabel retain];
    return [reasonForWaitingToPlayLabel autorelease];
}

- (void)didTriggerPlaybackButton:(UIButton *)sender {
    AVPlayer * _Nullable player = self.playerLayer.player;
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
- (void)didTouchDownSeekingSlider:(UISlider *)sender {
    AVPlayer * _Nullable player = self.playerLayer.player;
    if (player == nil) return;
    
    self.wasPlaying = (player.rate > 0.);
    [player pause];
}

- (void)didChangeSeekingSliderValue:(UISlider *)sender {
    AVPlayer * _Nullable player = self.playerLayer.player;
    if (player == nil) return;
    
    CMTime time = CMTimeMake(sender.value, 1000000UL);
    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)didTouchUpSeekingSlider:(UISlider *)sender {
    AVPlayer * _Nullable player = self.playerLayer.player;
    if (player == nil) return;
    
    if (self.wasPlaying) {
        [player play];
    }
}
#endif

- (void)updatePlaybackButton {
    UIButtonConfiguration *configuration;
    BOOL isEnabled;
    
    if (AVPlayer *player = self.playerLayer.player) {
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
    
    UIButton *playbackButton = self.playbackButton;
    playbackButton.configuration = configuration;
    playbackButton.enabled = isEnabled;
}

#if !TARGET_OS_TV
- (void)updateSeekingSlider {
    UISlider *seekingSlider = self.seekingSlider;
    
    AVPlayer * _Nullable player = self.playerLayer.player;
    if (player == nil) {
        seekingSlider.enabled = NO;
        return;
    }
    
    seekingSlider.minimumValue = 0.;
    seekingSlider.maximumValue = CMTimeConvertScale(player.currentItem.duration, 1000000UL, kCMTimeRoundingMethod_Default).value;
    
    if (!seekingSlider.isTracking) {
        seekingSlider.value = CMTimeConvertScale(player.currentTime, 1000000UL, kCMTimeRoundingMethod_Default).value;
    }
    
    seekingSlider.enabled = YES;
}
#endif

- (void)updateReasonForWaitingToPlay {
    self.reasonForWaitingToPlayLabel.text = self.playerLayer.player.reasonForWaitingToPlay;
}

- (void)removeObserverForPlayer:(AVPlayer *)player {
    [player removeObserver:self forKeyPath:@"rate"];
    [player removeObserver:self forKeyPath:@"status"];
    [player removeObserver:self forKeyPath:@"reasonForWaitingToPlay"];
    
#if !TARGET_OS_TV
    assert(self.periodicTimeObserver != nil);
    [player removeTimeObserver:self.periodicTimeObserver];
#endif
}

- (void)addObserverForPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"reasonForWaitingToPlay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
#if !TARGET_OS_TV
    __weak auto weakSelf = self;
    self.periodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateSeekingSlider];
    }];
#endif
}

@end
