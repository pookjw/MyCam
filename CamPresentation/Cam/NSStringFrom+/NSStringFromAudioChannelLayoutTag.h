//
//  NSStringFromAudioChannelLayoutTag.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <Foundation/Foundation.h>
#import <CoreAudioTypes/CoreAudioTypes.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * NSStringFromAudioChannelLayoutTag(AudioChannelLayoutTag tag);
CP_EXTERN NSArray<NSNumber *> *allAudioChannelLayoutTags(void);

NS_ASSUME_NONNULL_END
