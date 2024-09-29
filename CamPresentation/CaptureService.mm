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
NSString * const CaptureServiceCaptureDeviceKey = @"CaptureServiceCaptureDeviceKey";

NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName = @"CaptureServiceDidChangeRecordingStatusNotificationName";
NSString * const CaptureServiceRecordingKey = @"CaptureServiceRecordingKey";

NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName = @"CaptureServiceDidChangeCaptureReadinessNotificationName";
NSString * const CaptureServiceCaptureReadinessKey = @"CaptureServiceCaptureReadinessKey";

NSNotificationName const CaptureServiceDidChangeReactionEffectsInProgressNotificationName = @"CaptureServiceDidChangeReactionEffectsInProgressNotificationName";
NSString * const CaptureServiceReactionEffectsInProgressKey = @"CaptureServiceReactionEffectsInProgressKey";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate>
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *queue_photoFormatModelsByCaptureDevice;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByCapturePhotoOutput;
@property (retain, nonatomic, readonly) NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *queue_readinessCoordinatorByCapturePhotoOutput;
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService

- (instancetype)init {
    if (self = [super init]) {
        AVCaptureMultiCamSession *captureSession = [AVCaptureSession new];
        
//        assert([captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]);
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", attr);
        
        //
        
#if TARGET_OS_IOS
        // https://x.com/_silgen_name/status/1837346064808169951
        id controlsOverlay = captureSession.cp_controlsOverlay;
        
        dispatch_queue_t _connectionQueue;
        assert(object_getInstanceVariable(controlsOverlay, "_connectionQueue", reinterpret_cast<void **>(&_connectionQueue)) != NULL);
        dispatch_release(_connectionQueue);
        
        assert(object_setInstanceVariable(controlsOverlay, "_connectionQueue", reinterpret_cast<void *>(captureSessionQueue)));
        dispatch_retain(captureSessionQueue);
        
        //
        
        [captureSession setControlsDelegate:self queue:captureSessionQueue];
#endif
        
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
        
        NSMapTable<AVCapturePhotoOutput *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByCapturePhotoOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCapturePhotoOutput *, AVCapturePhotoOutputReadinessCoordinator *> *readinessCoordinatorByCapturePhotoOutput = [NSMapTable weakToStrongObjectsMapTable];
        NSMapTable<AVCaptureDevice *, PhotoFormatModel *> *photoFormatModelsByCaptureDevice = [NSMapTable weakToStrongObjectsMapTable];
        
        //
        
        AVCaptureMovieFileOutput *captureMovieFileOutput = [AVCaptureMovieFileOutput new];
        assert([captureSession canAddOutput:captureMovieFileOutput]);
        [captureMovieFileOutput release];
        
        [captureSession commitConfiguration];
        
        //
        
        CLLocationManager *locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        
#if !TARGET_OS_TV
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startUpdatingLocation];
#endif
        
        //
        
        _captureSession = captureSession;
        _captureSessionQueue = captureSessionQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _queue_photoFormatModelsByCaptureDevice = [photoFormatModelsByCaptureDevice retain];
        _locationManager = locationManager;
        _queue_rotationCoordinatorsByCapturePhotoOutput = [rotationCoordinatorsByCapturePhotoOutput retain];
        _queue_readinessCoordinatorByCapturePhotoOutput = [readinessCoordinatorByCapturePhotoOutput retain];
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    for (__kindof AVCaptureInput *input in _captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            auto oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [oldCaptureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
        }
    }
    [_captureSession release];
    
    [_captureSessionQueue release];
    [_captureDeviceDiscoverySession release];
    
    for (AVCapturePhotoOutput *photoOutput in _queue_rotationCoordinatorsByCapturePhotoOutput.keyEnumerator) {
        [[_queue_rotationCoordinatorsByCapturePhotoOutput objectForKey:photoOutput] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    [_queue_rotationCoordinatorsByCapturePhotoOutput release];
    [_queue_photoFormatModelsByCaptureDevice release];
    [_queue_readinessCoordinatorByCapturePhotoOutput release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVCaptureDeviceRotationCoordinator.class]) {
        if ([keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
            auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
            static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer).connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
            return;
        }
    } else if ([object isKindOfClass:AVCaptureDevice.class]) {
        if ([keyPath isEqualToString:@"reactionEffectsInProgress"]) {
            [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeReactionEffectsInProgressNotificationName
                                                              object:self
                                                            userInfo:@{CaptureServiceReactionEffectsInProgressKey: change[NSKeyValueChangeNewKey]}];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSArray<AVCaptureDevice *> *)queue_addedCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableArray<AVCaptureDevice *> *captureDevices = [NSMutableArray new];
    
    for (__kindof AVCaptureInput *input in self.captureSession.inputs) {
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

- (void)queue_addCapureDevice:(AVCaptureDevice *)captureDevice captureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    
    AVCaptureSession *captureSession = self.captureSession;
    captureVideoPreviewLayer.session = captureSession;
    
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
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
    [self.queue_rotationCoordinatorsByCapturePhotoOutput setObject:rotationCoodinator forKey:photoOutput];
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
    
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidAddDeviceNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(captureDevice != nil);
    
    [captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    
    AVCaptureSession *captureSession = self.captureSession;
    
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
    
    [self.queue_rotationCoordinatorsByCapturePhotoOutput removeObjectForKey:photoOutput];
    [self.queue_readinessCoordinatorByCapturePhotoOutput removeObjectForKey:photoOutput];
    
    for (AVCaptureConnection *connection in removingConnections) {
        [captureSession removeConnection:connection];
        connection.videoPreviewLayer.session = nil;
    }
    [removingConnections release];
    
    [captureSession removeOutput:photoOutput];
    [captureSession removeInput:deviceInput];
    
    [captureSession commitConfiguration];
    
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidRemoveDeviceNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureDeviceKey: captureDevice}];
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
    for (AVCaptureConnection *connection in self.captureSession.connections) {
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

- (NSArray<AVCaptureVideoPreviewLayer *> *)queue_captureVideoPreviewLayersWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableArray<AVCaptureVideoPreviewLayer *> *captureVideoPreviewLayers = [NSMutableArray new];
    
    for (AVCaptureConnection *connection in self.captureSession.connections) {
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = connection.videoPreviewLayer;
        if (captureVideoPreviewLayer == nil) continue;
        
        for (AVCaptureInputPort *inputPort in connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            if ([deviceInput.device isEqual:captureDevice]) {
                [captureVideoPreviewLayers addObject:captureVideoPreviewLayer];
            }
        }
    }
    
    return [captureVideoPreviewLayers autorelease];
}

- (void)queue_startPhotoCaptureWithPhotoModel:(PhotoFormatModel *)photoModel {
    abort();
//    assert(self.captureSessionQueue);
//    
//    NSMutableDictionary<NSString *, id> *format = [NSMutableDictionary new];
//    if (NSNumber *photoPixelFormatType = photoModel.photoPixelFormatType) {
//        format[(id)kCVPixelBufferPixelFormatTypeKey] = photoModel.photoPixelFormatType;
//    } else if (AVVideoCodecType codecType = photoModel.codecType) {
//        format[AVVideoCodecKey] = photoModel.codecType;
//        format[AVVideoCompressionPropertiesKey] = @{
//            AVVideoQualityKey: @(photoModel.quality)
//        };
//    }
//    
//    AVCapturePhotoSettings * __autoreleasing capturePhotoSettings;
//    
//    if (photoModel.isRAWEnabled) {
//        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:photoModel.rawPhotoPixelFormatType.unsignedIntValue
//                                                                               rawFileType:photoModel.rawFileType
//                                                                           processedFormat:format
//                                                                         processedFileType:photoModel.processedFileType];
//    } else {
//        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
//    }
//    
//    [format release];
//    
//    capturePhotoSettings.maxPhotoDimensions = self.capturePhotoOutput.maxPhotoDimensions;
//    
//    // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
//    if (!photoModel.isRAWEnabled) {
//        capturePhotoSettings.photoQualityPrioritization = photoModel.photoQualityPrioritization;
//    }
//    
//    capturePhotoSettings.flashMode = photoModel.flashMode;
//    
//    //
//    
//    [self.capturePhotoOutputReadinessCoordinator startTrackingCaptureRequestUsingPhotoSettings:capturePhotoSettings];
//    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
//    [self.capturePhotoOutputReadinessCoordinator stopTrackingCaptureRequestUsingPhotoSettingsUniqueID:capturePhotoSettings.uniqueID];
}

- (void)didReceiveCaptureDeviceWasDisconnectedNotification:(NSNotification *)notification {
    NSLog(@"Disconnected!");
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
