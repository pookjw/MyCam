//
//  CaptureService.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/PhotoFormatModel.h>
#import <CamPresentation/Extern.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/PhotoLibraryFileOutput.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * const CaptureServiceCaptureDeviceKey;

CP_EXTERN NSNotificationName const CaptureServiceDidAddDeviceNotificationName /* CaptureServiceCaptureDeviceKey */;
CP_EXTERN NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName /* CaptureServiceCaptureDeviceKey */;
CP_EXTERN NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName /* CaptureServiceCaptureDeviceKey */;

CP_EXTERN NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName;

CP_EXTERN NSString * const CaptureServiceCaptureReadinessKey;
CP_EXTERN NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName /* CaptureServiceCaptureDeviceKey, CaptureServiceCaptureReadinessKey */;

CP_EXTERN NSString * const CaptureServiceReactionEffectsInProgressKey;
CP_EXTERN NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName /* CaptureServiceCaptureDeviceKey, CaptureServiceReactionEffectsInProgressKey */;

CP_EXTERN NSNotificationName const CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName /* CaptureServiceCaptureDeviceKey */;

//

@interface CaptureService : NSObject
@property (retain, nonatomic, readonly, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, readonly) AVExternalStorageDeviceDiscoverySession *externalStorageDeviceDiscoverySession;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedCaptureDevices;
@property (nonatomic, readonly, nullable) AVCaptureDevice *defaultCaptureDevice;
@property (retain, nonatomic, null_resettable, setter=queue_setFileOutput:) __kindof BaseFileOutput *queue_fileOutput;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDeviceCopiedMapTable;

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;

- (PhotoFormatModel * _Nullable)queue_photoFormatModelForCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_setPhotoFormatModel:(PhotoFormatModel * _Nullable)photoFormatModel forCaptureDevice:(AVCaptureDevice *)captureDevice;

- (AVCapturePhotoOutput * _Nullable)queue_photoOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureVideoPreviewLayer * _Nullable)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCapturePhotoOutputReadinessCoordinator * _Nullable)queue_readinessCoordinatorFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureMovieFileOutput * _Nullable)queue_movieFileOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_startPhotoCaptureWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_startRecordingWithCaptureDevice:(AVCaptureDevice *)captureDevice;
@end

NS_ASSUME_NONNULL_END
