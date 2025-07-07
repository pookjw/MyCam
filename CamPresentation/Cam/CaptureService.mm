//
//  CaptureService.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureService.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/AVCaptureSession+CP_Private.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <CoreLocation/CoreLocation.h>
#import <CamPresentation/NSStringFromCMVideoDimensions.h>
#import <CamPresentation/ImageBufferLayer.h>
#import <CamPresentation/MetadataObjectsLayer.h>
#import <CamPresentation/NSURL+CP.h>
#import <UIKit/UIKit.h>

/*
 Rotation이랑 (Connection쪽)
 Switch할 때 Rotation쪽 봐야 할 것 같음
 */

#warning HDR Format Filter
#warning Zoom, Exposure
#warning AVCaptureDataOutputSynchronizer, AVControlCenterModuleState AVControlCenterCaptureDeviceWatcher
#warning 녹화할 때 connection에 audio도 추가해야함

#warning AVCaptureFileOutput.maxRecordedDuration
#warning KVO에서 is 제거

#warning AVCaptureMetadataInput - remove/switch 대응

#warning isShutterSoundSuppressionEnabled

#warning CIPortraitEffectContour
#warning AVCaptureVideoThumbnailOutput

AVF_EXPORT AVMediaType const AVMediaTypeVisionData;
AVF_EXPORT AVMediaType const AVMediaTypePointCloudData;
AVF_EXPORT AVMediaType const AVMediaTypeCameraCalibrationData;

NSNotificationName const CaptureServiceDidAddDeviceNotificationName = @"CaptureServiceDidAddDeviceNotificationName";
NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName = @"CaptureServiceDidRemoveDeviceNotificationName";
NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName = @"CaptureServiceReloadingPhotoFormatMenuNeededNotificationName";
NSString * const CaptureServiceCaptureDeviceKey = @"CaptureServiceCaptureDeviceKey";

NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName = @"CaptureServiceDidUpdatePreviewLayersNotificationName";
NSNotificationName const CaptureServiceDidUpdatePointCloudLayersNotificationName = @"CaptureServiceDidUpdatePointCloudLayersNotificationName";

NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName = @"CaptureServiceDidChangeCaptureReadinessNotificationName";
NSString * const CaptureServiceCaptureReadinessKey = @"CaptureServiceCaptureReadinessKey";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (retain, nonatomic, readonly) dispatch_queue_t audioDataOutputQueue;
@property (retain, nonatomic, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *queue_customPreviewLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVSampleBufferDisplayLayer *> *queue_sampleBufferDisplayLayersByVideoDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, CALayer *> *queue_videoThumbnailLayersByVideoDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *queue_depthMapLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *queue_pointCloudLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *queue_visionLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, MetadataObjectsLayer *> *queue_metadataObjectsLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, NerualAnalyzerLayer *> *queue_nerualAnalyzerLayersByVideoDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *queue_photoFormatModelsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *queue_readinessCoordinatorByCapturePhotoOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *queue_movieFileOutputsByFileOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureMetadataInput *> *queue_metadataInputsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, MovieWriter *> *queue_movieWritersByVideoDevice;
@property (retain, nonatomic, readonly) NSMapTable<MovieWriter *, AVCaptureAudioDataOutput *> *adoQueue_audioDataOutputsByMovieWriter;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureAudioDataOutput *, id> *adoQueue_audioSourceFormatHintsByAudioDataOutput;

// Capture 할 때 -[AVWeakReferencingDelegateStorage setDelegate:queue:]에 Main Queue가 할당됨
@property (retain, nonatomic, readonly) NSMapTable<NSNumber *, AVCapturePhoto *> *mainQueue_capturePhotosByUniqueID;
@property (retain, nonatomic, readonly) NSMapTable<NSNumber *, NSURL *> *mainQueue_livePhotoMovieFileURLsByUniqueID;
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService

+ (void)load {
    if (Protocol *AVCapturePointCloudDataOutputDelegate = NSProtocolFromString(@"AVCapturePointCloudDataOutputDelegate")) {
        assert(AVCapturePointCloudDataOutputDelegate != nil);
        assert(class_addProtocol(self, AVCapturePointCloudDataOutputDelegate));
    }
    
    if (Protocol *AVCaptureVisionDataOutputDelegate = NSProtocolFromString(@"AVCaptureVisionDataOutputDelegate")) {
        assert(AVCaptureVisionDataOutputDelegate != nil);
        assert(class_addProtocol(self, AVCaptureVisionDataOutputDelegate));
    }
    
    if (Protocol *AVCaptureCameraCalibrationDataOutputDelegate = NSProtocolFromString(@"AVCaptureCameraCalibrationDataOutputDelegate")) {
        assert(AVCaptureCameraCalibrationDataOutputDelegate != nil);
        assert(class_addProtocol(self, AVCaptureCameraCalibrationDataOutputDelegate));
    }
    
    if (Protocol *AVCaptureVideoThumbnailContentsDelegate = NSProtocolFromString(@"AVCaptureVideoThumbnailContentsDelegate")) {
        assert(AVCaptureVideoThumbnailContentsDelegate != nil);
        assert(class_addProtocol(self, AVCaptureVideoThumbnailContentsDelegate));
    }
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t captureSessionAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", captureSessionAttr);
        
        dispatch_queue_attr_t audioDataOutputAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("Audio Data Output Queue", audioDataOutputAttr);
        
        //
        
        NSArray<AVCaptureDeviceType> *allDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allDeviceTypes"));
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:allDeviceTypes
                                                                                                                                     mediaType:nil
                                                                                                                                      position:AVCaptureDevicePositionUnspecified];
        
        //
        
        AVExternalStorageDeviceDiscoverySession *externalStorageDeviceDiscoverySession = AVExternalStorageDeviceDiscoverySession.sharedSession;
        [externalStorageDeviceDiscoverySession addObserver:self forKeyPath:@"externalStorageDevices" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *photoFormatModelsByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *customPreviewLayersByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVSampleBufferDisplayLayer *> *sampleBufferDisplayLayersByVideoDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, CALayer *> *videoThumbnailLayersByVideoDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *depthMapLayersByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *pointCloudLayersByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, ImageBufferLayer *> *visionLayersByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, MetadataObjectsLayer *> *metadataObjectsLayersByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, NerualAnalyzerLayer *> *nerualAnalyzerLayersByVideoDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *movieFileOutputsByFileOutput = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVCaptureMetadataInput *> *metadataInputsByCaptureDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, MovieWriter *> *movieWritersByVideoDevice = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<NSNumber *, AVCapturePhoto *> *capturePhotosByUniqueID = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<NSNumber *, NSURL *> *livePhotoMovieFileURLsByUniqueID = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<MovieWriter *, AVCaptureAudioDataOutput *> *audioDataOutputsByMovieWriter = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable<AVCaptureAudioDataOutput *, id> *audioSourceFormatHintsByAudioDataOutput = [NSMapTable strongToStrongObjectsMapTable];
        
        //
        
        CLLocationManager *locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        
#if !TARGET_OS_TV
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startUpdatingLocation];
#endif
        
        //
        
        _captureSessionQueue = captureSessionQueue;
        _audioDataOutputQueue = audioDataOutputQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _externalStorageDeviceDiscoverySession = [externalStorageDeviceDiscoverySession retain];
        _queue_photoFormatModelsByCaptureDevice = [photoFormatModelsByCaptureDevice retain];
        _locationManager = locationManager;
        _queue_rotationCoordinatorsByCaptureDevice = [rotationCoordinatorsByCaptureDevice retain];
        _queue_readinessCoordinatorByCapturePhotoOutput = [readinessCoordinatorByCapturePhotoOutput retain];
        _queue_customPreviewLayersByCaptureDevice = [customPreviewLayersByCaptureDevice retain];
        _queue_sampleBufferDisplayLayersByVideoDevice = [sampleBufferDisplayLayersByVideoDevice retain];
        _queue_videoThumbnailLayersByVideoDevice = [videoThumbnailLayersByVideoDevice retain];
        _queue_depthMapLayersByCaptureDevice = [depthMapLayersByCaptureDevice retain];
        _queue_visionLayersByCaptureDevice = [visionLayersByCaptureDevice retain];
        _queue_pointCloudLayersByCaptureDevice = [pointCloudLayersByCaptureDevice retain];
        _queue_metadataObjectsLayersByCaptureDevice = [metadataObjectsLayersByCaptureDevice retain];
        _queue_nerualAnalyzerLayersByVideoDevice = [nerualAnalyzerLayersByVideoDevice retain];
        _queue_movieFileOutputsByFileOutput = [movieFileOutputsByFileOutput retain];
        _queue_metadataInputsByCaptureDevice = [metadataInputsByCaptureDevice retain];
        _queue_movieWritersByVideoDevice = [movieWritersByVideoDevice retain];
        _adoQueue_audioDataOutputsByMovieWriter = [audioDataOutputsByMovieWriter retain];
        _adoQueue_audioSourceFormatHintsByAudioDataOutput = [audioSourceFormatHintsByAudioDataOutput retain];
        _mainQueue_capturePhotosByUniqueID = [capturePhotosByUniqueID retain];
        _mainQueue_livePhotoMovieFileURLsByUniqueID = [livePhotoMovieFileURLsByUniqueID retain];
        _queue_fileOutput = [[PhotoLibraryFileOutput alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
        
        [AVCaptureDevice addObserver:self forKeyPath:@"centerStageEnabled" options:NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [AVCaptureDevice removeObserver:self forKeyPath:@"centerStageEnabled"];
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    
    for (__kindof AVCaptureInput *input in _queue_captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto captureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            if (![allVideoDeviceTypes containsObject:captureDevice.deviceType]) continue;
            [self removeObserversForVideoCaptureDevice:captureDevice];
        }
    }
    
    for (__kindof AVCaptureOutput *output in _queue_captureSession.outputs) {
        if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
            auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
            [self removeObserversForPhotoOutput:photoOutput];
        }
    }
    
    if ([_queue_captureSession isKindOfClass:AVCaptureMultiCamSession.class]) {
        [_queue_captureSession removeObserver:self forKeyPath:@"hardwareCost"];
        [_queue_captureSession removeObserver:self forKeyPath:@"systemPressureCost"];
    }
    
    [_queue_captureSession release];
    
    dispatch_release(_captureSessionQueue);
    dispatch_release(_audioDataOutputQueue);
    
    [_captureDeviceDiscoverySession release];
    [_externalStorageDeviceDiscoverySession removeObserver:self forKeyPath:@"externalStorageDevices"];
    [_externalStorageDeviceDiscoverySession release];
    
    for (AVCaptureDeviceRotationCoordinator *rotationCoordinator in _queue_rotationCoordinatorsByCaptureDevice.objectEnumerator) {
        [self removeObserversForRotationCoordinator:rotationCoordinator];
    }
    
    for (CALayer *videoThumbnailLayer in _queue_videoThumbnailLayersByVideoDevice.objectEnumerator) {
        [self removeObservsersVideoThumbnailLayer:videoThumbnailLayer];
    }
    
    [_queue_rotationCoordinatorsByCaptureDevice release];
    [_queue_photoFormatModelsByCaptureDevice release];
    [_queue_readinessCoordinatorByCapturePhotoOutput release];
    [_queue_customPreviewLayersByCaptureDevice release];
    [_queue_sampleBufferDisplayLayersByVideoDevice release];
    [_queue_videoThumbnailLayersByVideoDevice release];
    [_queue_depthMapLayersByCaptureDevice release];
    [_queue_pointCloudLayersByCaptureDevice release];
    [_queue_visionLayersByCaptureDevice release];
    [_queue_metadataObjectsLayersByCaptureDevice release];
    [_queue_nerualAnalyzerLayersByVideoDevice release];
    [_queue_movieFileOutputsByFileOutput release];
    [_queue_metadataInputsByCaptureDevice release];
    [_queue_movieWritersByVideoDevice release];
    [_adoQueue_audioDataOutputsByMovieWriter release];
    [_adoQueue_audioSourceFormatHintsByAudioDataOutput release];
    [_mainQueue_capturePhotosByUniqueID release];
    [_mainQueue_livePhotoMovieFileURLsByUniqueID release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [_queue_fileOutput release];
    [super dealloc];
}

//- (BOOL)respondsToSelector:(SEL)aSelector {
//    BOOL responds = [super respondsToSelector:aSelector];
//    
//    if (!responds) {
//        NSLog(@"%@: %s", NSStringFromClass(self.class), sel_getName(aSelector));
//    }
//    
//    return responds;
//}

+ (BOOL)conformsToProtocol:(Protocol *)protocol {
    BOOL confroms = [super conformsToProtocol:protocol];
    
    if (!confroms) {
        NSLog(@"%@: %@", NSStringFromClass(self), NSStringFromProtocol(protocol));
    }
    
    return confroms;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.externalStorageDeviceDiscoverySession]) {
        if ([keyPath isEqualToString:@"externalStorageDevices"]) {
            dispatch_async(self.captureSessionQueue, ^{
                __kindof BaseFileOutput *fileOutput = self.queue_fileOutput;
                
                if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
                    auto output = static_cast<ExternalStorageDeviceFileOutput *>(fileOutput);
                    
                    if (!output.externalStorageDevice.isConnected) {
                        self.queue_fileOutput = nil;
                    }
                }
            });
            return;
        }
    } else if ([object isKindOfClass:AVCaptureMultiCamSession.class]) {
        if ([keyPath isEqualToString:@"hardwareCost"]) {
            NSLog(@"hardwareCost: %@", change[NSKeyValueChangeNewKey]);
            return;
        } else if ([keyPath isEqualToString:@"systemPressureCost"]) {
            NSLog(@"systemPressureCost: %@", change[NSKeyValueChangeNewKey]);
            return;
        }
    } else if ([object isKindOfClass:AVCaptureDeviceRotationCoordinator.class]) {
        if ([keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
            auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
            
            dispatch_async(self.captureSessionQueue, ^{
                auto previewLayer = static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer);
                assert(previewLayer != nil);
                assert(previewLayer.connection != nil);
                
                previewLayer.connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
                
                AVCaptureDevice *videoDevice = [self queue_captureDeviceFromPreviewLayer:previewLayer];
                assert(videoDevice != nil);
                
                for (AVCaptureVideoDataOutput *videoDataOutput in [self queue_outputClass:AVCaptureVideoDataOutput.class fromCaptureDevice:videoDevice]) {
                    for (AVCaptureConnection *connection in videoDataOutput.connections) {
                        if (videoDataOutput.deliversPreviewSizedOutputBuffers) {
                            connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
                        }
                    }
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"videoRotationAngleForHorizonLevelCapture"]) {
            auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
            
            dispatch_async(self.captureSessionQueue, ^{
                auto previewLayer = static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer);
                assert(previewLayer != nil);
                
                AVCaptureDevice *videoDevice = [self queue_captureDeviceFromPreviewLayer:previewLayer];
                assert(videoDevice != nil);
                
                for (AVCaptureVideoDataOutput *videoDataOutput in [self queue_outputClass:AVCaptureVideoDataOutput.class fromCaptureDevice:videoDevice]) {
                    for (AVCaptureConnection *connection in videoDataOutput.connections) {
                        if (!videoDataOutput.deliversPreviewSizedOutputBuffers) {
                            connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture;
                        }
                    }
                }
            });
            return;
        }
    } else if ([object isKindOfClass:AVCaptureDevice.class]) {
        auto captureDevice = static_cast<AVCaptureDevice *>(object);
        
        if ([keyPath isEqualToString:@"activeFormat"]) {
            if (captureDevice != nil) {
                [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
            }
            return;
        } else if ([keyPath isEqualToString:@"formats"]) {
            if (captureDevice != nil) {
                [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
            }
            return;
        } else if ([keyPath isEqualToString:@"torchAvailable"]) {
            if (captureDevice != nil) {
                [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
            }
            return;
        } else if ([keyPath isEqualToString:@"activeDepthDataFormat"]) {
            if (captureDevice != nil) {
                if (captureDevice.activeDepthDataFormat == nil) {
                    [self queue_setUpdatesDepthMapLayer:NO captureDevice:captureDevice];
                }
                
                [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
            }
            return;
        } else if ([keyPath isEqualToString:@"isCenterStageActive"]) {
            if (captureDevice != nil) {
                [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
            }
            return;
        }
    } else if ([object isKindOfClass:AVCapturePhotoOutput.class]) {
        if ([keyPath isEqualToString:@"availablePhotoPixelFormatTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoCodecTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateCodecTypeIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoPixelFormatTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoFileTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateRawFileTypeIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoFileTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateProcessedFileTypeIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isSpatialPhotoCaptureSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAutoDeferredPhotoDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"supportedFlashModes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isZeroShutterLagSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isResponsiveCaptureSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAppleProRAWSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isFastCapturePrioritizationSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isCameraCalibrationDataDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isDepthDataDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availableLivePhotoVideoCodecTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                
                for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
                    MutablePhotoFormatModel *copy = [[self queue_photoFormatModelForCaptureDevice:captureDevice] mutableCopy];
                    
                    [copy updateLivePhotoVideoCodecTypeWithPhotoOutput:photoOutput];
                    
                    [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                    
                    [copy release];
                }
            });
            return;
        }
    } else if ([object isEqual:AVCaptureDevice.class]) {
        if ([keyPath isEqualToString:@"centerStageEnabled"]) {
#warning TODO
            return;
        }
    } else if ([object class] == [CALayer class]) {
        if ([keyPath isEqualToString:@"bounds"] or [keyPath isEqualToString:@"contentsScale"]) {
            dispatch_async(self.captureSessionQueue, ^{
                BOOL found = NO;
                
                for (AVCaptureDevice *videoDevice in self.queue_videoThumbnailLayersByVideoDevice.keyEnumerator) {
                    CALayer *layer = [self.queue_videoThumbnailLayersByVideoDevice objectForKey:videoDevice];
                    
                    if ([layer isEqual:object]) {
                        assert(!found);
                        
                        NSSet<__kindof AVCaptureOutput *> *videoThumbnailOutputs = [self queue_outputClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput") fromCaptureDevice:videoDevice];
                        
                        for (__kindof AVCaptureOutput *output in videoThumbnailOutputs) {
                            CGRect bounds = layer.bounds;
                            
                            if (!CGRectIsNull(bounds) and !CGRectIsEmpty(bounds)) {
                                CGFloat contentsScale = layer.contentsScale;
                                CGSize thumbnailSize = bounds.size;
                                thumbnailSize.width *= contentsScale;
                                thumbnailSize.height *= contentsScale;
                                
                                [self.queue_captureSession beginConfiguration];
                                reinterpret_cast<void (*)(id, SEL, CGSize)>(objc_msgSend)(output, sel_registerName("setThumbnailSize:"), thumbnailSize);
                                [self.queue_captureSession commitConfiguration];
                            }
                        }
                        
                        found = YES;
                    }
                }
                
                assert(found);
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSArray<AVCaptureDevice *> *)queue_addedCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableArray<AVCaptureDevice *> *captureDevices = [NSMutableArray new];
    
    for (__kindof AVCaptureInput *input in self.queue_captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            AVCaptureDevice *captureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}

- (NSArray<AVCaptureDevice *> *)queue_addedVideoCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    NSMutableArray<AVCaptureDevice *> *captureDevices = [NSMutableArray new];
    
    for (AVCaptureDevice *captureDevice in self.queue_addedCaptureDevices) {
        if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}

- (NSArray<AVCaptureDevice *> *)queue_addedAudioCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    NSMutableArray<AVCaptureDevice *> *captureDevices = [NSMutableArray new];
    
    for (AVCaptureDevice *captureDevice in self.queue_addedCaptureDevices) {
        if ([allAudioDeviceTypes containsObject:captureDevice.deviceType]) {
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}


- (NSArray<AVCaptureDevice *> *)queue_addedPointCloudCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    NSMutableArray<AVCaptureDevice *> *captureDevices = [NSMutableArray new];
    
    for (AVCaptureDevice *captureDevice in self.queue_addedCaptureDevices) {
        if ([allPointCloudDeviceTypes containsObject:captureDevice.deviceType]) {
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}

- (AVCaptureDevice *)defaultVideoCaptureDevice {
    AVCaptureDevice * _Nullable captureDevice = AVCaptureDevice.userPreferredCamera;
    
    if (captureDevice == nil) {
        captureDevice = AVCaptureDevice.systemPreferredCamera;
    }
    
    if (captureDevice.uniqueID == nil) {
        // Simulator
        return nil;
    }
    
    return captureDevice;
}

- (void)queue_setFileOutput:(__kindof BaseFileOutput *)fileOutput {
    dispatch_assert_queue(self.captureSessionQueue);
    
    [_queue_fileOutput release];
    
    if (fileOutput == nil) {
        _queue_fileOutput = [[PhotoLibraryFileOutput alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
    } else {
        _queue_fileOutput = [fileOutput retain];
    }
    
    for (MovieWriter *movieWriter in self.queue_movieWritersByVideoDevice.objectEnumerator) {
        assert(movieWriter.status == MovieWriterStatusPending);
        movieWriter.fileOutput = fileOutput;
    }
}

- (NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *)queue_previewLayersByCaptureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *table = [NSMapTable weakToStrongObjectsMapTable];
    
    for (AVCaptureDevice *videoDevice in self.queue_addedVideoCaptureDevices) {
        AVCaptureVideoPreviewLayer *previewLayer = [self queue_previewLayerFromCaptureDevice:videoDevice];
        assert(previewLayer != nil);
        [table setObject:previewLayer forKey:videoDevice];
    }
    
    return table;
}

- (NSMapTable<AVCaptureDevice *,PixelBufferLayer *> *)queue_customPreviewLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_customPreviewLayersByCaptureDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,AVSampleBufferDisplayLayer *> *)queue_sampleBufferDisplayLayersByVideoDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_sampleBufferDisplayLayersByVideoDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,CALayer *> *)queue_videoThumbnailLayersByVideoDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_videoThumbnailLayersByVideoDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,__kindof CALayer *> *)queue_depthMapLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_depthMapLayersByCaptureDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,__kindof CALayer *> *)queue_pointCloudLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_pointCloudLayersByCaptureDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,__kindof CALayer *> *)queue_visionLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_visionLayersByCaptureDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *,__kindof CALayer *> *)queue_metadataObjectsLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_metadataObjectsLayersByCaptureDevice copy] autorelease];
}

- (NSMapTable<AVCaptureDevice *, NerualAnalyzerLayer *> *)queue_nerualAnalyzerLayersByVideoDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_nerualAnalyzerLayersByVideoDevice copy] autorelease];
}

