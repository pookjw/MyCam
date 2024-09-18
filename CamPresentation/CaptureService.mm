//
//  CaptureService.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureService.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <CoreLocation/CoreLocation.h>

NSNotificationName const CaptureServiceDidChangeSelectedDeviceNotificationName = @"CaptureServiceDidChangeSelectedDeviceNotificationName";
NSString * const CaptureServiceOldCaptureDeviceKey = @"CaptureServiceOldCaptureDeviceKey";
NSString * const CaptureServiceNewCaptureDeviceKey = @"CaptureServiceNewCaptureDeviceKey";

NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName = @"CaptureServiceDidChangeRecordingStatusNotificationName";
NSString * const CaptureServiceRecordingKey = @"CaptureServiceRecordingKey";

@interface CaptureService () <AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate>
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByPreviewLayer;
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService

- (instancetype)init {
    if (self = [super init]) {
        AVCaptureSession *captureSession = [AVCaptureSession new];
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeBuiltInUltraWideCamera,
            AVCaptureDeviceTypeBuiltInTelephotoCamera,
            AVCaptureDeviceTypeBuiltInDualCamera,
            AVCaptureDeviceTypeBuiltInDualWideCamera,
            AVCaptureDeviceTypeBuiltInTripleCamera,
            AVCaptureDeviceTypeContinuityCamera,
            AVCaptureDeviceTypeExternal
        ]
                                                                                                                                mediaType:AVMediaTypeVideo
                                                                                                                                 position:AVCaptureDevicePositionUnspecified];
        
        NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByPreviewLayer = [NSMapTable weakToStrongObjectsMapTable];
        
        //
        
        AVCapturePhotoOutput *capturePhotoOutput = [AVCapturePhotoOutput new];
        [capturePhotoOutput addObserver:self forKeyPath:@"appleProRAWSupported" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
        
        [captureSession beginConfiguration];
        
        assert([captureSession canAddOutput:capturePhotoOutput]);
        [captureSession addOutput:capturePhotoOutput];
        
        //
        
        AVCaptureMovieFileOutput *captureMovieFileOutput = [AVCaptureMovieFileOutput new];
        assert([captureSession canAddOutput:captureMovieFileOutput]);
        [captureMovieFileOutput release];
        
        [captureSession commitConfiguration];
        
        //
        
        CLLocationManager *locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        locationManager.pausesLocationUpdatesAutomatically = YES;
        [locationManager startUpdatingLocation];
        
        //
        
        _captureSession = captureSession;
        _captureSessionQueue = dispatch_queue_create("Camera Session Queue", attr);
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _queue_rotationCoordinatorsByPreviewLayer = [rotationCoordinatorsByPreviewLayer retain];
        _capturePhotoOutput = capturePhotoOutput;
        _captureMovieFileOutput = captureMovieFileOutput;
        _locationManager = locationManager;
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_captureSession release];
    [_captureSessionQueue release];
    [_captureDeviceDiscoverySession release];
    
    for (AVCaptureVideoPreviewLayer *previewLayer in _queue_rotationCoordinatorsByPreviewLayer.keyEnumerator) {
        [[_queue_rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    [_queue_rotationCoordinatorsByPreviewLayer release];
    
    [_capturePhotoOutput release];
    [_captureMovieFileOutput release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVCaptureDeviceRotationCoordinator.class] && [keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
        auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
        static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer).connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
    } else if ([object isKindOfClass:AVCapturePhotoOutput.class] && [keyPath isEqualToString:@"appleProRAWSupported"]) {
        auto casted = static_cast<AVCapturePhotoOutput *>(object);
        casted.appleProRAWEnabled = casted.isAppleProRAWSupported;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (AVCaptureDevice *)queue_selectedCaptureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (__kindof AVCaptureInput *input in self.captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            return static_cast<AVCaptureDeviceInput *>(input).device;
        }
    }
    
    return nil;
}

- (void)queue_setSelectedCaptureDevice:(AVCaptureDevice *)captureDevice {
    assert(self.captureSessionQueue);
    
    NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByPreviewLayer = self.queue_rotationCoordinatorsByPreviewLayer;
    NSMutableArray<AVCaptureVideoPreviewLayer *> *previewLayers = [[NSMutableArray alloc] initWithCapacity:rotationCoordinatorsByPreviewLayer.count];
    for (AVCaptureVideoPreviewLayer *previewLayer in rotationCoordinatorsByPreviewLayer.keyEnumerator) {
        [[rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
        [previewLayers addObject:previewLayer];
    }
    
    [rotationCoordinatorsByPreviewLayer removeAllObjects];
    
    //
    
    AVCaptureSession *captureSession = self.captureSession;
    
    [captureSession beginConfiguration];
    
    AVCaptureDevice * _Nullable oldCaptureDevice = nil;
    
    for (__kindof AVCaptureInput *input in captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            oldCaptureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
        }
        
        [captureSession removeInput:input];
    }
    
    if (captureDevice != nil) {
        NSError * _Nullable error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        assert(error == nil);
        [captureSession addInput:newInput];
    }
    
    [captureSession commitConfiguration];
    
    AVCaptureDevice.userPreferredCamera = captureDevice;
    
    //
    
    for (AVCaptureVideoPreviewLayer *previewLayer in previewLayers) {
        AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
        previewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
        [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
        
        [rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:previewLayer];
        [rotationCoodinator release];
    }
    
    [previewLayers release];
    
    [self postDidChangeSelectedDeviceNotificationWithOldCaptureDevice:oldCaptureDevice newCaptureDevice:captureDevice];
}

- (void)queue_selectDefaultCaptureDevice {
    assert(self.captureSessionQueue);
    
    AVCaptureDevice * _Nullable captureDevice = AVCaptureDevice.userPreferredCamera;
    
    if (captureDevice == nil) {
        captureDevice = AVCaptureDevice.systemPreferredCamera;
    }
    
    self.queue_selectedCaptureDevice = captureDevice;
}

- (void)queue_registerCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    assert(self.captureSessionQueue);
    
    captureVideoPreviewLayer.session = self.captureSession;
    
    AVCaptureDevice *selectedCaptureDevice = self.queue_selectedCaptureDevice;
    if (selectedCaptureDevice == nil) {
        abort();
    }
    
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:selectedCaptureDevice previewLayer:captureVideoPreviewLayer];
    captureVideoPreviewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
    
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.queue_rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:captureVideoPreviewLayer];
    [rotationCoodinator release];
}

