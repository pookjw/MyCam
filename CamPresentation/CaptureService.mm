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

#warning HDR Format Filter

NSNotificationName const CaptureServiceDidAddDeviceNotificationName = @"CaptureServiceDidAddDeviceNotificationName";
NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName = @"CaptureServiceDidRemoveDeviceNotificationName";
NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName = @"CaptureServiceReloadingPhotoFormatMenuNeededNotificationName";
NSString * const CaptureServiceCaptureDeviceKey = @"CaptureServiceCaptureDeviceKey";

NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName = @"CaptureServiceDidUpdatePreviewLayersNotificationName";

NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName = @"CaptureServiceDidChangeCaptureReadinessNotificationName";
NSString * const CaptureServiceCaptureReadinessKey = @"CaptureServiceCaptureReadinessKey";

NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName = @"CaptureServiceDidChangeReactionEffectsInProgressNotificationName";
NSString * const CaptureServiceReactionEffectsInProgressKey = @"CaptureServiceReactionEffectsInProgressKey";

NSNotificationName const CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName = @"CaptureServiceDidChangeSpatialCaptureDiscomfortReasonNotificationName";

NSString * const CaptureServiceCaptureSessionKey = @"CaptureServiceCaptureSessionKey";
NSNotificationName const CaptureServiceCaptureSessionRuntimeErrorNotificationName = @"CaptureServiceCaptureSessionRuntimeErrorNotificationName";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (retain, nonatomic, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *queue_photoFormatModelsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *queue_readinessCoordinatorByCapturePhotoOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *queue_movieFileOutputsByFileOutput;
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService
@synthesize queue_previewLayersByCaptureDevice = _queue_previewLayersByCaptureDevice;

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", attr);
        
        //
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeBuiltInUltraWideCamera,
            AVCaptureDeviceTypeBuiltInTelephotoCamera,
            AVCaptureDeviceTypeBuiltInDualCamera,
            AVCaptureDeviceTypeBuiltInDualWideCamera,
            AVCaptureDeviceTypeBuiltInTripleCamera,
            AVCaptureDeviceTypeContinuityCamera,
            AVCaptureDeviceTypeBuiltInTrueDepthCamera,
            AVCaptureDeviceTypeBuiltInLiDARDepthCamera,
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeExternal,
            
        ]
                                                                                                                                mediaType:AVMediaTypeVideo
                                                                                                                                 position:AVCaptureDevicePositionUnspecified];
        
        //
        
        AVExternalStorageDeviceDiscoverySession *externalStorageDeviceDiscoverySession = AVExternalStorageDeviceDiscoverySession.sharedSession;
        [externalStorageDeviceDiscoverySession addObserver:self forKeyPath:@"externalStorageDevices" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *photoFormatModelsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureMovieFileOutput *, __kindof BaseFileOutput *> *movieFileOutputsByFileOutput = [NSMapTable weakToStrongObjectsMapTable];
        
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
        _queue_movieFileOutputsByFileOutput = [movieFileOutputsByFileOutput retain];
        self.queue_fileOutput = nil;
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    for (__kindof AVCaptureInput *input in _queue_captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto captureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [self unregisterObserversForCaptureDevice:captureDevice];
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
    [_queue_movieFileOutputsByFileOutput release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [super dealloc];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL responds = [super respondsToSelector:aSelector];
    
    if (!responds) {
        NSLog(@"%@: %s", NSStringFromClass(self.class), sel_getName(aSelector));
    }
    
    return responds;
}

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
#warning TODO
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
        }
    } else if ([object isKindOfClass:AVCapturePhotoOutput.class]) {
        if ([keyPath isEqualToString:@"availablePhotoPixelFormatTypes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAutoDeferredPhotoDeliverySupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"supportedFlashModes"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isZeroShutterLagSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isResponsiveCaptureSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isAppleProRAWSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"isFastCapturePrioritizationSupported"]) {
            dispatch_async(self.captureSessionQueue, ^{
                auto photoOutput = static_cast<AVCapturePhotoOutput *>(object);
                AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
                
                if (captureDevice != nil) {
                    [self postReloadingPhotoFormatMenuNeededNotification:captureDevice];
                }
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

- (AVCaptureDevice *)defaultCaptureDevice {
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

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert(![self.queue_addedCaptureDevices containsObject:captureDevice]);
    
    __kindof AVCaptureSession *captureSession;
    if (__kindof AVCaptureSession *currentCaptureSession = self.queue_captureSession) {
        NSUInteger numberOfInputDevices = 0;
        for (AVCaptureInput *input in currentCaptureSession.inputs) {
            if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                numberOfInputDevices += 1;
            }
        }
        
        if (numberOfInputDevices == 0) {
            if (currentCaptureSession.class == AVCaptureSession.class) {
                captureSession = currentCaptureSession;
            } else {
                abort();
            }
        } else if (numberOfInputDevices == 1) {
            if (currentCaptureSession.class == AVCaptureSession.class) {
                captureSession = [self queue_switchCaptureSessionWithClass:AVCaptureMultiCamSession.class postNotification:NO];
            } else {
                abort();
            }
        } else {
            if (currentCaptureSession.class == AVCaptureMultiCamSession.class) {
                captureSession = currentCaptureSession;
            } else {
                abort();
            }
        }
    } else {
        captureSession = [self queue_switchCaptureSessionWithClass:AVCaptureSession.class postNotification:NO];
    }
    
    [self registerObserversForCaptureDevice:captureDevice];
    
    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice] == nil);
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
    [self.queue_previewLayersByCaptureDevice setObject:captureVideoPreviewLayer forKey:captureDevice];
    
    [captureSession beginConfiguration];
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    assert([captureSession canAddInput:newInput]);
    [captureSession addInputWithNoConnections:newInput];
    
    NSMutableArray<AVCaptureInputPort *> *inputPorts = [NSMutableArray new];
    AVCaptureInputPort *videoInputPort = nil;
    for (AVCaptureInputPort *inputPort in newInput.ports) {
        if ([inputPort.mediaType isEqualToString:AVMediaTypeVideo]) {
            [inputPorts addObject:inputPort];
            videoInputPort = inputPort;
        } else if ([inputPort.mediaType isEqualToString:AVMediaTypeDepthData]) {
            [inputPorts addObject:inputPort];
        }
    }
    assert(videoInputPort != nil);
    
    AVCaptureConnection *previewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:captureVideoPreviewLayer];
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    AVCapturePhotoOutput *photoOutput = [AVCapturePhotoOutput new];
    photoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
    [self registerObserversForPhotoOutput:photoOutput];
    
    [captureSession addOutputWithNoConnections:photoOutput];
    AVCaptureConnection *photoOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:photoOutput];
    [captureSession addConnection:photoOutputConnection];
    [photoOutputConnection release];
    
    [newInput release];
    
    //
    
    AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
    assert([captureSession canAddOutput:movieFileOutput]);
    [captureSession addOutputWithNoConnections:movieFileOutput];
    
    AVCaptureConnection *movieFileOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:movieFileOutput];
    [movieFileOutput release];
    [captureSession addConnection:movieFileOutputConnection];
    [movieFileOutputConnection release];
    
    //
    
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    [videoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
    assert([captureSession canAddOutput:videoDataOutput]);
    [captureSession addOutputWithNoConnections:videoDataOutput];
    
    AVCaptureConnection *videoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:videoDataOutput];
    [videoDataOutput release];
    [captureSession addConnection:videoDataOutputConnection];
    [videoDataOutputConnection release];
    
    //
    
    [inputPorts release];
    
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
        
        AVCaptureIndexPicker *captureIndexPicker = [[AVCaptureIndexPicker alloc] initWithLocalizedTitle:@"Hello Index Picker!" symbolName:@"figure.waterpolo.circle.fill" numberOfIndexes:100 localizedTitleTransform:^NSString * _Nonnull(NSInteger index) {
            return [NSString stringWithFormat:@"%ld!!!", index];
        }];
        [captureIndexPicker setActionQueue:captureSessionQueue action:^(NSInteger selectedIndex) {
            NSLog(@"%ld", selectedIndex);
        }];
        reinterpret_cast<BOOL (*)(id, SEL, id, id *)>(objc_msgSend)(captureSession, sel_registerName("_canAddControl:failureReason:"), captureIndexPicker, &failureReason);
        assert(failureReason == nil);
        [captureSession addControl:captureIndexPicker];
        [captureIndexPicker release];
    }
