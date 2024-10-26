//
//  PhotoFormatModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <CamPresentation/PhotoFormatModel.h>

@implementation PhotoFormatModel

- (instancetype)init {
    if (self = [super init]) {
        _quality = 1.f;
        _photoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
        _bracketedSettings = [NSArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_photoPixelFormatType release];
    [_codecType release];
    [_rawPhotoPixelFormatType release];
    [_rawFileType release];
    [_processedFileType release];
    [_bracketedSettings release];
    [_livePhotoVideoCodecType release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    PhotoFormatModel *copy = [[PhotoFormatModel allocWithZone:zone] init];
    
    copy->_photoPixelFormatType = [_photoPixelFormatType copyWithZone:zone];
    copy->_codecType = [_codecType copyWithZone:zone];
    copy->_quality = _quality;
    copy->_rawEnabled = _rawEnabled;
    copy->_rawPhotoPixelFormatType = [_rawPhotoPixelFormatType copyWithZone:zone];
    copy->_rawFileType = [_rawFileType copyWithZone:zone];
    copy->_processedFileType = [_processedFileType copyWithZone:zone];
    copy->_photoQualityPrioritization = _photoQualityPrioritization;
    copy->_flashMode = _flashMode;
    copy->_cameraCalibrationDataDeliveryEnabled = _cameraCalibrationDataDeliveryEnabled;
    copy->_bracketedSettings = [_bracketedSettings copyWithZone:zone];
    copy->_livePhotoVideoCodecType = [_livePhotoVideoCodecType copyWithZone:zone];
    
    return copy;
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone {
    MutablePhotoFormatModel *mutableCopy = [[MutablePhotoFormatModel allocWithZone:zone] init];
    
    mutableCopy->_photoPixelFormatType = [_photoPixelFormatType copyWithZone:zone];
    mutableCopy->_codecType = [_codecType copyWithZone:zone];
    mutableCopy->_quality = _quality;
    mutableCopy->_rawEnabled = _rawEnabled;
    mutableCopy->_rawPhotoPixelFormatType = [_rawPhotoPixelFormatType copyWithZone:zone];
    mutableCopy->_rawFileType = [_rawFileType copyWithZone:zone];
    mutableCopy->_processedFileType = [_processedFileType copyWithZone:zone];
    mutableCopy->_photoQualityPrioritization = _photoQualityPrioritization;
    mutableCopy->_flashMode = _flashMode;
    mutableCopy->_cameraCalibrationDataDeliveryEnabled = _cameraCalibrationDataDeliveryEnabled;
    mutableCopy->_bracketedSettings = [_bracketedSettings copyWithZone:zone];
    mutableCopy->_livePhotoVideoCodecType = [_livePhotoVideoCodecType copyWithZone:zone];
    
    return mutableCopy;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else {
        auto casted = static_cast<PhotoFormatModel *>(other);
        return [_photoPixelFormatType isEqualToNumber:casted->_photoPixelFormatType] &&
        [_codecType isEqualToString:casted->_codecType] &&
        (_quality == casted->_quality) &&
        (_rawEnabled == casted->_rawEnabled) &&
        [_rawPhotoPixelFormatType isEqualToNumber:casted->_rawPhotoPixelFormatType] &&
        [_rawFileType isEqualToString:casted->_rawFileType] &&
        [_processedFileType isEqualToString:casted->_processedFileType] &&
        _photoQualityPrioritization == casted->_photoQualityPrioritization &&
        _flashMode == casted->_flashMode &&
        _cameraCalibrationDataDeliveryEnabled == casted->_cameraCalibrationDataDeliveryEnabled &&
        [_bracketedSettings isEqualToArray:casted->_bracketedSettings] &&
        [_livePhotoVideoCodecType isEqualToString:casted->_livePhotoVideoCodecType];
    }
}

- (NSUInteger)hash {
    return _photoPixelFormatType.hash ^
    _codecType.hash ^
    static_cast<NSUInteger>(_quality) ^
    _rawEnabled ^
    _rawPhotoPixelFormatType.hash ^
    _rawFileType.hash ^
    _processedFileType.hash ^
    _photoQualityPrioritization ^
    _flashMode ^
    _cameraCalibrationDataDeliveryEnabled ^
    _bracketedSettings.hash ^
    _livePhotoVideoCodecType.hash;
}

@end

@implementation MutablePhotoFormatModel

- (void)setPhotoPixelFormatType:(NSNumber *)photoPixelFormatType {
    [_photoPixelFormatType release];
    _photoPixelFormatType = [photoPixelFormatType copy];
}

- (void)setCodecType:(AVVideoCodecType)codecType {
    [_codecType release];
    _codecType = [codecType copy];
}

- (void)setQuality:(float)quality {
    _quality = quality;
}

- (void)setRAWEnabled:(BOOL)isRAWEnabled {
    _isRAWEnabled = isRAWEnabled;
}

- (void)setRawPhotoPixelFormatType:(NSNumber *)rawPhotoPixelFormatType {
    [_rawPhotoPixelFormatType release];
    _rawPhotoPixelFormatType = [rawPhotoPixelFormatType copy];
}

- (void)setRawFileType:(AVFileType)rawFileType {
    [_rawFileType release];
    _rawFileType = [rawFileType copy];
}

- (void)setProcessedFileType:(AVFileType)processedFileType {
    [_processedFileType release];
    _processedFileType = [processedFileType copy];
}

- (void)setPhotoQualityPrioritization:(AVCapturePhotoQualityPrioritization)photoQualityPrioritization {
    _photoQualityPrioritization = photoQualityPrioritization;
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    _flashMode = flashMode;
}

- (void)setCameraCalibrationDataDeliveryEnabled:(BOOL)cameraCalibrationDataDeliveryEnabled {
    _cameraCalibrationDataDeliveryEnabled = cameraCalibrationDataDeliveryEnabled;
}

- (void)setBracketedSettings:(NSArray<__kindof AVCaptureBracketedStillImageSettings *> *)bracketedSettings {
    [_bracketedSettings release];
    _bracketedSettings = [bracketedSettings copy];
}

- (void)setLivePhotoVideoCodecType:(AVVideoCodecType)livePhotoVideoCodecType {
    [_livePhotoVideoCodecType release];
    _livePhotoVideoCodecType = [livePhotoVideoCodecType copy];
}

- (void)updateAllWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    [self updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateCodecTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateRawFileTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateProcessedFileTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateLivePhotoVideoCodecTypeWithPhotoOutput:photoOutput];
}

- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<NSNumber *> *photoPixelFormatTypes;
    if (self.processedFileType == nil) {
        photoPixelFormatTypes = photoOutput.availablePhotoPixelFormatTypes;
    } else {
        photoPixelFormatTypes = [photoOutput supportedPhotoPixelFormatTypesForFileType:self.processedFileType];
    }
    
    BOOL shouldUpdate;
    if (self.photoPixelFormatType == nil) {
        if (self.codecType == nil) {
            shouldUpdate = YES;
        } else {
            shouldUpdate = NO;
        }
    } else if (![photoPixelFormatTypes containsObject:self.photoPixelFormatType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.photoPixelFormatType = photoPixelFormatTypes.lastObject;
    }
    
    return shouldUpdate;
}

- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<AVVideoCodecType> *photoCodecTypes;
    if (self.processedFileType == nil) {
        photoCodecTypes = photoOutput.availablePhotoCodecTypes;
    } else {
        photoCodecTypes = [photoOutput supportedPhotoCodecTypesForFileType:self.processedFileType];
    }
    
    BOOL shouldUpdate;
    if (self.codecType == nil) {
        if (self.photoPixelFormatType == nil) {
            shouldUpdate = YES;
        } else {
            shouldUpdate = NO;
        }
    } else if (![photoCodecTypes containsObject:self.codecType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.codecType = photoCodecTypes.lastObject;
    }
    
    return shouldUpdate;
}

- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<NSNumber *> *rawPhotoPixelFormatTypes;
    if (self.processedFileType == nil) {
        rawPhotoPixelFormatTypes = photoOutput.availableRawPhotoPixelFormatTypes;
    } else {
        rawPhotoPixelFormatTypes = [photoOutput supportedRawPhotoPixelFormatTypesForFileType:self.processedFileType];
    }
    
    BOOL shouldUpdate;
    if (self.rawPhotoPixelFormatType == nil) {
        shouldUpdate = YES;
    } else if (![rawPhotoPixelFormatTypes containsObject:self.rawPhotoPixelFormatType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.rawPhotoPixelFormatType = rawPhotoPixelFormatTypes.lastObject;
    }
    
    return shouldUpdate;
}

- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<AVFileType> *availableRawPhotoFileTypes = photoOutput.availableRawPhotoFileTypes;
    
    BOOL shouldUpdate;
    if (self.rawFileType == nil) {
        shouldUpdate = YES;
    } else if (![availableRawPhotoFileTypes containsObject:self.rawFileType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.rawFileType = availableRawPhotoFileTypes.lastObject;
    }
    
    return shouldUpdate;
}

- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<AVFileType> *availablePhotoFileTypes = photoOutput.availablePhotoFileTypes;
    
    BOOL shouldUpdate;
    if (self.processedFileType == nil) {
        shouldUpdate = YES;
    } else if (![availablePhotoFileTypes containsObject:self.processedFileType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.processedFileType = nil;
    }
    
    return shouldUpdate;
}

- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    if (!photoOutput.isCameraCalibrationDataDeliverySupported) {
        self.cameraCalibrationDataDeliveryEnabled = NO;
        return YES;
    }
    
    return NO;
}

- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    NSArray<AVVideoCodecType> *availableLivePhotoVideoCodecTypes = photoOutput.availableLivePhotoVideoCodecTypes;
    
    BOOL shouldUpdate;
    if (self.livePhotoVideoCodecType == nil) {
        shouldUpdate = YES;
    } else if (![availableLivePhotoVideoCodecTypes containsObject:self.livePhotoVideoCodecType]) {
        shouldUpdate = YES;
    } else {
        shouldUpdate = NO;
    }
    
    if (shouldUpdate) {
        self.livePhotoVideoCodecType = availableLivePhotoVideoCodecTypes.lastObject;
    }
    
    return shouldUpdate;
}

@end