- (void)queue_unregisterCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    assert(self.captureSessionQueue);
    
    [[self.queue_rotationCoordinatorsByPreviewLayer objectForKey:captureVideoPreviewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    [self.queue_rotationCoordinatorsByPreviewLayer removeObjectForKey:captureVideoPreviewLayer];
    captureVideoPreviewLayer.session = nil;
}

- (void)queue_startPhotoCaptureWithPhotoModel:(PhotoFormatModel *)photoModel {
    assert(self.captureSessionQueue);
    
    AVCapturePhotoSettings * __autoreleasing capturePhotoSettings;
    
    NSMutableDictionary<NSString *, id> *format = [NSMutableDictionary new];
    if (NSNumber *photoPixelFormatType = photoModel.photoPixelFormatType) {
        format[(id)kCVPixelBufferPixelFormatTypeKey] = photoModel.photoPixelFormatType;
    } else if (AVVideoCodecType codecType = photoModel.codecType) {
        format[AVVideoCodecKey] = photoModel.codecType;
        format[AVVideoCompressionPropertiesKey] = @{
            AVVideoQualityKey: @(photoModel.quality)
        };
    }
    
    if (photoModel.isRAWEnabled) {
        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:photoModel.rawPhotoPixelFormatType.unsignedIntValue
                                                                               rawFileType:photoModel.rawFileType
                                                                           processedFormat:format
                                                                         processedFileType:photoModel.processedFileType];
    } else {
        capturePhotoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    }
    
    [format release];
    
    capturePhotoSettings.maxPhotoDimensions = self.capturePhotoOutput.maxPhotoDimensions;
    capturePhotoSettings.photoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setAutoSpatialOverCaptureEnabled:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setAutoSpatialPhotoCaptureEnabled:"), YES);
    
    //
    
//    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    
    self.capturePhotoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("setSpatialPhotoCaptureEnabled:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("setMovieRecordingEnabled:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("setAutoDeferredPhotoDeliveryEnabled:"), YES);
    
    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    
//    id momentCaptureSettings = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("AVMomentCaptureSettings"), sel_registerName("settingsWithPhotoSettings:"), capturePhotoSettings);
    
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(momentCaptureSettings, sel_registerName("setAutoDeferredPhotoDeliveryEnabled:"), NO);
    
//    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("beginMomentCaptureWithSettings:delegate:"), momentCaptureSettings, self);
}

