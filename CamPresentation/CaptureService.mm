//
//  CaptureService.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureService.h>
#import <CamPresentation/AVCaptureSession+CP_Private.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <CoreLocation/CoreLocation.h>
#import <CamPresentation/NSStringFromCMVideoDimensions.h>
#import <CamPresentation/PixelBufferLayer.h>
#import <CamPresentation/MetadataObjectsLayer.h>
#import <UIKit/UIKit.h>

#warning HDR Format Filter
#warning Zoom, Exposure
#warning AVCaptureDataOutputSynchronizer, AVControlCenterModuleState
#warning 녹화할 때 connection에 audio도 추가해야함

#warning AVCaptureFileOutput.maxRecordedDuration
#warning KVO에서 is 제거

#warning AVCaptureMetadataInput - remove/switch 대응

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

NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName = @"CaptureServiceDidChangeReactionEffectsInProgressNotificationName";
NSString * const CaptureServiceReactionEffectsInProgressKey = @"CaptureServiceReactionEffectsInProgressKey";

NSNotificationName const CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName = @"CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName";

NSString * const CaptureServiceCaptureSessionKey = @"CaptureServiceCaptureSessionKey";
NSNotificationName const CaptureServiceCaptureSessionRuntimeErrorNotificationName = @"CaptureServiceCaptureSessionRuntimeErrorNotificationName";

