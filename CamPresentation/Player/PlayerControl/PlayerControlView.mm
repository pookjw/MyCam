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
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
}

@end