- (void)queue_addCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    
    if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_addVideoCapureDevice:captureDevice];
        return;
    }
    
    //
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    if ([allAudioDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_addAudioCapureDevice:captureDevice];
        return;
    }
    
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    
    if ([allPointCloudDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_addPointCloudCaptureDevice:captureDevice];
        return;
    }
    
    abort();
}

- (void)_queue_addVideoCapureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert(![self.queue_addedVideoCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    __kindof AVCaptureSession *captureSession = [self queue_switchCaptureSessionByAddingDevice:YES postNotification:NO];
    
    [self addObserversForVideoCaptureDevice:captureDevice];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
    previewLayer.hidden = NO;
    
    assert([self.queue_customPreviewLayersByCaptureDevice objectForKey:captureDevice] == nil);
    PixelBufferLayer *customPreviewLayer = [PixelBufferLayer new];
    [self.queue_customPreviewLayersByCaptureDevice setObject:customPreviewLayer forKey:captureDevice];
    customPreviewLayer.hidden = YES;
    [customPreviewLayer release];
    
    assert([self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:captureDevice] == nil);
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [AVSampleBufferDisplayLayer new];
    [self.queue_sampleBufferDisplayLayersByVideoDevice setObject:sampleBufferDisplayLayer forKey:captureDevice];
    sampleBufferDisplayLayer.hidden = YES;
    [sampleBufferDisplayLayer release];
    
    assert([self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:captureDevice] == nil);
    NerualAnalyzerLayer *nerualAnalyzerLayer = [NerualAnalyzerLayer new];
    [self.queue_nerualAnalyzerLayersByVideoDevice setObject:nerualAnalyzerLayer forKey:captureDevice];
    nerualAnalyzerLayer.hidden = YES;
    nerualAnalyzerLayer.modelType = std::nullopt;
    [nerualAnalyzerLayer release];
    
    assert([self.queue_videoThumbnailLayersByVideoDevice objectForKey:captureDevice] == nil);
    CALayer *videoThumbnailLayer = [CALayer new];
    [self.queue_videoThumbnailLayersByVideoDevice setObject:videoThumbnailLayer forKey:captureDevice];
    videoThumbnailLayer.hidden = YES;
    [self addObservsersVideoThumbnailLayer:videoThumbnailLayer];
    
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
    [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
    [self registerObserversForRotationCoordinator:rotationCoodinator];
    
    [captureSession beginConfiguration];
    
    NSString *reason = nil;
    NSError * _Nullable error = nil;
    
    AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    assert([captureSession canAddInput:newInput]);
    
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newInput, sel_registerName("setBackgroundReplacementAllowed:"), YES);
    
    // -addInputWithNoConnections: 전에 해야함 -addInputWithNoConnections:에서 changeSeed에 KVO를 시켜야 하기 때문. 안하면 remove 할 때 문제됨
    if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice.activeFormat, sel_registerName("isVisionDataDeliverySupported"))) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newInput, sel_registerName("setVisionDataDeliveryEnabled:"), YES);
    } else {
        // TODO: activeFormat이 바뀔 때마다 처리해줘야 하나?
        [captureDevice.formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(obj, sel_registerName("isVisionDataDeliverySupported"))) {
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeFormat = obj;
                [captureDevice unlockForConfiguration];
                reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newInput, sel_registerName("setVisionDataDeliveryEnabled:"), YES);
                *stop = YES;
            }
        }];
    }
    
    if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice.activeFormat, sel_registerName("isCameraCalibrationDataDeliverySupported"))) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newInput, sel_registerName("setCameraCalibrationDataDeliveryEnabled:"), YES);
    } else {
        // TODO: activeFormat이 바뀔 때마다 처리해줘야 하나?
        [captureDevice.formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(obj, sel_registerName("isCameraCalibrationDataDeliverySupported"))) {
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeFormat = obj;
                [captureDevice unlockForConfiguration];
                reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newInput, sel_registerName("setCameraCalibrationDataDeliveryEnabled:"), YES);
                *stop = YES;
            }
        }];
    }
    
    [captureSession addInputWithNoConnections:newInput];
    
    AVCaptureInputPort *videoInputPort = [newInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    assert(videoInputPort != nil);
    AVCaptureInputPort * _Nullable depthDataInputPort = [newInput portsWithMediaType:AVMediaTypeDepthData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    AVCaptureInputPort * _Nullable visionDataInputPort = [newInput portsWithMediaType:AVMediaTypeVisionData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    AVCaptureInputPort * _Nullable cameraCalibrationDataInputPort = [newInput portsWithMediaType:AVMediaTypeCameraCalibrationData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    AVCaptureInputPort * _Nullable metadataObjectInputPort = [newInput portsWithMediaType:AVMediaTypeMetadataObject sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    
    //
    
    AVCaptureConnection *previewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:previewLayer];
    previewLayerConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    previewLayerConnection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
    previewLayerConnection.enabled = YES;
    [previewLayer release];
    assert([captureSession canAddConnection:previewLayerConnection]);
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    AVCapturePhotoOutput *photoOutput = [AVCapturePhotoOutput new];
    photoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
    [self addObserversForPhotoOutput:photoOutput];
    
    [captureSession addOutputWithNoConnections:photoOutput];
    AVCaptureConnection *photoOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:photoOutput];
    photoOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    assert([captureSession canAddConnection:photoOutputConnection]);
    [captureSession addConnection:photoOutputConnection];
    [photoOutputConnection release];
    
    [newInput release];
    
    //
    
    AVCaptureVideoDataOutput *previewVideoDataOutput = [AVCaptureVideoDataOutput new];
    previewVideoDataOutput.automaticallyConfiguresOutputBufferDimensions = NO;
    previewVideoDataOutput.deliversPreviewSizedOutputBuffers = YES;
    previewVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [previewVideoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
    assert([captureSession canAddOutput:previewVideoDataOutput]);
    [captureSession addOutputWithNoConnections:previewVideoDataOutput];
    
    AVCaptureConnection *videoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:previewVideoDataOutput];
    [previewVideoDataOutput release];
    videoDataOutputConnection.enabled = NO;
    videoDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    assert([captureSession canAddConnection:videoDataOutputConnection]);
    [captureSession addConnection:videoDataOutputConnection];
    videoDataOutputConnection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
    [videoDataOutputConnection release];
    
    //
    
    AVCaptureVideoDataOutput *movieVideoDataOutput = [AVCaptureVideoDataOutput new];
    assert([captureSession canAddOutput:movieVideoDataOutput]);
    [captureSession addOutputWithNoConnections:movieVideoDataOutput];
    
    AVCaptureConnection *movieVideoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:movieVideoDataOutput];
    movieVideoDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    assert([captureSession canAddConnection:movieVideoDataOutputConnection]);
    [captureSession addConnection:movieVideoDataOutputConnection];
    movieVideoDataOutputConnection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelCapture;
    [movieVideoDataOutputConnection release];
    
    CLLocationManager *locationManager = self.locationManager;
    
    MovieWriter *movieWriter = [[MovieWriter alloc] initWithFileOutput:self.queue_fileOutput
                                                       videoDataOutput:movieVideoDataOutput
                                                      useFastRecording:NO
                                                         isolatedQueue:self.captureSessionQueue
                                                       locationHandler:^CLLocation * _Nullable{
        return locationManager.location;
    }];
    
    [movieVideoDataOutput release];
    
    [self.queue_movieWritersByVideoDevice setObject:movieWriter forKey:captureDevice];
    [movieWriter release];
    
    //
    
    [rotationCoodinator release];
    
    //
    
    if (depthDataInputPort != nil) {
        AVCaptureDepthDataOutput *depthDataOutput = [AVCaptureDepthDataOutput new];
        depthDataOutput.filteringEnabled = YES;
        depthDataOutput.alwaysDiscardsLateDepthData = YES;
        [depthDataOutput setDelegate:self callbackQueue:self.captureSessionQueue];
        assert([captureSession canAddOutput:depthDataOutput]);
        [captureSession addOutputWithNoConnections:depthDataOutput];
        
        AVCaptureConnection *depthDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[depthDataInputPort] output:depthDataOutput];
        [depthDataOutput release];
        depthDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
        depthDataOutputConnection.videoMirrored = YES;
        depthDataOutputConnection.enabled = NO;
        assert([captureSession canAddConnection:depthDataOutputConnection]);
        [captureSession addConnection:depthDataOutputConnection];
        [depthDataOutputConnection release];
        
        ImageBufferLayer *depthMapLayer = [ImageBufferLayer new];
        depthMapLayer.opacity = 0.75f;
        [self.queue_depthMapLayersByCaptureDevice setObject:depthMapLayer forKey:captureDevice];
        [depthMapLayer release];
    }
    
    //
    
    // Depth를 전달하는 Device에서는 안 됨. 왜인지 모르겠음
    // AVCaptureDepthDataOutput를 추가하지 않아도 안 됨
    if (visionDataInputPort != nil && depthDataInputPort == nil) {
        __kindof AVCaptureOutput *visionDataOutput = [objc_lookUpClass("AVCaptureVisionDataOutput") new];
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(visionDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
        assert([captureSession canAddOutput:visionDataOutput]);
        [captureSession addOutputWithNoConnections:visionDataOutput];
        
        AVCaptureConnection *visionDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[visionDataInputPort] output:visionDataOutput];
        [visionDataOutput release];
        visionDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
        visionDataOutputConnection.enabled = NO;
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), visionDataOutputConnection, &reason));
        [captureSession addConnection:visionDataOutputConnection];
        [visionDataOutputConnection release];
        
        ImageBufferLayer *visionLayer = [ImageBufferLayer new];
        visionLayer.opacity = 0.75f;
        [self.queue_visionLayersByCaptureDevice setObject:visionLayer forKey:captureDevice];
        [visionLayer release];
    }
    
    //
    
    if (cameraCalibrationDataInputPort != nil) {
        __kindof AVCaptureOutput *calibrationDataOutput = [objc_lookUpClass("AVCaptureCameraCalibrationDataOutput") new];
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(calibrationDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
        assert([captureSession canAddOutput:calibrationDataOutput]);
        [captureSession addOutputWithNoConnections:calibrationDataOutput];
        
        AVCaptureConnection *calibrationDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[cameraCalibrationDataInputPort] output:calibrationDataOutput];
        [calibrationDataOutput release];
        calibrationDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), calibrationDataOutputConnection, &reason));
        [captureSession addConnection:calibrationDataOutputConnection];
        [calibrationDataOutputConnection release];
    }
    
    //
    
    if (metadataObjectInputPort != nil) {
        AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
        [self addObserversForMetadataOutput:metadataOutput];
        [metadataOutput setMetadataObjectsDelegate:self queue:self.captureSessionQueue];
        assert([captureSession canAddOutput:metadataOutput]);
        [captureSession addOutputWithNoConnections:metadataOutput];
        
        AVCaptureConnection *metadataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[metadataObjectInputPort] output:metadataOutput];
        [metadataOutput release];
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), metadataOutputConnection, &reason));
        [captureSession addConnection:metadataOutputConnection];
        [metadataOutputConnection release];
        
        MetadataObjectsLayer *metadataObjectsLayer = [MetadataObjectsLayer new];
        [self.queue_metadataObjectsLayersByCaptureDevice setObject:metadataObjectsLayer forKey:captureDevice];
        [metadataObjectsLayer release];
    }
    
    //
    
    __kindof AVCaptureOutput *videoThumbnailOutput = [objc_lookUpClass("AVCaptureVideoThumbnailOutput") new];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(videoThumbnailOutput, sel_registerName("setThumbnailContentsDelegate:"), self);
    
    CGRect bounds = videoThumbnailLayer.bounds;
    if (!CGRectIsNull(bounds) and !CGRectIsEmpty(bounds)) {
        CGFloat contentsScale = videoThumbnailLayer.contentsScale;
        CGSize thumbnailSize = bounds.size;
        thumbnailSize.width *= contentsScale;
        thumbnailSize.height *= contentsScale;
        reinterpret_cast<void (*)(id, SEL, CGSize)>(objc_msgSend)(videoThumbnailOutput, sel_registerName("setThumbnailSize:"), thumbnailSize);
    } else {
        // 안하면 에러남
        reinterpret_cast<void (*)(id, SEL, CGSize)>(objc_msgSend)(videoThumbnailOutput, sel_registerName("setThumbnailSize:"), CGSizeMake(1800., 1200.));
    }
    
    [captureSession addOutputWithNoConnections:videoThumbnailOutput];
    
    AVCaptureConnection *videoThumbnailOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:videoThumbnailOutput];
    videoThumbnailOutputConnection.enabled = NO;
    [videoThumbnailOutput release];
    reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), videoThumbnailOutputConnection, &reason));
    [captureSession addConnection:videoThumbnailOutputConnection];
    [videoThumbnailOutputConnection release];
    
    [videoThumbnailLayer release];
    
    //
    
