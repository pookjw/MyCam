//
//  NSStringFromAVAudioSessionRenderingMode.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/15/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionRenderingMode.h>

NSString * NSStringFromAVAudioSessionRenderingMode(AVAudioSessionRenderingMode renderingMode) {
    switch (renderingMode) {
        case AVAudioSessionRenderingModeNotApplicable:
            return @"Not Applicable";
        case AVAudioSessionRenderingModeMonoStereo:
            return @"Mono Stereo";
        case AVAudioSessionRenderingModeSurround:
            return @"Surround";
        case AVAudioSessionRenderingModeSpatialAudio:
            return @"Spatial Audio";
        case AVAudioSessionRenderingModeDolbyAudio:
            return @"Dolby Audio";
        case AVAudioSessionRenderingModeDolbyAtmos:
            return @"Dolby Atmos";
        default:
            abort();
    }
}
