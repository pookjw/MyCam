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
        case AVAudioSessionRouteSharingPolicyLongFormVideo:
            return @"Long Form Video";
        case AVAudioSessionRouteSharingPolicyIndependent:
            return @"Independent";
        default:
            abort();
    }
}
