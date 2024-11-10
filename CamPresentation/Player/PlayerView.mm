//
//  PlayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/9/24.
//

#import <CamPresentation/PlayerView.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerView ()
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *playbackButton;
@property (retain, nonatomic, readonly) UISlider *seekingSlider;
@property (retain, nonatomic, readonly) MPVolumeView *volumeView;
@property (retain, nonatomic, nullable) id periodicTimeObserver;
@property (assign, nonatomic) BOOL wasPlaying;
@end

@implementation PlayerView
@synthesize stackView = _stackView;
@synthesize playbackButton = _playbackButton;
@synthesize seekingSlider = _seekingSlider;
@synthesize volumeView = _volumeView;

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayerLayer *)playerLayer {
    return static_cast<AVPlayerLayer *>(self.layer);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.systemBackgroundColor;
        
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stackView];
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
            [stackView.heightAnchor constraintEqualToConstant:44.]
        ]];
        
        [self updatePlaybackButton];
        
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
    [_seekingSlider release];
    [_volumeView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.playerLayer]) {
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
    } else if ([object isKindOfClass:AVPlayer.class]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePlaybackButton];
        });
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    MPVolumeView *volumeView = self.volumeView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.playbackButton,
        self.seekingSlider,
        volumeView
    ]];
    
    [volumeView.widthAnchor constraintEqualToConstant:100.].active = YES;
    
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
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

- (MPVolumeView *)volumeView {
    if (auto volumeView = _volumeView) return volumeView;
    
    MPVolumeView *volumeView = [MPVolumeView new];
    
    _volumeView = [volumeView retain];
    return [volumeView autorelease];
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

- (void)removeObserverForPlayer:(AVPlayer *)player {
    [player removeObserver:self forKeyPath:@"rate"];
    [player removeObserver:self forKeyPath:@"status"];
    
    assert(self.periodicTimeObserver != nil);
    [player removeTimeObserver:self.periodicTimeObserver];
}

- (void)addObserverForPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    
    __weak auto weakSelf = self;
    self.periodicTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateSeekingSlider];
    }];
}

@end
