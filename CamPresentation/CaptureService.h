//
//  CaptureService.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PhotoFormatModel.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
NSNotificationName const CaptureServiceDidChangeSelectedDeviceNotificationName;

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
NSString * const CaptureServiceOldCaptureDeviceKey;

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
NSString * const CaptureServiceNewCaptureDeviceKey;

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName;

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
NSString * const CaptureServiceRecordingKey;

@interface CaptureService : NSObject
@property (retain, nonatomic, readonly) AVCaptureSession *captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, nullable, setter=queue_setSelectedCaptureDevice:) AVCaptureDevice *queue_selectedCaptureDevice;
@property (retain, nonatomic, readonly) AVCapturePhotoOutput *capturePhotoOutput;
@property (nonatomic, readonly, getter=queue_recording) BOOL queue_isRecording; 
- (void)queue_selectDefaultCaptureDevice;
- (void)queue_registerCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;
- (void)queue_unregisterCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;
- (void)queue_startPhotoCaptureWithPhotoModel:(PhotoFormatModel *)photoModel;
- (void)queue_startVideoRecording;
- (void)queue_stopVideoRecording;
@end

NS_ASSUME_NONNULL_END
