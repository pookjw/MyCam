//
//  PhotoFormatModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <CamPresentation/PhotoFormatModel.h>

@implementation PhotoFormatModel

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
        _quality = 1.f;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _photoPixelFormatType = [[coder decodeObjectOfClass:NSNumber.class forKey:@"photoPixelFormatType"] copy];
        _codecType = [[coder decodeObjectOfClass:NSString.class forKey:@"codecType"] copy];
        _quality = [coder decodeFloatForKey:@"quality"];
        _isRAWEnabled = [coder decodeBoolForKey:@"isRAWEnabled"];
        _rawPhotoPixelFormatType = [[coder decodeObjectOfClass:NSNumber.class forKey:@"rawPhotoPixelFormatType"] copy];
        _rawFileType = [[coder decodeObjectOfClass:NSString.class forKey:@"rawFileType"] copy];
        _processedFileType = [[coder decodeObjectOfClass:NSString.class forKey:@"processedFileType"] copy];
        _photoQualityPrioritization = static_cast<AVCapturePhotoQualityPrioritization>([coder decodeIntegerForKey:@"photoQualityPrioritization"]);
        _flashMode = static_cast<AVCaptureFlashMode>([coder decodeIntegerForKey:@"flashMode"]);
        _torchMode = static_cast<AVCaptureTorchMode>([coder decodeIntegerForKey:@"torchMode"]);
    }
    
    return self;
}

- (void)dealloc {
    [_photoPixelFormatType release];
    [_codecType release];
    [_rawPhotoPixelFormatType release];
    [_rawFileType release];
    [_processedFileType release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        auto casted = static_cast<PhotoFormatModel *>(copy);
        casted->_photoPixelFormatType = [_photoPixelFormatType copyWithZone:zone];
        casted->_codecType = [_codecType copyWithZone:zone];
        casted->_quality = _quality;
        casted->_isRAWEnabled = _isRAWEnabled;
        casted->_rawPhotoPixelFormatType = [_rawPhotoPixelFormatType copyWithZone:zone];
        casted->_rawFileType = [_rawFileType copyWithZone:zone];
        casted->_processedFileType = [_processedFileType copyWithZone:zone];
        casted->_photoQualityPrioritization = _photoQualityPrioritization;
        casted->_flashMode = _flashMode;
        casted->_torchMode = _torchMode;
    }
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_photoPixelFormatType forKey:@"photoPixelFormatType"];
    [coder encodeObject:_codecType forKey:@"codecType"];
    [coder encodeFloat:_quality forKey:@"quality"];
    [coder encodeBool:_isRAWEnabled forKey:@"isRAWEnabled"];
    [coder encodeObject:_rawPhotoPixelFormatType forKey:@"rawPhotoPixelFormatType"];
    [coder encodeObject:_rawFileType forKey:@"rawFileType"];
    [coder encodeObject:_processedFileType forKey:@"processedFileType"];
    [coder encodeInteger:_photoQualityPrioritization forKey:@"photoQualityPrioritization"];
    [coder encodeInteger:_flashMode forKey:@"flashMode"];
    [coder encodeInteger:_torchMode forKey:@"torchMode"];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else {
        auto casted = static_cast<PhotoFormatModel *>(other);
        return [_photoPixelFormatType isEqualToNumber:casted->_photoPixelFormatType] &&
        [_codecType isEqualToString:casted->_codecType] &&
        (_quality == casted->_quality) &&
        (_isRAWEnabled == casted->_isRAWEnabled) &&
        [_rawPhotoPixelFormatType isEqualToNumber:casted->_rawPhotoPixelFormatType] &&
        [_rawFileType isEqualToString:casted->_rawFileType] &&
        [_processedFileType isEqualToString:casted->_processedFileType] &&
        _photoQualityPrioritization == casted->_photoQualityPrioritization &&
        _flashMode == casted->_flashMode &&
        _torchMode == casted->_torchMode;
    }
}

- (NSUInteger)hash {
    return _photoPixelFormatType.hash ^
    _codecType.hash ^
    static_cast<NSUInteger>(_quality) ^
    _isRAWEnabled ^
    _rawPhotoPixelFormatType.hash ^
    _rawFileType.hash ^
    _processedFileType.hash ^
    _photoQualityPrioritization ^
    _flashMode ^
    _torchMode;
}

@end
