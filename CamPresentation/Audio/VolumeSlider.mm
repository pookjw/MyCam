//
//  VolumeSlider.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/17/24.
//

#import <CamPresentation/VolumeSlider.h>
#import <objc/message.h>
#import <objc/runtime.h>

/*
 MPVolumeController
 MPVolumeHUDController
 */

@interface VolumeSlider ()
@property (retain, nonatomic, readonly) id volumeController;
@end

@implementation VolumeSlider
@synthesize volumeController = _volumeController;

+ (void)load {
    Protocol *MPVolumeControllerDelegate = NSProtocolFromString(@"MPVolumeControllerDelegate");
    assert(MPVolumeControllerDelegate != nil);
    assert(class_addProtocol(self, MPVolumeControllerDelegate));
    
    Protocol *MPVolumeDisplaying = NSProtocolFromString(@"MPVolumeDisplaying");
    assert(MPVolumeDisplaying != nil);
    assert(class_addProtocol(self, MPVolumeDisplaying));
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    
    return self;
}

- (void)dealloc {
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(_volumeController, sel_registerName("setDelegate:"), nil);
    [_volumeController release];
    
    [super dealloc];
}

- (id)volumeController {
    if (id volumeController = _volumeController) return volumeController;
    
    id volumeController = [objc_lookUpClass("MPVolumeController") new];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(volumeController, sel_registerName("setDelegate:"), self);
    
    _volumeController = [volumeController retain];
    return [volumeController autorelease];
}

- (float)maximumValue {
    return 1.f;
}

- (float)minimumValue {
    return 1.f;
}

- (void)setValue:(float)value animated:(BOOL)animated {
    reinterpret_cast<void (*)(id, SEL, float, BOOL)>(objc_msgSend)(self.volumeController, sel_registerName("setVolume:withNotificationDelay:"), value, animated);
    [super setValue:value animated:animated];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.isEnabled) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.volumeController, sel_registerName("setMuted:"), NO);
    }
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self _commitVolumeChange];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self _commitVolumeChange];
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [self _commitVolumeChange];
    [super cancelTrackingWithEvent:event];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    id controller = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("MPVolumeHUDController"), sel_registerName("sharedInstance"));
    
    if (self.window == nil) {
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(controller, sel_registerName("removeVolumeDisplay:"), self);
    } else {
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(controller, sel_registerName("addVolumeDisplay:"), self);
    }
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    id controller = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("MPVolumeHUDController"), sel_registerName("sharedInstance"));
    reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controller, sel_registerName("setNeedsUpdate"));
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    id controller = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("MPVolumeHUDController"), sel_registerName("sharedInstance"));
    reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controller, sel_registerName("setNeedsUpdate"));
}

- (void)_commitVolumeChange {
    reinterpret_cast<void (*)(id, SEL, float)>(objc_msgSend)(self.volumeController, sel_registerName("setVolumeValue:"), self.value);
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)_updateVolumeAnimated:(BOOL)animated silenceVolumeHUD:(BOOL)silenceVolumeHUD {
    id volumeController = self.volumeController;
    
    BOOL isVolumeControlAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(volumeController, sel_registerName("isVolumeControlAvailable"));
    self.enabled = isVolumeControlAvailable;
    
    float volumeValue = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(volumeController, sel_registerName("volumeValue"));
    
    if (self.value != volumeValue) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}


#pragma mark - MPVolumeControllerDelegate

- (void)volumeController:(id)volumeControler volumeValueDidChange:(float)arg2 {
    
}

- (void)volumeController:(id)volumeControler volumeControlAvailableDidChange:(BOOL)arg2 {
    
}

- (void)volumeController:(id)volumeControler volumeControlCapabilitiesDidChange:(unsigned int)arg2 {
    
}

- (void)volumeController:(id)volumeControler volumeValueDidChange:(float)arg2 silenceVolumeHUD:(BOOL)arg3 {
    
}

- (void)volumeController:(id)volumeControler volumeControlLabelDidChange:(id)arg2 {
    
}

- (void)volumeController:(id)volumeControler EUVolumeLimitDidChange:(float)arg2 {
    
}

- (void)volumeController:(id)volumeControler EUVolumeLimitEnforcedDidChange:(BOOL)arg2 {
    
}

- (void)volumeController:(id)volumeControler mutedStateDidChange:(BOOL)arg2 {
    
}

- (void)volumeController:(id)volumeControler volumeWarningStateDidChange:(long)arg2 {
    
}


#pragma mark - MPVolumeDisplaying

- (id)volumeAudioCategory {
    return reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self.volumeController, sel_registerName("volumeAudioCategory"));
}

- (BOOL)isOnScreen {
    abort();
}

- (BOOL)isOnScreenForVolumeDisplay {
    if (self.window == nil) return NO;
    if (self.isHidden) return NO;
    if (self.alpha <= 0.) return NO;
    if (self.superview == nil) return NO;
    return YES;
}

- (id)windowSceneForVolumeDisplay {
    return self.window.windowScene;
}

@end
