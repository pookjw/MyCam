//
//  NSStringFromAVAudioSessionInterruptionType.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionInterruptionType.h>

NSString * NSStringFromAVAudioSessionInterruptionType(AVAudioSessionInterruptionType interruptionType) {
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            return @"Began";
        case AVAudioSessionInterruptionTypeEnded:
            return @"Ended";
        default:
            abort();
    }
}