#if TARGET_OS_IOS
    for (__kindof AVCaptureControl *control in captureSession.controls) {
        [captureSession removeControl:control];
    }
    
    if (captureSession.supportsControls) {
        dispatch_queue_t captureSessionQueue = self.captureSessionQueue;
        NSString * _Nullable failureReason = nil;
        
        //
        
        AVCaptureSystemZoomSlider *captureSystemZoomSlider = [[AVCaptureSystemZoomSlider alloc] initWithDevice:captureDevice];
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureSystemZoomSlider, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:captureSystemZoomSlider];
        [captureSystemZoomSlider release];
        
        //
        
        AVCaptureSystemExposureBiasSlider *captureSystemExposureBiasSlider = [[AVCaptureSystemExposureBiasSlider alloc] initWithDevice:captureDevice];
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureSystemExposureBiasSlider, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:captureSystemExposureBiasSlider];
        [captureSystemExposureBiasSlider release];
        
        //
        
        AVCaptureSlider *captureSlider = [[AVCaptureSlider alloc] initWithLocalizedTitle:@"Hello Slider!"
                                                                              symbolName:@"scope"
                                                                                  values:@[
            @1, @2, @3, @5, @8, @13, @21, @34, @55
        ]];
        [captureSlider setActionQueue:captureSessionQueue action:^(float newValue) {
            NSLog(@"%lf", newValue);
        }];
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureSlider, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:captureSlider];
        [captureSlider release];
        
        //
        
        __kindof AVCaptureControl *captureToggle = reinterpret_cast<id (*)(id, SEL, id, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureToggle") alloc], sel_registerName("initWithLocalizedTitle:onSymbolName:offSymbolName:"), @"Hello Toggle!", @"drop.degreesign.fill", @"figure.water.fitness.circle");
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureToggle, sel_registerName("setOn:"), NO);
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(captureToggle, sel_registerName("setActionQueue:action:"), captureSessionQueue, ^(BOOL on) {
            NSLog(@"%d", on);
        });
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureToggle, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:captureToggle];
        [captureToggle release];
        
        //
        
//        AVCaptureIndexPicker *captureIndexPicker = [[AVCaptureIndexPicker alloc] initWithLocalizedTitle:@"Hello Index Picker!" symbolName:@"figure.waterpolo.circle.fill" numberOfIndexes:100 localizedTitleTransform:^NSString * _Nonnull(NSInteger index) {
//            return [NSString stringWithFormat:@"%ld!!!", index];
//        }];
//        [captureIndexPicker setActionQueue:captureSessionQueue action:^(NSInteger selectedIndex) {
//            NSLog(@"%ld", selectedIndex);
//        }];
//        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureIndexPicker, &failureReason);
//        assert(failureReason == nil);
//        [captureSession addControl:captureIndexPicker];
//        [captureIndexPicker release];
        
        //
        
        __kindof AVCaptureControl *systemLensSelector = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureSystemLensSelector") alloc], sel_registerName("initWithDevice:"), captureDevice);
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), systemLensSelector, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:systemLensSelector];
        [systemLensSelector release];
        
        //
        
        __kindof AVCaptureControl *systemStylePicker = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureSystemStylePicker") alloc], sel_registerName("initWithSession:"), captureSession);
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), systemStylePicker, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:systemStylePicker];
        [systemStylePicker release];
        
        //
        
        /*
         0, 1, 2
         */
        __kindof AVCaptureControl *systemStyleSlider = reinterpret_cast<id (*)(id, SEL, id, NSInteger, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureSystemStyleSlider") alloc], sel_registerName("initWithSession:parameter:action:"), captureSession, 0, nil);
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), systemStyleSlider, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:systemStyleSlider];
        [systemStyleSlider release];
    }
#endif
    
    //
    
    [captureSession commitConfiguration];
    
    AVCaptureDevice.userPreferredCamera = captureDevice;
    
    //
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:photoOutput];
    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:photoOutput];
    readinessCoordinator.delegate = self;
    [readinessCoordinator release];
    
    MutablePhotoFormatModel *photoFormatModel = [MutablePhotoFormatModel new];
    [photoFormatModel updateAllWithPhotoOutput:photoOutput];
    [photoOutput release];
    
    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
    [photoFormatModel release];
    
    [self postDidAddDeviceNotificationWithCaptureDevice:captureDevice];
    [self postDidUpdatePreviewLayersNotification];
    
    NSLog(@"%@", captureSession);
}

- (void)_queue_addAudioCapureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert(![self.queue_addedVideoCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    assert([allAudioDeviceTypes containsObject:captureDevice.deviceType]);
    
#warning AVCaptureAudioDataOutput으로 파형 그려보기
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    
    [captureSession beginConfiguration];
    
    //
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    
    NSString * _Nullable reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddInput:failureReason:"), deviceInput, &reason));
    [captureSession addInputWithNoConnections:deviceInput];
    
    NSArray<AVCaptureInputPort *> *audioDevicePorts = [deviceInput portsWithMediaType:AVMediaTypeAudio sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified];
    
    //
    
    AVCaptureAudioDataOutput *audioDataOutput = [AVCaptureAudioDataOutput new];
    [audioDataOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
    assert([captureSession canAddOutput:audioDataOutput]);
    [captureSession addOutputWithNoConnections:audioDataOutput];
    
    //
    
    AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:audioDevicePorts output:audioDataOutput];
    [deviceInput release];
    [audioDataOutput release];
    assert([captureSession canAddConnection:connection]);
    [captureSession addConnection:connection];
    [connection release];
    
    [captureSession commitConfiguration];
    
    [self postDidAddDeviceNotificationWithCaptureDevice:captureDevice];
}

- (void)_queue_addPointCloudCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert(![self.queue_addedVideoCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    assert([allPointCloudDeviceTypes containsObject:captureDevice.deviceType]);
    
    //
    
    __kindof AVCaptureSession *captureSession = [self queue_switchCaptureSessionByAddingDevice:YES postNotification:NO];
    
    [captureSession beginConfiguration];
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    
    NSString * _Nullable reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddInput:failureReason:"), deviceInput, &reason));
    [captureSession addInputWithNoConnections:deviceInput];
    
    NSArray<AVCaptureInputPort *>* pointCloudDataPorts = [deviceInput portsWithMediaType:AVMediaTypePointCloudData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified];
    
    __kindof AVCaptureOutput *pointCloudDataOutput = [objc_lookUpClass("AVCapturePointCloudDataOutput") new];
    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(pointCloudDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
    assert([captureSession canAddOutput:pointCloudDataOutput]);
    [captureSession addOutputWithNoConnections:pointCloudDataOutput];
    
    //
    
    AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:pointCloudDataPorts output:pointCloudDataOutput];
    [deviceInput release];
    [pointCloudDataOutput release];
    assert([captureSession canAddConnection:connection]);
    assert(connection.isEnabled);
    assert(connection.isActive);
    [captureSession addConnection:connection];
    [connection release];
    
    [captureSession commitConfiguration];
    
    //
    
    ImageBufferLayer *pointCloudLayer = [ImageBufferLayer new];
    [self.queue_pointCloudLayersByCaptureDevice setObject:pointCloudLayer forKey:captureDevice];
    [pointCloudLayer release];
    
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:nil];
    [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
    [self registerObserversForRotationCoordinator:rotationCoodinator];
    [rotationCoodinator release];
    
    //
    
    [self postDidAddDeviceNotificationWithCaptureDevice:captureDevice];
    [self postDidUpdatePointCloudLayersNotification];
}

- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedCaptureDevices containsObject:captureDevice]);
    
#warning Syncrhonizer
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));

    if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_removeVideoCaptureDevice:captureDevice];
        return;
    }
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    if ([allAudioDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_removeAudioCaptureDevice:captureDevice];
        return;
    }
    
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    
    if ([allPointCloudDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_removePointCloudCaptureDevice:captureDevice];
        return;
    }
    
    abort();
}

- (void)_queue_removeVideoCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedVideoCaptureDevices containsObject:captureDevice]);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:captureDevice];
    assert(movieWriter != nil);
    assert(movieWriter.status == MovieWriterStatusPending);
    
    dispatch_sync(self.audioDataOutputQueue, ^{
        [self.adoQueue_audioDataOutputsByMovieWriter removeObjectForKey:movieWriter];
    });
    
    [self.queue_movieWritersByVideoDevice removeObjectForKey:captureDevice];
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [self removeObserversForVideoCaptureDevice:captureDevice];
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    assert(captureSession != nil);
    
    //
    
    [captureSession beginConfiguration];
    
    //
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureDeviceInput *input in captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            AVCaptureDevice *oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            if ([captureDevice isEqual:oldCaptureDevice]) {
                deviceInput = input;
                break;
            }
        }
    }
    assert(deviceInput != nil);
    
    AVCaptureMetadataInput * _Nullable metadataInput = [self.queue_metadataInputsByCaptureDevice objectForKey:captureDevice];
    
    // connections loop에서 바로 output을 지워주면, output이 여러 개의 connection을 가지고 있을 때 문제된다. (예: Video Data Output -> Video Input Port, Metadata Input Port)
    // ouput이 가진 connection들을 모두 지워준 다음에 output을 지워줘야 하므로, Set에 모아놓고 나중에 output을 지운다.
    NSMutableSet<__kindof AVCaptureOutput *> *outputs = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        BOOL doesInputMatch = NO;
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if ([inputPort.input isEqual:deviceInput] || [inputPort.input isEqual:metadataInput]) {
                doesInputMatch = YES;
                break;
            }
        }
        if (!doesInputMatch) continue;
        
        //
        
        [captureSession removeConnection:connection];
        
        if (connection.videoPreviewLayer != nil) {
            connection.videoPreviewLayer.session = nil;
        } else if (connection.output != nil) {
            [outputs addObject:connection.output];
        } else {
            abort();
        }
    }
    
    //
    
    for (__kindof AVCaptureOutput *output in outputs) {
        if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
            auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
            
            [self removeObserversForPhotoOutput:photoOutput];
            
            if (AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput]) {
                readinessCoordinator.delegate = nil;
                [self.queue_readinessCoordinatorByCapturePhotoOutput removeObjectForKey:photoOutput];
            } else {
                abort();
            }
            
            [captureSession removeOutput:photoOutput];
        } else if ([output isKindOfClass:AVCaptureMovieFileOutput.class]) {
            [captureSession removeOutput:output];
        } else if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
            auto videoDataOutput = static_cast<AVCaptureVideoDataOutput *>(output);
            [videoDataOutput setSampleBufferDelegate:nil queue:nil];
            [captureSession removeOutput:videoDataOutput];
        } else if ([output isKindOfClass:AVCaptureDepthDataOutput.class]) {
            auto depthDataOutput = static_cast<AVCaptureDepthDataOutput *>(output);
            [depthDataOutput setDelegate:nil callbackQueue:nil];
            [captureSession removeOutput:depthDataOutput];
        } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(output, sel_registerName("setDelegate:callbackQueue:"), nil, nil);
            [captureSession removeOutput:output];
            
            assert([self.queue_visionLayersByCaptureDevice objectForKey:captureDevice] != nil);
            [self.queue_visionLayersByCaptureDevice removeObjectForKey:captureDevice];
        } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureCameraCalibrationDataOutput")]) {
            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(output, sel_registerName("setDelegate:callbackQueue:"), nil, nil);
            [captureSession removeOutput:output];
        } else if ([output isKindOfClass:AVCaptureMetadataOutput.class]) {
            auto metadataOutput = static_cast<AVCaptureMetadataOutput *>(output);
            [metadataOutput setMetadataObjectsDelegate:nil queue:nil];
            [self removeObserversForMetadataOutput:metadataOutput];
            [captureSession removeOutput:metadataOutput];
            
            assert([self.queue_metadataObjectsLayersByCaptureDevice objectForKey:captureDevice] != nil);
            [self.queue_metadataObjectsLayersByCaptureDevice removeObjectForKey:captureDevice];
        } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput")]) {
            assert([self.queue_videoThumbnailLayersByVideoDevice objectForKey:captureDevice] != nil);
            [self.queue_videoThumbnailLayersByVideoDevice removeObjectForKey:captureDevice];
            [captureSession removeOutput:output];
        } else {
            abort();
        }
    }
    
    [outputs release];
    
    //
    
    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
        [self removeObserversForRotationCoordinator:rotationCoordinator];
        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
    } else {
        abort();
    }
    
    assert([self.queue_customPreviewLayersByCaptureDevice objectForKey:captureDevice] != nil);
    [self.queue_customPreviewLayersByCaptureDevice removeObjectForKey:captureDevice];
    assert([self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:captureDevice] != nil);
    [self.queue_sampleBufferDisplayLayersByVideoDevice removeObjectForKey:captureDevice];
    assert([self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:captureDevice] != nil);
    [self.queue_nerualAnalyzerLayersByVideoDevice removeObjectForKey:captureDevice];
    [self.queue_metadataInputsByCaptureDevice removeObjectForKey:captureDevice];
    
    [captureSession removeInput:deviceInput];
    
    if (metadataInput != nil) {
        [captureSession removeInput:metadataInput];
    }
    
    [captureSession commitConfiguration];
    
    //
    
    [self.queue_photoFormatModelsByCaptureDevice removeObjectForKey:captureDevice];
    
    [self queue_switchCaptureSessionByAddingDevice:NO postNotification:NO];
    
    //
    
    [self postDidRemoveDeviceNotificationWithCaptureDevice:captureDevice];
    [self postDidUpdatePreviewLayersNotification];
}

- (void)_queue_removeAudioCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedAudioCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    assert([allAudioDeviceTypes containsObject:captureDevice.deviceType]);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    [captureSession beginConfiguration];
    
    //
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureDeviceInput *input in captureSession.inputs) {
        if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
        
        AVCaptureDevice *oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
        if ([captureDevice isEqual:oldCaptureDevice]) {
            deviceInput = input;
            break;
        }
    }
    assert(deviceInput != nil);
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        BOOL doesInputMatch = NO;
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if ([inputPort.input isEqual:deviceInput]) {
                doesInputMatch = YES;
                break;
            }
        }
        if (!doesInputMatch) continue;
        
        //
        
        [captureSession removeConnection:connection];
        
        if (connection.output != nil) {
            if ([connection.output isKindOfClass:AVCaptureAudioDataOutput.class]) {
                auto audioDataOutput = static_cast<AVCaptureAudioDataOutput *>(connection.output);
                [captureSession removeOutput:audioDataOutput];
                
                dispatch_sync(self.audioDataOutputQueue, ^{
                    [self.adoQueue_audioSourceFormatHintsByAudioDataOutput removeObjectForKey:audioDataOutput];
                    
                    for (MovieWriter *movieWriter in self.adoQueue_audioDataOutputsByMovieWriter) {
                        AVCaptureAudioDataOutput *_audioDataOutput = [self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter];
                        if ([_audioDataOutput isEqual:audioDataOutput]) {
                            [self.adoQueue_audioDataOutputsByMovieWriter removeObjectForKey:movieWriter];
                        }
                    }
                });
            } else if ([connection.output isKindOfClass:AVCaptureMovieFileOutput.class]) {
                // Video Devide Input과 연결되어 있을 것이기에 Output을 제거하면 안 됨
            } else {
                abort();
            }
        } else {
            abort();
        }
    }
    
    [captureSession removeInput:deviceInput];
    [captureSession commitConfiguration];
    
    [self postDidRemoveDeviceNotificationWithCaptureDevice:captureDevice];
}

- (void)_queue_removePointCloudCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedPointCloudCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    assert([allPointCloudDeviceTypes containsObject:captureDevice.deviceType]);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    [captureSession beginConfiguration];
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureDeviceInput *input in captureSession.inputs) {
        if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
        
        AVCaptureDevice *oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
        if ([captureDevice isEqual:oldCaptureDevice]) {
            deviceInput = input;
            break;
        }
    }
    assert(deviceInput != nil);
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        BOOL doesInputMatch = NO;
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if ([inputPort.input isEqual:deviceInput]) {
                doesInputMatch = YES;
                break;
            }
        }
        if (!doesInputMatch) continue;
        
        //
        
        [captureSession removeConnection:connection];
        
        if (connection.output != nil) {
            if ([connection.output isKindOfClass:objc_lookUpClass("AVCapturePointCloudDataOutput")]) {
                [captureSession removeOutput:connection.output];
            } else {
                abort();
            }
        } else {
            abort();
        }
    }
    
    [captureSession removeInput:deviceInput];
    [captureSession commitConfiguration];
    
    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
        [self removeObserversForRotationCoordinator:rotationCoordinator];
        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
    } else {
        abort();
    }
    
    [self.queue_pointCloudLayersByCaptureDevice removeObjectForKey:captureDevice];
    
    [self queue_switchCaptureSessionByAddingDevice:NO postNotification:NO];
    [self postDidRemoveDeviceNotificationWithCaptureDevice:captureDevice];
    [self postDidUpdatePointCloudLayersNotification];
}

- (PhotoFormatModel *)queue_photoFormatModelForCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    PhotoFormatModel * _Nullable copy = [[self.queue_photoFormatModelsByCaptureDevice objectForKey:captureDevice] copy];
    return [copy autorelease];
}

- (void)queue_setPhotoFormatModel:(PhotoFormatModel *)photoFormatModel forCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    PhotoFormatModel * _Nullable copy = [photoFormatModel copy];
    [self.queue_photoFormatModelsByCaptureDevice setObject:copy forKey:captureDevice];
    [copy release];
    
    for (PhotoFormatModel *photoFormatModel in self.queue_photoFormatModelsByCaptureDevice.objectEnumerator) {
        assert(photoFormatModel.class == PhotoFormatModel.class);
    }
}

- (__kindof AVCaptureOutput *)queue_toBeRemoved_outputClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice __attribute__((deprecated)) {
//    NSSet<__kindof AVCaptureOutput *> *outputs = [self queue_outputClass:outputClass fromCaptureDevice:captureDevice];
//    assert(outputs.count < 2);
//    return outputs.allObjects.firstObject;
    // -[AVCaptureSession _outputWithClass:forSourceDevice:]도 있음
    NSArray<__kindof AVCaptureOutput *> *outputs = reinterpret_cast<id (*)(id, SEL, Class, id)>(objc_msgSend)(self.queue_captureSession, sel_registerName("_outputsWithClass:forSourceDevice:"), outputClass, captureDevice);
    assert(outputs.count < 2);
    return outputs.firstObject;
}

