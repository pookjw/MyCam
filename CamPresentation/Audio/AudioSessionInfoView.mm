//
//  AudioSessionInfoView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#warning -[AVAudioSession interruptionPriority]
#warning setPrefersNoInterruptionsByRingtonesAndAlerts

#import <CamPresentation/AudioSessionInfoView.h>
#import <CamPresentation/NSStringFromAVAudioSessionRenderingMode.h>
#import <CamPresentation/NSStringFromAVAudioSessionRouteChangeReason.h>
#import <CamPresentation/NSStringFromAVAudioSessionInterruptionReason.h>
#import <CamPresentation/NSStringFromAVAudioSessionInterruptionType.h>
#import <CamPresentation/NSStringFromAVAudioSessionInterruptionOptions.h>
#import <CamPresentation/NSStringFromAVAudioSessionPromptStyle.h>

@interface AudioSessionInfoView ()
@property (retain, nonatomic, readonly) AVAudioSession *audioSession;
@property (retain, nonatomic, readonly) UILabel *label;
@property (copy, nonatomic, nullable) NSNumber *routeChangeReasonNumber;

@property (copy, nonatomic, nullable) NSNumber *interruptionTypeNumber;
@property (copy, nonatomic, nullable) NSNumber *interruptionOptionsNumber;
@property (copy, nonatomic, nullable) NSNumber *interruptionReasonNumber;
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
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSilenceSecondaryAudioHintNotification:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSpatialPlaybackCapabilitiesChangedNotification:) name:AVAudioSessionSpatialPlaybackCapabilitiesChangedNotification object:audioSession];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveRenderingCapabilitiesChangeNotification:) name:AVAudioSessionRenderingCapabilitiesChangeNotification object:audioSession];
        
        [audioSession addObserver:self forKeyPath:@"promptStyle" options:NSKeyValueObservingOptionNew context:nil];
        [audioSession addObserver:self forKeyPath:@"sampleRate" options:NSKeyValueObservingOptionNew context:nil];
        
        // KVO 안 됨
//        [audioSession addObserver:self forKeyPath:@"IOBufferDuration" options:NSKeyValueObservingOptionNew context:nil];
        
        [audioSession addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
        [audioSession addObserver:self forKeyPath:@"inputNumberOfChannels" options:NSKeyValueObservingOptionNew context:nil];
        [audioSession addObserver:self forKeyPath:@"outputNumberOfChannels" options:NSKeyValueObservingOptionNew context:nil];
        
        [self updateLabel];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_audioSession removeObserver:self forKeyPath:@"promptStyle"];
    [_audioSession removeObserver:self forKeyPath:@"sampleRate"];
//    [_audioSession removeObserver:self forKeyPath:@"IOBufferDuration"];
    [_audioSession removeObserver:self forKeyPath:@"outputVolume"];
    [_audioSession removeObserver:self forKeyPath:@"inputNumberOfChannels"];
    [_audioSession removeObserver:self forKeyPath:@"outputNumberOfChannels"];
    [_audioSession release];
    [_label release];
    [_routeChangeReasonNumber release];
    [_interruptionOptionsNumber release];
    [_interruptionReasonNumber release];
    [_interruptionTypeNumber release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.audioSession]) {
        if ([keyPath isEqualToString:@"promptStyle"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"sampleRate"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
//        } else if ([keyPath isEqualToString:@"IOBufferDuration"]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self updateLabel];
//            });
//            return;
        } else if ([keyPath isEqualToString:@"outputVolume"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"inputNumberOfChannels"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        } else if ([keyPath isEqualToString:@"outputNumberOfChannels"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLabel];
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)didReceiveRenderingModeChangeNotification:(NSNotification *)notification {
//    AVAudioSessionRenderingModeNewRenderingModeKey
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (void)didReceiveInterruptionNotification:(NSNotification *)notification {
    NSNumber *interruptionTypeNumber = notification.userInfo[AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOptionsNumber = notification.userInfo[AVAudioSessionInterruptionOptionKey];
    NSNumber *interruptionReasonNumber = notification.userInfo[AVAudioSessionInterruptionReasonKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interruptionTypeNumber = interruptionTypeNumber;
        self.interruptionOptionsNumber = interruptionOptionsNumber;
        self.interruptionReasonNumber = interruptionReasonNumber;
        [self updateLabel];
    });
}

- (void)didReceiveSilenceSecondaryAudioHintNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (void)didReceiveRouteChangeNotification:(NSNotification *)notification {
    NSNumber *routeChangeReasonNumber = notification.userInfo[AVAudioSessionRouteChangeReasonKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.routeChangeReasonNumber = routeChangeReasonNumber;
        [self updateLabel];
    });
}

- (void)didReceiveSpatialPlaybackCapabilitiesChangedNotification:(NSNotification *)notification {
    // AVAudioSessionSpatialAudioEnabledKey
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLabel];
    });
}