#endif
    
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
    [self queue_postDidUpdatePreviewLayersNotification];
}

- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    assert([self.queue_addedCaptureDevices containsObject:captureDevice]);
    
    [self unregisterObserversForCaptureDevice:captureDevice];
    
    __kindof AVCaptureSession *captureSession = self.queue_captureSession;
    assert(captureSession != nil);
    
    //
    
    [captureSession beginConfiguration];
    
    AVCaptureDeviceInput *deviceInput = nil;
    for (__kindof AVCaptureInput *input in captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            AVCaptureDevice *oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            if ([captureDevice isEqual:oldCaptureDevice]) {
                deviceInput = input;
                break;
            }
        }
    }
    assert(deviceInput != nil);
    
    NSMutableArray<AVCaptureConnection *> *removingConnections = [NSMutableArray new];
    AVCapturePhotoOutput *photoOutput = nil;
    AVCaptureMovieFileOutput *movieFileOutput = nil;
    AVCaptureVideoDataOutput *videoDataOutput = nil;
    for (__kindof AVCaptureConnection *connection in captureSession.connections) {
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            if ([inputPort.input isEqual:deviceInput]) {
                [removingConnections addObject:connection];
                
                if (connection.output != nil) {
                    if ([connection.output isKindOfClass:AVCapturePhotoOutput.class]) {
                        assert(photoOutput == nil);
                        photoOutput = static_cast<AVCapturePhotoOutput *>(connection.output);
                    } else if ([connection.output isKindOfClass:AVCaptureMovieFileOutput.class]) {
                        assert(movieFileOutput == nil);
                        movieFileOutput = static_cast<AVCaptureMovieFileOutput *>(connection.output);
                    } else if ([connection.output isKindOfClass:AVCaptureVideoDataOutput.class]) {
                        assert(videoDataOutput == nil);
                        videoDataOutput = static_cast<AVCaptureVideoDataOutput *>(connection.output);
                    } else {
                        abort();
                    }
                }
                
                break;
            }
        }
    }
    assert(photoOutput != nil);
    assert(movieFileOutput != nil);
    assert(videoDataOutput != nil);
    
    [self unregisterObserversForPhotoOutput:photoOutput];
    
    if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
        [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
    } else {
        abort();
    }
    
    if (AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput]) {
        readinessCoordinator.delegate = nil;
        [self.queue_readinessCoordinatorByCapturePhotoOutput removeObjectForKey:photoOutput];
    } else {
        abort();
    }
    
    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice] != nil);
    [self.queue_previewLayersByCaptureDevice removeObjectForKey:captureDevice];
    
    for (AVCaptureConnection *connection in removingConnections) {
        [captureSession removeConnection:connection];
        connection.videoPreviewLayer.session = nil;
    }
    [removingConnections release];
    
    [captureSession removeOutput:photoOutput];
    [captureSession removeOutput:movieFileOutput];
    [captureSession removeOutput:videoDataOutput];
    [captureSession removeInput:deviceInput];
    
    [captureSession commitConfiguration];
    
    //
    
    [self.queue_photoFormatModelsByCaptureDevice removeObjectForKey:captureDevice];
    
    NSUInteger numberOfInputDevices = 0;
    for (AVCaptureInput *input in captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            numberOfInputDevices += 1;
        }
    }
    
    if (numberOfInputDevices == 0) {
        assert(captureSession.class == AVCaptureSession.class);
    } else if (numberOfInputDevices == 1) {
        assert(captureSession.class == AVCaptureMultiCamSession.class);
        captureSession = [self queue_switchCaptureSessionWithClass:AVCaptureSession.class postNotification:NO];
    } else {
        assert(captureSession.class == AVCaptureMultiCamSession.class);
    }
    
    //
    
    [self postDidRemoveDeviceNotificationWithCaptureDevice:captureDevice];
    [self queue_postDidUpdatePreviewLayersNotification];
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

