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

NSNotificationName const CaptureServiceDidAddDeviceNotificationName = @"CaptureServiceDidAddDeviceNotificationName";
NSNotificationName const CaptureServiceDidRemoveDeviceNotificationName = @"CaptureServiceDidRemoveDeviceNotificationName";
NSNotificationName const CaptureServiceReloadingPhotoFormatMenuNeededNotificationName = @"CaptureServiceReloadingPhotoFormatMenuNeededNotificationName";
NSString * const CaptureServiceCaptureDeviceKey = @"CaptureServiceCaptureDeviceKey";

NSNotificationName const CaptureServiceDidUpdatePreviewLayersNotificationName = @"CaptureServiceDidUpdatePreviewLayersNotificationName";

NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName = @"CaptureServiceDidChangeRecordingStatusNotificationName";
NSString * const CaptureServiceRecordingKey = @"CaptureServiceRecordingKey";

NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName = @"CaptureServiceDidChangeCaptureReadinessNotificationName";
NSString * const CaptureServiceCaptureReadinessKey = @"CaptureServiceCaptureReadinessKey";

NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName = @"CaptureServiceDidChangeReactionEffectsInProgressNotificationName";
NSString * const CaptureServiceReactionEffectsInProgressKey = @"CaptureServiceReactionEffectsInProgressKey";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate>
@property (retain, nonatomic, nullable) __kindof AVCaptureSession *queue_captureSession;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *queue_previewLayersByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *queue_photoFormatModelsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *queue_readinessCoordinatorByCapturePhotoOutput;
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
        
        NSMapTable<AVCaptureDevice *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *photoFormatModelsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, AVCaptureVideoPreviewLayer *> *previewLayersByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        
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
        _queue_photoFormatModelsByCaptureDevice = [photoFormatModelsByCaptureDevice retain];
        _locationManager = locationManager;
        _queue_rotationCoordinatorsByCaptureDevice = [rotationCoordinatorsByCaptureDevice retain];
        _queue_readinessCoordinatorByCapturePhotoOutput = [readinessCoordinatorByCapturePhotoOutput retain];
        _queue_previewLayersByCaptureDevice = [previewLayersByCaptureDevice retain];
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    for (__kindof AVCaptureInput *input in _queue_captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [oldCaptureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
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
    
    [_captureSessionQueue release];
    [_captureDeviceDiscoverySession release];
    
    for (AVCaptureDeviceRotationCoordinator *rotationCoordinator in _queue_rotationCoordinatorsByCaptureDevice.objectEnumerator) {
        [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    [_queue_rotationCoordinatorsByCaptureDevice release];
    [_queue_photoFormatModelsByCaptureDevice release];
    [_queue_readinessCoordinatorByCapturePhotoOutput release];
    [_queue_previewLayersByCaptureDevice release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVCaptureMultiCamSession.class]) {
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
            [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
                                                              object:self
                                                            userInfo:@{CaptureServiceReactionEffectsInProgressKey: change[NSKeyValueChangeNewKey]}];
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
    
    return captureDevice;
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
    
    assert([self.queue_previewLayersByCaptureDevice objectForKey:captureDevice] == nil);
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
    [self.queue_previewLayersByCaptureDevice setObject:captureVideoPreviewLayer forKey:captureDevice];
    
    [captureSession beginConfiguration];
    
    [captureDevice addObserver:self forKeyPath:@"reactionEffectsInProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    assert(error == nil);
    assert([captureSession canAddInput:newInput]);
    [captureSession addInputWithNoConnections:newInput];
    
    AVCaptureInputPort *videoPort = nil;
    for (AVCaptureInputPort *inputPort in newInput.ports) {
        if (inputPort.mediaType == AVMediaTypeVideo) {
            videoPort = inputPort;
            break;
        }
    }
    assert(videoPort != nil);
    
    AVCaptureConnection *previewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:videoPort videoPreviewLayer:captureVideoPreviewLayer];
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    AVCapturePhotoOutput *photoOutput = [AVCapturePhotoOutput new];
    photoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
    [self registerObserversForPhotoOutput:photoOutput];
    
    [captureSession addOutputWithNoConnections:photoOutput];
    AVCaptureConnection *photoOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoPort] output:photoOutput];
    [captureSession addConnection:photoOutputConnection];
    [photoOutputConnection release];
    
    [newInput release];
    
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
    captureVideoPreviewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:nullptr];
    [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
    [rotationCoodinator release];
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:photoOutput];
    readinessCoordinator.delegate = self;
    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:photoOutput];
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
    
    [captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    
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
    for (__kindof AVCaptureConnection *connection in captureSession.connections) {
        if ([connection.inputPorts.firstObject.input isEqual:deviceInput]) {
            [removingConnections addObject:connection];
            
            if ([connection.output isKindOfClass:AVCapturePhotoOutput.class]) {
                assert(photoOutput == nil);
                photoOutput = static_cast<AVCapturePhotoOutput *>(connection.output);
            }
        }
    }
    assert(photoOutput != nil);
    
    [self removeObserversForPhotoOutput:photoOutput];
    
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
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:capturePhotoOutput]; 
    assert(readinessCoordinator != nullptr);
    
    [readinessCoordinator startTrackingCaptureRequestUsingPhotoSettings:capturePhotoSettings];
    [capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    [readinessCoordinator stopTrackingCaptureRequestUsingPhotoSettingsUniqueID:capturePhotoSettings.uniqueID];
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
}