NSString * const CaptureServiceAdjustingFocusKey = @"CaptureServiceAdjustingFocusKey";
NSNotificationName const CaptureServiceAdjustingFocusDidChangeNotificationName = @"CaptureServiceAdjustingFocusDidChangeNotificationName";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (retain, nonatomic, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *queue_depthMapLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *queue_pointCloudLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *queue_visionLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, MetadataObjectsLayer *> *queue_metadataObjectsLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *queue_photoFormatModelsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *queue_readinessCoordinatorByCapturePhotoOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *queue_movieFileOutputsByFileOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureMetadataInput *> *queue_metadataInputsByCaptureDevice;
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService
@synthesize queue_previewLayersByCaptureDevice = _queue_previewLayersByCaptureDevice;

+ (void)load {
    Protocol *AVCapturePointCloudDataOutputDelegate = NSProtocolFromString(@"AVCapturePointCloudDataOutputDelegate");
    assert(AVCapturePointCloudDataOutputDelegate != nil);
    assert(class_addProtocol(self, AVCapturePointCloudDataOutputDelegate));
    
    Protocol *AVCaptureVisionDataOutputDelegate = NSProtocolFromString(@"AVCaptureVisionDataOutputDelegate");
    assert(AVCaptureVisionDataOutputDelegate != nil);
    assert(class_addProtocol(self, AVCaptureVisionDataOutputDelegate));
    
    Protocol *AVCaptureCameraCalibrationDataOutputDelegate = NSProtocolFromString(@"AVCaptureCameraCalibrationDataOutputDelegate");
    assert(AVCaptureCameraCalibrationDataOutputDelegate != nil);
    assert(class_addProtocol(self, AVCaptureCameraCalibrationDataOutputDelegate));
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", attr);
        
        //
        
        NSArray<AVCaptureDeviceType> *allDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allDeviceTypes"));
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:allDeviceTypes
                                                                                                                                     mediaType:nil
                                                                                                                                      position:AVCaptureDevicePositionUnspecified];
        
        //
        
        AVExternalStorageDeviceDiscoverySession *externalStorageDeviceDiscoverySession = AVExternalStorageDeviceDiscoverySession.sharedSession;
        [externalStorageDeviceDiscoverySession addObserver:self forKeyPath:@"externalStorageDevices" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *photoFormatModelsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *depthMapLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *pointCloudLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PixelBufferLayer *> *visionLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, MetadataObjectsLayer *> *metadataObjectsLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *movieFileOutputsByFileOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVCaptureMetadataInput *> *metadataInputsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        
        //
        
        CLLocationManager *locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        
#if !TARGET_OS_TV
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startUpdatingLocation];
#endif
        
        //
        
        _captureSessionQueue = captureSessionQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _externalStorageDeviceDiscoverySession = [externalStorageDeviceDiscoverySession retain];
        _queue_photoFormatModelsByCaptureDevice = [photoFormatModelsByCaptureDevice retain];
        _locationManager = locationManager;
        _queue_rotationCoordinatorsByCaptureDevice = [rotationCoordinatorsByCaptureDevice retain];
        _queue_readinessCoordinatorByCapturePhotoOutput = [readinessCoordinatorByCapturePhotoOutput retain];
        _queue_previewLayersByCaptureDevice = [previewLayersByCaptureDevice retain];
        _queue_depthMapLayersByCaptureDevice = [depthMapLayersByCaptureDevice retain];
        _queue_visionLayersByCaptureDevice = [visionLayersByCaptureDevice retain];
        _queue_pointCloudLayersByCaptureDevice = [pointCloudLayersByCaptureDevice retain];
        _queue_metadataObjectsLayersByCaptureDevice = [metadataObjectsLayersByCaptureDevice retain];
        _queue_movieFileOutputsByFileOutput = [movieFileOutputsByFileOutput retain];
        _queue_metadataInputsByCaptureDevice = [metadataInputsByCaptureDevice retain];
        self.queue_fileOutput = nil;
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
        
        [AVCaptureDevice addObserver:self forKeyPath:@"centerStageEnabled" options:NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [AVCaptureDevice removeObserver:self forKeyPath:@"centerStageEnabled"];
    
    for (__kindof AVCaptureInput *input in _queue_captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto captureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [self unregisterObserversForVideoCaptureDevice:captureDevice];
        }
    }
    
    for (__kindof AVCaptureOutput *output in _queue_captureSession.outputs) {
        if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
            auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
            [self unregisterObserversForPhotoOutput:photoOutput];
        }
    }
    
    if ([_queue_captureSession isKindOfClass:AVCaptureMultiCamSession.class]) {
        [_queue_captureSession removeObserver:self forKeyPath:@"hardwareCost"];
        [_queue_captureSession removeObserver:self forKeyPath:@"systemPressureCost"];
    }
    
    [_queue_captureSession release];
    
    [_captureSessionQueue release];
    [_captureDeviceDiscoverySession release];
    [_externalStorageDeviceDiscoverySession removeObserver:self forKeyPath:@"externalStorageDevices"];
    [_externalStorageDeviceDiscoverySession release];
    
    for (AVCaptureDeviceRotationCoordinator *rotationCoordinator in _queue_rotationCoordinatorsByCaptureDevice.objectEnumerator) {
        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    [_queue_rotationCoordinatorsByCaptureDevice release];
    [_queue_photoFormatModelsByCaptureDevice release];
    [_queue_readinessCoordinatorByCapturePhotoOutput release];
    [_queue_previewLayersByCaptureDevice release];
    [_queue_depthMapLayersByCaptureDevice release];
    [_queue_pointCloudLayersByCaptureDevice release];
    [_queue_visionLayersByCaptureDevice release];
    [_queue_metadataObjectsLayersByCaptureDevice release];
    [_queue_movieFileOutputsByFileOutput release];
    [_queue_metadataInputsByCaptureDevice release];
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
            static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer).connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
            return;
        }
    } else if ([object isKindOfClass:AVCaptureDevice.class]) {
        auto captureDevice = static_cast<AVCaptureDevice *>(object);
        
        if ([keyPath isEqualToString:@"reactionEffectsInProgress"]) {
#warning TODO - method 분리
            [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
                                                              object:self
                                                            userInfo:@{
                CaptureServiceCaptureDeviceKey: captureDevice,
                CaptureServiceReactionEffectsInProgressKey: change[NSKeyValueChangeNewKey]
            }];
            return;
        } else if ([keyPath isEqualToString:@"spatialCaptureDiscomfortReasons"]) {
            [self postDidChangeSpatialCaptureDiscomfortReasonNotificationWithCaptureDevice:captureDevice];
            return;
        } else if ([keyPath isEqualToString:@"activeFormat"]) {
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
        } else if ([keyPath isEqualToString:@"adjustingFocus"]) {
            if (captureDevice != nil) {
                dispatch_async(self.captureSessionQueue, ^{
                    [self queue_postAdjustingFocusDidChangeNotificationWithCaptureDevice:captureDevice];
                });
            }
            return;
        }
    } else if ([object isKindOfClass:AVCapturePhotoOutput.class]) {
        if ([keyPath isEqualToString:@"availablePhotoPixelFormatTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoCodecTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updateCodecTypeIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoPixelFormatTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoFileTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updateRawFileTypeIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoFileTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updateProcessedFileTypeIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isSpatialPhotoCaptureSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAutoDeferredPhotoDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"supportedFlashModes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isZeroShutterLagSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isResponsiveCaptureSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAppleProRAWSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isFastCapturePrioritizationSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isCameraCalibrationDataDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                PhotoFormatModel *photoFormatModel = [self queue_photoFormatModelForCaptureDevice:captureDevice];
                
                [photoFormatModel updateCameraCalibrationDataDeliveryEnabledIfNeededWithPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self queue_setPhotoFormatModel:photoFormatModel forCaptureDevice:captureDevice];
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isDepthDataDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        }
    } else if ([object isKindOfClass:AVCaptureMetadataOutput.class]) {
        if ([keyPath isEqualToString:@"availableMetadataObjectTypes"]) {
            auto metadataOutput = static_cast<AVCaptureMetadataOutput *>(object);
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes;
            return;
        }
    } else if ([object isEqual:AVCaptureDevice.class]) {
        if ([keyPath isEqualToString:@"centerStageEnabled"]) {
            dispatch_async(self.captureSessionQueue, ^{
#warning TODO
                NSLog(@"Hello World! %d", self.queue_addedVideoCaptureDevices.firstObject.isCenterStageActive);
            });
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *)queue_previewLayersByCaptureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return _queue_previewLayersByCaptureDevice;
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

- (void)queue_setFileOutput:(__kindof BaseFileOutput *)queue_fileOutput {
    [_queue_fileOutput release];
    
    if (queue_fileOutput == nil) {
        _queue_fileOutput = [[PhotoLibraryFileOutput alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
    } else {
        _queue_fileOutput = [queue_fileOutput retain];
    }
}

- (NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *)queue_previewLayersByCaptureDeviceCopiedMapTable {
    dispatch_assert_queue(self.captureSessionQueue);
    return [[self.queue_previewLayersByCaptureDevice copy] autorelease];
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

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice {
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
    
    [self registerObserversForVideoCaptureDevice:captureDevice];
    
    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice] == nil);
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
    [self.queue_previewLayersByCaptureDevice setObject:captureVideoPreviewLayer forKey:captureDevice];
    
    [captureSession beginConfiguration];
    
    NSString *reason = nil;
    NSError * _Nullable error = nil;
    
    AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    assert([captureSession canAddInput:newInput]);
    
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
    
    AVCaptureConnection *previewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:captureVideoPreviewLayer];
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    AVCapturePhotoOutput *photoOutput = [AVCapturePhotoOutput new];
    photoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
    [self registerObserversForPhotoOutput:photoOutput];
    
    [captureSession addOutputWithNoConnections:photoOutput];
    AVCaptureConnection *photoOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:photoOutput];
    assert([captureSession canAddConnection:photoOutputConnection]);
    [captureSession addConnection:photoOutputConnection];
    [photoOutputConnection release];
    
    [newInput release];
    
    //
    
    AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
    reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddOutput:failureReason:"), movieFileOutput, &reason));
    [captureSession addOutputWithNoConnections:movieFileOutput];
    
    AVCaptureConnection *movieFileOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:movieFileOutput];
    assert([captureSession canAddConnection:movieFileOutputConnection]);
    [captureSession addConnection:movieFileOutputConnection];
    [movieFileOutputConnection release];
    
    //
    
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    videoDataOutput.automaticallyConfiguresOutputBufferDimensions = NO;
    videoDataOutput.deliversPreviewSizedOutputBuffers = YES;
    [videoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
    assert([captureSession canAddOutput:videoDataOutput]);
    [captureSession addOutputWithNoConnections:videoDataOutput];
    
    AVCaptureConnection *videoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:videoDataOutput];
    [videoDataOutput release];
    assert([captureSession canAddConnection:videoDataOutputConnection]);
    [captureSession addConnection:videoDataOutputConnection];
    [videoDataOutputConnection release];
    
    //
    
    if (depthDataInputPort != nil) {
        AVCaptureDepthDataOutput *depthDataOutput = [AVCaptureDepthDataOutput new];
        depthDataOutput.filteringEnabled = YES;
        depthDataOutput.alwaysDiscardsLateDepthData = YES;
        [depthDataOutput setDelegate:self callbackQueue:self.captureSessionQueue];
        assert([captureSession canAddOutput:depthDataOutput]);
        [captureSession addOutputWithNoConnections:depthDataOutput];
        
        AVCaptureConnection *depthDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[depthDataInputPort] output:depthDataOutput];
        depthDataOutputConnection.videoMirrored = YES;
        [depthDataOutput release];
        assert([captureSession canAddConnection:depthDataOutputConnection]);
        [captureSession addConnection:depthDataOutputConnection];
        [depthDataOutputConnection release];
        
        PixelBufferLayer *depthMapLayer = [PixelBufferLayer new];
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
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), visionDataOutputConnection, &reason));
        [captureSession addConnection:visionDataOutputConnection];
        [visionDataOutputConnection release];
        
        PixelBufferLayer *visionLayer = [PixelBufferLayer new];
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
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), calibrationDataOutputConnection, &reason));
        [captureSession addConnection:calibrationDataOutputConnection];
        [calibrationDataOutputConnection release];
    }
    
    //
    
    if (metadataObjectInputPort != nil) {
        AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
        [self registerObserversForMetadataOutput:metadataOutput];
        [metadataOutput setMetadataObjectsDelegate:self queue:self.captureSessionQueue];
        assert([captureSession canAddOutput:metadataOutput]);
        [captureSession addOutputWithNoConnections:metadataOutput];
        
        AVCaptureConnection *metadataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[metadataObjectInputPort] output:metadataOutput];
        reason = nil;
        assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), metadataOutputConnection, &reason));
        [captureSession addConnection:metadataOutputConnection];
        [metadataOutputConnection release];
        
        [metadataOutput release];
        
        MetadataObjectsLayer *metadataObjectsLayer = [MetadataObjectsLayer new];
        [self.queue_metadataObjectsLayersByCaptureDevice setObject:metadataObjectsLayer forKey:captureDevice];
        [metadataObjectsLayer release];
    }
    
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
        
        __kindof AVCaptureControl *systemStyleSlider = reinterpret_cast<id (*)(id, SEL, id, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureSystemStyleSlider") alloc], sel_registerName("initWithSession:parameter:action:"), captureSession, nil, nil);
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), systemStyleSlider, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:systemStyleSlider];
        [systemStyleSlider release];
    }