- (NSSet<__kindof AVCaptureOutput *> *)queue_outputClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
//    NSMutableSet<__kindof AVCaptureOutput *> *outputs = [NSMutableSet new];
//    
//    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
//        if (connection.output.class != outputClass) {
//            continue;
//        }
//        
//        for (AVCaptureInputPort *port in connection.inputPorts) {
//            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
//            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
//                if ([deviceInput.device isEqual:captureDevice]) {
//                    [outputs addObject:connection.output];
//                    break;
//                }
//            }
//        }
//    }
//    
//    return [outputs autorelease];
    
    NSArray<__kindof AVCaptureOutput *> *outputs = reinterpret_cast<id (*)(id, SEL, Class, id)>(objc_msgSend)(self.queue_captureSession, sel_registerName("_outputsWithClass:forSourceDevice:"), outputClass, captureDevice);
    return [NSSet setWithArray:outputs];
}

- (void)queue_setUpdatesDepthMapLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    AVCaptureDepthDataOutput *depthDataOutput = [self queue_toBeRemoved_outputClass:AVCaptureDepthDataOutput.class fromCaptureDevice:captureDevice];
    assert(depthDataOutput != nil);
    AVCaptureConnection *connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert(connection != nil);
    
    connection.enabled = updatesDepthMapLayer;
    
    ImageBufferLayer *depthMapLayer = [self.queue_depthMapLayersByCaptureDevice objectForKey:captureDevice];
    assert(depthMapLayer != nil);
    [depthMapLayer updateWithCIImage:nil rotationAngle:0.f fill:NO];
}

- (BOOL)queue_updatesDepthMapLayer:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    AVCaptureDepthDataOutput *depthDataOutput = [self queue_toBeRemoved_outputClass:AVCaptureDepthDataOutput.class fromCaptureDevice:captureDevice];
    assert(depthDataOutput != nil);
    AVCaptureConnection *connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert(connection != nil);
    
    return connection.isEnabled;
}

- (void)queue_setUpdatesVisionLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    __kindof AVCaptureOutput *visionDataOutput = [self queue_toBeRemoved_outputClass:objc_lookUpClass("AVCaptureVisionDataOutput") fromCaptureDevice:captureDevice];
    assert(visionDataOutput != nil);
    AVCaptureConnection *connection = [visionDataOutput connectionWithMediaType:AVMediaTypeVisionData];
    assert(connection != nil);
    
    connection.enabled = updatesDepthMapLayer;
    
    ImageBufferLayer *visionLayer = [self.queue_visionLayersByCaptureDevice objectForKey:captureDevice];
    assert(visionLayer != nil);
    [visionLayer updateWithCIImage:nil rotationAngle:0.f fill:NO];
}

- (BOOL)queue_updatesVisionLayer:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    __kindof AVCaptureOutput *visionDataOutput = [self queue_toBeRemoved_outputClass:objc_lookUpClass("AVCaptureVisionDataOutput") fromCaptureDevice:captureDevice];
    assert(visionDataOutput != nil);
    AVCaptureConnection *connection = [visionDataOutput connectionWithMediaType:AVMediaTypeVisionData];
    assert(connection != nil);
    
    return connection.isEnabled;
}

- (BOOL)queue_isPreviewLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCaptureVideoPreviewLayer *previewLayer = [self queue_previewLayerFromCaptureDevice:videoDevice];
    assert(previewLayer != nil);
    assert(previewLayer.connection != nil);
    
    return previewLayer.connection.isEnabled;
}

- (void)queue_setPreviewLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCaptureVideoPreviewLayer *previewLayer = [self queue_previewLayerFromCaptureDevice:videoDevice];
    assert(previewLayer != nil);
    assert(previewLayer.connection != nil);
    
    previewLayer.connection.enabled = enabled;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        previewLayer.hidden = !enabled;
    });
}

- (BOOL)queue_isCustomPreviewLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    PixelBufferLayer *customPreviewLayer = [self.queue_customPreviewLayersByCaptureDevice objectForKey:videoDevice];
    assert(customPreviewLayer != nil);
    
    return !customPreviewLayer.isHidden;
}

- (void)queue_setCustomPreviewLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    PixelBufferLayer *customPreviewLayer = [self.queue_customPreviewLayersByCaptureDevice objectForKey:videoDevice];
    assert(customPreviewLayer != nil);
    
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:videoDevice];
    assert(sampleBufferDisplayLayer != nil);
    
    NerualAnalyzerLayer *nerualAnalyzerLayer = [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
    assert(nerualAnalyzerLayer != nil);
    
    for (AVCaptureVideoDataOutput *videoDataOutput in [self queue_outputClass:AVCaptureVideoDataOutput.class fromCaptureDevice:videoDevice]) {
        if (!videoDataOutput.deliversPreviewSizedOutputBuffers) continue;
        
        assert(videoDataOutput.connections.count == 1);
        AVCaptureConnection *connection = videoDataOutput.connections.firstObject;
        assert(connection != nil);
        
        connection.enabled = (enabled or !sampleBufferDisplayLayer.isHidden or !nerualAnalyzerLayer.isHidden);
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        customPreviewLayer.hidden = !enabled;
    });
}

- (BOOL)queue_isSampleBufferDisplayLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:videoDevice];
    assert(sampleBufferDisplayLayer != nil);
    
    return !sampleBufferDisplayLayer.isHidden;
}

- (void)queue_setSampleBufferDisplayLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    PixelBufferLayer *customPreviewLayer = [self.queue_customPreviewLayersByCaptureDevice objectForKey:videoDevice];
    assert(customPreviewLayer != nil);
    
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:videoDevice];
    assert(sampleBufferDisplayLayer != nil);
    
    NerualAnalyzerLayer *nerualAnalyzerLayer = [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
    assert(nerualAnalyzerLayer != nil);
    
    for (AVCaptureVideoDataOutput *videoDataOutput in [self queue_outputClass:AVCaptureVideoDataOutput.class fromCaptureDevice:videoDevice]) {
        if (!videoDataOutput.deliversPreviewSizedOutputBuffers) continue;
        
        assert(videoDataOutput.connections.count == 1);
        AVCaptureConnection *connection = videoDataOutput.connections.firstObject;
        assert(connection != nil);
        
        connection.enabled = (enabled or !customPreviewLayer.isHidden or !nerualAnalyzerLayer.isHidden);
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        sampleBufferDisplayLayer.hidden = !enabled;
    });
}

- (BOOL)queue_isNerualAnalyzerLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NerualAnalyzerLayer *nerualAnalyzerLayer = [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
    assert(nerualAnalyzerLayer != nil);
    
    return !nerualAnalyzerLayer.isHidden;
}

- (void)queue_setNerualAnalyzerLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    PixelBufferLayer *customPreviewLayer = [self.queue_customPreviewLayersByCaptureDevice objectForKey:videoDevice];
    assert(customPreviewLayer != nil);
    
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:videoDevice];
    assert(sampleBufferDisplayLayer != nil);
    
    NerualAnalyzerLayer *nerualAnalyzerLayer = [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
    assert(nerualAnalyzerLayer != nil);
    
    for (AVCaptureVideoDataOutput *videoDataOutput in [self queue_outputClass:AVCaptureVideoDataOutput.class fromCaptureDevice:videoDevice]) {
        if (!videoDataOutput.deliversPreviewSizedOutputBuffers) continue;
        
        assert(videoDataOutput.connections.count == 1);
        AVCaptureConnection *connection = videoDataOutput.connections.firstObject;
        assert(connection != nil);
        
        connection.enabled = (enabled or !customPreviewLayer.isHidden or !sampleBufferDisplayLayer.isHidden);
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        nerualAnalyzerLayer.hidden = !enabled;
    });
}

- (BOOL)queue_isVideoThumbnailLayerEnabledForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    CALayer *videoThumbnailLayer = [self.queue_videoThumbnailLayersByVideoDevice objectForKey:videoDevice];
    assert(videoThumbnailLayer != nil);
    
    return !videoThumbnailLayer.isHidden;
}

- (void)queue_setVideoThumbnailLayerEnabled:(BOOL)enabled forVideoDeivce:(AVCaptureDevice *)videoDevice {
    CALayer *videoThumbnailLayer = [self.queue_videoThumbnailLayersByVideoDevice objectForKey:videoDevice];
    assert(videoThumbnailLayer != nil);
    
    for (__kindof AVCaptureOutput *videoThumbnailOutput in [self queue_outputClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput") fromCaptureDevice:videoDevice]) {
        AVCaptureConnection *connection = videoThumbnailOutput.connections.firstObject;
        assert(connection != nil);
        
        connection.enabled = enabled;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        videoThumbnailLayer.hidden = !enabled;
    });
}

- (AVCaptureVideoPreviewLayer *)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        AVCaptureVideoPreviewLayer *previewLayer = connection.videoPreviewLayer;
        if (previewLayer == nil) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            
            if ([deviceInput.device isEqual:captureDevice]) {
                return previewLayer;
            }
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)queue_captureDeviceFromPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCaptureConnection *connection = previewLayer.connection;
    if (connection == nil) return nil;
    
    for (AVCaptureInputPort *inputPort in connection.inputPorts) {
        if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
        
        auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
        return deviceInput.device;
    }
    
    return nil;
}

- (__kindof CALayer *)queue_depthMapLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_depthMapLayersByCaptureDevice objectForKey:captureDevice];
}

- (__kindof CALayer *)queue_visionLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_visionLayersByCaptureDevice objectForKey:captureDevice];
}

- (__kindof CALayer *)queue_metadataObjectsLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_metadataObjectsLayersByCaptureDevice objectForKey:captureDevice];
}

- (NerualAnalyzerLayer *)queue_nerualAnalyzerLayerFromVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
}

- (AVCapturePhotoOutputReadinessCoordinator *)queue_readinessCoordinatorFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCapturePhotoOutput *photoOutput = [self queue_toBeRemoved_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    return [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput];
}

- (AVCaptureMovieFileOutput *)queue_movieFileOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto movieFileOutput = static_cast<AVCaptureMovieFileOutput *>(connection.output);
            if (![movieFileOutput isKindOfClass:AVCaptureMovieFileOutput.class]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return movieFileOutput;
                }
            }
        }
    }
    
    return nil;
}

- (NSSet<AVCaptureDevice *> *)queue_captureDevicesFromOutput:(AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableSet<AVCaptureDevice *> *captureDevices = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            [captureDevices addObject:deviceInput.device];
        }
    }
    
    return [captureDevices autorelease];
}

- (NSSet<AVCaptureDevice *> *)queue_videoCaptureDevicesFromOutput:(AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    
    NSMutableSet<AVCaptureDevice *> *captureDevices = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            if (![allVideoDeviceTypes containsObject:deviceInput.device.deviceType]) continue;
            
            [captureDevices addObject:deviceInput.device];
        }
    }
    
    return [captureDevices autorelease];
}

- (NSSet<AVCaptureDevice *> *)queue_audioCaptureDevicesFromOutput:(AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    NSMutableSet<AVCaptureDevice *> *captureDevices = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            if (![allAudioDeviceTypes containsObject:deviceInput.device.deviceType]) continue;
            
            [captureDevices addObject:deviceInput.device];
        }
    }
    
    return [captureDevices autorelease];
}

- (AVCaptureMovieFileOutput *)queue_addMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    assert([self queue_movieFileOutputFromCaptureDevice:captureDevice] == nil);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureInput *input in captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto _deviceInput = static_cast<AVCaptureDeviceInput *>(input);
            if ([_deviceInput.device isEqual:captureDevice]) {
                deviceInput = _deviceInput;
                break;
            }
        }
    }
    assert(deviceInput != nil);
    
    AVCaptureInputPort *videoInputPort = [deviceInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
    assert(videoInputPort != nil);
    
    [captureSession beginConfiguration];
    
    AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
    NSString * _Nullable reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddOutput:failureReason:"), movieFileOutput, &reason));
    [captureSession addOutputWithNoConnections:movieFileOutput];
    
    AVCaptureConnection *movieFileOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:movieFileOutput];
    movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    assert([captureSession canAddConnection:movieFileOutputConnection]);
    [captureSession addConnection:movieFileOutputConnection];
    [movieFileOutputConnection release];
    
    //
    
    CMMetadataFormatDescriptionRef formatDescription = [self newMetadataFormatDescription];
    AVCaptureMetadataInput *metadataInput = [[AVCaptureMetadataInput alloc] initWithFormatDescription:formatDescription clock:videoInputPort.clock];
    CFRelease(formatDescription);
    assert([captureSession canAddInput:metadataInput]);
    [captureSession addInputWithNoConnections:metadataInput];
    
    BOOL didAdd = NO;
    for (AVCaptureInputPort *inputPort in metadataInput.ports) {
        if ([inputPort.mediaType isEqualToString:AVMediaTypeMetadata]) {
            AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:@[inputPort] output:movieFileOutput];
            // 왜인지 모르겠지만 AVCaptureMultiCamSession 상태에서 -11819 Error가 나옴
            connection.enabled = (captureSession.class != AVCaptureMultiCamSession.class);
            
            assert([captureSession canAddConnection:connection]);
            [captureSession addConnection:connection];
            [connection release];
            didAdd = YES;
            break;
        }
    }
    assert(didAdd);
    
    [self.queue_metadataInputsByCaptureDevice setObject:metadataInput forKey:captureDevice];
    [metadataInput release];
    
    //
    
    [captureSession commitConfiguration];
    
    return [movieFileOutput autorelease];
}

- (void)queue_removeMovieFileOutputWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    [captureSession beginConfiguration];
    
    AVCaptureMovieFileOutput *movieFileOutput = nil;
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        if (![connection.output isKindOfClass:AVCaptureMovieFileOutput.class]) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            
            if ([deviceInput.device isEqual:captureDevice]) {
                movieFileOutput = static_cast<AVCaptureMovieFileOutput *>(connection.output);
                [captureSession removeConnection:connection];
                break;
            }
        }
        
        if (movieFileOutput != nil) {
            break;
        }
    }
    
    assert(movieFileOutput != nil);
    
    //
    
    AVCaptureMetadataInput *metadataInput = nil;
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        if ([connection.output isEqual:movieFileOutput]) {
            
            for (AVCaptureInputPort *inputPort in connection.inputPorts) {
                if ([inputPort.input isKindOfClass:AVCaptureMetadataInput.class]) {
                    metadataInput = static_cast<AVCaptureMetadataInput *>(inputPort.input);
                    [captureSession removeConnection:connection];
                    break;
                }
            }
        }
        
        if (metadataInput != nil) {
            break;
        }
    }
    
    assert(metadataInput != nil);
    [captureSession removeInput:metadataInput];
    
    //
    
    [captureSession removeOutput:movieFileOutput];
    
    [captureSession commitConfiguration];
}

#warning Multi Mic 지원
- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice withOutput:(AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    
    [captureSession beginConfiguration];
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureDeviceInput *input in captureSession.inputs) {
        if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
        if ([input.device isEqual:audioDevice]) {
            deviceInput = input;
            break;
        }
    }
    assert(deviceInput != nil);
    
    NSArray<AVCaptureInputPort *> *inputPorts = [deviceInput portsWithMediaType:AVMediaTypeAudio sourceDeviceType:audioDevice.deviceType sourceDevicePosition:AVCaptureDevicePositionUnspecified];
    
    AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:output];
    
    NSString * _Nullable reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), connection, &reason));
    [captureSession addConnection:connection];
    [connection release];
    
    [captureSession commitConfiguration];
}

- (void)queue_disconnectAudioDevice:(AVCaptureDevice *)audioDevice fromOutput:(AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeAudio];
    assert(connection != nil);
    
    [captureSession beginConfiguration];
    [captureSession removeConnection:connection];
    [captureSession commitConfiguration];
}

- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice forAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedVideoCaptureDevices containsObject:videoDevice]);
    assert([self.queue_addedAudioCaptureDevices containsObject:audioDevice]);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    
    AVCaptureAudioDataOutput *audioDataOutput = [self queue_toBeRemoved_outputClass:AVCaptureAudioDataOutput.class fromCaptureDevice:audioDevice];
    assert(audioDataOutput != nil);
    
    dispatch_sync(self.audioDataOutputQueue, ^{
        assert([self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter] == nil);
        [self.adoQueue_audioDataOutputsByMovieWriter setObject:audioDataOutput forKey:movieWriter];
    });
}

- (void)queue_disconnectAudioDeviceForAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedVideoCaptureDevices containsObject:videoDevice]);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    
    dispatch_sync(self.audioDataOutputQueue, ^{
        assert([self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter] != nil);
        [self.adoQueue_audioDataOutputsByMovieWriter removeObjectForKey:movieWriter];
    });
}

- (BOOL)queue_isAudioDeviceConnected:(AVCaptureDevice *)audioDevice forAssetWriterVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedVideoCaptureDevices containsObject:videoDevice]);
    assert([self.queue_addedAudioCaptureDevices containsObject:audioDevice]);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    
    AVCaptureAudioDataOutput *audioDataOutput = [self queue_toBeRemoved_outputClass:AVCaptureAudioDataOutput.class fromCaptureDevice:audioDevice];
    assert(audioDataOutput != nil);
    
    __block BOOL result = NO;
    dispatch_sync(self.audioDataOutputQueue, ^{
        result = [[self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter] isEqual:audioDataOutput];
    });
    
    return result;
}

