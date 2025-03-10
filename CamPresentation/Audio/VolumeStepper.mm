//
//  VolumeStepper.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/17/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <CamPresentation/VolumeStepper.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VolumeStepper ()
@property (retain, nonatomic, readonly) MPVolumeView *volumeView;
@property (nonatomic, readonly) __kindof UISlider *volumeSlider;
@end

@implementation VolumeStepper
@synthesize volumeView = _volumeView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        __kindof UISlider *volumeSlider = self.volumeSlider;
        
        // HUD 방지
        [self addSubview:volumeSlider];
        volumeSlider.hidden = YES;
        object_setInstanceVariable(volumeSlider, "_forcingOffscreenVisibility", reinterpret_cast<void *>(YES));
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(volumeSlider, sel_registerName("_setIsOffScreen:"), NO);
        
        [volumeSlider addTarget:self action:@selector(didVolumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        self.stepValue = 0.1;
        self.minimumValue = 0.;
        self.maximumValue = 1.f;
    }
    
    return self;
}

- (void)dealloc {
    [_volumeView release];
    [super dealloc];
}

- (void)setValue:(double)value {
    [self.volumeSlider setValue:value animated:YES];
    [super setValue:value];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.volumeSlider.value = self.value;
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.volumeSlider.value = self.value;
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.volumeSlider.value = self.value;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    self.volumeSlider.value = self.value;
    [super cancelTrackingWithEvent:event];
}

- (MPVolumeView *)volumeView {
    if (auto volumeView = _volumeView) return volumeView;
    
    MPVolumeView *volumeView = [MPVolumeView new];
    
    _volumeView = [volumeView retain];
    return [volumeView autorelease];
}

- (__kindof UISlider *)volumeSlider {
    __kindof UISlider *volumeSlider = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self.volumeView, sel_registerName("volumeSlider"));
    return volumeSlider;
}

- (void)didVolumeSliderValueChanged:(__kindof UISlider *)sender {
    self.value = sender.value;
}

@end

#endif