- (void)didReceiveRenderingCapabilitiesChangeNotification:(NSNotification *)notification {
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
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.001;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)updateLabel {
    NSMutableString *string = [NSMutableString new];
    
    [string appendFormat:@"Rendering Mode : %@", NSStringFromAVAudioSessionRenderingMode(self.audioSession.renderingMode)];
    
    [string appendString:@"\n"];
    [string appendFormat:@"isOtherAudioPlaying : %d", self.audioSession.isOtherAudioPlaying];
    
    [string appendString:@"\n"];
    [string appendFormat:@"secondaryAudioShouldBeSilencedHint : %d", self.audioSession.secondaryAudioShouldBeSilencedHint];
    
    [string appendString:@"\n"];
    [string appendFormat:@"sampleRate : %lf", self.audioSession.sampleRate];
    
    [string appendString:@"\n"];
    [string appendFormat:@"IOBufferDuration : %lf", self.audioSession.IOBufferDuration];
    
    [string appendString:@"\n"];
    [string appendFormat:@"inputLatency : %lf", self.audioSession.inputLatency];
    
    [string appendString:@"\n"];
    [string appendFormat:@"outputLatency : %lf", self.audioSession.outputLatency];
    
    [string appendString:@"\n"];
    [string appendFormat:@"outputVolume : %lf", self.audioSession.outputVolume];
    
    [string appendString:@"\n"];
    [string appendFormat:@"inputNumberOfChannels : %ld", self.audioSession.inputNumberOfChannels];
    
    [string appendString:@"\n"];
    [string appendFormat:@"outputNumberOfChannels : %ld", self.audioSession.outputNumberOfChannels];
    
    [string appendString:@"\n"];
    [string appendFormat:@"supportsMultichannelContent : %d", self.audioSession.supportsMultichannelContent];
    
    [string appendString:@"\n"];
    [string appendFormat:@"supportedOutputChannelLayouts count : %ld", self.audioSession.supportedOutputChannelLayouts.count];
    
    [string appendString:@"\n"];
    [string appendFormat:@"currentRoute : %p (inputs : %ld, outputs : %ld)", self.audioSession.currentRoute, self.audioSession.currentRoute.inputs.count, self.audioSession.currentRoute.outputs.count];
    
//    if (self.audioSession.currentRoute.inputs.count > 0) {
//        NSMutableArray<AVAudioSessionPort> *ports = [[NSMutableArray alloc] initWithCapacity:self.audioSession.currentRoute.inputs.count];
//        
//        for (AVAudioSessionPortDescription *desc in self.audioSession.currentRoute.inputs) {
//            [ports addObject:desc.portType];
//        }
//        
//        [string appendString:@"\n"];
//        [string appendFormat:@"Input Port Types : %@", [ports componentsJoinedByString:@", "]];
//        [ports release];
//    }
//    
//    if (self.audioSession.currentRoute.outputs.count > 0) {
//        NSMutableArray<AVAudioSessionPort> *ports = [[NSMutableArray alloc] initWithCapacity:self.audioSession.currentRoute.outputs.count];
//        
//        for (AVAudioSessionPortDescription *desc in self.audioSession.currentRoute.outputs) {
//            [ports addObject:desc.portType];
//        }
//        
//        [string appendString:@"\n"];
//        [string appendFormat:@"Output Port Types : %@", [ports componentsJoinedByString:@", "]];
//        [ports release];
//    }
    
    BOOL isSpatialAudioEnabled = NO;
    for (AVAudioSessionPortDescription *output in self.audioSession.currentRoute.outputs) {
        if (output.isSpatialAudioEnabled) {
            isSpatialAudioEnabled = YES;
            break;
        }
    }
    [string appendString:@"\n"];
    [string appendFormat:@"isSpatialAudioEnabled : %d", isSpatialAudioEnabled];
    
    if (NSNumber *routeChangeReasonNumber = self.routeChangeReasonNumber) {
        [string appendString:@"\n"];
        [string appendFormat:@"routeChangeReason : %@", NSStringFromAVAudioSessionRouteChangeReason(static_cast<AVAudioSessionRouteChangeReason>(routeChangeReasonNumber.unsignedIntegerValue))];
    }
    
    [string appendString:@"\n"];
    [string appendFormat:@"promptStyle : %@", NSStringFromAVAudioSessionPromptStyle(self.audioSession.promptStyle)];
    
    if (NSNumber *interruptionTypeNumber = self.interruptionTypeNumber) {
        [string appendString:@"\n"];
        [string appendFormat:@"interruptionType : %@", NSStringFromAVAudioSessionInterruptionType(static_cast<AVAudioSessionInterruptionType>(interruptionTypeNumber.unsignedIntegerValue))];
    }
    
    if (NSNumber *interruptionOptionsNumber = self.interruptionOptionsNumber) {
        [string appendString:@"\n"];
        [string appendFormat:@"interruptionOptions : %@", NSStringFromAVAudioSessionInterruptionOptions(static_cast<AVAudioSessionInterruptionOptions>(interruptionOptionsNumber.unsignedIntegerValue))];
    }
    
    if (NSNumber *interruptionReasonNumber = self.interruptionReasonNumber) {
        [string appendString:@"\n"];
        [string appendFormat:@"interruptionReason : %@", NSStringFromAVAudioSessionInterruptionReason(static_cast<AVAudioSessionInterruptionReason>(interruptionReasonNumber.unsignedIntegerValue))];
    }
    
    self.label.text = string;
    [string release];
}

@end
