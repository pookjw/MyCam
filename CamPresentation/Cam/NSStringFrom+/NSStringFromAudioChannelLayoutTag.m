//
//  NSStringFromAudioChannelLayoutTag.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <CamPresentation/NSStringFromAudioChannelLayoutTag.h>

NSString * NSStringFromAudioChannelLayoutTag(AudioChannelLayoutTag tag) {
    NSMutableArray *components = [NSMutableArray array];
    if (tag & kAudioChannelLayoutTag_AAC_3_0) [components addObject:@"kAudioChannelLayoutTag_AAC_3_0"];
    if (tag & kAudioChannelLayoutTag_AAC_4_0) [components addObject:@"kAudioChannelLayoutTag_AAC_4_0"];
    if (tag & kAudioChannelLayoutTag_AAC_5_0) [components addObject:@"kAudioChannelLayoutTag_AAC_5_0"];
    if (tag & kAudioChannelLayoutTag_AAC_5_1) [components addObject:@"kAudioChannelLayoutTag_AAC_5_1"];
    if (tag & kAudioChannelLayoutTag_AAC_6_0) [components addObject:@"kAudioChannelLayoutTag_AAC_6_0"];
    if (tag & kAudioChannelLayoutTag_AAC_6_1) [components addObject:@"kAudioChannelLayoutTag_AAC_6_1"];
    if (tag & kAudioChannelLayoutTag_AAC_7_0) [components addObject:@"kAudioChannelLayoutTag_AAC_7_0"];
    if (tag & kAudioChannelLayoutTag_AAC_7_1) [components addObject:@"kAudioChannelLayoutTag_AAC_7_1"];
    if (tag & kAudioChannelLayoutTag_AAC_7_1_B) [components addObject:@"kAudioChannelLayoutTag_AAC_7_1_B"];
    if (tag & kAudioChannelLayoutTag_AAC_7_1_C) [components addObject:@"kAudioChannelLayoutTag_AAC_7_1_C"];
    if (tag & kAudioChannelLayoutTag_AAC_Octagonal) [components addObject:@"kAudioChannelLayoutTag_AAC_Octagonal"];
    if (tag & kAudioChannelLayoutTag_AAC_Quadraphonic) [components addObject:@"kAudioChannelLayoutTag_AAC_Quadraphonic"];
    if (tag & kAudioChannelLayoutTag_AC3_1_0_1) [components addObject:@"kAudioChannelLayoutTag_AC3_1_0_1"];
    if (tag & kAudioChannelLayoutTag_AC3_2_1_1) [components addObject:@"kAudioChannelLayoutTag_AC3_2_1_1"];
    if (tag & kAudioChannelLayoutTag_AC3_3_0) [components addObject:@"kAudioChannelLayoutTag_AC3_3_0"];
    if (tag & kAudioChannelLayoutTag_AC3_3_0_1) [components addObject:@"kAudioChannelLayoutTag_AC3_3_0_1"];
    if (tag & kAudioChannelLayoutTag_AC3_3_1) [components addObject:@"kAudioChannelLayoutTag_AC3_3_1"];
    if (tag & kAudioChannelLayoutTag_AC3_3_1_1) [components addObject:@"kAudioChannelLayoutTag_AC3_3_1_1"];
    if (tag & kAudioChannelLayoutTag_Ambisonic_B_Format) [components addObject:@"kAudioChannelLayoutTag_Ambisonic_B_Format"];
    if (tag & kAudioChannelLayoutTag_Atmos_5_1_2) [components addObject:@"kAudioChannelLayoutTag_Atmos_5_1_2"];
    if (tag & kAudioChannelLayoutTag_Atmos_5_1_4) [components addObject:@"kAudioChannelLayoutTag_Atmos_5_1_4"];
    if (tag & kAudioChannelLayoutTag_Atmos_7_1_2) [components addObject:@"kAudioChannelLayoutTag_Atmos_7_1_2"];
    if (tag & kAudioChannelLayoutTag_Atmos_7_1_4) [components addObject:@"kAudioChannelLayoutTag_Atmos_7_1_4"];
    if (tag & kAudioChannelLayoutTag_Atmos_9_1_6) [components addObject:@"kAudioChannelLayoutTag_Atmos_9_1_6"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_4) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_4"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_5) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_5"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_5_0) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_5_0"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_5_1) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_5_1"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_6) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_6"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_6_0) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_6_0"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_6_1) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_6_1"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_7_0) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_7_0"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_7_0_Front) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_7_0_Front"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_7_1) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_7_1"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_7_1_Front) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_7_1_Front"];
    if (tag & kAudioChannelLayoutTag_AudioUnit_8) [components addObject:@"kAudioChannelLayoutTag_AudioUnit_8"];
    if (tag & kAudioChannelLayoutTag_BeginReserved) [components addObject:@"kAudioChannelLayoutTag_BeginReserved"];
    if (tag & kAudioChannelLayoutTag_Binaural) [components addObject:@"kAudioChannelLayoutTag_Binaural"];
    if (tag & kAudioChannelLayoutTag_CICP_1) [components addObject:@"kAudioChannelLayoutTag_CICP_1"];
    if (tag & kAudioChannelLayoutTag_CICP_10) [components addObject:@"kAudioChannelLayoutTag_CICP_10"];
    if (tag & kAudioChannelLayoutTag_CICP_11) [components addObject:@"kAudioChannelLayoutTag_CICP_11"];
    if (tag & kAudioChannelLayoutTag_CICP_12) [components addObject:@"kAudioChannelLayoutTag_CICP_12"];
    if (tag & kAudioChannelLayoutTag_CICP_13) [components addObject:@"kAudioChannelLayoutTag_CICP_13"];
    if (tag & kAudioChannelLayoutTag_CICP_14) [components addObject:@"kAudioChannelLayoutTag_CICP_14"];
    if (tag & kAudioChannelLayoutTag_CICP_15) [components addObject:@"kAudioChannelLayoutTag_CICP_15"];
    if (tag & kAudioChannelLayoutTag_CICP_16) [components addObject:@"kAudioChannelLayoutTag_CICP_16"];
    if (tag & kAudioChannelLayoutTag_CICP_17) [components addObject:@"kAudioChannelLayoutTag_CICP_17"];
    if (tag & kAudioChannelLayoutTag_CICP_18) [components addObject:@"kAudioChannelLayoutTag_CICP_18"];
    if (tag & kAudioChannelLayoutTag_CICP_19) [components addObject:@"kAudioChannelLayoutTag_CICP_19"];
    if (tag & kAudioChannelLayoutTag_CICP_2) [components addObject:@"kAudioChannelLayoutTag_CICP_2"];
    if (tag & kAudioChannelLayoutTag_CICP_20) [components addObject:@"kAudioChannelLayoutTag_CICP_20"];
    if (tag & kAudioChannelLayoutTag_CICP_3) [components addObject:@"kAudioChannelLayoutTag_CICP_3"];
    if (tag & kAudioChannelLayoutTag_CICP_4) [components addObject:@"kAudioChannelLayoutTag_CICP_4"];
    if (tag & kAudioChannelLayoutTag_CICP_5) [components addObject:@"kAudioChannelLayoutTag_CICP_5"];
    if (tag & kAudioChannelLayoutTag_CICP_6) [components addObject:@"kAudioChannelLayoutTag_CICP_6"];
    if (tag & kAudioChannelLayoutTag_CICP_7) [components addObject:@"kAudioChannelLayoutTag_CICP_7"];
    if (tag & kAudioChannelLayoutTag_CICP_9) [components addObject:@"kAudioChannelLayoutTag_CICP_9"];
    if (tag & kAudioChannelLayoutTag_Cube) [components addObject:@"kAudioChannelLayoutTag_Cube"];
    if (tag & kAudioChannelLayoutTag_DTS_3_1) [components addObject:@"kAudioChannelLayoutTag_DTS_3_1"];
    if (tag & kAudioChannelLayoutTag_DTS_4_1) [components addObject:@"kAudioChannelLayoutTag_DTS_4_1"];
    if (tag & kAudioChannelLayoutTag_DTS_6_0_A) [components addObject:@"kAudioChannelLayoutTag_DTS_6_0_A"];
    if (tag & kAudioChannelLayoutTag_DTS_6_0_B) [components addObject:@"kAudioChannelLayoutTag_DTS_6_0_B"];
    if (tag & kAudioChannelLayoutTag_DTS_6_0_C) [components addObject:@"kAudioChannelLayoutTag_DTS_6_0_C"];
    if (tag & kAudioChannelLayoutTag_DTS_6_1_A) [components addObject:@"kAudioChannelLayoutTag_DTS_6_1_A"];
    if (tag & kAudioChannelLayoutTag_DTS_6_1_B) [components addObject:@"kAudioChannelLayoutTag_DTS_6_1_B"];
    if (tag & kAudioChannelLayoutTag_DTS_6_1_C) [components addObject:@"kAudioChannelLayoutTag_DTS_6_1_C"];
    if (tag & kAudioChannelLayoutTag_DTS_6_1_D) [components addObject:@"kAudioChannelLayoutTag_DTS_6_1_D"];
    if (tag & kAudioChannelLayoutTag_DTS_7_0) [components addObject:@"kAudioChannelLayoutTag_DTS_7_0"];
    if (tag & kAudioChannelLayoutTag_DTS_7_1) [components addObject:@"kAudioChannelLayoutTag_DTS_7_1"];
    if (tag & kAudioChannelLayoutTag_DTS_8_0_A) [components addObject:@"kAudioChannelLayoutTag_DTS_8_0_A"];
    if (tag & kAudioChannelLayoutTag_DTS_8_0_B) [components addObject:@"kAudioChannelLayoutTag_DTS_8_0_B"];
    if (tag & kAudioChannelLayoutTag_DTS_8_1_A) [components addObject:@"kAudioChannelLayoutTag_DTS_8_1_A"];
    if (tag & kAudioChannelLayoutTag_DTS_8_1_B) [components addObject:@"kAudioChannelLayoutTag_DTS_8_1_B"];
    if (tag & kAudioChannelLayoutTag_DVD_0) [components addObject:@"kAudioChannelLayoutTag_DVD_0"];
    if (tag & kAudioChannelLayoutTag_DVD_1) [components addObject:@"kAudioChannelLayoutTag_DVD_1"];
    if (tag & kAudioChannelLayoutTag_DVD_10) [components addObject:@"kAudioChannelLayoutTag_DVD_10"];
    if (tag & kAudioChannelLayoutTag_DVD_11) [components addObject:@"kAudioChannelLayoutTag_DVD_11"];
    if (tag & kAudioChannelLayoutTag_DVD_12) [components addObject:@"kAudioChannelLayoutTag_DVD_12"];
    if (tag & kAudioChannelLayoutTag_DVD_13) [components addObject:@"kAudioChannelLayoutTag_DVD_13"];
    if (tag & kAudioChannelLayoutTag_DVD_14) [components addObject:@"kAudioChannelLayoutTag_DVD_14"];
    if (tag & kAudioChannelLayoutTag_DVD_15) [components addObject:@"kAudioChannelLayoutTag_DVD_15"];
    if (tag & kAudioChannelLayoutTag_DVD_16) [components addObject:@"kAudioChannelLayoutTag_DVD_16"];
    if (tag & kAudioChannelLayoutTag_DVD_17) [components addObject:@"kAudioChannelLayoutTag_DVD_17"];
    if (tag & kAudioChannelLayoutTag_DVD_18) [components addObject:@"kAudioChannelLayoutTag_DVD_18"];
    if (tag & kAudioChannelLayoutTag_DVD_19) [components addObject:@"kAudioChannelLayoutTag_DVD_19"];
    if (tag & kAudioChannelLayoutTag_DVD_2) [components addObject:@"kAudioChannelLayoutTag_DVD_2"];
    if (tag & kAudioChannelLayoutTag_DVD_20) [components addObject:@"kAudioChannelLayoutTag_DVD_20"];
    if (tag & kAudioChannelLayoutTag_DVD_3) [components addObject:@"kAudioChannelLayoutTag_DVD_3"];
    if (tag & kAudioChannelLayoutTag_DVD_4) [components addObject:@"kAudioChannelLayoutTag_DVD_4"];
    if (tag & kAudioChannelLayoutTag_DVD_5) [components addObject:@"kAudioChannelLayoutTag_DVD_5"];
    if (tag & kAudioChannelLayoutTag_DVD_6) [components addObject:@"kAudioChannelLayoutTag_DVD_6"];
    if (tag & kAudioChannelLayoutTag_DVD_7) [components addObject:@"kAudioChannelLayoutTag_DVD_7"];
    if (tag & kAudioChannelLayoutTag_DVD_8) [components addObject:@"kAudioChannelLayoutTag_DVD_8"];
    if (tag & kAudioChannelLayoutTag_DVD_9) [components addObject:@"kAudioChannelLayoutTag_DVD_9"];
    if (tag & kAudioChannelLayoutTag_DiscreteInOrder) [components addObject:@"kAudioChannelLayoutTag_DiscreteInOrder"];
    if (tag & kAudioChannelLayoutTag_EAC3_6_1_A) [components addObject:@"kAudioChannelLayoutTag_EAC3_6_1_A"];
    if (tag & kAudioChannelLayoutTag_EAC3_6_1_B) [components addObject:@"kAudioChannelLayoutTag_EAC3_6_1_B"];
    if (tag & kAudioChannelLayoutTag_EAC3_6_1_C) [components addObject:@"kAudioChannelLayoutTag_EAC3_6_1_C"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_A) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_A"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_B) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_B"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_C) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_C"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_D) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_D"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_E) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_E"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_F) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_F"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_G) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_G"];
    if (tag & kAudioChannelLayoutTag_EAC3_7_1_H) [components addObject:@"kAudioChannelLayoutTag_EAC3_7_1_H"];
    if (tag & kAudioChannelLayoutTag_EAC_6_0_A) [components addObject:@"kAudioChannelLayoutTag_EAC_6_0_A"];
    if (tag & kAudioChannelLayoutTag_EAC_7_0_A) [components addObject:@"kAudioChannelLayoutTag_EAC_7_0_A"];
    if (tag & kAudioChannelLayoutTag_Emagic_Default_7_1) [components addObject:@"kAudioChannelLayoutTag_Emagic_Default_7_1"];
    if (tag & kAudioChannelLayoutTag_EndReserved) [components addObject:@"kAudioChannelLayoutTag_EndReserved"];
    if (tag & kAudioChannelLayoutTag_HOA_ACN_N3D) [components addObject:@"kAudioChannelLayoutTag_HOA_ACN_N3D"];
    if (tag & kAudioChannelLayoutTag_HOA_ACN_SN3D) [components addObject:@"kAudioChannelLayoutTag_HOA_ACN_SN3D"];
    if (tag & kAudioChannelLayoutTag_Hexagonal) [components addObject:@"kAudioChannelLayoutTag_Hexagonal"];
    if (tag & kAudioChannelLayoutTag_ITU_1_0) [components addObject:@"kAudioChannelLayoutTag_ITU_1_0"];
    if (tag & kAudioChannelLayoutTag_ITU_2_0) [components addObject:@"kAudioChannelLayoutTag_ITU_2_0"];
    if (tag & kAudioChannelLayoutTag_ITU_2_1) [components addObject:@"kAudioChannelLayoutTag_ITU_2_1"];
    if (tag & kAudioChannelLayoutTag_ITU_2_2) [components addObject:@"kAudioChannelLayoutTag_ITU_2_2"];
    if (tag & kAudioChannelLayoutTag_ITU_3_0) [components addObject:@"kAudioChannelLayoutTag_ITU_3_0"];
    if (tag & kAudioChannelLayoutTag_ITU_3_1) [components addObject:@"kAudioChannelLayoutTag_ITU_3_1"];
    if (tag & kAudioChannelLayoutTag_ITU_3_2) [components addObject:@"kAudioChannelLayoutTag_ITU_3_2"];
    if (tag & kAudioChannelLayoutTag_ITU_3_2_1) [components addObject:@"kAudioChannelLayoutTag_ITU_3_2_1"];
    if (tag & kAudioChannelLayoutTag_ITU_3_4_1) [components addObject:@"kAudioChannelLayoutTag_ITU_3_4_1"];
    if (tag & kAudioChannelLayoutTag_Logic_4_0_A) [components addObject:@"kAudioChannelLayoutTag_Logic_4_0_A"];
    if (tag & kAudioChannelLayoutTag_Logic_4_0_B) [components addObject:@"kAudioChannelLayoutTag_Logic_4_0_B"];
    if (tag & kAudioChannelLayoutTag_Logic_4_0_C) [components addObject:@"kAudioChannelLayoutTag_Logic_4_0_C"];
    if (tag & kAudioChannelLayoutTag_Logic_5_0_A) [components addObject:@"kAudioChannelLayoutTag_Logic_5_0_A"];
    if (tag & kAudioChannelLayoutTag_Logic_5_0_B) [components addObject:@"kAudioChannelLayoutTag_Logic_5_0_B"];
    if (tag & kAudioChannelLayoutTag_Logic_5_0_C) [components addObject:@"kAudioChannelLayoutTag_Logic_5_0_C"];
    if (tag & kAudioChannelLayoutTag_Logic_5_0_D) [components addObject:@"kAudioChannelLayoutTag_Logic_5_0_D"];
    if (tag & kAudioChannelLayoutTag_Logic_5_1_A) [components addObject:@"kAudioChannelLayoutTag_Logic_5_1_A"];
    if (tag & kAudioChannelLayoutTag_Logic_5_1_B) [components addObject:@"kAudioChannelLayoutTag_Logic_5_1_B"];
    if (tag & kAudioChannelLayoutTag_Logic_5_1_C) [components addObject:@"kAudioChannelLayoutTag_Logic_5_1_C"];
    if (tag & kAudioChannelLayoutTag_Logic_5_1_D) [components addObject:@"kAudioChannelLayoutTag_Logic_5_1_D"];
    if (tag & kAudioChannelLayoutTag_Logic_6_0_A) [components addObject:@"kAudioChannelLayoutTag_Logic_6_0_A"];
    if (tag & kAudioChannelLayoutTag_Logic_6_0_B) [components addObject:@"kAudioChannelLayoutTag_Logic_6_0_B"];
    if (tag & kAudioChannelLayoutTag_Logic_6_0_C) [components addObject:@"kAudioChannelLayoutTag_Logic_6_0_C"];
    if (tag & kAudioChannelLayoutTag_Logic_6_1_A) [components addObject:@"kAudioChannelLayoutTag_Logic_6_1_A"];
    if (tag & kAudioChannelLayoutTag_Logic_6_1_B) [components addObject:@"kAudioChannelLayoutTag_Logic_6_1_B"];
    if (tag & kAudioChannelLayoutTag_Logic_6_1_C) [components addObject:@"kAudioChannelLayoutTag_Logic_6_1_C"];
    if (tag & kAudioChannelLayoutTag_Logic_6_1_D) [components addObject:@"kAudioChannelLayoutTag_Logic_6_1_D"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_A) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_A"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_B) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_B"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_C) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_C"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_SDDS_A) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_SDDS_A"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_SDDS_B) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_SDDS_B"];
    if (tag & kAudioChannelLayoutTag_Logic_7_1_SDDS_C) [components addObject:@"kAudioChannelLayoutTag_Logic_7_1_SDDS_C"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_5_1_2) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_5_1_2"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_5_1_4) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_5_1_4"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_7_1_2) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_7_1_2"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_7_1_4_A) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_7_1_4_A"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_7_1_4_B) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_7_1_4_B"];
    if (tag & kAudioChannelLayoutTag_Logic_Atmos_7_1_6) [components addObject:@"kAudioChannelLayoutTag_Logic_Atmos_7_1_6"];
    if (tag & kAudioChannelLayoutTag_Logic_Mono) [components addObject:@"kAudioChannelLayoutTag_Logic_Mono"];
    if (tag & kAudioChannelLayoutTag_Logic_Quadraphonic) [components addObject:@"kAudioChannelLayoutTag_Logic_Quadraphonic"];
    if (tag & kAudioChannelLayoutTag_Logic_Stereo) [components addObject:@"kAudioChannelLayoutTag_Logic_Stereo"];
    if (tag & kAudioChannelLayoutTag_MPEG_1_0) [components addObject:@"kAudioChannelLayoutTag_MPEG_1_0"];
    if (tag & kAudioChannelLayoutTag_MPEG_2_0) [components addObject:@"kAudioChannelLayoutTag_MPEG_2_0"];
    if (tag & kAudioChannelLayoutTag_MPEG_3_0_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_3_0_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_3_0_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_3_0_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_4_0_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_4_0_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_4_0_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_4_0_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_0_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_0_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_0_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_0_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_0_C) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_0_C"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_0_D) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_0_D"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_0_E) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_0_E"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_1_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_1_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_1_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_1_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_1_C) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_1_C"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_1_D) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_1_D"];
    if (tag & kAudioChannelLayoutTag_MPEG_5_1_E) [components addObject:@"kAudioChannelLayoutTag_MPEG_5_1_E"];
    if (tag & kAudioChannelLayoutTag_MPEG_6_1_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_6_1_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_6_1_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_6_1_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_7_1_A) [components addObject:@"kAudioChannelLayoutTag_MPEG_7_1_A"];
    if (tag & kAudioChannelLayoutTag_MPEG_7_1_B) [components addObject:@"kAudioChannelLayoutTag_MPEG_7_1_B"];
    if (tag & kAudioChannelLayoutTag_MPEG_7_1_C) [components addObject:@"kAudioChannelLayoutTag_MPEG_7_1_C"];
    if (tag & kAudioChannelLayoutTag_MPEG_7_1_D) [components addObject:@"kAudioChannelLayoutTag_MPEG_7_1_D"];
    if (tag & kAudioChannelLayoutTag_MatrixStereo) [components addObject:@"kAudioChannelLayoutTag_MatrixStereo"];
    if (tag & kAudioChannelLayoutTag_MidSide) [components addObject:@"kAudioChannelLayoutTag_MidSide"];
    if (tag & kAudioChannelLayoutTag_Mono) [components addObject:@"kAudioChannelLayoutTag_Mono"];
    if (tag & kAudioChannelLayoutTag_Octagonal) [components addObject:@"kAudioChannelLayoutTag_Octagonal"];
    if (tag & kAudioChannelLayoutTag_Ogg_3_0) [components addObject:@"kAudioChannelLayoutTag_Ogg_3_0"];
    if (tag & kAudioChannelLayoutTag_Ogg_4_0) [components addObject:@"kAudioChannelLayoutTag_Ogg_4_0"];
    if (tag & kAudioChannelLayoutTag_Ogg_5_0) [components addObject:@"kAudioChannelLayoutTag_Ogg_5_0"];
    if (tag & kAudioChannelLayoutTag_Ogg_5_1) [components addObject:@"kAudioChannelLayoutTag_Ogg_5_1"];
    if (tag & kAudioChannelLayoutTag_Ogg_6_1) [components addObject:@"kAudioChannelLayoutTag_Ogg_6_1"];
    if (tag & kAudioChannelLayoutTag_Ogg_7_1) [components addObject:@"kAudioChannelLayoutTag_Ogg_7_1"];
    if (tag & kAudioChannelLayoutTag_Pentagonal) [components addObject:@"kAudioChannelLayoutTag_Pentagonal"];
    if (tag & kAudioChannelLayoutTag_Quadraphonic) [components addObject:@"kAudioChannelLayoutTag_Quadraphonic"];
    if (tag & kAudioChannelLayoutTag_SMPTE_DTV) [components addObject:@"kAudioChannelLayoutTag_SMPTE_DTV"];
    if (tag & kAudioChannelLayoutTag_Stereo) [components addObject:@"kAudioChannelLayoutTag_Stereo"];
    if (tag & kAudioChannelLayoutTag_StereoHeadphones) [components addObject:@"kAudioChannelLayoutTag_StereoHeadphones"];
    if (tag & kAudioChannelLayoutTag_TMH_10_2_full) [components addObject:@"kAudioChannelLayoutTag_TMH_10_2_full"];
    if (tag & kAudioChannelLayoutTag_TMH_10_2_std) [components addObject:@"kAudioChannelLayoutTag_TMH_10_2_std"];
    if (tag & kAudioChannelLayoutTag_Unknown) [components addObject:@"kAudioChannelLayoutTag_Unknown"];
    if (tag & kAudioChannelLayoutTag_UseChannelBitmap) [components addObject:@"kAudioChannelLayoutTag_UseChannelBitmap"];
    if (tag & kAudioChannelLayoutTag_UseChannelDescriptions) [components addObject:@"kAudioChannelLayoutTag_UseChannelDescriptions"];
    if (tag & kAudioChannelLayoutTag_WAVE_2_1) [components addObject:@"kAudioChannelLayoutTag_WAVE_2_1"];
    if (tag & kAudioChannelLayoutTag_WAVE_3_0) [components addObject:@"kAudioChannelLayoutTag_WAVE_3_0"];
    if (tag & kAudioChannelLayoutTag_WAVE_4_0_A) [components addObject:@"kAudioChannelLayoutTag_WAVE_4_0_A"];
    if (tag & kAudioChannelLayoutTag_WAVE_4_0_B) [components addObject:@"kAudioChannelLayoutTag_WAVE_4_0_B"];
    if (tag & kAudioChannelLayoutTag_WAVE_5_0_A) [components addObject:@"kAudioChannelLayoutTag_WAVE_5_0_A"];
    if (tag & kAudioChannelLayoutTag_WAVE_5_0_B) [components addObject:@"kAudioChannelLayoutTag_WAVE_5_0_B"];
    if (tag & kAudioChannelLayoutTag_WAVE_5_1_A) [components addObject:@"kAudioChannelLayoutTag_WAVE_5_1_A"];
    if (tag & kAudioChannelLayoutTag_WAVE_5_1_B) [components addObject:@"kAudioChannelLayoutTag_WAVE_5_1_B"];
    if (tag & kAudioChannelLayoutTag_WAVE_6_1) [components addObject:@"kAudioChannelLayoutTag_WAVE_6_1"];
    if (tag & kAudioChannelLayoutTag_WAVE_7_1) [components addObject:@"kAudioChannelLayoutTag_WAVE_7_1"];
    if (tag & kAudioChannelLayoutTag_XY) [components addObject:@"kAudioChannelLayoutTag_XY"];
    if (components.count == 0) return @"Unknown";
    return [components componentsJoinedByString:@", "];
};

