//
//  PhotoFormatModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface PhotoFormatModel : NSObject <NSCopying, NSMutableCopying> {
    @package NSNumber *_photoPixelFormatType;
    @package AVVideoCodecType _codecType;
    @package float _quality;
    @package BOOL _rawEnabled;
    @package NSNumber *_rawPhotoPixelFormatType;
    @package AVFileType _rawFileType;
    @package AVFileType _processedFileType;
    @package AVCapturePhotoQualityPrioritization _photoQualityPrioritization;
    @package AVCaptureFlashMode _flashMode;
    @package BOOL _cameraCalibrationDataDeliveryEnabled;
    @package NSArray<__kindof AVCaptureBracketedStillImageSettings *> *_bracketedSettings;
    @package AVVideoCodecType _livePhotoVideoCodecType;
    @package BOOL _shutterSoundSuppressionEnabled;
}
@property (copy, nonatomic, readonly, nullable) NSNumber *photoPixelFormatType;
@property (copy, nonatomic, readonly, nullable) AVVideoCodecType codecType;
@property (assign, nonatomic, readonly) float quality;

@property (assign, nonatomic, nonatomic, readonly, getter=isRAWEnabled) BOOL rawEnabled;
@property (copy, nonatomic, readonly, nullable) NSNumber *rawPhotoPixelFormatType;
@property (copy, nonatomic, readonly, nullable) AVFileType rawFileType;
@property (copy, nonatomic, readonly, nullable) AVFileType processedFileType;

@property (assign, nonatomic, readonly) AVCapturePhotoQualityPrioritization photoQualityPrioritization;
@property (assign, nonatomic, readonly) AVCaptureFlashMode flashMode;

@property (assign, nonatomic, readonly, getter=isCameraCalibrationDataDeliveryEnabled) BOOL cameraCalibrationDataDeliveryEnabled;

@property (copy, nonatomic, readonly) NSArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings;

@property (copy, nonatomic, readonly) AVVideoCodecType livePhotoVideoCodecType;

@property (assign, nonatomic, readonly, getter=isShutterSoundSuppressionEnabled) BOOL shutterSoundSuppressionEnabled;
@end


API_UNAVAILABLE(visionos)
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

@property (assign, nonatomic) AVCapturePhotoQualityPrioritization photoQualityPrioritization;
@property (assign, nonatomic) AVCaptureFlashMode flashMode;

@property (assign, nonatomic, getter=isCameraCalibrationDataDeliveryEnabled) BOOL cameraCalibrationDataDeliveryEnabled;

@property (copy, nonatomic) NSArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings;

@property (copy, nonatomic) AVVideoCodecType livePhotoVideoCodecType;

@property (assign, nonatomic, getter=isShutterSoundSuppressionEnabled) BOOL shutterSoundSuppressionEnabled;

- (void)updateAllWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;

- (BOOL)updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateCodecTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateRawFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateProcessedFileTypeIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
- (BOOL)updateLivePhotoVideoCodecTypeWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput;
@end

NS_ASSUME_NONNULL_END
