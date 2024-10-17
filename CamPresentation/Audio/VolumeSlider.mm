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

+ (void)load {
    Protocol *MPVolumeControllerDelegate = NSProtocolFromString(@"MPVolumeControllerDelegate");
    assert(MPVolumeControllerDelegate != nil);
    assert(class_addProtocol(self, MPVolumeControllerDelegate));
    
    Protocol *MPVolumeDisplaying = NSProtocolFromString(@"MPVolumeDisplaying");
    assert(MPVolumeDisplaying != nil);
    assert(class_addProtocol(self, MPVolumeDisplaying));
}

- (id)volumeController {
//    if (auto volumeController = _volumeController) return volumeController;
    abort();
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
