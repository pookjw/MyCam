//
//  CaptureService.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CameraRootPhotoModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CaptureService;
@protocol CaptureServiceDelegate <NSObject>
- (void)didChangeCaptureDeviceStatus:(CaptureService *)captureService;
@end

@interface CaptureService : NSObject
@property (weak) id<CaptureServiceDelegate> delegate;
@property (retain, nonatomic, readonly) AVCaptureSession *captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, nullable, setter=queue_setSelectedCaptureDevice:) AVCaptureDevice *queue_selectedCaptureDevice;
@property (retain, nonatomic, readonly) AVCapturePhotoOutput *capturePhotoOutput;
- (void)queue_selectDefaultCaptureDevice;
- (void)queue_registerCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;
- (void)queue_unregisterCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;
- (void)queue_startPhotoCaptureWithPhotoModel:(CameraRootPhotoModel *)photoModel;
- (void)queue_startVideoRecording;
- (void)queue_stopVideoRecording;
@end

NS_ASSUME_NONNULL_END