- (BOOL)queue_isAssetWriterConnectedWithAudioDevice:(AVCaptureDevice *)audioDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedAudioCaptureDevices containsObject:audioDevice]);
    
    for (AVCaptureDevice *videoDevice in self.queue_addedVideoCaptureDevices) {
        BOOL connected = [self queue_isAudioDeviceConnected:audioDevice forAssetWriterVideoDevice:videoDevice];
        
        if (connected) {
            return YES;
        }
    }
    
    return NO;
}

- (NSSet<AVCaptureDeviceInput *> *)queue_audioDeviceInputsForOutput:(__kindof AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableSet<AVCaptureDeviceInput *> *inputs = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([port.mediaType isEqualToString:AVMediaTypeAudio]) {
                    [inputs addObject:deviceInput];
                }
            }
        }
    }
    
    return [inputs autorelease];
}

- (AVCapturePhotoOutput *)queue_photoOutputFromReadinessCoordinator:(AVCapturePhotoOutputReadinessCoordinator *)readinessCoordinator {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = self.queue_readinessCoordinatorByCapturePhotoOutput;
    
    for (AVCapturePhotoOutput *photoOutput in readinessCoordinatorByCapturePhotoOutput.keyEnumerator) {
        AVCapturePhotoOutputReadinessCoordinator *other = [readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput];
        assert(other != nil);
        
        if ([other isEqual:readinessCoordinator]) {
            return photoOutput;
        }
    }
    
    return nil;
}

- (void)queue_startPhotoCaptureWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    assert(self.captureSessionQueue);
    
    PhotoFormatModel *photoModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
    AVCapturePhotoOutput *capturePhotoOutput = [self queue_toBeRemoved_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    
    NSMutableDictionary<NSString *, id> *format = [NSMutableDictionary new];
    if (NSNumber *photoPixelFormatType = photoModel.photoPixelFormatType) {
        format[(id)kCVPixelBufferPixelFormatTypeKey] = photoModel.photoPixelFormatType;
    } else if (AVVideoCodecType codecType = photoModel.codecType) {
        format[AVVideoCodecKey] = photoModel.codecType;
        format[AVVideoCompressionPropertiesKey] = @{
            AVVideoQualityKey: @(photoModel.quality)
        };
    }
    
    __kindof AVCapturePhotoSettings * __autoreleasing capturePhotoSettings;
    
    if (photoModel.bracketedSettings.count > 0) {
        capturePhotoSettings = [AVCapturePhotoBracketSettings photoBracketSettingsWithRawPixelFormatType:photoModel.rawPhotoPixelFormatType.unsignedIntValue
                                                                                             rawFileType:photoModel.rawFileType
                                                                                         processedFormat:format
                                                                                       processedFileType:photoModel.processedFileType
                                                                                       bracketedSettings:photoModel.bracketedSettings];
    } else {
        if (photoModel.isRAWEnabled) {
            capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:photoModel.rawPhotoPixelFormatType.unsignedIntValue
                                                                                   rawFileType:photoModel.rawFileType
                                                                               processedFormat:format
                                                                             processedFileType:photoModel.processedFileType];
        } else {
            capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
        }
    }
    
    [format release];
    
    capturePhotoSettings.maxPhotoDimensions = capturePhotoOutput.maxPhotoDimensions;
    
    // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
    if (!photoModel.isRAWEnabled) {
        capturePhotoSettings.photoQualityPrioritization = photoModel.photoQualityPrioritization;
    }
    
    capturePhotoSettings.flashMode = photoModel.flashMode;
    capturePhotoSettings.cameraCalibrationDataDeliveryEnabled = photoModel.isCameraCalibrationDataDeliveryEnabled;
    
    if (photoModel.isCameraCalibrationDataDeliveryEnabled) {
        capturePhotoSettings.virtualDeviceConstituentPhotoDeliveryEnabledDevices = captureDevice.constituentDevices;
    }
    
    BOOL isDepthDataDeliveryEnabled = capturePhotoOutput.isDepthDataDeliveryEnabled;
    capturePhotoSettings.depthDataDeliveryEnabled = isDepthDataDeliveryEnabled;
    
#warning option으로 분리
    capturePhotoSettings.embedsDepthDataInPhoto = isDepthDataDeliveryEnabled;
    
    if (capturePhotoOutput.isLivePhotoCaptureEnabled) {
        capturePhotoSettings.livePhotoVideoCodecType = photoModel.livePhotoVideoCodecType;
        
        NSURL *tmpURL = [NSURL cp_processTemporaryURLByCreatingDirectoryIfNeeded:YES];
        NSURL *livePhotoMovieFileURL = [tmpURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
        
        capturePhotoSettings.livePhotoMovieFileURL = livePhotoMovieFileURL;
    }
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setShutterSoundSuppressionEnabled:"), photoModel.isShutterSoundSuppressionEnabled);
    
    //
    
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(capturePhotoOutput, sel_registerName("isSpatialPhotoCaptureEnabled"));
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setAutoSpatialPhotoCaptureEnabled:"), isSpatialPhotoCaptureEnabled);
    
    BOOL isSpatialOverCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(capturePhotoOutput, sel_registerName("isSpatialOverCaptureEnabled"));
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setAutoSpatialOverCaptureEnabled:"), isSpatialOverCaptureEnabled);
    if (isSpatialPhotoCaptureEnabled || isSpatialOverCaptureEnabled) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoOutput, sel_registerName("setMovieRecordingEnabled:"), YES);
        
        NSError * _Nullable error = nil;
        [captureDevice lockForConfiguration:&error];
        assert(error == nil);
        captureDevice.videoZoomFactor = captureDevice.virtualDeviceSwitchOverVideoZoomFactors.firstObject.doubleValue;
        [captureDevice unlockForConfiguration];
    }
    
    //
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:capturePhotoOutput]; 
    assert(readinessCoordinator != nullptr);
    
    [readinessCoordinator startTrackingCaptureRequestUsingPhotoSettings:capturePhotoSettings];
    
    if (isSpatialOverCaptureEnabled) {
        id momentCaptureSettings = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("AVMomentCaptureSettings"), sel_registerName("settingsWithPhotoSettings:"), capturePhotoSettings);
        
        NSInteger uniqueID = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(momentCaptureSettings, sel_registerName("uniqueID"));
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(capturePhotoOutput, sel_registerName("beginMomentCaptureWithSettings:delegate:"), momentCaptureSettings, self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(capturePhotoOutput, sel_registerName("commitMomentCaptureToPhotoWithUniqueID:"), uniqueID);
            reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(capturePhotoOutput, sel_registerName("endMomentCaptureWithUniqueID:"), uniqueID);
        });
    } else {
        [capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    }
    
    [readinessCoordinator stopTrackingCaptureRequestUsingPhotoSettingsUniqueID:capturePhotoSettings.uniqueID];
}

- (void)queue_startRecordingWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCaptureMovieFileOutput *movieFileOutput = [self queue_movieFileOutputFromCaptureDevice:captureDevice];
    assert(movieFileOutput != nil);
    assert(!movieFileOutput.isRecording);
    assert(!movieFileOutput.isRecordingPaused);
    
    __kindof BaseFileOutput *fileOutput = self.queue_fileOutput;
    NSURL *outputURL;
    
    if (fileOutput.class == PhotoLibraryFileOutput.class) {
        NSURL *tmpURL = [NSURL cp_processTemporaryURLByCreatingDirectoryIfNeeded:YES];
        outputURL = [tmpURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
    } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
        auto output = static_cast<ExternalStorageDeviceFileOutput *>(fileOutput);
        AVExternalStorageDevice *externalStorageDevice = output.externalStorageDevice;
        NSError * _Nullable error = nil;
        NSArray<NSURL *> *urls = [externalStorageDevice nextAvailableURLsWithPathExtensions:@[UTTypeQuickTimeMovie.preferredFilenameExtension] error:&error];
        assert(error == nil);
        outputURL = urls[0];
    } else {
        abort();
    }
    
    [self.queue_movieFileOutputsByFileOutput setObject:fileOutput forKey:movieFileOutput];
    
    [outputURL startAccessingSecurityScopedResource];
    [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (MovieWriter *)queue_movieWriterWithVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    return movieWriter;
}

- (void)queue_startRecordingUsingAssetWriterWithVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    assert(movieWriter.status == MovieWriterStatusPending);
    
    __block NSDictionary<NSString *, id> * _Nullable audioOutputSettings = nil;
    __block CMFormatDescriptionRef _Nullable audioSourceFormatHint = nil;
    
    dispatch_sync(self.audioDataOutputQueue, ^{
        AVCaptureAudioDataOutput *audioDataOutput = [self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter];
        
        if (audioDataOutput) {
            audioOutputSettings = [[audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie] retain];
            audioSourceFormatHint = (CMFormatDescriptionRef _Nullable)[self.adoQueue_audioSourceFormatHintsByAudioDataOutput objectForKey:audioDataOutput];
            
            if (audioSourceFormatHint) {
                CFRetain(audioSourceFormatHint);
            }
        } else {
            audioOutputSettings = nil;
            audioSourceFormatHint = nil;
        }
    });
    
    CMMetadataFormatDescriptionRef metadataSourceFormatHint = [self newMetadataFormatDescription];
    
    [movieWriter startRecordingWithAudioOutputSettings:audioOutputSettings audioSourceFormatHint:audioSourceFormatHint metadataOutputSettings:nil metadataSourceFormatHint:metadataSourceFormatHint];
    
    CFRelease(metadataSourceFormatHint);
    
    if (audioOutputSettings) {
        [audioOutputSettings release];
    }
    if (audioSourceFormatHint) {
        CFRelease(audioSourceFormatHint);
    }
}

- (void)queue_setPreferredStablizationModeForAllConnections:(AVCaptureVideoStabilizationMode)stabilizationMode forVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        // videoPreviewLayer != nil은 NO가 나오는 문제가 있음
        if (!connection.isVideoStabilizationSupported) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput.device isEqual:videoDevice]) continue;
            
            connection.preferredVideoStabilizationMode = stabilizationMode;
        }
    }
}

- (AVCaptureVideoStabilizationMode)queue_preferredStablizationModeForAllConnectionsForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    auto result = static_cast<AVCaptureVideoStabilizationMode>(NSNotFound);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        // videoPreviewLayer != nil은 NO가 나오는 문제가 있음
        if (!connection.isVideoStabilizationSupported) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput.device isEqual:videoDevice]) continue;
            
            if (result == NSNotFound) {
                result = connection.preferredVideoStabilizationMode;
                continue;
            }
            
            assert(result == connection.preferredVideoStabilizationMode);
        }
    }
    
#warning TODO NSNumber로 Nullable하게 해야함
//    assert(result != NSNotFound);
    
    return result;
}

- (BOOL)queue_isGreenGhostMitigationEnabledForAllConnectionsForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoGreenGhostMitigationSupported"))) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput.device isEqual:videoDevice]) continue;
            
            return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoGreenGhostMitigationEnabled"));
        }
    }
    
    return NO;
}

- (void)queue_setGreenGhostMitigationEnabledForAllConnections:(BOOL)greenGhostMitigationEnabled forVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoGreenGhostMitigationSupported"))) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if (![inputPort.input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput.device isEqual:videoDevice]) continue;
            
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(connection, sel_registerName("setVideoGreenGhostMitigationEnabled:"), greenGhostMitigationEnabled);
        }
    }
}

- (BOOL)queue_isRecordingUsingAssetWriterWithVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
    assert(movieWriter != nil);
    
    return movieWriter.status == MovieWriterStatusRecording;
}

- (void)didReceiveCaptureDeviceWasDisconnectedNotification:(NSNotification *)notification {
    auto captureDevice = static_cast<AVCaptureDevice * _Nullable>(notification.object);
    if (captureDevice == nil) return;
    
    dispatch_async(self.captureSessionQueue, ^{
        if ([self.queue_addedVideoCaptureDevices containsObject:captureDevice]) {
            [self queue_removeCaptureDevice:captureDevice];
        }
    });
}

- (void)postReloadingPhotoFormatMenuNeededNotification:(AVCaptureDevice *)captureDevice {
    if (captureDevice == nil) return;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceReloadingPhotoFormatMenuNeededNotificationName object:self userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)postDidUpdatePreviewLayersNotification {
    dispatch_assert_queue(self.captureSessionQueue);
    
    // NSMapTable은 Thread-safe하지 않기에 다른 Thread에서 불릴 여지가 없어야 한다. 따라서 userInfo에 전달하지 않는다.
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidUpdatePreviewLayersNotificationName object:self userInfo:nil];
}

- (void)postDidUpdatePointCloudLayersNotification {
    dispatch_assert_queue(self.captureSessionQueue);
    
    // NSMapTable은 Thread-safe하지 않기에 다른 Thread에서 불릴 여지가 없어야 한다. 따라서 userInfo에 전달하지 않는다.
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidUpdatePointCloudLayersNotificationName object:self userInfo:nil];
}

- (void)postDidAddDeviceNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidAddDeviceNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)postDidRemoveDeviceNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidRemoveDeviceNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)addObserversForVideoCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"formats" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"torchAvailable" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"activeDepthDataFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"isCenterStageActive" options:NSKeyValueObservingOptionNew context:nullptr];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSubjectAreaDidChangeNotification:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    
    NSError * _Nullable error = nil;
    [captureDevice lockForConfiguration:&error];
    assert(error == nil);
    captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    [captureDevice unlockForConfiguration];
}

- (void)removeObserversForVideoCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [captureDevice removeObserver:self forKeyPath:@"formats"];
    [captureDevice removeObserver:self forKeyPath:@"torchAvailable"];
    [captureDevice removeObserver:self forKeyPath:@"activeDepthDataFormat"];
    [captureDevice removeObserver:self forKeyPath:@"isCenterStageActive"];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    
    NSError * _Nullable error = nil;
    [captureDevice lockForConfiguration:&error];
    assert(error == nil);
    captureDevice.subjectAreaChangeMonitoringEnabled = NO;
    [captureDevice unlockForConfiguration];
}

- (void)addObserversForPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    [photoOutput addObserver:self forKeyPath:@"availablePhotoPixelFormatTypes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"availablePhotoCodecTypes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"availableRawPhotoFileTypes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"availablePhotoFileTypes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isSpatialPhotoCaptureSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isAutoDeferredPhotoDeliverySupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"supportedFlashModes" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isZeroShutterLagSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isResponsiveCaptureSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isAppleProRAWSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isFastCapturePrioritizationSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isCameraCalibrationDataDeliverySupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"isDepthDataDeliverySupported" options:NSKeyValueObservingOptionNew context:nullptr];
    [photoOutput addObserver:self forKeyPath:@"availableLivePhotoVideoCodecTypes" options:NSKeyValueObservingOptionNew context:nullptr];
}

- (void)removeObserversForPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    [photoOutput removeObserver:self forKeyPath:@"availablePhotoPixelFormatTypes"];
    [photoOutput removeObserver:self forKeyPath:@"availablePhotoCodecTypes"];
    [photoOutput removeObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes"];
    [photoOutput removeObserver:self forKeyPath:@"availableRawPhotoFileTypes"];
    [photoOutput removeObserver:self forKeyPath:@"availablePhotoFileTypes"];
    [photoOutput removeObserver:self forKeyPath:@"isSpatialPhotoCaptureSupported"];
    [photoOutput removeObserver:self forKeyPath:@"isAutoDeferredPhotoDeliverySupported"];
    [photoOutput removeObserver:self forKeyPath:@"supportedFlashModes"];
    [photoOutput removeObserver:self forKeyPath:@"isZeroShutterLagSupported"];
    [photoOutput removeObserver:self forKeyPath:@"isResponsiveCaptureSupported"];
    [photoOutput removeObserver:self forKeyPath:@"isAppleProRAWSupported"];
    [photoOutput removeObserver:self forKeyPath:@"isFastCapturePrioritizationSupported"];
    [photoOutput removeObserver:self forKeyPath:@"isCameraCalibrationDataDeliverySupported"];
    [photoOutput removeObserver:self forKeyPath:@"isDepthDataDeliverySupported"];
    [photoOutput removeObserver:self forKeyPath:@"availableLivePhotoVideoCodecTypes"];
}

- (void)addObserversForMetadataOutput:(AVCaptureMetadataOutput *)metadataOutput {
    
}

- (void)removeObserversForMetadataOutput:(AVCaptureMetadataOutput *)metadataOutput {
    
}

