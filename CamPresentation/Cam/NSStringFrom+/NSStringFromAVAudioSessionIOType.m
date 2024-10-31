//
//  NSStringFromAVAudioSessionIOType.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/18/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionIOType.h>

NSString * NSStringFromAVAudioSessionIOType(AVAudioSessionIOType IOType) {
    switch (IOType) {
        case AVAudioSessionIOTypeNotSpecified:
            return @"Not Specified";
        case AVAudioSessionIOTypeAggregated:
            return @"Aggregated";
        default:
            abort();
    }
}
