//
//  NSStringFromAVAudioSessionPromptStyle.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/17/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionPromptStyle.h>

NSString * NSStringFromAVAudioSessionPromptStyle(AVAudioSessionPromptStyle promptStyle) {
    switch (promptStyle) {
        case AVAudioSessionPromptStyleNone:
            return @"None";
        case AVAudioSessionPromptStyleShort:
            return @"Short";
        case AVAudioSessionPromptStyleNormal:
            return @"Normal";
        default:
            abort();
    }
}