NSArray<NSNumber *> *allAudioChannelLayoutTags(void) {
    return @[ 
        @(kAudioChannelLayoutTag_AAC_3_0),
        @(kAudioChannelLayoutTag_AAC_4_0),
        @(kAudioChannelLayoutTag_AAC_5_0),
        @(kAudioChannelLayoutTag_AAC_5_1),
        @(kAudioChannelLayoutTag_AAC_6_0),
        @(kAudioChannelLayoutTag_AAC_6_1),
        @(kAudioChannelLayoutTag_AAC_7_0),
        @(kAudioChannelLayoutTag_AAC_7_1),
        @(kAudioChannelLayoutTag_AAC_7_1_B),
        @(kAudioChannelLayoutTag_AAC_7_1_C),
        @(kAudioChannelLayoutTag_AAC_Octagonal),
        @(kAudioChannelLayoutTag_AAC_Quadraphonic),
        @(kAudioChannelLayoutTag_AC3_1_0_1),
        @(kAudioChannelLayoutTag_AC3_2_1_1),
        @(kAudioChannelLayoutTag_AC3_3_0),
        @(kAudioChannelLayoutTag_AC3_3_0_1),
        @(kAudioChannelLayoutTag_AC3_3_1),
        @(kAudioChannelLayoutTag_AC3_3_1_1),
        @(kAudioChannelLayoutTag_Ambisonic_B_Format),
        @(kAudioChannelLayoutTag_Atmos_5_1_2),
        @(kAudioChannelLayoutTag_Atmos_5_1_4),
        @(kAudioChannelLayoutTag_Atmos_7_1_2),
        @(kAudioChannelLayoutTag_Atmos_7_1_4),
        @(kAudioChannelLayoutTag_Atmos_9_1_6),
        @(kAudioChannelLayoutTag_AudioUnit_4),
        @(kAudioChannelLayoutTag_AudioUnit_5),
        @(kAudioChannelLayoutTag_AudioUnit_5_0),
        @(kAudioChannelLayoutTag_AudioUnit_5_1),
        @(kAudioChannelLayoutTag_AudioUnit_6),
        @(kAudioChannelLayoutTag_AudioUnit_6_0),
        @(kAudioChannelLayoutTag_AudioUnit_6_1),
        @(kAudioChannelLayoutTag_AudioUnit_7_0),
        @(kAudioChannelLayoutTag_AudioUnit_7_0_Front),
        @(kAudioChannelLayoutTag_AudioUnit_7_1),
        @(kAudioChannelLayoutTag_AudioUnit_7_1_Front),
        @(kAudioChannelLayoutTag_AudioUnit_8),
        @(kAudioChannelLayoutTag_BeginReserved),
        @(kAudioChannelLayoutTag_Binaural),
        @(kAudioChannelLayoutTag_CICP_1),
        @(kAudioChannelLayoutTag_CICP_10),
        @(kAudioChannelLayoutTag_CICP_11),
        @(kAudioChannelLayoutTag_CICP_12),
        @(kAudioChannelLayoutTag_CICP_13),
        @(kAudioChannelLayoutTag_CICP_14),
        @(kAudioChannelLayoutTag_CICP_15),
        @(kAudioChannelLayoutTag_CICP_16),
        @(kAudioChannelLayoutTag_CICP_17),
        @(kAudioChannelLayoutTag_CICP_18),
        @(kAudioChannelLayoutTag_CICP_19),
        @(kAudioChannelLayoutTag_CICP_2),
        @(kAudioChannelLayoutTag_CICP_20),
        @(kAudioChannelLayoutTag_CICP_3),
        @(kAudioChannelLayoutTag_CICP_4),
        @(kAudioChannelLayoutTag_CICP_5),
        @(kAudioChannelLayoutTag_CICP_6),
        @(kAudioChannelLayoutTag_CICP_7),
        @(kAudioChannelLayoutTag_CICP_9),
        @(kAudioChannelLayoutTag_Cube),
        @(kAudioChannelLayoutTag_DTS_3_1),
        @(kAudioChannelLayoutTag_DTS_4_1),
        @(kAudioChannelLayoutTag_DTS_6_0_A),
        @(kAudioChannelLayoutTag_DTS_6_0_B),
        @(kAudioChannelLayoutTag_DTS_6_0_C),
        @(kAudioChannelLayoutTag_DTS_6_1_A),
        @(kAudioChannelLayoutTag_DTS_6_1_B),
        @(kAudioChannelLayoutTag_DTS_6_1_C),
        @(kAudioChannelLayoutTag_DTS_6_1_D),
        @(kAudioChannelLayoutTag_DTS_7_0),
        @(kAudioChannelLayoutTag_DTS_7_1),
        @(kAudioChannelLayoutTag_DTS_8_0_A),
        @(kAudioChannelLayoutTag_DTS_8_0_B),
        @(kAudioChannelLayoutTag_DTS_8_1_A),
        @(kAudioChannelLayoutTag_DTS_8_1_B),
        @(kAudioChannelLayoutTag_DVD_0),
        @(kAudioChannelLayoutTag_DVD_1),
        @(kAudioChannelLayoutTag_DVD_10),
        @(kAudioChannelLayoutTag_DVD_11),
        @(kAudioChannelLayoutTag_DVD_12),
        @(kAudioChannelLayoutTag_DVD_13),
        @(kAudioChannelLayoutTag_DVD_14),
        @(kAudioChannelLayoutTag_DVD_15),
        @(kAudioChannelLayoutTag_DVD_16),
        @(kAudioChannelLayoutTag_DVD_17),
        @(kAudioChannelLayoutTag_DVD_18),
        @(kAudioChannelLayoutTag_DVD_19),
        @(kAudioChannelLayoutTag_DVD_2),
        @(kAudioChannelLayoutTag_DVD_20),
        @(kAudioChannelLayoutTag_DVD_3),
        @(kAudioChannelLayoutTag_DVD_4),
        @(kAudioChannelLayoutTag_DVD_5),
        @(kAudioChannelLayoutTag_DVD_6),
        @(kAudioChannelLayoutTag_DVD_7),
        @(kAudioChannelLayoutTag_DVD_8),
        @(kAudioChannelLayoutTag_DVD_9),
        @(kAudioChannelLayoutTag_DiscreteInOrder),
        @(kAudioChannelLayoutTag_EAC3_6_1_A),
        @(kAudioChannelLayoutTag_EAC3_6_1_B),
        @(kAudioChannelLayoutTag_EAC3_6_1_C),
        @(kAudioChannelLayoutTag_EAC3_7_1_A),
        @(kAudioChannelLayoutTag_EAC3_7_1_B),
        @(kAudioChannelLayoutTag_EAC3_7_1_C),
        @(kAudioChannelLayoutTag_EAC3_7_1_D),
        @(kAudioChannelLayoutTag_EAC3_7_1_E),
        @(kAudioChannelLayoutTag_EAC3_7_1_F),
        @(kAudioChannelLayoutTag_EAC3_7_1_G),
        @(kAudioChannelLayoutTag_EAC3_7_1_H),
        @(kAudioChannelLayoutTag_EAC_6_0_A),
        @(kAudioChannelLayoutTag_EAC_7_0_A),
        @(kAudioChannelLayoutTag_Emagic_Default_7_1),
        @(kAudioChannelLayoutTag_EndReserved),
        @(kAudioChannelLayoutTag_HOA_ACN_N3D),
        @(kAudioChannelLayoutTag_HOA_ACN_SN3D),
        @(kAudioChannelLayoutTag_Hexagonal),
        @(kAudioChannelLayoutTag_ITU_1_0),
        @(kAudioChannelLayoutTag_ITU_2_0),
        @(kAudioChannelLayoutTag_ITU_2_1),
        @(kAudioChannelLayoutTag_ITU_2_2),
        @(kAudioChannelLayoutTag_ITU_3_0),
        @(kAudioChannelLayoutTag_ITU_3_1),
        @(kAudioChannelLayoutTag_ITU_3_2),
        @(kAudioChannelLayoutTag_ITU_3_2_1),
        @(kAudioChannelLayoutTag_ITU_3_4_1),
        @(kAudioChannelLayoutTag_Logic_4_0_A),
        @(kAudioChannelLayoutTag_Logic_4_0_B),
        @(kAudioChannelLayoutTag_Logic_4_0_C),
        @(kAudioChannelLayoutTag_Logic_5_0_A),
        @(kAudioChannelLayoutTag_Logic_5_0_B),
        @(kAudioChannelLayoutTag_Logic_5_0_C),
        @(kAudioChannelLayoutTag_Logic_5_0_D),
        @(kAudioChannelLayoutTag_Logic_5_1_A),
        @(kAudioChannelLayoutTag_Logic_5_1_B),
        @(kAudioChannelLayoutTag_Logic_5_1_C),
        @(kAudioChannelLayoutTag_Logic_5_1_D),
        @(kAudioChannelLayoutTag_Logic_6_0_A),
        @(kAudioChannelLayoutTag_Logic_6_0_B),
        @(kAudioChannelLayoutTag_Logic_6_0_C),
        @(kAudioChannelLayoutTag_Logic_6_1_A),
        @(kAudioChannelLayoutTag_Logic_6_1_B),
        @(kAudioChannelLayoutTag_Logic_6_1_C),
        @(kAudioChannelLayoutTag_Logic_6_1_D),
        @(kAudioChannelLayoutTag_Logic_7_1_A),
        @(kAudioChannelLayoutTag_Logic_7_1_B),
        @(kAudioChannelLayoutTag_Logic_7_1_C),
        @(kAudioChannelLayoutTag_Logic_7_1_SDDS_A),
        @(kAudioChannelLayoutTag_Logic_7_1_SDDS_B),
        @(kAudioChannelLayoutTag_Logic_7_1_SDDS_C),
        @(kAudioChannelLayoutTag_Logic_Atmos_5_1_2),
        @(kAudioChannelLayoutTag_Logic_Atmos_5_1_4),
        @(kAudioChannelLayoutTag_Logic_Atmos_7_1_2),
        @(kAudioChannelLayoutTag_Logic_Atmos_7_1_4_A),
        @(kAudioChannelLayoutTag_Logic_Atmos_7_1_4_B),
        @(kAudioChannelLayoutTag_Logic_Atmos_7_1_6),
        @(kAudioChannelLayoutTag_Logic_Mono),
        @(kAudioChannelLayoutTag_Logic_Quadraphonic),
        @(kAudioChannelLayoutTag_Logic_Stereo),
        @(kAudioChannelLayoutTag_MPEG_1_0),
        @(kAudioChannelLayoutTag_MPEG_2_0),
        @(kAudioChannelLayoutTag_MPEG_3_0_A),
        @(kAudioChannelLayoutTag_MPEG_3_0_B),
        @(kAudioChannelLayoutTag_MPEG_4_0_A),
        @(kAudioChannelLayoutTag_MPEG_4_0_B),
        @(kAudioChannelLayoutTag_MPEG_5_0_A),
        @(kAudioChannelLayoutTag_MPEG_5_0_B),
        @(kAudioChannelLayoutTag_MPEG_5_0_C),
        @(kAudioChannelLayoutTag_MPEG_5_0_D),
        @(kAudioChannelLayoutTag_MPEG_5_0_E),
        @(kAudioChannelLayoutTag_MPEG_5_1_A),
        @(kAudioChannelLayoutTag_MPEG_5_1_B),
        @(kAudioChannelLayoutTag_MPEG_5_1_C),
        @(kAudioChannelLayoutTag_MPEG_5_1_D),
        @(kAudioChannelLayoutTag_MPEG_5_1_E),
        @(kAudioChannelLayoutTag_MPEG_6_1_A),
        @(kAudioChannelLayoutTag_MPEG_6_1_B),
        @(kAudioChannelLayoutTag_MPEG_7_1_A),
        @(kAudioChannelLayoutTag_MPEG_7_1_B),
        @(kAudioChannelLayoutTag_MPEG_7_1_C),
        @(kAudioChannelLayoutTag_MPEG_7_1_D),
        @(kAudioChannelLayoutTag_MatrixStereo),
        @(kAudioChannelLayoutTag_MidSide),
        @(kAudioChannelLayoutTag_Mono),
        @(kAudioChannelLayoutTag_Octagonal),
        @(kAudioChannelLayoutTag_Ogg_3_0),
        @(kAudioChannelLayoutTag_Ogg_4_0),
        @(kAudioChannelLayoutTag_Ogg_5_0),
        @(kAudioChannelLayoutTag_Ogg_5_1),
        @(kAudioChannelLayoutTag_Ogg_6_1),
        @(kAudioChannelLayoutTag_Ogg_7_1),
        @(kAudioChannelLayoutTag_Pentagonal),
        @(kAudioChannelLayoutTag_Quadraphonic),
        @(kAudioChannelLayoutTag_SMPTE_DTV),
        @(kAudioChannelLayoutTag_Stereo),
        @(kAudioChannelLayoutTag_StereoHeadphones),
        @(kAudioChannelLayoutTag_TMH_10_2_full),
        @(kAudioChannelLayoutTag_TMH_10_2_std),
        @(kAudioChannelLayoutTag_Unknown),
        @(kAudioChannelLayoutTag_UseChannelBitmap),
        @(kAudioChannelLayoutTag_UseChannelDescriptions),
        @(kAudioChannelLayoutTag_WAVE_2_1),
        @(kAudioChannelLayoutTag_WAVE_3_0),
        @(kAudioChannelLayoutTag_WAVE_4_0_A),
        @(kAudioChannelLayoutTag_WAVE_4_0_B),
        @(kAudioChannelLayoutTag_WAVE_5_0_A),
        @(kAudioChannelLayoutTag_WAVE_5_0_B),
        @(kAudioChannelLayoutTag_WAVE_5_1_A),
        @(kAudioChannelLayoutTag_WAVE_5_1_B),
        @(kAudioChannelLayoutTag_WAVE_6_1),
        @(kAudioChannelLayoutTag_WAVE_7_1),
        @(kAudioChannelLayoutTag_XY),
    ];
};
