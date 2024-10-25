//
//  PhotoFormatModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <CamPresentation/PhotoFormatModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation PhotoFormatModel

- (instancetype)init {
    if (self = [super init]) {
        _quality = 1.f;
#if TARGET_OS_VISION
        _photoQualityPrioritization = 3;
#else
        _photoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
#endif
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
    copy->_isRAWEnabled = _isRAWEnabled;
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
    mutableCopy->_isRAWEnabled = _isRAWEnabled;
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
        (_isRAWEnabled == casted->_isRAWEnabled) &&
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
    _isRAWEnabled ^
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
@dynamic photoPixelFormatType;
@dynamic codecType;
@dynamic quality;
@dynamic isRAWEnabled;
@dynamic rawPhotoPixelFormatType;
@dynamic rawFileType;
@dynamic processedFileType;
@dynamic photoQualityPrioritization;
@dynamic flashMode;
@dynamic cameraCalibrationDataDeliveryEnabled;
@dynamic bracketedSettings;
@dynamic livePhotoVideoCodecType;

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

#if TARGET_OS_VISION
- (void)setPhotoQualityPrioritization:(NSInteger)photoQualityPrioritization
#else
- (void)setPhotoQualityPrioritization:(AVCapturePhotoQualityPrioritization)photoQualityPrioritization
#endif
{
    _photoQualityPrioritization = photoQualityPrioritization;
}

#if TARGET_OS_VISION
- (void)setFlashMode:(NSInteger)flashMode
#else
- (void)setFlashMode:(AVCaptureFlashMode)flashMode
#endif
{
    _flashMode = flashMode;
}

- (void)setCameraCalibrationDataDeliveryEnabled:(BOOL)cameraCalibrationDataDeliveryEnabled {
    _cameraCalibrationDataDeliveryEnabled = cameraCalibrationDataDeliveryEnabled;
}

#if TARGET_OS_VISION
- (void)setBracketedSettings:(NSArray<id> *)bracketedSettings
#else
- (void)setBracketedSettings:(NSArray<__kindof AVCaptureBracketedStillImageSettings *> *)bracketedSettings
#endif
{
    [_bracketedSettings release];
    _bracketedSettings = [bracketedSettings copy];
}

- (void)setLivePhotoVideoCodecType:(AVVideoCodecType)livePhotoVideoCodecType {
    [_livePhotoVideoCodecType release];
    _livePhotoVideoCodecType = [livePhotoVideoCodecType copy];
}

#if TARGET_OS_VISION
- (void)updateAllWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (void)updateAllWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    [self updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateCodecTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateRawFileTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateProcessedFileTypeIfNeededWithPhotoOutput:photoOutput];
    [self updateLivePhotoVideoCodecTypeWithPhotoOutput:photoOutput];
}

#if TARGET_OS_VISION
- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<NSNumber *> *photoPixelFormatTypes;
#if TARGET_OS_VISION
    if (self.processedFileType == nil) {
        photoPixelFormatTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availablePhotoPixelFormatTypes"));
    } else {
        photoPixelFormatTypes = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)(photoOutput, sel_registerName("supportedPhotoPixelFormatTypesForFileType:"), self.processedFileType);
    }
#else
    if (self.processedFileType == nil) {
        photoPixelFormatTypes = photoOutput.availablePhotoPixelFormatTypes;
    } else {
        photoPixelFormatTypes = [photoOutput supportedPhotoPixelFormatTypesForFileType:self.processedFileType];
    }
#endif
    
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

#if TARGET_OS_VISION
- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<AVVideoCodecType> *photoCodecTypes;
#if TARGET_OS_VISION
    if (self.processedFileType == nil) {
        photoCodecTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availablePhotoCodecTypes"));
    } else {
        photoCodecTypes = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)(photoOutput, sel_registerName("supportedPhotoCodecTypesForFileType:"), self.processedFileType);
    }
#else
    if (self.processedFileType == nil) {
        photoCodecTypes = photoOutput.availablePhotoCodecTypes;
    } else {
        photoCodecTypes = [photoOutput supportedPhotoCodecTypesForFileType:self.processedFileType];
    }
#endif
    
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

#if TARGET_OS_VISION
- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<NSNumber *> *rawPhotoPixelFormatTypes;
#if TARGET_OS_VISION
    if (self.processedFileType == nil) {
        rawPhotoPixelFormatTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availableRawPhotoPixelFormatTypes"));
    } else {
        rawPhotoPixelFormatTypes = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)(photoOutput, sel_registerName("supportedRawPhotoPixelFormatTypesForFileType:"), self.processedFileType);
    }
#else
    if (self.processedFileType == nil) {
        rawPhotoPixelFormatTypes = photoOutput.availableRawPhotoPixelFormatTypes;
    } else {
        rawPhotoPixelFormatTypes = [photoOutput supportedRawPhotoPixelFormatTypesForFileType:self.processedFileType];
    }
#endif
    
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

#if TARGET_OS_VISION
- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<AVFileType> *availableRawPhotoFileTypes;
#if TARGET_OS_VISION
    availableRawPhotoFileTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availableRawPhotoFileTypes"));
#else
    availableRawPhotoFileTypes = photoOutput.availableRawPhotoFileTypes;
#endif
    
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

#if TARGET_OS_VISION
- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<AVFileType> *availablePhotoFileTypes;
#if TARGET_OS_VISION
    availablePhotoFileTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availablePhotoFileTypes"));
#else
    availablePhotoFileTypes = photoOutput.availablePhotoFileTypes;
#endif
    
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

#if TARGET_OS_VISION
- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    BOOL isCameraCalibrationDataDeliverySupported;
#if TARGET_OS_VISION
    isCameraCalibrationDataDeliverySupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isCameraCalibrationDataDeliverySupported"));
#else
    isCameraCalibrationDataDeliverySupported = photoOutput.isCameraCalibrationDataDeliverySupported;
#endif
    
    if (!isCameraCalibrationDataDeliverySupported) {
        self.cameraCalibrationDataDeliveryEnabled = NO;
        return YES;
    }
    
    return NO;
}

#if TARGET_OS_VISION
- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput
#else
- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
#endif
{
    NSArray<AVVideoCodecType> *availableLivePhotoVideoCodecTypes;
#if TARGET_OS_VISION
    availableLivePhotoVideoCodecTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("availableLivePhotoVideoCodecTypes"));
#else
    availableLivePhotoVideoCodecTypes = photoOutput.availableLivePhotoVideoCodecTypes;
#endif
    
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