- (__kindof AVCaptureSession *)queue_switchCaptureSessionWithClass:(Class)captureSessionClass postNotification:(BOOL)postNotification {
    dispatch_assert_queue(self.captureSessionQueue);
#warning TODO
//    assert(captureSessionClass == AVCaptureSession);
    
    //
    
    assert(self.queue_captureSession.class != captureSessionClass);
    
    //
    
    BOOL wasRunning;
    if (__kindof AVCaptureSession *currentCaptureSession = _queue_captureSession) {
        wasRunning = currentCaptureSession.isRunning;
        if (wasRunning) {
            [currentCaptureSession stopRunning];
        }
        
        if ([currentCaptureSession isKindOfClass:AVCaptureMultiCamSession.class]) {
            [currentCaptureSession removeObserver:self forKeyPath:@"hardwareCost"];
            [currentCaptureSession removeObserver:self forKeyPath:@"systemPressureCost"];
        }
    } else {
        wasRunning = NO;
    }
    
    //
    
    auto captureSession = static_cast<__kindof AVCaptureSession *>([captureSessionClass new]);
    
    if (captureSessionClass == AVCaptureSession.class) {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    } else if (captureSessionClass == AVCaptureMultiCamSession.class) {
        _queue_captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
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
                    [self removeObserversForPhotoOutput:photoOutput];
                    
                    //
                    
                    for (AVCaptureInputPort *inputPort in connection.inputPorts) {
                        auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
                        
                        if ([deviceInput isKindOfClass:AVCaptureDeviceInput.class]) {
                            AVCaptureDevice *captureDevice = deviceInput.device;
                            
                            if (AVCaptureDeviceRotationCoordinator *rotationCoordinator = [self.queue_rotationCoordinatorsByCaptureDevice objectForKey:captureDevice]) {
                                [rotationCoordinator removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
                                [self.queue_rotationCoordinatorsByCaptureDevice removeObjectForKey:captureDevice];
                            } else {
                                abort();
                            }
                        }
                    }
                    
                    //
                    
                    if (AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [self.queue_readinessCoordinatorByCapturePhotoOutput objectForKey:photoOutput]) {
                        readinessCoordinator.delegate = nil;
                        [self.queue_readinessCoordinatorByCapturePhotoOutput removeObjectForKey:photoOutput];
                    } else {
                        abort();
                    }
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
            
            AVCaptureInputPort *videoPort = nil;
            for (AVCaptureInputPort *inputPort in addedInput.ports) {
                if (inputPort.mediaType == AVMediaTypeVideo) {
                    videoPort = inputPort;
                    break;
                }
            }
            assert(videoPort != nil);
            
            AVCaptureConnection *newConnection;
            if (connection.videoPreviewLayer != nil) {
                assert([addedInput isKindOfClass:AVCaptureDeviceInput.class]);
                auto addedDeviceInput = static_cast<AVCaptureDeviceInput *>(addedInput);
                AVCaptureDevice *captureDevice = addedDeviceInput.device;
                
                AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:captureSession];
                [self.queue_previewLayersByCaptureDevice setObject:previewLayer forKey:captureDevice];
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPort:videoPort videoPreviewLayer:previewLayer];
                
                AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
                previewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
                [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
                [self.queue_rotationCoordinatorsByCaptureDevice setObject:rotationCoodinator forKey:captureDevice];
                [rotationCoodinator release];
                
                [previewLayer release];
            } else {
                AVCaptureOutput *addedOutput = [addedOutputsByOutputs objectForKey:connection.output];
                assert(addedOutput != nil);
                
                newConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoPort] output:addedOutput];
                
                if ([addedOutput isKindOfClass:AVCapturePhotoOutput.class]) {
                    auto addedPhotoOutput = static_cast<AVCapturePhotoOutput *>(addedOutput);
                    
                    //
                    
                    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:addedPhotoOutput];
                    readinessCoordinator.delegate = self;
                    [self.queue_readinessCoordinatorByCapturePhotoOutput setObject:readinessCoordinator forKey:addedPhotoOutput];
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
                }
            }
            
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
    
    NSData * _Nullable fileDataRepresentation = photo.fileDataRepresentation;
    
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        
        assert(fileDataRepresentation != nil);
        [request addResourceWithType:PHAssetResourceTypePhoto data:fileDataRepresentation options:nil];
        request.location = self.locationManager.location;
    }
                                    completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"%d %@", success, error);
    }];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCapturingDeferredPhotoProxy:(AVCaptureDeferredPhotoProxy *)deferredPhotoProxy error:(NSError *)error {
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
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureReadinessKey: @(captureReadiness)}];
}

@end
