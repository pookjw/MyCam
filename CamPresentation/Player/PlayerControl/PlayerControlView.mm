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
#import <os/lock.h>

@interface PlayerControlView () {
    os_unfair_lock _currentItemLock; // https://x.com/_silgen_name/status/1862891777839309219
}
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
#if !TARGET_OS_TV
@property (assign, nonatomic) BOOL _wasPlaying;
#endif
@property (retain, nonatomic, nullable) AVPlayerItem *_observingPlayerItem;
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
    if (AVPlayer *player = _player) {
        // removeObserver는 즉시 반영되지 않을 것이기에 lock을 먼저 건다.
        os_unfair_lock_lock(&_currentItemLock);
        [self _removeObserversForPlayer:player];
        
        if (AVPlayerItem *observingPlayerItem = self._observingPlayerItem) {
            [self _removeObserversForPlayerItem:observingPlayerItem];
        }
        os_unfair_lock_unlock(&_currentItemLock);
        
        [player release];
    }
    
    [__stackView release];
    [__playbackButton release];
    [__seekingSlider release];
    [__volumeView release];
    [__routePickerView release];
    [__reasonForWaitingToPlayLabel release];
    [__periodicTimeObserver release];
    [__observingPlayerItem release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVPlayer.class]) {
        if ([keyPath isEqualToString:@"rate"] or [keyPath isEqualToString:@"status"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                assert([self.player isEqual:object]);
                [self _updateAttributes];
            });
            return;
        } else if ([keyPath isEqualToString:@"reasonForWaitingToPlay"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                assert([self.player isEqual:object]);
                [self _updateReasonForWaitingToPlay];
            });
            return;
        } else if ([keyPath isEqualToString:@"currentItem"]) {
            os_unfair_lock_lock(&_currentItemLock);
            
            if (AVPlayerItem *oldPlayerItem = change[NSKeyValueChangeOldKey]) {
                [self _removeObserversForPlayerItem:oldPlayerItem];
            }
            
            if (AVPlayerItem *newPlayerItem = change[NSKeyValueChangeNewKey]) {
                [self _addObserversForPlayerItem:newPlayerItem];
                self._observingPlayerItem = newPlayerItem;
            } else if (AVPlayerItem *playerItem = self.player.currentItem) {
                // Initial
                [self _addObserversForPlayerItem:newPlayerItem];
                self._observingPlayerItem = playerItem;
            }
            
            os_unfair_lock_unlock(&_currentItemLock);
            return;
        }
    } else if ([object isKindOfClass:AVPlayerItem.class]) {
        if ([keyPath isEqualToString:@"duration"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [PlayerControlView _updateSeekingSlider:self._seekingSlider player:self.player currentTime:kCMTimeInvalid];
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(200., 40.);
}

- (void)_commonInit {
    _currentItemLock = OS_UNFAIR_LOCK_INIT;
    
    UIStackView *stackView = self._stackView;
    UILabel *reasonForWaitingToPlayLabel = self._reasonForWaitingToPlayLabel;
    
    [self addSubview:stackView];
    [self addSubview:reasonForWaitingToPlayLabel];
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), reasonForWaitingToPlayLabel);
    
    [self _updateAttributes];
}

- (void)setPlayer:(AVPlayer *)player {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (_player) {
        // removeObserver는 즉시 반영되지 않을 것이기에 lock을 먼저 건다.
        os_unfair_lock_lock(&_currentItemLock);
        
        [self _removeObserversForPlayer:_player];
        if (AVPlayerItem *observingPlayerItem = self._observingPlayerItem) {
            [self _removeObserversForPlayerItem:observingPlayerItem];
        }
        
        os_unfair_lock_unlock(&_currentItemLock);
        
        [_player release];
    }
    
    if (player) {
        _player = [player retain];
        [self _addObserversForPlayer:player];
    } else {
        _player = nil;
    }
    
    [self _updateAttributes];
}

