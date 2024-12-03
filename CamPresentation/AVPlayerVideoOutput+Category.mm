//
//  AVPlayerVideoOutput+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/3/24.
//

#import <CamPresentation/AVPlayerVideoOutput+Category.h>
#import <VideoToolbox/VideoToolbox.h>

@implementation AVPlayerVideoOutput (Category)

// https://x.com/_silgen_name/status/1863893603548111284

+ (BOOL)cp_isSupported {
    if (!VTIsStereoMVHEVCDecodeSupported()) return NO;
    if (!VTIsStereoMVHEVCEncodeSupported()) return NO;
    if ([AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPresetMVHEVC960x960] == nil) return NO;
    return YES;
}

@end
