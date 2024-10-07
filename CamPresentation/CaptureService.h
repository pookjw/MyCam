//
//  CaptureService.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/Extern.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const CaptureServiceDidAddDeviceNotificationName;
CP_EXTERN NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName;
CP_EXTERN NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName;
CP_EXTERN NSString * const CaptureServiceCaptureDeviceKey;

CP_EXTERN NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName;

#warning Device 분기
CP_EXTERN NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName;
CP_EXTERN NSString * const CaptureServiceCaptureReadinessKey;

#warning Device 분기
CP_EXTERN NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName;
CP_EXTERN NSString * const CaptureServiceReactionEffectsInProgressKey;

//

@interface CaptureService : NSObject
@property (retain, nonatomic, readonly, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedCaptureDevices;
@property (nonatomic, readonly, nullable) AVCaptureDevice *defaultCaptureDevice;

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;

- (PhotoFormatModel * _Nullable)queue_photoFormatModelForCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_setPhotoFormatModel:(PhotoFormatModel * _Nullable)photoFormatModel forCaptureDevice:(AVCaptureDevice *)captureDevice;

- (AVCapturePhotoOutput * _Nullable)queue_photoOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureVideoPreviewLayer * _Nullable)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_startPhotoCaptureWithCaptureDevice:(AVCaptureDevice *)captureDevice;
@end

NS_ASSUME_NONNULL_END