#endif
    
    //
    
    CMMetadataFormatDescriptionRef formatDescription = [self createMetadataFormatDescription];
    AVCaptureMetadataInput *metadataInput = [[AVCaptureMetadataInput alloc] initWithFormatDescription:formatDescription clock:metadataObjectInputPort.clock];
    CFRelease(formatDescription);
    assert([captureSession canAddInput:metadataInput]);
    [captureSession addInputWithNoConnections:metadataInput];
    
    BOOL didAdd = NO;
    for (AVCaptureInputPort *inputPort in metadataInput.ports) {
        if ([inputPort.mediaType isEqualToString:AVMediaTypeMetadata]) {
            AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:@[inputPort] output:movieFileOutput];
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
    
    [movieFileOutput release];
    
    //
    
    [captureSession commitConfiguration];
    
    AVCaptureDevice.userPreferredCamera = captureDevice;
    
    //
    
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:captureVideoPreviewLayer];
    [captureVideoPreviewLayer release];
    captureVideoPreviewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:nullptr];
    [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
    [rotationCoodinator release];
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:photoOutput];
    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:photoOutput];
    readinessCoordinator.delegate = self;
    [readinessCoordinator release];
    
    PhotoFormatModel *photoFormatModel = [PhotoFormatModel new];
    [photoFormatModel updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [photoFormatModel updateCodecTypeIfNeededWithPhotoOutput:photoOutput];
    [photoFormatModel updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:photoOutput];
    [photoFormatModel updateRawFileTypeIfNeededWithPhotoOutput:photoOutput];
    [photoFormatModel updateProcessedFileTypeIfNeededWithPhotoOutput:photoOutput];
    
    [self.queue_photoFormatModelsByCaptureDevice setObject:photoFormatModel forKey:captureDevice];
    [photoOutput release];
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
    
    assert([captureSession canAddInput:deviceInput]);
    [captureSession addInputWithNoConnections:deviceInput];
    
    NSArray<AVCaptureInputPort *> *audioDevicePorts = [deviceInput portsWithMediaType:AVMediaTypeAudio sourceDeviceType:nil sourceDevicePosition:AVCaptureDevicePositionUnspecified];
    
    //
    
    AVCaptureAudioDataOutput *audioDataOutput = [AVCaptureAudioDataOutput new];
    [audioDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
    assert([captureSession canAddOutput:audioDataOutput]);
    [captureSession addOutputWithNoConnections:audioDataOutput];
    
    //
    
    AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:audioDevicePorts output:audioDataOutput];
    [deviceInput release];
    [audioDataOutput release];
    assert([captureSession canAddConnection:connection]);
    assert(connection.isEnabled);
    assert(connection.isActive);
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
    
    PixelBufferLayer *pointCloudLayer = [PixelBufferLayer new];
    [self.queue_pointCloudLayersByCaptureDevice setObject:pointCloudLayer forKey:captureDevice];
    [pointCloudLayer release];
    
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:nil];
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:nullptr];
    [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
    [rotationCoodinator release];
    
    //
    
    [self postDidAddDeviceNotificationWithCaptureDevice:captureDevice];
    [self postDidUpdatePointCloudLayersNotification];
}

- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedCaptureDevices containsObject:captureDevice]);
    
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
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [self unregisterObserversForVideoCaptureDevice:captureDevice];
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    assert(captureSession != nil);
    
    //
    
    [captureSession beginConfiguration];
    
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
    
    AVCaptureMetadataInput *metadataInput = [self.queue_metadataInputsByCaptureDevice objectForKey:captureDevice];
    assert(metadataInput != nil);
    
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
            
            [self unregisterObserversForPhotoOutput:photoOutput];
            
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
            [captureSession removeOutput:output];
        } else if ([output isKindOfClass:AVCaptureDepthDataOutput.class]) {
            [captureSession removeOutput:output];
        } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
            [captureSession removeOutput:output];
            
            assert([self.queue_visionLayersByCaptureDevice objectForKey:captureDevice] != nil);
            [self.queue_visionLayersByCaptureDevice removeObjectForKey:captureDevice];
        } else if ([output isKindOfClass:objc_lookUpClass("AVCaptureCameraCalibrationDataOutput")]) {
            [captureSession removeOutput:output];
        } else if ([output isKindOfClass:AVCaptureMetadataOutput.class]) {
            auto metadataOutput = static_cast<AVCaptureMetadataOutput *>(output);
            [self unregisterObserversForMetadataOutput:metadataOutput];
            [captureSession removeOutput:metadataOutput];
            
            assert([self.queue_metadataObjectsLayersByCaptureDevice objectForKey:captureDevice] != nil);
            [self.queue_metadataObjectsLayersByCaptureDevice removeObjectForKey:captureDevice];
        } else {
            abort();
        }
    }
    
    [outputs release];
    
    //
    
    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
    } else {
        abort();
    }
    
    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice] != nil);
    [self.queue_previewLayersByCaptureDevice removeObjectForKey:captureDevice];
    [self.queue_metadataInputsByCaptureDevice removeObjectForKey:captureDevice];
    
    [captureSession removeInput:deviceInput];
    [captureSession removeInput:metadataInput];
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
                [captureSession removeOutput:connection.output];
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
        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
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
}

- (AVCapturePhotoOutput *)queue_photoOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto photoOutput = static_cast<AVCapturePhotoOutput *>(connection.output);
            if (![photoOutput isKindOfClass:AVCapturePhotoOutput.class]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return photoOutput;
                }
            }
        }
    }
    
    return nil;
}

- (AVCaptureDepthDataOutput *)queue_depthDataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto depthDataOutput = static_cast<AVCaptureDepthDataOutput *>(connection.output);
            if (![depthDataOutput isKindOfClass:AVCaptureDepthDataOutput.class]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return depthDataOutput;
                }
            }
        }
    }
    
    return nil;
}

- (__kindof AVCaptureOutput *)queue_visionDataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            __kindof AVCaptureOutput *visionDataOutput = connection.output;
            if (![visionDataOutput isKindOfClass:objc_lookUpClass("AVCaptureVisionDataOutput")]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return visionDataOutput;
                }
            }
        }
    }
    
    return nil;
}

- (AVCaptureMetadataOutput *)queue_metadataOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            __kindof AVCaptureOutput *visionDataOutput = connection.output;
            if (![visionDataOutput isKindOfClass:AVCaptureMetadataOutput.class]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return visionDataOutput;
                }
            }
        }
    }
    
    return nil;
}

