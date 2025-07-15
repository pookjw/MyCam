//
//  MovieInputDescriptor.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/15/25.
//

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface MovieInputDescriptor : NSObject <NSCopying>
@property (retain, nonatomic, readonly) id key;
@property (copy, nonatomic, readonly, nullable) NSDictionary<NSString *, id> *outputSettings;
@property (assign, nonatomic, readonly, nullable) CMFormatDescriptionRef sourceFomratHints;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithKey:(id /* such as AVAudioDataOutput */)key audioOutputSettings:(NSDictionary<NSString *, id> * _Nullable)audioOutputSettings audioSourceFomratHints:(CMFormatDescriptionRef _Nullable)audioSourceFomratHints;
@end

NS_ASSUME_NONNULL_END
