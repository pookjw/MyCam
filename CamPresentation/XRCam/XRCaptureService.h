//
//  XRCaptureService.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <CamPresentation/MovieWriter.h>
#import <CamPresentation/XRPhotoSettings.h>

NS_ASSUME_NONNULL_BEGIN

CP_EXTERN NSNotificationName const XRCaptureServiceUpdatedPreviewLayerNotificationName;
CP_EXTERN NSNotificationName const XRCaptureServiceAddedCaptureDeviceNotificationName;
CP_EXTERN NSNotificationName const XRCaptureServiceRemovedCaptureDeviceNotificationName;
CP_EXTERN NSString * const XRCaptureServiceCaptureDeviceKey;

API_AVAILABLE(visionos(1.0))
@interface XRCaptureService : NSObject
@property (retain, nonatomic, readonly) dispatch_queue_t captureSessionQueue;
@property (retain, nonatomic, readonly, nullable) AVCaptureSession *captureSession;
@property (retain, nonatomic, readonly) AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession;
@property (retain, nonatomic, readonly) NSSet<AVCaptureDevice *> *queue_addedCaptureDevices;
@property (retain, nonatomic, readonly) NSSet<AVCaptureDevice *> *queue_addedVideoDevices;
@property (nonatomic, readonly, nullable) AVCaptureDevice *defaultVideoDevice;
@property (retain, nonatomic, nullable, readonly) __kindof CALayer *queue_previewLayer;

- (void)queue_addCaptureDevice:(AVCaptureDevice *)captureDevice;
- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice;
- (NSSet<__kindof AVCaptureOutput *> *)queue_outputClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice;
- (XRPhotoSettings *)queue_photoSettingsForVideoDevice:(AVCaptureDevice *)videoDevice;
- (void)queue_setPhotoSettings:(XRPhotoSettings *)photoSettings forVideoDevice:(AVCaptureDevice *)videoDevice;

- (void)queue_startPhotoCaptureWithVideoDevice:(AVCaptureDevice *)videoDevice;
- (MovieWriter *)queue_movieWriterForVideoDevice:(AVCaptureDevice *)videoDevice;
@end

NS_ASSUME_NONNULL_END