- (void)queue_setUpdatesDepthMapLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    AVCaptureDepthDataOutput *depthDataOutput = [self queue_depthDataOutputFromCaptureDevice:captureDevice];
    assert(depthDataOutput != nil);
    AVCaptureConnection *connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert(connection != nil);
    
    connection.enabled = updatesDepthMapLayer;
    
    PixelBufferLayer *depthMapLayer = [self.queue_depthMapLayersByCaptureDevice objectForKey:captureDevice];
    assert(depthMapLayer != nil);
    [depthMapLayer updateWithCIImage:nil rotationAngle:0.f fill:NO];
}

- (BOOL)queue_updatesDepthMapLayer:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    AVCaptureDepthDataOutput *depthDataOutput = [self queue_depthDataOutputFromCaptureDevice:captureDevice];
    assert(depthDataOutput != nil);
    AVCaptureConnection *connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert(connection != nil);
    
    return connection.isEnabled;
}

- (void)queue_setUpdatesVisionLayer:(BOOL)updatesDepthMapLayer captureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    __kindof AVCaptureOutput *visionDataOutput = [self queue_visionDataOutputFromCaptureDevice:captureDevice];
    assert(visionDataOutput != nil);
    AVCaptureConnection *connection = [visionDataOutput connectionWithMediaType:AVMediaTypeVisionData];
    assert(connection != nil);
    
    connection.enabled = updatesDepthMapLayer;
    
    PixelBufferLayer *visionLayer = [self.queue_visionLayersByCaptureDevice objectForKey:captureDevice];
    assert(visionLayer != nil);
    [visionLayer updateWithCIImage:nil rotationAngle:0.f fill:NO];
}

- (BOOL)queue_updatesVisionLayer:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    __kindof AVCaptureOutput *visionDataOutput = [self queue_visionDataOutputFromCaptureDevice:captureDevice];
    assert(visionDataOutput != nil);
    AVCaptureConnection *connection = [visionDataOutput connectionWithMediaType:AVMediaTypeVisionData];
    assert(connection != nil);
    
    return connection.isEnabled;
}

- (AVCaptureVideoPreviewLayer *)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_previewLayersByCaptureDevice objectForKey:captureDevice];
}

- (AVCaptureDevice *)queue_captureDeviceFromPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMapTable<AVCaptureDevice *,AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDevice = self.queue_previewLayersByCaptureDevice;
    
    for (AVCaptureDevice *captureDevice in previewLayersByCaptureDevice.keyEnumerator) {
        AVCaptureVideoPreviewLayer *_previewLayer = [previewLayersByCaptureDevice objectForKey:captureDevice];
        if ([_previewLayer isEqual:previewLayer]) {
            return captureDevice;
        }
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

- (AVCapturePhotoOutputReadinessCoordinator *)queue_readinessCoordinatorFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    AVCapturePhotoOutput *photoOutput = [self queue_photoOutputFromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    return [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput];
}

- (AVCaptureMovieFileOutput *)queue_movieFileOutputFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto movileFileOutput = static_cast<AVCaptureMovieFileOutput *>(connection.output);
            if (![movileFileOutput isKindOfClass:AVCaptureMovieFileOutput.class]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                if ([deviceInput.device isEqual:captureDevice]) {
                    return movileFileOutput;
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

#warning Multi Mic 지원
- (void)queue_connectAudioDevice:(AVCaptureDevice *)audioDevice withMovieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput {
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
    
    AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:movieFileOutput];
    
    NSString * _Nullable reason = nil;
    assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), connection, &reason));
    [captureSession addConnection:connection];
    [connection release];
    
    [captureSession commitConfiguration];
}

- (void)queue_disconnectAudioDevice:(AVCaptureDevice *)audioDevice fromMovieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput {
    dispatch_assert_queue(self.captureSessionQueue);
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeAudio];
    assert(connection != nil);
    
    [captureSession beginConfiguration];
    [captureSession removeConnection:connection];
    [captureSession commitConfiguration];
}

- (AVCaptureDevice *)queue_captureDeviceFromOutput:(__kindof AVCaptureOutput *)output {
    dispatch_assert_queue(self.captureSessionQueue);
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if (![output isEqual:connection.output]) {
                continue;
            }
            
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(port.input);
            if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                return deviceInput.device;
            }
        }
    }
    
    return nil;
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
    AVCapturePhotoOutput *capturePhotoOutput = [self queue_photoOutputFromCaptureDevice:captureDevice];
    
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
    capturePhotoSettings.embedsDepthDataInPhoto = isDepthDataDeliveryEnabled;
    
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
        NSURL *tmpURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        NSString *processName = NSProcessInfo.processInfo.processName;
        NSURL *processDirectoryURL = [tmpURL URLByAppendingPathComponent:processName isDirectory:YES];
        
        BOOL isDirectory;
        if (![NSFileManager.defaultManager fileExistsAtPath:processDirectoryURL.path isDirectory:&isDirectory]) {
            NSError * _Nullable error = nil;
            [NSFileManager.defaultManager createDirectoryAtURL:processDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
            assert(error == nil);
            isDirectory = YES;
        }
        assert(isDirectory);
        
        outputURL = [processDirectoryURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
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

- (void)queue_postAdjustingFocusDidChangeNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceAdjustingFocusDidChangeNotificationName
                                                      object:self
                                                    userInfo:@{
        CaptureServiceCaptureDeviceKey: captureDevice,
        CaptureServiceAdjustingFocusKey: @(captureDevice.adjustingFocus)
    }];
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

- (void)postDidChangeSpatialCaptureDiscomfortReasonNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName
                                                      object:self
                                                    userInfo:@{
        CaptureServiceCaptureDeviceKey: captureDevice
    }];
}

