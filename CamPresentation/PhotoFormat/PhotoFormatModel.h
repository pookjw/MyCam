//
//  PhotoFormatModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoFormatModel : NSObject <NSCopying, NSSecureCoding>
@property (copy, nullable) NSNumber *photoPixelFormatType;
@property (copy, nullable) AVVideoCodecType codecType;
@property (assign) float quality;

@property (assign, getter=rawEnabled, setter=setRAWEnabled:) BOOL isRAWEnabled;
@property (copy, nullable) NSNumber *rawPhotoPixelFormatType;
@property (copy, nullable) AVFileType rawFileType;
@property (copy, nullable) AVFileType processedFileType;

@property (assign) AVCapturePhotoQualityPrioritization photoQualityPrioritization;
@property (assign) AVCaptureFlashMode flashMode;
@property (assign) AVCaptureTorchMode torchMode;
@end

NS_ASSUME_NONNULL_END