- (AVCaptureVideoPreviewLayer *)queue_previewLayerFromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    return [self.queue_previewLayersByCaptureDevice objectForKey:captureDevice];
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

- (AVCaptureDevice *)queue_captureDeviceFromPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    dispatch_assert_queue(self.captureSessionQueue);
    for (AVCaptureConnection *connection in self.queue_captureSession.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            auto _photoOutput = static_cast<AVCapturePhotoOutput *>(connection.output);
            
            if (![photoOutput isKindOfClass:AVCapturePhotoOutput.class]) {
                continue;
            }
            
            if (![photoOutput isEqual:_photoOutput]) {
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
    
    AVCapturePhotoSettings * __autoreleasing capturePhotoSettings;
    
    if (photoModel.isRAWEnabled) {
        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:photoModel.rawPhotoPixelFormatType.unsignedIntValue
                                                                               rawFileType:photoModel.rawFileType
                                                                           processedFormat:format
                                                                         processedFileType:photoModel.processedFileType];
    } else {
        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    }
    
    [format release];
    
    capturePhotoSettings.maxPhotoDimensions = capturePhotoOutput.maxPhotoDimensions;
    
    // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
    if (!photoModel.isRAWEnabled) {
        capturePhotoSettings.photoQualityPrioritization = photoModel.photoQualityPrioritization;
    }
    
    capturePhotoSettings.flashMode = photoModel.flashMode;
    
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
#warning TODO
    NSLog(@"Disconnected!");
}