- (void)registerObserversForVideoCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [captureDevice addObserver:self forKeyPath:@"reactionEffectsInProgress" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"formats" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"torchAvailable" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"activeDepthDataFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"isCenterStageActive" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nullptr];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveSubjectAreaDidChangeNotification:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    
    NSError * _Nullable error = nil;
    [captureDevice lockForConfiguration:&error];
    assert(error == nil);
    captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    [captureDevice unlockForConfiguration];
}

- (void)unregisterObserversForVideoCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:captureDevice.deviceType]);
    
    [captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    [captureDevice removeObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons"];
    [captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [captureDevice removeObserver:self forKeyPath:@"formats"];
    [captureDevice removeObserver:self forKeyPath:@"torchAvailable"];
    [captureDevice removeObserver:self forKeyPath:@"activeDepthDataFormat"];
    [captureDevice removeObserver:self forKeyPath:@"isCenterStageActive"];
    [captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    
    NSError * _Nullable error = nil;
    [captureDevice lockForConfiguration:&error];
    assert(error == nil);
    captureDevice.subjectAreaChangeMonitoringEnabled = NO;
    [captureDevice unlockForConfiguration];
}

- (void)registerObserversForPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
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
}

- (void)unregisterObserversForPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
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
}

- (void)registerObserversForMetadataOutput:(AVCaptureMetadataOutput *)metadataOutput {
    [metadataOutput addObserver:self forKeyPath:@"availableMetadataObjectTypes" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)unregisterObserversForMetadataOutput:(AVCaptureMetadataOutput *)metadataOutput {
    [metadataOutput removeObserver:self forKeyPath:@"availableMetadataObjectTypes"];
}

- (void)didReceiveRuntimeErrorNotification:(NSNotification *)notification {
    dispatch_async(self.captureSessionQueue, ^{
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        
        if (NSError *error = notification.userInfo[AVCaptureSessionErrorKey]) {
            assert([error isKindOfClass:NSError.class]);
            userInfo[AVCaptureSessionErrorKey] = error;
            NSLog(@"%@", error);
        } else {
            abort();
        }
        
        if (__kindof AVCaptureSession *session = notification.object) {
            assert([session isKindOfClass:AVCaptureSession.class]);
            assert(([session isEqual:self.queue_captureSession]));
            userInfo[CaptureServiceCaptureSessionKey] = session;
        } else {
            abort();
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceCaptureSessionRuntimeErrorNotificationName object:self userInfo:userInfo];
        [userInfo release];
    });
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
        if (wasRunning) {
            [currentCaptureSession stopRunning];
        }
        
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
    
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureSession, sel_registerName("setSystemStyleEnabled:"), YES);
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveRuntimeErrorNotification:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
    captureSession.automaticallyConfiguresCaptureDeviceForWideColor = NO;
    captureSession.usesApplicationAudioSession = YES;
    captureSession.automaticallyConfiguresApplicationAudioSession = NO;
#warning configuresApplicationAudioSessionToMixWithOthers
    
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
        
        NSArray<AVCaptureConnection *> *connections = oldCaptureSession.connections;
        
        // AVCaptureMovieFileOutput 처럼 여러 Connection (Video, Audio)이 하나의 Output을 가지는 경우가 있어, 배열에 중복을 피하기 위해 Set을 사용
        NSMutableSet<__kindof AVCaptureOutput *> *outputs = [NSMutableSet new];
        
        for (AVCaptureConnection *connection in oldCaptureSession.connections) {
            if (__kindof AVCaptureOutput *output = connection.output) {
                if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
                    auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
                    [self unregisterObserversForPhotoOutput:photoOutput];
                    
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
                    [self unregisterObserversForMetadataOutput:metadataOutput];
                } else {
                    abort();
                }
                
                [outputs addObject:output];
            }
            
            [oldCaptureSession removeConnection:connection];
        }
        
        for (AVCaptureOutput *output in outputs) {
            [oldCaptureSession removeOutput:output];
        }
        
        NSArray<__kindof AVCaptureInput *> *inputs = oldCaptureSession.inputs;
        for (__kindof AVCaptureInput *input in oldCaptureSession.inputs) {
            if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
                AVCaptureDevice *captureDevice = deviceInput.device;
                
                NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
                
                if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
                    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
                        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
                        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
                    } else {
                        abort();
                    }
                    
                    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice]);
                    [self.queue_previewLayersByCaptureDevice removeObjectForKey:captureDevice];
                    
                    // AVCaptureSession <-> AVCaptureMultiCamSession 전환이 될 경우 Preview Layer는 0개 및 1개일 것이며, 1개는 위에서 지워질 것이다.
                    assert(self.queue_previewLayersByCaptureDevice.count == 0);
                }
            } else if ([input isKindOfClass:AVCaptureMetadataInput.class]) {
                
            } else {
                abort();
            }
            
            [oldCaptureSession removeInput:input];
        }
        
        [oldCaptureSession commitConfiguration];
        
        //
        
        [captureSession beginConfiguration];
        
        NSMapTable<AVCaptureInput *, AVCaptureInput *> *addedInputsByOldInput = [NSMapTable strongToStrongObjectsMapTable];
        for (__kindof AVCaptureInput *input in inputs) {
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
                
                CMMetadataFormatDescriptionRef formatDescription = [self createMetadataFormatDescription];
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
        assert(inputs.count == addedInputsByOldInput.count);
        
        NSMapTable<AVCaptureOutput *, AVCaptureOutput *> *addedOutputsByOutputs = [NSMapTable strongToStrongObjectsMapTable];
        for (__kindof AVCaptureOutput *output in outputs) {
            if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
                AVCapturePhotoOutput *newPhotoOutput = [AVCapturePhotoOutput new];
                newPhotoOutput.maxPhotoQualityPrioritization = static_cast<AVCapturePhotoOutput *>(output).maxPhotoQualityPrioritization;
                assert([captureSession canAddOutput:newPhotoOutput]);
                [captureSession addOutputWithNoConnections:newPhotoOutput];
                
                [addedOutputsByOutputs setObject:newPhotoOutput forKey:output];
                [self registerObserversForPhotoOutput:newPhotoOutput];
                
                //
                
                [newPhotoOutput release];
            } else if ([output isKindOfClass:AVCaptureMovieFileOutput.class]) {
                AVCaptureMovieFileOutput *newMovieFileOutput = [AVCaptureMovieFileOutput new];
                
                assert([captureSession canAddOutput:newMovieFileOutput]);
                [captureSession addOutputWithNoConnections:newMovieFileOutput];
                
                [addedOutputsByOutputs setObject:newMovieFileOutput forKey:output];
                [newMovieFileOutput release];
            } else if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
                AVCaptureVideoDataOutput *newVideoDataOutput = [AVCaptureVideoDataOutput new];
                [newVideoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
                
                assert([captureSession canAddOutput:newVideoDataOutput]);
                [captureSession addOutputWithNoConnections:newVideoDataOutput];
                
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
                [newAudioDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
                
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
                [self registerObserversForMetadataOutput:newMetadataOutput];
                [newMetadataOutput setMetadataObjectsDelegate:self queue:self.captureSessionQueue];
                
                assert([captureSession canAddOutput:newMetadataOutput]);
                [captureSession addOutputWithNoConnections:newMetadataOutput];
                
                [addedOutputsByOutputs setObject:newMetadataOutput forKey:output];
                [newMetadataOutput release];
            } else {
                abort();
            }
        }
        assert(outputs.count == addedOutputsByOutputs.count);
        [outputs release];
        
        // AVCaptureDeviceInput과 연결된 AVCaptureConnection들 처리
        for (AVCaptureConnection *connection in connections) {
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
            if (connection.videoPreviewLayer != nil) {
                AVCaptureDevice *captureDevice = addedInput.device;
                
                AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
                [self.queue_previewLayersByCaptureDevice setObject:previewLayer forKey:captureDevice];
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:previewLayer];
                [previewLayer release];
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
                    
                    if (PhotoFormatModel *photoFormatModel = [self.queue_photoFormatModelsByCaptureDevice objectForKey:captureDevice]) {
                        [photoFormatModel updatePhotoPixelFormatTypeIfNeededWithPhotoOutput:addedPhotoOutput];
                        [photoFormatModel updateCodecTypeIfNeededWithPhotoOutput:addedPhotoOutput];
                        [photoFormatModel updateRawPhotoPixelFormatTypeIfNeededWithPhotoOutput:addedPhotoOutput];
                        [photoFormatModel updateRawFileTypeIfNeededWithPhotoOutput:addedPhotoOutput];
                        [photoFormatModel updateProcessedFileTypeIfNeededWithPhotoOutput:addedPhotoOutput];
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
                    assert(videoInputPort != nil);
                    newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:addedOutput];
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
                } else {
                    abort();
                }
            }
            
            newConnection.enabled = connection.isEnabled;
            
            if (newConnection.isVideoMirroringSupported) {
                newConnection.automaticallyAdjustsVideoMirroring = connection.automaticallyAdjustsVideoMirroring;
                
                if (!newConnection.automaticallyAdjustsVideoMirroring) {
                    newConnection.videoMirrored = connection.isVideoMirrored;
                }
            }
            
            NSString * _Nullable reason = nil;
            assert(reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddConnection:failureReason:"), newConnection, &reason));
            [captureSession addConnection:newConnection];
            
            AVCaptureDevice *captureDevice = addedInput.device;
            
            NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
            
            if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
                AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:newConnection.videoPreviewLayer];
                newConnection.videoPreviewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
                [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
                [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
                [rotationCoodinator release];
            }
            
            //
            
            [newConnection release];
        }
        
        // AVCaptureMetadataInput과 연결된 AVCaptureConnection들 처리
        for (AVCaptureConnection *connection in connections) {
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
            } else {
                abort();
            }
            
            newConnection.enabled = connection.isEnabled;
            
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