- (UIStackView *)_stackView {
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

- (UIButton *)_playbackButton {
    if (auto playbackButton = __playbackButton) return playbackButton;
    
    UIButton *playbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [playbackButton addTarget:self action:@selector(_didTriggerPlaybackButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    __playbackButton = [playbackButton retain];
    return playbackButton;
}

#if TARGET_OS_TV
- (TVSlider *)_seekingSlider {
    if (auto seekingSlider = __seekingSlider) return seekingSlider;
    
    TVSlider *seekingSlider = [TVSlider new];
    seekingSlider.continuous = YES;
    
    __block auto unretained = self;
    [seekingSlider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained _didChangeSeekingSliderValue:static_cast<TVSlider *>(action.sender)];
    }]];
    
    __seekingSlider = [seekingSlider retain];
    return [seekingSlider autorelease];
}
#else
- (UISlider *)_seekingSlider {
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

- (MPVolumeView *)_volumeView {
    if (auto volumeView = __volumeView) return volumeView;
    
    MPVolumeView *volumeView = [MPVolumeView new];
    
    __volumeView = [volumeView retain];
    return [volumeView autorelease];
}

#if !TARGET_OS_VISION
- (AVRoutePickerView *)_routePickerView {
    if (auto routePickerView = __routePickerView) return routePickerView;
    
    AVRoutePickerView *routePickerView = [AVRoutePickerView new];
    
    __routePickerView = [routePickerView retain];
    return [routePickerView autorelease];
}
#endif

- (UILabel *)_reasonForWaitingToPlayLabel {
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
    
    self._seekingSlider.enabled = isEnabled;
    [PlayerControlView _updateSeekingSlider:self._seekingSlider player:self.player currentTime:kCMTimeInvalid];
    [self _updateReasonForWaitingToPlay];
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
    [player removeObserver:self forKeyPath:@"currentItem"];
    
    assert(self._periodicTimeObserver != nil);
    [player removeTimeObserver:self._periodicTimeObserver];
}

- (void)_addObserversForPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"reasonForWaitingToPlay" options:NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
    auto seekingSlider = self._seekingSlider;
    
    self._periodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [PlayerControlView _updateSeekingSlider:seekingSlider player:player currentTime:time];
    }];
}

- (void)_removeObserversForPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"duration"];
}

- (void)_addObserversForPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:NULL];
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

#if TARGET_OS_TV
- (void)_didChangeSeekingSliderValue:(TVSlider *)sender {
    AVPlayer * _Nullable player = self.player;
    if (player == nil) return;
    
    [player pause];
    
    CMTime time = CMTimeMake(sender.value, 1000000UL);
    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
#else
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
+ (void)_updateSeekingSlider:(TVSlider *)seekingSlider player:(AVPlayer * _Nullable)player currentTime:(CMTime)currentTime
#else
+ (void)_updateSeekingSlider:(UISlider *)seekingSlider player:(AVPlayer * _Nullable)player currentTime:(CMTime)currentTime
#endif
{
    if (player == nil) {
        seekingSlider.enabled = NO;
        return;
    }
    
    if (CMTIME_IS_INVALID(currentTime)) {
        currentTime = player.currentTime;
    }
    
    seekingSlider.minimumValue = 0.;
    seekingSlider.maximumValue = CMTimeConvertScale(player.currentItem.duration, 1000000UL, kCMTimeRoundingMethod_Default).value;
    seekingSlider.stepValue = (seekingSlider.maximumValue - seekingSlider.minimumValue) / 100.f;
    
#if TARGET_OS_TV
    if (!seekingSlider.isEditing) {
        seekingSlider.value = CMTimeConvertScale(player.currentTime, 1000000UL, kCMTimeRoundingMethod_Default).value;
    }
#else
    if (!seekingSlider.isTracking) {
        seekingSlider.value = CMTimeConvertScale(currentTime, 1000000UL, kCMTimeRoundingMethod_Default).value;
    }
#endif
    
    seekingSlider.enabled = YES;
}

@end
