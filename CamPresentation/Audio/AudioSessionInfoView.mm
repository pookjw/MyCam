//
//  AudioSessionInfoView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/AudioSessionInfoView.h>
#import <CamPresentation/NSStringFromAVAudioSessionRenderingMode.h>

@interface AudioSessionInfoView ()
@property (retain, nonatomic, readonly) AVAudioSession *audioSession;
@property (retain, nonatomic, readonly) UILabel *label;
@end

@implementation AudioSessionInfoView
@synthesize label = _label;

- (instancetype)initWithAudioSession:(AVAudioSession *)audioSession {
    if (self = [super initWithFrame:CGRectNull]) {
        _audioSession = [audioSession retain];
        
        UILabel *label = self.label;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:self.topAnchor],
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveRenderingModeChangeNotification:) name:AVAudioSessionRenderingModeChangeNotification object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveInterruptionNotification:) name:@"AVAudioSessionPickableRouteChangeNotification" object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSilenceSecondaryAudioHintNotification:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:audioSession];
        
        [self updateLabel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_audioSession release];
    [_label release];
    [super dealloc];
}

- (void)didReceiveRenderingModeChangeNotification:(NSNotification *)notification {
//    AVAudioSessionRenderingModeNewRenderingModeKey
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (void)didReceiveInterruptionNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (void)didReceiveSilenceSecondaryAudioHintNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textAlignment = NSTextAlignmentCenter;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)updateLabel {
    self.label.text = [NSString stringWithFormat:@"Rendering Mode : %@\nisOtherAudioPlaying : %d\nsecondaryAudioShouldBeSilencedHint : %d", NSStringFromAVAudioSessionRenderingMode(self.audioSession.renderingMode), self.audioSession.isOtherAudioPlaying, self.audioSession.secondaryAudioShouldBeSilencedHint];
}

@end
