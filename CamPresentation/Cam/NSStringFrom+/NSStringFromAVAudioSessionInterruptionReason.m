//
//  NSStringFromAVAudioSessionInterruptionReason.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionInterruptionReason.h>
#import <TargetConditionals.h>

NSString * NSStringFromAVAudioSessionInterruptionReason(AVAudioSessionInterruptionReason interruptionReason) {
    switch (interruptionReason) {
        case AVAudioSessionInterruptionReasonDefault:
            return @"Default";
        case AVAudioSessionInterruptionReasonBuiltInMicMuted:
            return @"Built-In Mic Muted";
        case AVAudioSessionInterruptionReasonRouteDisconnected:
            return @"Route Disconnected";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        case AVAudioSessionInterruptionReasonAppWasSuspended:
            return @"App Was Suspended";
#pragma clang diagnostic pop
#if TARGET_OS_VISION
        case AVAudioSessionInterruptionReasonSceneWasBackgrounded:
            return @"Scene Was Backgrounded";
#endif
        default:
            abort();
    }
}