- (CMMetadataFormatDescriptionRef)createMetadataFormatDescription CM_RETURNS_RETAINED {
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
    NSLog(@"%@", photo.depthData);
    
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photo.resolvedSettings, sel_registerName("isSpatialPhotoCaptureEnabled"));
    NSLog(@"isSpatialPhotoCaptureEnabled: %d", isSpatialPhotoCaptureEnabled);
    
    dispatch_async(self.captureSessionQueue, ^{
        __kindof BaseFileOutput *fileOutput = self.queue_fileOutput;
        
        if (fileOutput.class == PhotoLibraryFileOutput.class) {
            auto output = static_cast<PhotoLibraryFileOutput *>(fileOutput);
            NSData * _Nullable fileDataRepresentation = photo.fileDataRepresentation;
            
            [output.photoLibrary performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                
                assert(fileDataRepresentation != nil);
                [request addResourceWithType:PHAssetResourceTypePhoto data:fileDataRepresentation options:nil];
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
            
            NSError * _Nullable error = nil;
            NSArray<NSURL *> *urls = [device nextAvailableURLsWithPathExtensions:@[uti.preferredFilenameExtension] error:&error];
            assert(error == nil);
            NSURL *url = urls[0];
            
            assert([url startAccessingSecurityScopedResource]);
            assert([NSFileManager.defaultManager createFileAtPath:url.path contents:fileDataRepresentation attributes:nil]);
            [url stopAccessingSecurityScopedResource];
        } else {
            abort();
        }
    });
}