- (void)queue_startVideoRecording {
    abort();
}

- (void)queue_stopVideoRecording {
    abort();
}

- (void)didReceiveCaptureDeviceWasDisconnectedNotification:(NSNotification *)notification {
    dispatch_async(self.captureSessionQueue, ^{
        if (![self.queue_selectedCaptureDevice isEqual:notification.object]) return;
        [self queue_selectDefaultCaptureDevice];
    });
}

- (void)postDidChangeSelectedDeviceNotificationWithOldCaptureDevice:(AVCaptureDevice * _Nullable)oldCaptureDevice newCaptureDevice:(AVCaptureDevice * _Nullable)newCaptureDevice {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (oldCaptureDevice) {
        userInfo[CaptureServiceOldCaptureDeviceKey] = oldCaptureDevice;
    }
    if (newCaptureDevice) {
        userInfo[CaptureServiceNewCaptureDeviceKey] = newCaptureDevice;
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeSelectedDeviceNotificationName
                                                      object:self
                                                    userInfo:userInfo];
    [userInfo release];
}


#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    assert(error == nil);
    
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photo.resolvedSettings, sel_registerName("isSpatialPhotoCaptureEnabled"));
//    assert(isSpatialPhotoCaptureEnabled);
    NSLog(@"isSpatialPhotoCaptureEnabled: %d", isSpatialPhotoCaptureEnabled);
    
    __block NSURL *_url = nil;
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        NSURL *baseURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"MyCam"];
        [NSFileManager.defaultManager createDirectoryAtURL:baseURL withIntermediateDirectories:YES attributes:nil error:nil];
        
        UTType *uti;
        if (photo.isRawPhoto) {
            uti = UTTypeDNG;
        } else {
            NSString *processedFileType = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photo, sel_registerName("processedFileType"));
            uti = [UTType typeWithIdentifier:processedFileType];
        }
        
        NSURL *url = [[baseURL URLByAppendingPathComponent:@(NSDate.now.timeIntervalSince1970).stringValue] URLByAppendingPathExtensionForType:uti];
        _url = [url retain];
        
        assert([photo.fileDataRepresentation writeToURL:url atomically:YES]);
        
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
        request.location = self.locationManager.location;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (_url) {
            NSError * _Nullable error = nil;
            [NSFileManager.defaultManager removeItemAtURL:_url error:&error];
            assert(error == nil);
            [_url release];
        }
        NSLog(@"%d %@", success, error);
    }];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCapturingDeferredPhotoProxy:(AVCaptureDeferredPhotoProxy *)deferredPhotoProxy error:(NSError *)error {
    [self captureOutput:output didFinishProcessingPhoto:deferredPhotoProxy error:error];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL responds = [super respondsToSelector:aSelector];
    
    if (!responds) {
        NSLog(@"%s", sel_getName(aSelector));
    }
    
    return responds;
}


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

@end
