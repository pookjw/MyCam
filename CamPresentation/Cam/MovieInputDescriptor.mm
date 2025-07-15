//
//  MovieInputDescriptor.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/15/25.
//

#import <CamPresentation/MovieInputDescriptor.h>

@implementation MovieInputDescriptor

- (instancetype)initWithKey:(id)key audioOutputSettings:(NSDictionary<NSString *,id> *)audioOutputSettings audioSourceFomratHints:(CMFormatDescriptionRef)audioSourceFomratHints {
    if (self = [super init]) {
        _key = [key retain];
        _outputSettings = [audioOutputSettings copy];
        if (audioSourceFomratHints != NULL) {
            CFRetain(audioSourceFomratHints);
            _sourceFomratHints = audioSourceFomratHints;
        }
    }
    
    return self;
}

- (void)dealloc {
    [_key release];
    [_outputSettings release];
    if (_sourceFomratHints != NULL) {
        CFRelease(_sourceFomratHints);
    }
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [self retain];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    }
    
    auto casted = static_cast<MovieInputDescriptor *>(other);
    
    BOOL isKeyEqual = [_key isEqual:casted->_key];
    if (!isKeyEqual) return NO;
    
    BOOL isAudioOutputSettings;
    if ((_outputSettings == nil) && (casted->_outputSettings == nil)) {
        isAudioOutputSettings = YES;
    } else {
        isAudioOutputSettings = [_outputSettings isEqual:casted->_outputSettings];
    }
    if (!isAudioOutputSettings) return NO;
    
    BOOL isAudioSourceFomratHints = CMFormatDescriptionEqual(_sourceFomratHints, casted->_sourceFomratHints);
    if (!isAudioSourceFomratHints) return NO;
    
    return YES;
}

- (NSUInteger)hash {
    return [_key hash] ^ [_outputSettings hash] ^ [(id)_sourceFomratHints hash];
}

@end
