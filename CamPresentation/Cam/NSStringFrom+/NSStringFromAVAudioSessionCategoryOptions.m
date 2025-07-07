//
//  NSStringFromAVAudioSessionCategoryOptions.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/NSStringFromAVAudioSessionCategoryOptions.h>

NSString * NSStringFromAVAudioSessionCategoryOptions(AVAudioSessionCategoryOptions audioSessionCategoryOptions) {
    NSMutableArray<NSString *> *array = [NSMutableArray new];
    
    // 오타 아님. bit가 겹치기 때문 (0x11, 0x1)
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers) {
        [array addObject:@"Mix With Others"];
    }
    
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionDuckOthers) == AVAudioSessionCategoryOptionDuckOthers) {
        [array addObject:@"Duck Others"];
    }
    
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth) {
        [array addObject:@"Allow Bluetooth"];
    }
    
#if !TARGET_OS_TV
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionDefaultToSpeaker) == AVAudioSessionCategoryOptionDefaultToSpeaker) {
        [array addObject:@"Default To Speaker"];
    }
#endif
    
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) == AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers) {
        [array addObject:@"Interrupt Spoken Audio And Mix With Others"];
    }
    
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionAllowBluetoothA2DP) == AVAudioSessionCategoryOptionAllowBluetoothA2DP) {
        [array addObject:@"Allow Bluetooth A2DP"];
    }
    
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionAllowAirPlay) == AVAudioSessionCategoryOptionAllowAirPlay) {
        [array addObject:@"Allow AirPlay"];
    }
    
#if !TARGET_OS_TV
    if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption) == AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption) {
        [array addObject:@"Override Muted Microphone Interruption"];
    }
#endif
    
    if (@available(iOS 26.0, *)) {
        if ((audioSessionCategoryOptions & AVAudioSessionCategoryOptionBluetoothHighQualityRecording) == AVAudioSessionCategoryOptionBluetoothHighQualityRecording) {
            [array addObject:@"Bluetooth High Quality Recording"];
        }
    } else if (@available(watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, macOS 26.0, *)) {
        if ((audioSessionCategoryOptions & (1 << 19)) == (1 << 19)) {
            [array addObject:@"Bluetooth High Quality Recording"];
        }
    }
    
    NSString *string = [array componentsJoinedByString:@", "];
    [array release];
    
    return string;
}