#if !TARGET_OS_MACCATALYST
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
        
        AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:photoOutput];
        if (captureDevice == nil) return;
        
        [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                          object:self
                                                        userInfo:@{
            CaptureServiceCaptureDeviceKey: captureDevice,
            CaptureServiceCaptureReadinessKey: @(captureReadiness)
        }];
    });
}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    [output.outputFileURL stopAccessingSecurityScopedResource];
    
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
            assert(error == nil);
        }];
    } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
        
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
//    NSLog(@"%@", output.class);
    
    if ([output isKindOfClass:AVCaptureVideoDataOutput.class]) {
#warning Intrinsic
    
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    NSLog(@"%@", imageBuffer);
        
    } else if ([output isKindOfClass:AVCaptureAudioDataOutput.class]) {
//        NSLog(@"%@", output.class);
    } else {
        abort();
    }
}


#pragma mark - AVCaptureDepthDataOutputDelegate

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection {
    dispatch_assert_queue(self.captureSessionQueue);
    
    if (!connection.isEnabled) return;
    
    AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:output];
    assert(captureDevice != nil);
    
    AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice];
    assert(rotationCoordinator != nil);
    
    CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:depthData.depthDataMap options:@{kCIImageAuxiliaryDisparity: @YES}];
    
    PixelBufferLayer *depthMapLayer = [self.queue_depthMapLayersByCaptureDevice objectForKey:captureDevice];
    [depthMapLayer updateWithCIImage:ciImage rotationAngle:180.f - rotationCoordinator.videoRotationAngleForHorizonLevelCapture fill:NO];
    
    [ciImage release];
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
    
    AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:output];
    assert(captureDevice != nil);
    
    AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice];
    assert(rotationCoordinator != nil);
    
    PixelBufferLayer *pointCloudLayer = [self.queue_pointCloudLayersByCaptureDevice objectForKey:captureDevice];
    
    // videoRotationAngleForHorizonLevelCapture이 계속 0 나옴
    [pointCloudLayer updateWithCIImage:ciImage rotationAngle:180.f - rotationCoordinator.videoRotationAngleForHorizonLevelCapture fill:YES];
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
    AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:output];
    PixelBufferLayer *visionLayer = [self.queue_visionLayersByCaptureDevice objectForKey:captureDevice];
    [visionLayer updateWithCIImage:ciImage fill:YES];
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
    AVCaptureDevice *captureDevice = [self queue_captureDeviceFromOutput:output];
    MetadataObjectsLayer *metadataObjectsLayer = [self.queue_metadataObjectsLayersByCaptureDevice objectForKey:captureDevice];
    assert(metadataObjectsLayer != nil);
    
    AVCaptureVideoPreviewLayer *previewLayer = [self.queue_previewLayersByCaptureDevice objectForKey:captureDevice];
    
    [metadataObjectsLayer updateWithMetadataObjects:metadataObjects previewLayer:previewLayer];
    
    //
    
    AVCaptureMetadataInput *metadataInput = [self.queue_metadataInputsByCaptureDevice objectForKey:captureDevice];
    assert(metadataInput != nil);
    
    for (__kindof AVMetadataObject *metadataObject in metadataObjects) {
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
            AVMutableMetadataItem *metadataItem = [AVMutableMetadataItem new];
            metadataItem.identifier = AVMetadataIdentifierQuickTimeMetadataDetectedFace;
            metadataItem.dataType = (id)kCMMetadataBaseDataType_RectF32;
            metadataItem.value = @[
                @(CGRectGetMinX(metadataObject.bounds)),
                @(CGRectGetMinY(metadataObject.bounds)),
                @(CGRectGetWidth(metadataObject.bounds)),
                @(CGRectGetHeight(metadataObject.bounds))
            ];
            
            CMTimeRange timeRange = CMTimeRangeMake(metadataObject.time, metadataObject.duration);
            
            AVTimedMetadataGroup *metadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[metadataItem] timeRange:timeRange];
            [metadataItem release];
            
            NSError * _Nullable error = nil;
            [metadataInput appendTimedMetadataGroup:metadataGroup error:&error];
            [metadataGroup release];
//            assert(error == nil);
            if (error != nil) {
                NSLog(@"%s: %@", sel_getName(_cmd), error);
            }
        }
    }
}

@end
