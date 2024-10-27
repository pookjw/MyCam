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
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSString * const CaptureServiceCaptureDeviceKey;

CP_EXTERN NSNotificationName const CaptureServiceDidAddDeviceNotificationName /* CaptureServiceCaptureDeviceKey */;
CP_EXTERN NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName /* CaptureServiceCaptureDeviceKey */;
CP_EXTERN NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName /* CaptureServiceCaptureDeviceKey */;

CP_EXTERN NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName;
CP_EXTERN NSNotificationName const CaptureServiceDidUpdatePointCloudLayersNotificationName;

CP_EXTERN NSString * const CaptureServiceCaptureReadinessKey;
CP_EXTERN NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName /* CaptureServiceCaptureDeviceKey, CaptureServiceCaptureReadinessKey */;

//

@interface CaptureService : NSObject
@property (retain, nonatomic, readonly, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, readonly) AVExternalStorageDeviceDiscoverySession *externalStorageDeviceDiscoverySession;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedCaptureDevices;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedVideoCaptureDevices;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedAudioCaptureDevices;
@property (retain, nonatomic, readonly) NSArray<AVCaptureDevice *> *queue_addedPointCloudCaptureDevices;
@property (nonatomic, readonly, nullable) AVCaptureDevice *defaultVideoCaptureDevice;
@property (retain, nonatomic, null_resettable, setter=queue_setFileOutput:) __kindof BaseFileOutput *queue_fileOutput;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_depthMapLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_pointCloudLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_visionLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_metadataObjectsLayersByCaptureDeviceCopiedMapTable;

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;

- (PhotoFormatModel * _Nullable)queue_photoFormatModelForCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_setPhotoFormatModel:(PhotoFormatModel * _Nullable)photoFormatModel forCaptureDevice:(AVCaptureDevice *)captureDevice;

- (AVCapturePhotoOutput * _Nullable)queue_photoOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureDepthDataOutput * _Nullable)queue_depthDataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (__kindof AVCaptureOutput *)queue_visionDataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureMetadataOutput *)queue_metadataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureVideoPreviewLayer * _Nullable)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureDevice * _Nullable)queue_captureDeviceFromPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;
- (__kindof CALayer * _Nullable)queue_depthMapLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (__kindof CALayer * _Nullable)queue_visionLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (__kindof CALayer * _Nullable)queue_metadataObjectsLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCapturePhotoOutputReadinessCoordinator * _Nullable)queue_readinessCoordinatorFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureMovieFileOutput * _Nullable)queue_movieFileOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice;

- (NSSet<AVCaptureDevice *> *)queue_captureDevicesFromOutput:(AVCaptureOutput *)output;

- (AVCaptureMovieFileOutput *)queue_addMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice withOutput:(AVCaptureOutput *)output;
- (void)queue_disconnectAudioDevice:(AVCaptureDevice *)audioDevice fromOutput:(AVCaptureOutput *)output;

- (NSSet<AVCaptureDeviceInput *> *)queue_audioDeviceInputsForOutput:(__kindof AVCaptureOutput *)output;

- (void)queue_setUpdatesDepthMapLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice;
- (BOOL)queue_updatesDepthMapLayer:(AVCaptureDevice *)captureDevice;

- (void)queue_setUpdatesVisionLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice;
- (BOOL)queue_updatesVisionLayer:(AVCaptureDevice *)captureDevice;

- (void)queue_startPhotoCaptureWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_startRecordingWithCaptureDevice:(AVCaptureDevice *)captureDevice;
@end

NS_ASSUME_NONNULL_END