- (void)postReloadingPhotoFormatMenuNeededNotification:(AVCaptureDevice *)captureDevice {
    if (captureDevice == nil) return;
    
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceReloadingPhotoFormatMenuNeededNotificationName object:self userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)queue_postDidUpdatePreviewLayersNotification {
    dispatch_assert_queue(self.captureSessionQueue);
    
    // NSMapTable은 Thread-safe하지 않기에 다른 Thread에서 불릴 여지가 없어야 한다. 따라서 userInfo에 전달하지 않는다.
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidUpdatePreviewLayersNotificationName object:self userInfo:nil];
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

- (void)registerObserversForCaptureDevice:(AVCaptureDevice *)captureDevice {
    [captureDevice addObserver:self forKeyPath:@"reactionEffectsInProgress" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"formats" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"torchAvailable" options:NSKeyValueObservingOptionNew context:nullptr];
}

- (void)unregisterObserversForCaptureDevice:(AVCaptureDevice *)captureDevice {
    [captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    [captureDevice removeObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons"];
    [captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [captureDevice removeObserver:self forKeyPath:@"formats"];
    [captureDevice removeObserver:self forKeyPath:@"torchAvailable"];
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
            for (__kindof AVCaptureInput *input in currentCaptureSession.inputs) {
                if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                    auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
                    AVCaptureDevice *device = deviceInput.device;
                    
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
                        
                        // Input을 지워야 할 수도 있음
                        assert(device.activeFormat.isMultiCamSupported);
                    }
                }
            }
        } else if (currentCaptureSession.class == AVCaptureMultiCamSession.class) {
            [currentCaptureSession removeObserver:self forKeyPath:@"hardwareCost"];
            [currentCaptureSession removeObserver:self forKeyPath:@"systemPressureCost"];
        }
    } else {
        wasRunning = NO;
    }
    
    //
    
    auto captureSession = static_cast<__kindof AVCaptureSession *>([captureSessionClass new]);
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveRuntimeErrorNotification:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
    captureSession.automaticallyConfiguresCaptureDeviceForWideColor = NO;
    
    if (captureSessionClass == AVCaptureSession.class) {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
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
        NSMutableArray<__kindof AVCaptureOutput *> *outputs = [NSMutableArray new];
        
        for (AVCaptureConnection *connection in oldCaptureSession.connections) {
            if (__kindof AVCaptureOutput *output = connection.output) {
                if ([output isKindOfClass:AVCapturePhotoOutput.class]) {
                    auto photoOutput = static_cast<AVCapturePhotoOutput *>(output);
                    [self unregisterObserversForPhotoOutput:photoOutput];
                    
                    //
                    
                    NSMutableArray<AVCaptureDevice *> *debug_removedDevices = [NSMutableArray new];
                    for (AVCaptureInputPort *inputPort in connection.inputPorts) {
                        auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
                        
                        if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                            AVCaptureDevice *captureDevice = deviceInput.device;
                            if ([debug_removedDevices containsObject:captureDevice]) continue;
                            
                            if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
                                [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
                                [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
                            } else {
                                abort();
                            }
                            
                            assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice]);
                            [self.queue_previewLayersByCaptureDevice removeObjectForKey:captureDevice];
                            [debug_removedDevices addObject:captureDevice];
                        }
                    }
                    [debug_removedDevices release];
                    
                    assert(self.queue_previewLayersByCaptureDevice.count == 0);
                    
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
                } else {
                    abort();
                }
                
                [outputs addObject:output];
            }
            
            [oldCaptureSession removeConnection:connection];
        }
        
        NSArray<__kindof AVCaptureInput *> *inputs = oldCaptureSession.inputs;
        for (__kindof AVCaptureInput *input in oldCaptureSession.inputs) {
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
                
                assert([captureSession canAddInput:newDeviceInput]);
                [captureSession addInputWithNoConnections:newDeviceInput];
                
                [addedInputsByOldInput setObject:newDeviceInput forKey:oldDeviceInput];
                
                [newDeviceInput release];
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
            } else {
                abort();
            }
        }
        assert(outputs.count == addedOutputsByOutputs.count);
        [outputs release];
        
        for (AVCaptureConnection *connection in connections) {
            AVCaptureInput *oldInput = connection.inputPorts.firstObject.input;
            assert(oldInput != nil);
            
            AVCaptureInput *addedInput = [addedInputsByOldInput objectForKey:oldInput];
            assert(addedInput != nil);
            
            NSMutableArray<AVCaptureInputPort *> *inputPorts = [NSMutableArray new];
            AVCaptureInputPort *videoInputPort = nil;
            for (AVCaptureInputPort *inputPort in addedInput.ports) {
                if ([inputPort.mediaType isEqualToString:AVMediaTypeVideo]) {
                    [inputPorts addObject:inputPort];
                    videoInputPort = inputPort;
                } else if ([inputPort.mediaType isEqualToString:AVMediaTypeDepthData]) {
                    [inputPorts addObject:inputPort];
                }
            }
            assert(videoInputPort != nil);
            
            AVCaptureConnection *newConnection;
            if (connection.videoPreviewLayer != nil) {
                assert([addedInput isKindOfClass:AVCaptureDeviceInput.class]);
                auto addedDeviceInput = static_cast<AVCaptureDeviceInput *>(addedInput);
                AVCaptureDevice *captureDevice = addedDeviceInput.device;
                
                AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
                [self.queue_previewLayersByCaptureDevice setObject:previewLayer forKey:captureDevice];
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPort:videoInputPort videoPreviewLayer:previewLayer];
                
                AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
                previewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
                [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
                [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
                [rotationCoodinator release];
                
                [previewLayer release];
            } else {
                AVCaptureOutput *addedOutput = [addedOutputsByOutputs objectForKey:connection.output];
                assert(addedOutput != nil);
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPorts:inputPorts output:addedOutput];
                
                if ([addedOutput isKindOfClass:AVCapturePhotoOutput.class]) {
                    auto addedPhotoOutput = static_cast<AVCapturePhotoOutput *>(addedOutput);
                    
                    //
                    
                    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:addedPhotoOutput];
                    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:addedPhotoOutput];
                    readinessCoordinator.delegate = self;
                    [readinessCoordinator release];
                    
                    //
                    
                    assert([addedInput isKindOfClass:AVCaptureDeviceInput.class]);
                    auto addedDeviceInput = static_cast<AVCaptureDeviceInput *>(addedInput);
                    AVCaptureDevice *captureDevice = addedDeviceInput.device;
                    
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
                    
                } else if ([addedOutput isKindOfClass:AVCaptureVideoDataOutput.class]) {
                    
                } else {
                    abort();
                }
            }
            
            [inputPorts release];
            
            [captureSession addConnection:newConnection];
            
            //
            
            [newConnection release];
        }
        
        if (postNotification) {
            [self queue_postDidUpdatePreviewLayersNotification];
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


#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    assert(error == nil);
    
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
        
        AVCaptureDevice *captureDevice = [self queue_captureDeviceFromPhotoOutput:photoOutput];
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


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

@end
