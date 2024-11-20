//
//  NSStringFromAVAudioSessionPortOverride.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/18/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionPortOverride.h>

NSString * NSStringFromAVAudioSessionPortOverride(AVAudioSessionPortOverride portOverride) {
    switch (portOverride) {
        case AVAudioSessionPortOverrideNone:
            return @"None";
#if !TARGET_OS_TV
        case AVAudioSessionPortOverrideSpeaker:
            return @"Speaker";
#endif
        default:
            abort();
    }
}