- (void)addObservsersVideoThumbnailLayer:(CALayer *)videoThumbnailLayer {
    [videoThumbnailLayer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    [videoThumbnailLayer addObserver:self forKeyPath:@"contentsScale" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeObservsersVideoThumbnailLayer:(CALayer *)videoThumbnailLayer {
    [videoThumbnailLayer removeObserver:self forKeyPath:@"bounds"];
    [videoThumbnailLayer removeObserver:self forKeyPath:@"contentsScale"];
}

- (void)registerObserversForRotationCoordinator:(AVCaptureDeviceRotationCoordinator *)rotationCoordinator {
    [rotationCoordinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:nil];
    [rotationCoordinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelCapture" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserversForRotationCoordinator:(AVCaptureDeviceRotationCoordinator *)rotationCoordinator {
    [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelCapture"];
}

- (__kindof AVCaptureSession *)queue_switchCaptureSessionByAddingDevice:(BOOL)addingDevice postNotification:(BOOL)postNotification {
    __kindof AVCaptureSession *currentCaptureSession = self.queue_captureSession;
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    NSArray<AVCaptureDeviceType> *allPointCloudDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allPointCloudDeviceTypes"));
    
    NSUInteger numberOfMultipleInputDevices = 0;
    for (AVCaptureDeviceInput *input in self.queue_captureSession.inputs) {
        if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
        
        if ([allVideoDeviceTypes containsObject:input.device.deviceType]) {
            numberOfMultipleInputDevices += 1;
        } else if ([allPointCloudDeviceTypes containsObject:input.device.deviceType]) {
            numberOfMultipleInputDevices += 1;
        }
    }
    
    if (addingDevice) {
        if (currentCaptureSession != nil) {
            if (numberOfMultipleInputDevices == 0) {
                if (currentCaptureSession.class == AVCaptureSession.class) {
                    return currentCaptureSession;
                } else {
                    abort();
                }
            } else if (numberOfMultipleInputDevices == 1) {
                if (currentCaptureSession.class == AVCaptureSession.class) {
                    return [self queue_switchCaptureSessionWithClass:AVCaptureMultiCamSession.class postNotification:postNotification];
                } else {
                    abort();
                }
            } else {
                if (currentCaptureSession.class == AVCaptureMultiCamSession.class) {
                    return currentCaptureSession;
                } else {
                    abort();
                }
            }
        } else {
            return [self queue_switchCaptureSessionWithClass:AVCaptureSession.class postNotification:postNotification];
        }
    } else {
        if (numberOfMultipleInputDevices == 0) {
            assert(currentCaptureSession.class == AVCaptureSession.class);
            return currentCaptureSession;
        } else if (numberOfMultipleInputDevices == 1) {
            assert(currentCaptureSession.class == AVCaptureMultiCamSession.class);
            return [self queue_switchCaptureSessionWithClass:AVCaptureSession.class postNotification:postNotification];
        } else {
            assert(currentCaptureSession.class == AVCaptureMultiCamSession.class);
            return currentCaptureSession;
        }
    }
}

- (__kindof AVCaptureSession *)queue_switchCaptureSessionWithClass:(Class)captureSessionClass postNotification:(BOOL)postNotification {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureSessionClass == AVCaptureSession.class || [captureSessionClass isSubclassOfClass:AVCaptureSession.class]);
    assert(self.queue_captureSession.class != captureSessionClass);
    
    //
    
    BOOL wasRunning;
    if (__kindof AVCaptureSession *currentCaptureSession = _queue_captureSession) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:currentCaptureSession];
        
        wasRunning = currentCaptureSession.isRunning;
        
        if (currentCaptureSession.class == AVCaptureSession.class) {
            NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
            
            for (__kindof AVCaptureInput *input in currentCaptureSession.inputs) {
                if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                    auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
                    AVCaptureDevice *device = deviceInput.device;
                    
                    if ([allVideoDeviceTypes containsObject:device.deviceType]) {
                        // MultiCam으로 전환하기 위해서는 현재 추가된 Device의 Format을 MultiCam이 지원되는 것으로 바꿔야함
                        if (!device.activeFormat.isMultiCamSupported) {
                            [device.formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (format.isMultiCamSupported) {
                                    NSError * _Nullable error = nil;
                                    [device lockForConfiguration:&error];
                                    assert(error == nil);
                                    device.activeFormat = format;
                                    [device unlockForConfiguration];
                                    *stop = YES;
                                }
                            }];
                            
                            // Input을 지워야 할 수도 있음 - iPad 7이 Multi-Cam을 지원하지 않아 문제됨
                            assert(device.activeFormat.isMultiCamSupported);
                        }
                    }
                }
            }
        } else if (currentCaptureSession.class == AVCaptureMultiCamSession.class) {
            [currentCaptureSession removeObserver:self forKeyPath:@"hardwareCost"];
            [currentCaptureSession removeObserver:self forKeyPath:@"systemPressureCost"];
        }
    } else {
        wasRunning = YES;
    }
    
    //
    
    auto captureSession = static_cast<__kindof AVCaptureSession *>([captureSessionClass new]);
    
#if !TARGET_OS_TV
    if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureSession, sel_registerName("isSystemStyleEnabled"))) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureSession, sel_registerName("setSystemStyleEnabled:"), YES);
    }
#endif
    
    captureSession.automaticallyConfiguresCaptureDeviceForWideColor = NO;
    captureSession.usesApplicationAudioSession = YES;
    captureSession.automaticallyConfiguresApplicationAudioSession = YES;
    
    if (captureSessionClass == AVCaptureSession.class) {
        captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
    } else if (captureSessionClass == AVCaptureMultiCamSession.class) {
        [captureSession addObserver:self forKeyPath:@"hardwareCost" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureSession addObserver:self forKeyPath:@"systemPressureCost" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    }
    
#if TARGET_OS_IOS
    // https://x.com/_silgen_name/status/1837346064808169951
    id controlsOverlay = captureSession.cp_controlsOverlay;
    
    dispatch_queue_t _connectionQueue;
    assert(object_getInstanceVariable(controlsOverlay, "_connectionQueue", reinterpret_cast<void **>(&_connectionQueue)) != NULL);
    dispatch_release(_connectionQueue);
    
    dispatch_queue_t captureSessionQueue = self.captureSessionQueue;
    assert(object_setInstanceVariable(controlsOverlay, "_connectionQueue", reinterpret_cast<void *>(captureSessionQueue)));
    dispatch_retain(captureSessionQueue);
    
    //
    
    [captureSession setControlsDelegate:self queue:captureSessionQueue];
#endif
    
    if (__kindof AVCaptureSession *oldCaptureSession = _queue_captureSession) {
        [oldCaptureSession beginConfiguration];
        
        NSArray<AVCaptureConnection *> *oldConnections = oldCaptureSession.connections;
        
        // AVCaptureMovieFileOutput 처럼 여러 Connection (Video, Audio)이 하나의 Output을 가지는 경우가 있어, 배열에 중복을 피하기 위해 Set을 사용
        NSMutableSet<__kindof AVCaptureOutput *> *oldOutputs = [NSMutableSet new];
        
        for (AVCaptureConnection *connection in oldCaptureSession.connections) {
            if (__kindof AVCaptureOutput *output = connection.output) {
                if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
                    auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
                    [self removeObserversForPhotoOutput:photoOutput];
                    
                    //
                    
                    if (AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput]) {
                        readinessCoordinator.delegate = nil;
                        [self.queue_readinessCoordinatorByCapturePhotoOutput removeObjectForKey:photoOutput];
                    } else {
                        abort();
                    }
                } else if ([output isKindOfClass:AVCaptureMovieFileOutput.class]) {
                    
                } else if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
                    auto videoDataOutput = static_cast<AVCaptureVideoDataOutput *>(output);
                    [videoDataOutput setSampleBufferDelegate:nil queue:nil];
                } else if ([output isKindOfClass:AVCaptureDepthDataOutput.class]) {
                    auto depthDataOutput = static_cast<AVCaptureDepthDataOutput *>(output);
                    [depthDataOutput setDelegate:nil callbackQueue:nil];
                } else if ([output isKindOfClass:AVCaptureAudioDataOutput.class]) {
                    auto audioDataOutput = static_cast<AVCaptureAudioDataOutput *>(output);
                    [audioDataOutput setSampleBufferDelegate:nil queue:nil];
                } else if ([output isKindOfClass:objc_lookUpClass("AVCapturePointCloudDataOutput")]) {
                    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(output, sel_registerName("setDelegate:callbackQueue:"), nil, nil);
                } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
                    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(output, sel_registerName("setDelegate:callbackQueue:"), nil, nil);
                } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureCameraCalibrationDataOutput")]) {
                    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(output, sel_registerName("setDelegate:callbackQueue:"), nil, nil);
                } else if ([output isKindOfClass:AVCaptureMetadataOutput.class]) {
                    auto metadataOutput = static_cast<AVCaptureMetadataOutput *>(output);
                    [metadataOutput setMetadataObjectsDelegate:nil queue:nil];
                    [self removeObserversForMetadataOutput:metadataOutput];
                } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput")]) {
                    
                } else {
                    abort();
                }
                
                [oldOutputs addObject:output];
            }
            
            [oldCaptureSession removeConnection:connection];
        }
        
        for (AVCaptureOutput *output in oldOutputs) {
            [oldCaptureSession removeOutput:output];
        }
        
        NSArray<__kindof AVCaptureInput *> *oldInputs = oldCaptureSession.inputs;
        for (__kindof AVCaptureInput *input in oldCaptureSession.inputs) {
            if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
                AVCaptureDevice *captureDevice = deviceInput.device;
                
                NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
                
                if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
                    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
                        [self removeObserversForRotationCoordinator:rotationCoordinator];
                        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
                    } else {
                        abort();
                    }
                }
            } else if ([input isKindOfClass:AVCaptureMetadataInput.class]) {
                
            } else {
                abort();
            }
            
            [oldCaptureSession removeInput:input];
        }
        
        [oldCaptureSession commitConfiguration];
        
        if (oldCaptureSession.isRunning) {
            [oldCaptureSession stopRunning];
        }
        
        //
        
        [captureSession beginConfiguration];
        
        NSMapTable<AVCaptureInput *, AVCaptureInput *> *addedInputsByOldInput = [NSMapTable strongToStrongObjectsMapTable];
        for (__kindof AVCaptureInput *input in oldInputs) {
            if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                auto oldDeviceInput = static_cast<AVCaptureDeviceInput *>(input);
                
                NSError * _Nullable error = nil;
                AVCaptureDeviceInput *newDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:oldDeviceInput.device error:&error];
                assert(error == nil);
                
                if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(oldDeviceInput.device.activeFormat, sel_registerName("isVisionDataDeliverySupported"))) {
                    BOOL isVisionDataDeliveryEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(input, sel_registerName("isVisionDataDeliveryEnabled"));
                    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newDeviceInput, sel_registerName("setVisionDataDeliveryEnabled:"), isVisionDataDeliveryEnabled);
                }
                
                if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(oldDeviceInput.device.activeFormat, sel_registerName("isCameraCalibrationDataDeliverySupported"))) {
                    BOOL isCameraCalibrationDataDeliveryEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(input, sel_registerName("isCameraCalibrationDataDeliveryEnabled"));
                    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(newDeviceInput, sel_registerName("setCameraCalibrationDataDeliveryEnabled:"), isCameraCalibrationDataDeliveryEnabled);
                }
                
                assert([captureSession canAddInput:newDeviceInput]);
                [captureSession addInputWithNoConnections:newDeviceInput];
                
                [addedInputsByOldInput setObject:newDeviceInput forKey:oldDeviceInput];
                
                [newDeviceInput release];
            } else if ([input isKindOfClass:AVCaptureMetadataInput.class]) {
                auto oldMetadataInput = static_cast<AVCaptureMetadataInput *>(input);
                
                CMMetadataFormatDescriptionRef formatDescription = [self newMetadataFormatDescription];
                CMClockRef clock = reinterpret_cast<CMClockRef (*)(id, SEL)>(objc_msgSend)(oldMetadataInput, sel_registerName("clock"));
                AVCaptureMetadataInput *newMetadataInput = [[AVCaptureMetadataInput alloc] initWithFormatDescription:formatDescription clock:clock];
                CFRelease(formatDescription);
                
                assert([captureSession canAddInput:newMetadataInput]);
                [captureSession addInputWithNoConnections:newMetadataInput];
                
                [addedInputsByOldInput setObject:newMetadataInput forKey:oldMetadataInput];
                
                [newMetadataInput release];
            } else {
                abort();
            }
        }
        assert(oldInputs.count == addedInputsByOldInput.count);
        
        NSMapTable<AVCaptureOutput *, AVCaptureOutput *> *addedOutputsByOutputs = [NSMapTable strongToStrongObjectsMapTable];
        for (__kindof AVCaptureOutput *output in oldOutputs) {
            if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
                AVCapturePhotoOutput *newPhotoOutput = [AVCapturePhotoOutput new];
                newPhotoOutput.maxPhotoQualityPrioritization = static_cast<AVCapturePhotoOutput *>(output).maxPhotoQualityPrioritization;
                assert([captureSession canAddOutput:newPhotoOutput]);
                [captureSession addOutputWithNoConnections:newPhotoOutput];
                
                [addedOutputsByOutputs setObject:newPhotoOutput forKey:output];
                [self addObserversForPhotoOutput:newPhotoOutput];
                
                //
                
                [newPhotoOutput release];
            } else if ([output isKindOfClass:AVCaptureMovieFileOutput.class]) {
                AVCaptureMovieFileOutput *newMovieFileOutput = [AVCaptureMovieFileOutput new];
                
                assert([captureSession canAddOutput:newMovieFileOutput]);
                [captureSession addOutputWithNoConnections:newMovieFileOutput];
                
                [addedOutputsByOutputs setObject:newMovieFileOutput forKey:output];
                [newMovieFileOutput release];
            } else if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
                auto oldVideoDataOutput = static_cast<AVCaptureVideoDataOutput *>(output);
                
                AVCaptureVideoDataOutput *newVideoDataOutput = [AVCaptureVideoDataOutput new];
                
                if (oldVideoDataOutput.deliversPreviewSizedOutputBuffers) {
                    [newVideoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
                }
                
                assert([captureSession canAddOutput:newVideoDataOutput]);
                [captureSession addOutputWithNoConnections:newVideoDataOutput];
                
                newVideoDataOutput.automaticallyConfiguresOutputBufferDimensions = oldVideoDataOutput.automaticallyConfiguresOutputBufferDimensions;
                newVideoDataOutput.deliversPreviewSizedOutputBuffers = oldVideoDataOutput.deliversPreviewSizedOutputBuffers;
                newVideoDataOutput.alwaysDiscardsLateVideoFrames = oldVideoDataOutput.alwaysDiscardsLateVideoFrames;
                
                [addedOutputsByOutputs setObject:newVideoDataOutput forKey:output];
                [newVideoDataOutput release];
            } else if ([output isKindOfClass:AVCaptureDepthDataOutput.class]) {
                auto depthDataOutput = static_cast<AVCaptureDepthDataOutput *>(output);
                AVCaptureDepthDataOutput *newDepthDataOutput = [AVCaptureDepthDataOutput new];
                newDepthDataOutput.filteringEnabled = depthDataOutput.isFilteringEnabled;
                newDepthDataOutput.alwaysDiscardsLateDepthData = depthDataOutput.alwaysDiscardsLateDepthData;
                [newDepthDataOutput setDelegate:self callbackQueue:self.captureSessionQueue];
                
                assert([captureSession canAddOutput:newDepthDataOutput]);
                [captureSession addOutputWithNoConnections:newDepthDataOutput];
                
                [addedOutputsByOutputs setObject:newDepthDataOutput forKey:output];
                [newDepthDataOutput release];
            } else if ([output isKindOfClass:AVCaptureAudioDataOutput.class]) {
                AVCaptureAudioDataOutput *newAudioDataOutput = [AVCaptureAudioDataOutput new];
                [newAudioDataOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
                
                assert([captureSession canAddOutput:newAudioDataOutput]);
                [captureSession addOutputWithNoConnections:newAudioDataOutput];
                
                [addedOutputsByOutputs setObject:newAudioDataOutput forKey:output];
                [newAudioDataOutput release];
            } else if ([output isKindOfClass:objc_lookUpClass("AVCapturePointCloudDataOutput")]) {
                __kindof AVCaptureOutput *newPointCloudDataOutput = [objc_lookUpClass("AVCapturePointCloudDataOutput") new];
                reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(newPointCloudDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
                
                assert([captureSession canAddOutput:newPointCloudDataOutput]);
                [captureSession addOutputWithNoConnections:newPointCloudDataOutput];
                
                [addedOutputsByOutputs setObject:newPointCloudDataOutput forKey:output];
                [newPointCloudDataOutput release];
            } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
                __kindof AVCaptureOutput *newVisionDataOutput = [objc_lookUpClass("AVCaptureVisionDataOutput") new];
                reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(newVisionDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
                
                assert([captureSession canAddOutput:newVisionDataOutput]);
                [captureSession addOutputWithNoConnections:newVisionDataOutput];
                
                [addedOutputsByOutputs setObject:newVisionDataOutput forKey:output];
                [newVisionDataOutput release];
            } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureCameraCalibrationDataOutput")]) {
                __kindof AVCaptureOutput *newCalibrationDataOutput = [objc_lookUpClass("AVCaptureCameraCalibrationDataOutput") new];
                reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(newCalibrationDataOutput, sel_registerName("setDelegate:callbackQueue:"), self, self.captureSessionQueue);
                
                assert([captureSession canAddOutput:newCalibrationDataOutput]);
                [captureSession addOutputWithNoConnections:newCalibrationDataOutput];
                
                [addedOutputsByOutputs setObject:newCalibrationDataOutput forKey:output];
                [newCalibrationDataOutput release];
            } else if ([output isKindOfClass:AVCaptureMetadataOutput.class]) {
                AVCaptureMetadataOutput *newMetadataOutput = [AVCaptureMetadataOutput new];
                [self addObserversForMetadataOutput:newMetadataOutput];
                [newMetadataOutput setMetadataObjectsDelegate:self queue:self.captureSessionQueue];
                
                assert([captureSession canAddOutput:newMetadataOutput]);
                [captureSession addOutputWithNoConnections:newMetadataOutput];
                
                [addedOutputsByOutputs setObject:newMetadataOutput forKey:output];
                [newMetadataOutput release];
            } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput")]) {
                __kindof AVCaptureOutput *newThumbnailOutput = [objc_lookUpClass("AVCaptureVideoThumbnailOutput") new];
                reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(newThumbnailOutput, sel_registerName("setThumbnailContentsDelegate:"), self);
                
                CGSize thumbnailSize = reinterpret_cast<CGSize (*)(id, SEL)>(objc_msgSend)(output, sel_registerName("thumbnailSize"));
                reinterpret_cast<void (*)(id, SEL, CGSize)>(objc_msgSend)(newThumbnailOutput, sel_registerName("setThumbnailSize:"), thumbnailSize);
                
                [addedOutputsByOutputs setObject:newThumbnailOutput forKey:output];
                
                assert([captureSession canAddOutput:newThumbnailOutput]);
                [captureSession addOutputWithNoConnections:newThumbnailOutput];
                
                [newThumbnailOutput release];
            } else {
                abort();
            }
        }
        
        assert(oldOutputs.count == addedOutputsByOutputs.count);
        [oldOutputs release];
        
        // AVCaptureDeviceInput과 연결된 AVCaptureConnection들 처리
        for (AVCaptureConnection *connection in oldConnections) {
            assert(connection.inputPorts.count == 0 || connection.inputPorts.count == 1);
            AVCaptureInput *oldInput = connection.inputPorts.firstObject.input;
            assert(oldInput != nil);
            
            auto addedInput = static_cast<AVCaptureDeviceInput *>([addedInputsByOldInput objectForKey:oldInput]);
            assert(addedInput != nil);
            
            if (![addedInput isKindOfClass:AVCaptureDeviceInput.class]) {
                continue;
            }
            
            AVCaptureInputPort * _Nullable videoInputPort = [addedInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable depthDataInputPort = [addedInput portsWithMediaType:AVMediaTypeDepthData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable audioInputPort = [addedInput portsWithMediaType:AVMediaTypeAudio sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable pointCloudDataInputPort = [addedInput portsWithMediaType:AVMediaTypePointCloudData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable visionDataInputPort = [addedInput portsWithMediaType:AVMediaTypeVisionData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable cameraCalibrationDataInputPort = [addedInput portsWithMediaType:AVMediaTypeCameraCalibrationData sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            AVCaptureInputPort * _Nullable metadataDataInputPort = [addedInput portsWithMediaType:AVMediaTypeMetadataObject sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified].firstObject;
            
            AVCaptureConnection *newConnection;
            if (AVCaptureVideoPreviewLayer *oldPreviewLayer = connection.videoPreviewLayer) {
                AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
                previewLayer.hidden = oldPreviewLayer.isHidden;
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:previewLayer];
                
                AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:addedInput.device previewLayer:previewLayer];
                [previewLayer release];
                
                assert([self.queue_rotationCoordinatorsByCaptureDevice objectForKey:addedInput.device] == nil);
                [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:addedInput.device];
                [self registerObserversForRotationCoordinator:rotationCoodinator];
                [rotationCoodinator release];
            } else {
                __kindof AVCaptureOutput *addedOutput = [addedOutputsByOutputs objectForKey:connection.output];
                assert(addedOutput != nil);
                
                if ([addedOutput isKindOfClass:AVCapturePhotoOutput.class]) {
                    assert(videoInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:addedOutput];
                    
                    auto addedPhotoOutput = static_cast<AVCapturePhotoOutput *>(addedOutput);
                    
                    //
                    
                    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:addedPhotoOutput];
                    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:addedPhotoOutput];
                    readinessCoordinator.delegate = self;
                    [readinessCoordinator release];
                    
                    //
                    
                    AVCaptureDevice *captureDevice = addedInput.device;
                    
                    if (PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice]) {
                        MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
                        [copy updateAllWithPhotoOutput:addedPhotoOutput];
                        [self queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                        [copy release];
                    } else {
                        abort();
                    }
                } else if ([addedOutput isKindOfClass:AVCaptureMovieFileOutput.class]) {
                    if (audioInputPort != nil) {
                        newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[audioInputPort] output:addedOutput];
                    } else if (videoInputPort != nil) {
                        newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:addedOutput];
                    } else {
                        abort();
                    }
                } else if ([addedOutput isKindOfClass:AVCaptureVideoDataOutput.class]) {
                    auto addedVideoDataOutput = static_cast<AVCaptureVideoDataOutput *>(addedOutput);
                    
                    assert(videoInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:addedVideoDataOutput];
                } else if ([addedOutput isKindOfClass:AVCaptureDepthDataOutput.class]) {
                    assert(depthDataInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[depthDataInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:AVCaptureAudioDataOutput.class]) {
                    assert(audioInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[audioInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:objc_lookUpClass("AVCapturePointCloudDataOutput")]) {
                    assert(pointCloudDataInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[pointCloudDataInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
                    assert(visionDataInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[visionDataInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:objc_lookUpClass("AVCaptureCameraCalibrationDataOutput")]) {
                    assert(cameraCalibrationDataInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[cameraCalibrationDataInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:AVCaptureMetadataOutput.class]) {
                    assert(metadataDataInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[metadataDataInputPort] output:addedOutput];
                } else if ([addedOutput isKindOfClass:objc_lookUpClass("AVCaptureVideoThumbnailOutput")]) {
                    assert(videoInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:addedOutput];
                } else {
                    abort();
                }
            }
            
            newConnection.enabled = connection.isEnabled;
            newConnection.preferredVideoStabilizationMode = connection.preferredVideoStabilizationMode;
            
            if (newConnection.isVideoMirroringSupported) {
                newConnection.automaticallyAdjustsVideoMirroring = connection.automaticallyAdjustsVideoMirroring;
                
                if (!newConnection.automaticallyAdjustsVideoMirroring) {
                    newConnection.videoMirrored = connection.isVideoMirrored;
                }
            }
            
            NSString * _Nullable reason = nil;
            assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), newConnection, &reason));
            [captureSession addConnection:newConnection];
            
            //
            
            //
            
            [newConnection release];
        }
        
        // AVCaptureMetadataInput과 연결된 AVCaptureConnection들 처리
        for (AVCaptureConnection *connection in oldConnections) {
            assert(connection.inputPorts.count == 0 || connection.inputPorts.count == 1);
            AVCaptureInput *oldInput = connection.inputPorts.firstObject.input;
            assert(oldInput != nil);
            
            auto addedInput = static_cast<AVCaptureMetadataInput *>([addedInputsByOldInput objectForKey:oldInput]);
            assert(addedInput != nil);
            
            if (![addedInput isKindOfClass:AVCaptureMetadataInput.class]) {
                continue;
            }
            
            AVCaptureInputPort *metadataInputPort = nil;
            for (AVCaptureInputPort *inputPort in addedInput.ports) {
                if ([inputPort.mediaType isEqualToString:AVMediaTypeMetadata]) {
                    assert(metadataInputPort == nil);
                    metadataInputPort = inputPort;
                }
            }
            assert(metadataInputPort != nil);
            
            __kindof AVCaptureOutput *addedOutput = [addedOutputsByOutputs objectForKey:connection.output];
            
            AVCaptureConnection *newConnection;
            if ([addedOutput isKindOfClass:AVCaptureMovieFileOutput.class]) {
                assert(metadataInputPort != nil);
                newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[metadataInputPort] output:addedOutput];
                
                // 왜인지 모르겠지만 AVCaptureMultiCamSession 상태에서 -11819 Error가 나옴
                newConnection.enabled = (captureSession.class != AVCaptureMultiCamSession.class);
            } else {
                abort();
            }
            
            NSString * _Nullable reason = nil;
            assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), newConnection, &reason));
            [captureSession addConnection:newConnection];
            
            if ([addedInput isKindOfClass:AVCaptureMetadataInput.class]) {
                auto metadataInput = static_cast<AVCaptureMetadataInput *>(addedInput);
                
                BOOL didSet = NO;
                for (AVCaptureDevice *captureDevice in self.queue_metadataInputsByCaptureDevice.keyEnumerator) {
                    if ([[self.queue_metadataInputsByCaptureDevice objectForKey:captureDevice] isEqual:oldInput]) {
                        [self.queue_metadataInputsByCaptureDevice removeObjectForKey:captureDevice];
                        [self.queue_metadataInputsByCaptureDevice setObject:metadataInput forKey:captureDevice];
                        didSet = YES;
                        break;
                    }
                }
                assert(didSet);
            }
            
            [newConnection release];
        }
        
        // Custom Preview Layet들의 Rotation 처리
        for (__kindof AVCaptureOutput *addedOutput in addedOutputsByOutputs.objectEnumerator) {
            if ([addedOutput isKindOfClass:AVCaptureVideoDataOutput.class]) {
                auto videoDataOutput = static_cast<AVCaptureVideoDataOutput *>(addedOutput);
                
                NSSet<AVCaptureDevice *> *videoDevices = [self queue_videoCaptureDevicesFromOutput:videoDataOutput];
                assert(videoDevices.count == 1);
                AVCaptureDevice *videoDevice = videoDevices.allObjects[0];
                
                AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:videoDevice];
                assert(rotationCoordinator != nil);
                
                assert(videoDataOutput.connections.count == 1);
                AVCaptureConnection *connection = videoDataOutput.connections[0];
                
                if (videoDataOutput.deliversPreviewSizedOutputBuffers) {
                    connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
                } else {
                    connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture;
                }
            }
        }
        
        // MovieWriter 처리
        NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
        NSMapTable<MovieWriter *, MovieWriter *> *addedMovieWritersByMovieWriters = [NSMapTable strongToStrongObjectsMapTable];
        
        for (AVCaptureInput *oldInput in oldInputs) {
            if (![oldInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            auto oldDeviceInput = static_cast<AVCaptureDeviceInput *>(oldInput);
            AVCaptureDevice *videoDevice = oldDeviceInput.device;
            
            if (![allVideoDeviceTypes containsObject:videoDevice.deviceType]) continue;
            
            MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:videoDevice];
            assert(movieWriter != nil);
            assert(movieWriter.status == MovieWriterStatusPending);
            
            auto newVideoDataOutput = static_cast<AVCaptureVideoDataOutput *>([addedOutputsByOutputs objectForKey:movieWriter.videoDataOutput]);
            assert(newVideoDataOutput != nil);
            CLLocationManager *locationManager = self.locationManager;
            
            MovieWriter *newMovieWriter = [[MovieWriter alloc] initWithFileOutput:movieWriter.fileOutput
                                                                  videoDataOutput:newVideoDataOutput
                                                                 useFastRecording:movieWriter.useFastRecording
                                                                    isolatedQueue:self.captureSessionQueue
                                                                  locationHandler:^CLLocation * _Nullable{
                return locationManager.location;
            }];
            
            [addedMovieWritersByMovieWriters setObject:newMovieWriter forKey:movieWriter];
            [self.queue_movieWritersByVideoDevice setObject:newMovieWriter forKey:videoDevice];
            [newMovieWriter release];
        }
        
        assert(self.queue_movieWritersByVideoDevice.count == addedMovieWritersByMovieWriters.count);
        // Verify
        for (MovieWriter *newMovieWriter in self.queue_movieWritersByVideoDevice.objectEnumerator) {
            for (MovieWriter *oldMovieWriter in addedMovieWritersByMovieWriters.keyEnumerator) {
                assert(![newMovieWriter isEqual:oldMovieWriter]);
            }
            
            BOOL found = NO;
            for (MovieWriter *_newMovieWriter in addedMovieWritersByMovieWriters.objectEnumerator) {
                if ([_newMovieWriter isEqual:newMovieWriter]) {
                    found = YES;
                    break;
                }
            }
            assert(found);
        }
        
        dispatch_sync(self.audioDataOutputQueue, ^{
            for (MovieWriter *oldMovieWriter in addedMovieWritersByMovieWriters.keyEnumerator) {
                AVCaptureAudioDataOutput * _Nullable oldAudioDataOutput = [self.adoQueue_audioDataOutputsByMovieWriter objectForKey:oldMovieWriter];
                if (oldAudioDataOutput == nil) continue;
                
                auto newAudioDataOutput = static_cast<AVCaptureAudioDataOutput *>([addedOutputsByOutputs objectForKey:oldAudioDataOutput]);
                assert(newAudioDataOutput != nil);
                
                MovieWriter *newMovieWriter = [addedMovieWritersByMovieWriters objectForKey:oldMovieWriter];
                assert(newMovieWriter != nil);
                
                [self.adoQueue_audioDataOutputsByMovieWriter removeObjectForKey:oldMovieWriter];
                [self.adoQueue_audioDataOutputsByMovieWriter setObject:newAudioDataOutput forKey:newMovieWriter];
            }
            
            // MultiCam으로 전환되면서 Format이 전환되면서 Format이 바뀔 수도 있기에 초기화 해준다.
            [self.adoQueue_audioSourceFormatHintsByAudioDataOutput removeAllObjects];
        });
        
        if (postNotification) {
            [self postDidUpdatePreviewLayersNotification];
        }
        
        [captureSession commitConfiguration];
    }
    
    if (wasRunning) {
        [captureSession startRunning];
    }
    
    self.queue_captureSession = captureSession;
    NSLog(@"New capture session: %@", captureSession);
    
    return [captureSession autorelease];
}

