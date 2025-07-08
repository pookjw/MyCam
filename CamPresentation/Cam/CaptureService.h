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
#import <CamPresentation/PixelBufferLayer.h>
#import <CamPresentation/MovieWriter.h>
#import <CamPresentation/NerualAnalyzerLayer.h>
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

/*
 -[AVCaptureMovieFileOutput(TrueVideo) setTrueVideoCaptureEnabled:]
 AVCaptureMultichannelAudioMode
 
 */

//

API_UNAVAILABLE(visionos)
__attribute__((objc_direct_members))
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
@property (nonatomic, readonly) NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDevice;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,PixelBufferLayer *> *queue_customPreviewLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVSampleBufferDisplayLayer *> *queue_sampleBufferDisplayLayersByVideoDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *, CALayer *> *queue_videoThumbnailLayersByVideoDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_depthMapLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_pointCloudLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_visionLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *,__kindof CALayer *> *queue_metadataObjectsLayersByCaptureDeviceCopiedMapTable;
@property (copy, nonatomic, readonly) NSMapTable<AVCaptureDevice *, NerualAnalyzerLayer *> *queue_nerualAnalyzerLayersByVideoDeviceCopiedMapTable;

- (void)queue_addCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;

- (PhotoFormatModel * _Nullable)queue_photoFormatModelForCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_setPhotoFormatModel:(PhotoFormatModel * _Nullable)photoFormatModel forCaptureDevice:(AVCaptureDevice *)captureDevice;

- (__kindof AVCaptureOutput * _Nullable)queue_outputWithClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (NSSet<__kindof AVCaptureOutput *> *)queue_outputsWithClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice;

- (BOOL)queue_isPreviewLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setPreviewLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice;

- (BOOL)queue_isCustomPreviewLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setCustomPreviewLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice;

- (BOOL)queue_isSampleBufferDisplayLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setSampleBufferDisplayLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice;

- (BOOL)queue_isNerualAnalyzerLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setNerualAnalyzerLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice;

- (BOOL)queue_isVideoThumbnailLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setVideoThumbnailLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice;

- (AVCaptureVideoPreviewLayer * _Nullable)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (AVCaptureDevice * _Nullable)queue_captureDeviceFromPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;
- (__kindof CALayer * _Nullable)queue_depthMapLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (__kindof CALayer * _Nullable)queue_visionLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (__kindof CALayer * _Nullable)queue_metadataObjectsLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (NerualAnalyzerLayer * _Nullable)queue_nerualAnalyzerLayerFromVideoDevice:(AVCaptureDevice *)videoDevice;
- (AVCapturePhotoOutputReadinessCoordinator * _Nullable)queue_readinessCoordinatorFromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (NSSet<AVCaptureDevice *> *)queue_captureDevicesFromOutput:(AVCaptureOutput *)output;

- (AVCaptureMovieFileOutput *)queue_addMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;

- (AVCaptureDepthDataOutput *)queue_addDepthDataOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeDepthDataOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice withOutput:(AVCaptureOutput *)output;
- (void)queue_disconnectAudioDevice:(AVCaptureDevice *)audioDevice fromOutput:(AVCaptureOutput *)output;

- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice forAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_disconnectAudioDeviceForAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice;
- (BOOL)queue_isAudioDeviceConnected:(AVCaptureDevice *)audioDevice forAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice;
- (BOOL)queue_isAssetWriterConnectedWithAudioDevice:(AVCaptureDevice *)audioDevice;

- (NSSet<AVCaptureDeviceInput *> *)queue_audioDeviceInputsForOutput:(__kindof AVCaptureOutput *)output;
- (NSSet<AVCaptureDeviceInput *> *)queue_addedDeviceInputsFromCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_setUpdatesDepthMapLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice;
- (BOOL)queue_updatesDepthMapLayer:(AVCaptureDevice *)captureDevice;

- (void)queue_setUpdatesVisionLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice;
- (BOOL)queue_updatesVisionLayer:(AVCaptureDevice *)captureDevice;

- (void)queue_startPhotoCaptureWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_startRecordingWithCaptureDevice:(AVCaptureDevice *)captureDevice;

- (void)queue_startRecordingUsingAssetWriterWithVideoDevice:(AVCaptureDevice *)videoDevice;
- (MovieWriter *)queue_movieWriterWithVideoDevice:(AVCaptureDevice *)videoDevice;

- (void)queue_setPreferredStablizationModeForAllConnections:(AVCaptureVideoStabilizationMode)stabilizationMode forVideoDevice:(AVCaptureDevice *)videoDevice;
- (AVCaptureVideoStabilizationMode)queue_preferredStablizationModeForAllConnectionsForVideoDevice:(AVCaptureDevice *)videoDevice;

- (void)queue_setGreenGhostMitigationEnabledForAllConnections:(BOOL)greenGhostMitigationEnabled forVideoDevice:(AVCaptureDevice *)videoDevice;
- (BOOL)queue_isGreenGhostMitigationEnabledForAllConnectionsForVideoDevice:(AVCaptureDevice *)videoDevice;
@end

NS_ASSUME_NONNULL_END
