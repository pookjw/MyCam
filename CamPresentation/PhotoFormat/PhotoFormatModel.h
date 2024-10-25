//
//  PhotoFormatModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoFormatModel : NSObject <NSCopying, NSMutableCopying> {
    @package NSNumber *_photoPixelFormatType;
    @package AVVideoCodecType _codecType;
    @package float _quality;
    @package BOOL _isRAWEnabled;
    @package NSNumber *_rawPhotoPixelFormatType;
    @package AVFileType _rawFileType;
    @package AVFileType _processedFileType;
#if TARGET_OS_VISION
    @package NSInteger _photoQualityPrioritization;
    @package NSInteger _flashMode;
#else
    @package AVCapturePhotoQualityPrioritization _photoQualityPrioritization;
    @package AVCaptureFlashMode _flashMode;
#endif
    @package BOOL _cameraCalibrationDataDeliveryEnabled;
#if TARGET_OS_VISION
    @package NSArray<id> *_bracketedSettings;
#else
    @package NSArray<__kindof AVCaptureBracketedStillImageSettings *> *_bracketedSettings;
#endif
    @package AVVideoCodecType _livePhotoVideoCodecType;
}
@property (copy, nonatomic, readonly, nullable) NSNumber *photoPixelFormatType;
@property (copy, nonatomic, readonly, nullable) AVVideoCodecType codecType;
@property (assign, nonatomic, readonly) float quality;

@property (assign, nonatomic, nonatomic, readonly, getter=rawEnabled) BOOL isRAWEnabled;
@property (copy, nonatomic, readonly, nullable) NSNumber *rawPhotoPixelFormatType;
@property (copy, nonatomic, readonly, nullable) AVFileType rawFileType;
@property (copy, nonatomic, readonly, nullable) AVFileType processedFileType;

#if TARGET_OS_VISION
@property (assign, nonatomic, readonly) NSInteger photoQualityPrioritization;
@property (assign, nonatomic, readonly) NSInteger flashMode;
#else
@property (assign, nonatomic, readonly) AVCapturePhotoQualityPrioritization photoQualityPrioritization;
@property (assign, nonatomic, readonly) AVCaptureFlashMode flashMode;
#endif

@property (assign, nonatomic, readonly, getter=isCameraCalibrationDataDeliveryEnabled) BOOL cameraCalibrationDataDeliveryEnabled;

#if TARGET_OS_VISION
@property (copy, nonatomic, readonly) NSArray<id> *bracketedSettings;
#else
@property (copy, nonatomic, readonly) NSArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings;
#endif

@property (copy, nonatomic, readonly) AVVideoCodecType livePhotoVideoCodecType;
@end


@interface MutablePhotoFormatModel : PhotoFormatModel
@property (copy, nonatomic, nullable) NSNumber *photoPixelFormatType;
@property (copy, nonatomic, nullable) AVVideoCodecType codecType;
@property (assign, nonatomic) float quality;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
@property (assign, nonatomic, getter=rawEnabled, setter=setRAWEnabled:) BOOL isRAWEnabled;
#pragma clang diagnostic pop
@property (copy, nonatomic, nullable) NSNumber *rawPhotoPixelFormatType;
@property (copy, nonatomic, nullable) AVFileType rawFileType;
@property (copy, nonatomic, nullable) AVFileType processedFileType;

#if TARGET_OS_VISION
@property (assign, nonatomic) NSInteger photoQualityPrioritization;
@property (assign, nonatomic) NSInteger flashMode;
#else
@property (assign, nonatomic) AVCapturePhotoQualityPrioritization photoQualityPrioritization;
@property (assign, nonatomic) AVCaptureFlashMode flashMode;
#endif

@property (assign, nonatomic, getter=isCameraCalibrationDataDeliveryEnabled) BOOL cameraCalibrationDataDeliveryEnabled;

#if TARGET_OS_VISION
@property (copy, nonatomic) NSArray<id> *bracketedSettings;
#else
@property (copy, nonatomic) NSArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings;
#endif

@property (copy, nonatomic) AVVideoCodecType livePhotoVideoCodecType;

#if TARGET_OS_VISION
- (void)updateAllWithPhotoOutput:(id)photoOutput;

- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(__kindof AVCaptureOutput *)photoOutput;
#else
- (void)updateAllWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;

- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
#endif
@end

NS_ASSUME_NONNULL_END