- (void)didReceiveSubjectAreaDidChangeNotification:(NSNotification *)notification {
    NSLog(@"%s", sel_getName(_cmd));
}

- (CMMetadataFormatDescriptionRef)newMetadataFormatDescription CM_RETURNS_RETAINED {
    CMMetadataFormatDescriptionRef formatDescription;
    assert(CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault,
                                                                       kCMMetadataFormatType_Boxed,
                                                                       (CFArrayRef)@[
        @{
            (id)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: AVMetadataIdentifierQuickTimeMetadataDetectedFace,
            (id)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: (id)kCMMetadataBaseDataType_RectF32
        },
        @{
            (id)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: AVMetadataIdentifierQuickTimeMetadataLocationISO6709,
            (id)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: (id)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709
        }
    ],
                                                                       &formatDescription) == 0);
    
    return formatDescription;
}

- (void)mainQueue_savePhotoWithPhotoOutput:(AVCapturePhotoOutput *)photoOutqut uniqueID:(int64_t)uniqueID {
    AVCapturePhoto *photo = [self.mainQueue_capturePhotosByUniqueID objectForKey:@(uniqueID)];
    assert(photo != nil);
    
    NSURL * _Nullable livePhotoMovieURL = [self.mainQueue_livePhotoMovieFileURLsByUniqueID objectForKey:@(uniqueID)];
    
    dispatch_async(self.captureSessionQueue, ^{
        __kindof BaseFileOutput *fileOutput = self.queue_fileOutput;
        
        if (fileOutput.class == PhotoLibraryFileOutput.class) {
            auto output = static_cast<PhotoLibraryFileOutput *>(fileOutput);
            NSData * _Nullable fileDataRepresentation = photo.fileDataRepresentation;
            
            [output.photoLibrary performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                
                assert(fileDataRepresentation != nil);
                [request addResourceWithType:PHAssetResourceTypePhoto data:fileDataRepresentation options:nil];
                
                if (livePhotoMovieURL != nil) {
                    PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                    options.shouldMoveFile = YES;
                    [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:livePhotoMovieURL options:options];
                    [options release];
                }
                
                request.location = self.locationManager.location;
            }
                                            completionHandler:^(BOOL success, NSError * _Nullable error) {
                NSLog(@"%d %@", success, error);
            }];
        } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
            NSData * _Nullable fileDataRepresentation = photo.fileDataRepresentation;
            assert(fileDataRepresentation != nil);
            
            auto output = static_cast<ExternalStorageDeviceFileOutput *>(fileOutput);
            AVExternalStorageDevice *device = output.externalStorageDevice;
            assert(device.isConnected);
            assert(!device.isNotRecommendedForCaptureUse);
            
            NSString *processedFileType = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photo, sel_registerName("processedFileType"));
            UTType *uti = [UTType typeWithIdentifier:processedFileType];
            
            if (livePhotoMovieURL == nil) {
                NSError * _Nullable error = nil;
                NSURL *url = [device nextAvailableURLsWithPathExtensions:@[uti.preferredFilenameExtension] error:&error].firstObject;
                assert(error == nil);
                assert(url != nil);
                
                assert([url startAccessingSecurityScopedResource]);
                assert([NSFileManager.defaultManager createFileAtPath:url.path contents:fileDataRepresentation attributes:nil]);
                [url stopAccessingSecurityScopedResource];
            } else {
                NSError * _Nullable error = nil;
                NSArray<NSURL *> *urls = [device nextAvailableURLsWithPathExtensions:@[uti.preferredFilenameExtension, UTTypeQuickTimeMovie.preferredFilenameExtension] error:&error];
                assert(error == nil);
                assert(urls.count == 2);
                
                for (NSURL *url in urls) {
                    assert([url startAccessingSecurityScopedResource]);
                    
                    if ([url.pathExtension isEqualToString:uti.preferredFilenameExtension]) {
                        BOOL result = [NSFileManager.defaultManager createFileAtPath:url.path contents:fileDataRepresentation attributes:nil];
                        [url stopAccessingSecurityScopedResource];
                        assert(result);
                    } else if ([url.pathExtension isEqualToString:UTTypeQuickTimeMovie.preferredFilenameExtension]) {
                        [NSFileManager.defaultManager moveItemAtURL:livePhotoMovieURL toURL:url error:&error];
                        [url stopAccessingSecurityScopedResource];
                        assert(error == nil);
                    }
                }
            }
        } else {
            abort();
        }
    });
    
    [self.mainQueue_capturePhotosByUniqueID removeObjectForKey:@(uniqueID)];
    [self.mainQueue_livePhotoMovieFileURLsByUniqueID removeObjectForKey:@(uniqueID)];
}

+ (BOOL)startSessionCalledForAssetWriter:(AVAssetWriter *)assetWriter {
    id _internal;
    assert(object_getInstanceVariable(assetWriter, "_internal", reinterpret_cast<void **>(&_internal)) != nullptr);
    
    id helper;
    assert(object_getInstanceVariable(_internal, "helper", reinterpret_cast<void **>(&helper)) != nullptr);
    
    BOOL _startSessionCalled;
    assert(object_getInstanceVariable(helper, "_startSessionCalled", reinterpret_cast<void **>(&_startSessionCalled)) != nullptr);
    
    return _startSessionCalled;
}

