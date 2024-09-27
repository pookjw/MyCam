//
//  CaptureService.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const CaptureServiceDidAddDeviceNotificationName;
CP_EXTERN NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName;
CP_EXTERN NSString * const CaptureServiceCaptureDeviceKey;

CP_EXTERN NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName;
CP_EXTERN NSString * const CaptureServiceRecordingKey;

CP_EXTERN NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName;
CP_EXTERN NSString * const CaptureServiceCaptureReadinessKey;

CP_EXTERN NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName;
CP_EXTERN NSString * const CaptureServiceReactionEffectsInProgressKey;

//

@interface CaptureService : NSObject
@property (retain, nonatomic, readonly) AVCaptureMultiCamSession *captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedCaptureDevices;
@property (nonatomic, readonly, nullable) AVCaptureDevice *defaultCaptureDevice;
#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) id capturePhotoOutput;
@property (retain, nonatomic, readonly) id captureMovieFileOutput;
#else
@property (retain, nonatomic, readonly) AVCapturePhotoOutput *capturePhotoOutput;
@property (retain, nonatomic, readonly) AVCaptureMovieFileOutput *captureMovieFileOutput;
#endif

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice captureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_startPhotoCaptureWithPhotoModel:(PhotoFormatModel *)photoModel;
@end

NS_ASSUME_NONNULL_END
