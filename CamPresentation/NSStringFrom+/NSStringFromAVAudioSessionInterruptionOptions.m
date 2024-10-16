//
//  NSStringFromAVAudioSessionInterruptionOptions.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionInterruptionOptions.h>

NSString *NSStringFromAVAudioSessionInterruptionOptions(AVAudioSessionInterruptionOptions interruptionOptions) {
    NSMutableArray<NSString *> *array = [NSMutableArray new];
    
    if ((interruptionOptions & AVAudioSessionInterruptionOptionShouldResume) == AVAudioSessionInterruptionOptionShouldResume) {
        [array addObject:@"Should Resume"];
    }
    
    NSString *string = [array componentsJoinedByString:@", "];
    [array release];
    
    return string;
}
