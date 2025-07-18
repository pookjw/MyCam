//
//  NSStringFromAVAudioSessionRouteSharingPolicy.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/15/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionRouteSharingPolicy.h>

NSString * NSStringFromAVAudioSessionRouteSharingPolicy(AVAudioSessionRouteSharingPolicy routeSharingPolicy) {
    switch (routeSharingPolicy) {
        case AVAudioSessionRouteSharingPolicyDefault:
            return @"Default";
        case AVAudioSessionRouteSharingPolicyLongFormAudio:
            return @"Long Form Audio";
#if !TARGET_OS_TV
        case AVAudioSessionRouteSharingPolicyLongFormVideo:
            return @"Long Form Video";
#else
        case 3:
            return @"Long Form Video";
#endif
        case AVAudioSessionRouteSharingPolicyIndependent:
            return @"Independent";
        default:
            abort();
    }
}