#warning Asset Writier - Metadata Face & Location
- (void)queue_handleMetadataOutput:(AVCaptureMetadataOutput *)depthDataOutput didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:depthDataOutput]) {
        MetadataObjectsLayer *metadataObjectsLayer = [self.queue_metadataObjectsLayersByCaptureDevice objectForKey:captureDevice];
        assert(metadataObjectsLayer != nil);
        
        AVCaptureVideoPreviewLayer *previewLayer = [self queue_previewLayerFromCaptureDevice:captureDevice];
        
        [metadataObjectsLayer updateWithMetadataObjects:metadataObjects previewLayer:previewLayer];
        
        //
        
        AVCaptureMetadataInput * _Nullable metadataInput = [self.queue_metadataInputsByCaptureDevice objectForKey:captureDevice];
        MovieWriter *movieWriter = [self.queue_movieWritersByVideoDevice objectForKey:captureDevice];
        assert(movieWriter != nil);
        
        if (metadataInput == nil and movieWriter.status != MovieWriterStatusRecording) {
            return;
        }
        
        for (__kindof AVMetadataObject *metadataObject in metadataObjects) {
            if ([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
                AVMutableMetadataItem *metadataItem = [AVMutableMetadataItem new];
                metadataItem.identifier = AVMetadataIdentifierQuickTimeMetadataDetectedFace;
                metadataItem.dataType = (id)kCMMetadataBaseDataType_RectF32;
                metadataItem.value = [NSValue valueWithCGRect:metadataObject.bounds];
                
                CMTimeRange timeRange = CMTimeRangeMake(metadataObject.time, metadataObject.duration);
                
                AVTimedMetadataGroup *metadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[metadataItem] timeRange:timeRange];
                [metadataItem release];
                
                if (metadataInput != nil) {
                    NSError * _Nullable error = nil;
                    [metadataInput appendTimedMetadataGroup:metadataGroup error:&error];
                    //            assert(error == nil);
                    if (error != nil) {
                        NSLog(@"%s: %@", sel_getName(_cmd), error);
                    }
                }
                
                if (movieWriter.status == MovieWriterStatusRecording) {
                    [movieWriter nonisolated_appendTimedMetadataGroup:metadataGroup];
                }
                
                [metadataGroup release];
            }
        }
    }
}

- (void)queue_handleVideoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
#warning Intrinsic
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSSet<AVCaptureDevice *> *videoDevices = [self queue_videoCaptureDevicesFromOutput:videoDataOutput];
    assert(videoDevices.count == 1);
    AVCaptureDevice *videoDevice = videoDevices.allObjects[0];
    
    CMAttachmentMode mode = 0;
    CFStringRef _Nullable reason = (CFStringRef)CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, &mode);
    if (reason) {
        CFShow(reason);
    }
    
    BOOL didHandle = NO;
    
    PixelBufferLayer *previewLayer = [self.queue_customPreviewLayersByCaptureDevice objectForKey:videoDevice];
    assert(previewLayer != nil);
    if (!previewLayer.isHidden) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [previewLayer updateWithPixelBuffer:imageBuffer];
        didHandle = YES;
    }
    
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer = [self.queue_sampleBufferDisplayLayersByVideoDevice objectForKey:videoDevice];
    assert(sampleBufferDisplayLayer != nil);
    if (!sampleBufferDisplayLayer.isHidden) {
        AVSampleBufferVideoRenderer *sampleBufferRenderer = sampleBufferDisplayLayer.sampleBufferRenderer;
        [sampleBufferRenderer flush];
        [sampleBufferRenderer enqueueSampleBuffer:sampleBuffer];
        didHandle = YES;
    }
    
    NerualAnalyzerLayer *nerualAnalyzerLayer = [self.queue_nerualAnalyzerLayersByVideoDevice objectForKey:videoDevice];
    assert(nerualAnalyzerLayer != nil);
    if (!nerualAnalyzerLayer.isHidden) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [nerualAnalyzerLayer updateWithPixelBuffer:imageBuffer];
        didHandle = YES;
    }
    
    assert(didHandle);
}

- (void)queue_handleAudioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
#warning 파형 그려보기
    dispatch_assert_queue(self.audioDataOutputQueue);
    
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    [self.adoQueue_audioSourceFormatHintsByAudioDataOutput setObject:(id)desc forKey:audioDataOutput];
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    for (AVCaptureConnection *connection in audioDataOutput.connections) {
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            AVCaptureDevice *audioDevice = deviceInput.device;
            
            if (![allAudioDeviceTypes containsObject:audioDevice.deviceType]) continue;
            
            for (MovieWriter *movieWriter in self.adoQueue_audioDataOutputsByMovieWriter.keyEnumerator) {
                if (![[self.adoQueue_audioDataOutputsByMovieWriter objectForKey:movieWriter] isEqual:audioDataOutput]) continue;
                [movieWriter nonisolated_appendAudioSampleBuffer:sampleBuffer];
            }
            
            break;
        }
    }
}


#pragma mark - AVCapturePhotoCaptureDelegate

//- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
//    
//}
//
//- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingRawPhotoSampleBuffer:(CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
//    
//}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
#warning 직접 calibration 해보기
    assert(error == nil);
#warning Capture depthData는 streaming과 다르게 해상도가 더 큼 configure 해보기
    NSLog(@"%@", photo.depthData);
    
    dispatch_assert_queue(dispatch_get_main_queue());
    [self.mainQueue_capturePhotosByUniqueID setObject:photo forKey:@(photo.resolvedSettings.uniqueID)];
}

#if TARGET_OS_IOS
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCapturingDeferredPhotoProxy:(AVCaptureDeferredPhotoProxy *)deferredPhotoProxy error:(NSError *)error {
    assert(self.queue_fileOutput.class == PhotoLibraryFileOutput.class);
    
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(deferredPhotoProxy.resolvedSettings, sel_registerName("isSpatialPhotoCaptureEnabled"));
    NSLog(@"isSpatialPhotoCaptureEnabled: %d", isSpatialPhotoCaptureEnabled);
    
    assert(error == nil);
    NSData * _Nullable fileDataRepresentation = deferredPhotoProxy.fileDataRepresentation;
    assert(fileDataRepresentation != nil); // AVVideoCodecTypeHEVC이 아니라면 nil일 수 있음
    
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        
        [request addResourceWithType:PHAssetResourceTypePhotoProxy data:fileDataRepresentation options:nil];
        
        request.location = self.locationManager.location;
    }
                                    completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"%d %@", success, error);
    }];
}
#endif

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    assert(error == nil);
    [self mainQueue_savePhotoWithPhotoOutput:output uniqueID:resolvedSettings.uniqueID];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    assert(error == nil);
    dispatch_assert_queue(dispatch_get_main_queue());
    [self.mainQueue_livePhotoMovieFileURLsByUniqueID setObject:outputFileURL forKey:@(resolvedSettings.uniqueID)];
}


#if TARGET_OS_IOS

#pragma mark - AVCaptureSessionControlsDelegate

- (void)sessionControlsDidBecomeActive:(AVCaptureSession *)session {
    NSLog(@"%s", sel_getName(_cmd));
}

- (void)sessionControlsWillEnterFullscreenAppearance:(AVCaptureSession *)session {
    NSLog(@"%s", sel_getName(_cmd));
}

- (void)sessionControlsWillExitFullscreenAppearance:(AVCaptureSession *)session {
    NSLog(@"%s", sel_getName(_cmd));
}

- (void)sessionControlsDidBecomeInactive:(AVCaptureSession *)session {
    NSLog(@"%s", sel_getName(_cmd));
}

#endif


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    dispatch_async(self.captureSessionQueue, ^{
        if (self.queue_metadataInputsByCaptureDevice.count == 0) return;
        
        for (CLLocation *location in locations) {
            if (CLLocationCoordinate2DIsValid(location.coordinate)) {
                AVMutableMetadataItem *metadataItem = [AVMutableMetadataItem new];
                metadataItem.identifier = AVMetadataIdentifierQuickTimeMetadataLocationISO6709;
                metadataItem.dataType = (id)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709;
                
                // https://github.com/ElfSundae/AVDemo/blob/60c31f30bf492ef89de9ac453d3e44b304133dcc/AVMetadataRecordPlay/Objective-C/AVMetadataRecordPlay/AVMetadataRecordPlayCameraViewController.m#L858C4-L858C30
                NSString *iso6709Notation;
                if (location.verticalAccuracy < 0.) {
                    iso6709Notation = [NSString stringWithFormat:@"%+08.4lf%+09.4lf/", location.coordinate.latitude, location.coordinate.longitude];
                } else {
                    iso6709Notation = [NSString stringWithFormat:@"%+08.4lf%+09.4lf%+08.3lf/", location.coordinate.latitude, location.coordinate.longitude, location.altitude];
                }
                metadataItem.value = iso6709Notation;
                
                AVTimedMetadataGroup *metadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[metadataItem] timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(location.timestamp.timeIntervalSince1970 / 10000.0, NSEC_PER_SEC), kCMTimeInvalid)];
                [metadataItem release];
                
                for (AVCaptureMetadataInput *input in self.queue_metadataInputsByCaptureDevice.objectEnumerator) {
                    NSError * _Nullable error = nil;
                    [input appendTimedMetadataGroup:metadataGroup error:&error];
//                    assert(error == nil);
                    if (error != nil) {
                        NSLog(@"%s: %@", sel_getName(_cmd), error);
                    }
                }
                
                for (MovieWriter *movieWriter in self.queue_movieWritersByVideoDevice.objectEnumerator) {
                    if (movieWriter.status == MovieWriterStatusRecording) {
                        [movieWriter nonisolated_appendTimedMetadataGroup:metadataGroup];
                    }
                }
                
                [metadataGroup release];
                
                break;
            }
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    switch (error.code) {
        case kCLErrorLocationUnknown:
        case kCLErrorDenied:
            break;
        default:
            abort();
            break;
    }
}


#pragma mark - AVCapturePhotoOutputReadinessCoordinatorDelegate

- (void)readinessCoordinator:(AVCapturePhotoOutputReadinessCoordinator *)coordinator captureReadinessDidChange:(AVCapturePhotoOutputCaptureReadiness)captureReadiness {
    dispatch_async(self.captureSessionQueue, ^{
        AVCapturePhotoOutput *photoOutput = [self queue_photoOutputFromReadinessCoordinator:coordinator];
        if (photoOutput == nil) return;
        
        
        for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:photoOutput]) {
            [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                              object:self
                                                            userInfo:@{
                CaptureServiceCaptureDeviceKey: captureDevice,
                CaptureServiceCaptureReadinessKey: @(captureReadiness)
            }];
        }
    });
}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    assert(error == nil);
    assert([output isKindOfClass:AVCaptureMovieFileOutput.class]);
    assert([NSFileManager.defaultManager fileExistsAtPath:outputFileURL.path]);
    
    auto movieFileOutput = static_cast<AVCaptureMovieFileOutput *>(output);
    __kindof BaseFileOutput *fileOutput = [self.queue_movieFileOutputsByFileOutput objectForKey:movieFileOutput];
    [self.queue_movieFileOutputsByFileOutput removeObjectForKey:movieFileOutput];
    
    if (fileOutput.class == PhotoLibraryFileOutput.class) {
        auto photoLibraryFileOutput = static_cast<PhotoLibraryFileOutput *>(fileOutput);
        
        [photoLibraryFileOutput.photoLibrary performChanges:^{
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            
            [request addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:nil];
            
            request.location = self.locationManager.location;
        }
                                        completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"%d %@", success, error);
            assert(error == nil);
            
            [NSFileManager.defaultManager removeItemAtURL:outputFileURL error:&error];
            [outputFileURL stopAccessingSecurityScopedResource];
            assert(error == nil);
        }];
    } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
        [outputFileURL stopAccessingSecurityScopedResource];
    } else {
        abort();
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)output didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)output didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
        [self queue_handleVideoDataOutput:static_cast<AVCaptureVideoDataOutput *>(output) didOutputSampleBuffer:sampleBuffer];
    } else if ([output isKindOfClass:AVCaptureAudioDataOutput.class]) {
        [self queue_handleAudioDataOutput:static_cast<AVCaptureAudioDataOutput *>(output) didOutputSampleBuffer:sampleBuffer];
    } else {
        abort();
    }
}


#pragma mark - AVCaptureDepthDataOutputDelegate

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection {
    dispatch_assert_queue(self.captureSessionQueue);
    
    if (!connection.isEnabled) return;
    
    for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:output]) {
        AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice];
        assert(rotationCoordinator != nil);
        
        CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:depthData.depthDataMap options:@{kCIImageAuxiliaryDisparity: @YES}];
        
        ImageBufferLayer *depthMapLayer = [self.queue_depthMapLayersByCaptureDevice objectForKey:captureDevice];
        [depthMapLayer updateWithCIImage:ciImage rotationAngle:180.f - rotationCoordinator.videoRotationAngleForHorizonLevelCapture fill:NO];
        
        [ciImage release];
    }
}

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didDropDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection reason:(AVCaptureOutputDataDroppedReason)reason {
    
}


#pragma mark - AVCapturePointCloudDataOutputDelegate

- (void)pointCloudDataOutput:(__kindof AVCaptureOutput *)output didDropPointCloudData:(id)arg2 timestamp:(CMTime)arg3 connection:(AVCaptureConnection *)connection reason:(NSInteger)arg5 {
//    NSLog(@"%@", arg2);
}

- (void)pointCloudDataOutput:(__kindof AVCaptureOutput *)output didOutputPointCloudData:(id)pointCloudData timestamp:(CMTime)arg3 connection:(AVCaptureConnection *)connection {
    // CVDataBuffer
//    CVBufferRef pointCloudDataBuffer = reinterpret_cast<CVPixelBufferRef (*)(id, SEL)>(objc_msgSend)(pointCloudData, sel_registerName("pointCloudDataBuffer"));
    
    id jasperPointCloud = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(pointCloudData, sel_registerName("jasperPointCloud"));
    CVImageBufferRef imageBuffer = reinterpret_cast<CVImageBufferRef (*)(id, SEL)>(objc_msgSend)(jasperPointCloud, sel_registerName("createVisualization"));
    CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:imageBuffer options:@{kCIImageAuxiliaryDisparity: @YES}];
    CVPixelBufferRelease(imageBuffer);
    
    for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:output]) {
        AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice];
        assert(rotationCoordinator != nil);
        
        ImageBufferLayer *pointCloudLayer = [self.queue_pointCloudLayersByCaptureDevice objectForKey:captureDevice];
        
        // videoRotationAngleForHorizonLevelCapture이 계속 0 나옴
        [pointCloudLayer updateWithCIImage:ciImage rotationAngle:180.f - rotationCoordinator.videoRotationAngleForHorizonLevelCapture fill:YES];
    }
    
    [ciImage release];
    
    // CVImageBufferRef이 Leak 있어서 쓰면 안 됨
//    CGImageRef cgImageRepresentation = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(jasperPointCloud, sel_registerName("cgImageRepresentation"));
//    
//    AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:output];
//    PixelBufferLayer *pointCloudLayer = [self.queue_pointCloudLayersByCaptureDevice objectForKey:captureDevice];
//    [pointCloudLayer updateWithCGImage:cgImageRepresentation];
//    CGImageRelease(cgImageRepresentation);
}


#pragma mark - AVCaptureVisionDataOutputDelegate

- (void)visionDataOutput:(__kindof AVCaptureOutput *)output didDropVisionDataPixelBufferForTimestamp:(CMTime)arg2 connection:(AVCaptureConnection *)arg3 reason:(NSInteger)arg4 {
    
}

- (void)visionDataOutput:(__kindof AVCaptureOutput *)output didOutputVisionDataPixelBuffer:(CVPixelBufferRef)arg2 timestamp:(CMTime)arg3 connection:(AVCaptureConnection *)arg4 {
    CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:arg2 options:@{kCIImageAuxiliaryDisparity: @YES}];
    
    for (AVCaptureDevice *captureDevice in [self queue_videoCaptureDevicesFromOutput:output]) {
        ImageBufferLayer *visionLayer = [self.queue_visionLayersByCaptureDevice objectForKey:captureDevice];
        [visionLayer updateWithCIImage:ciImage fill:YES];
    }
    
    [ciImage release];
}


#pragma mark - AVCaptureCameraCalibrationDataOutputDelegate

- (void)cameraCalibrationDataOutput:(__kindof AVCaptureOutput *)output didDropCameraCalibrationDataAtTimestamp:(CMTime)arg2 connection:(AVCaptureConnection *)arg3 reason:(NSInteger)arg4 {
    
}

- (void)cameraCalibrationDataOutput:(__kindof AVCaptureOutput *)output didOutputCameraCalibrationData:(AVCameraCalibrationData *)arg2 timestamp:(CMTime)arg3 connection:(AVCaptureConnection *)arg4 {
//    NSLog(@"%@", arg2);
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    [self queue_handleMetadataOutput:static_cast<AVCaptureMetadataOutput *>(output) didOutputMetadataObjects:metadataObjects];
}


#pragma mark - AVCaptureVideoThumbnailOutputDelgate

- (void)videoThumbnailOutput:(__kindof AVCaptureOutput *)videoThumbnailOutput willBeginRenderingThumbnailsWithContents:(id)contents {
    dispatch_async(self.captureSessionQueue, ^{
        NSSet<AVCaptureDevice *> *captureDevices = [self queue_captureDevicesFromOutput:videoThumbnailOutput];
        assert(captureDevices.count == 1);
        AVCaptureDevice *captureDevice = captureDevices.allObjects[0];
        
        CALayer *videoThumbnailLayer = [self.queue_videoThumbnailLayersByVideoDevice objectForKey:captureDevice];
        assert(videoThumbnailLayer != nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            videoThumbnailLayer.contents = contents;
        });
    });
}

- (void)videoThumbnailOutputWillEndRenderingThumbnails:(__kindof AVCaptureOutput *)videoThumbnailOutput {
    dispatch_async(self.captureSessionQueue, ^{
        NSSet<AVCaptureDevice *> *captureDevices = [self queue_captureDevicesFromOutput:videoThumbnailOutput];
        assert(captureDevices.count == 1);
        AVCaptureDevice *captureDevice = captureDevices.allObjects[0];
        
        CALayer *videoThumbnailLayer = [self.queue_videoThumbnailLayersByVideoDevice objectForKey:captureDevice];
        assert(videoThumbnailLayer != nil);
        videoThumbnailLayer.contents = nil;
    });
}

@end

#endif
