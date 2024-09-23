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

NSNotificationName const CaptureServiceDidChangeSelectedDeviceNotificationName = @"CaptureServiceDidChangeSelectedDeviceNotificationName";
NSString * const CaptureServiceOldCaptureDeviceKey = @"CaptureServiceOldCaptureDeviceKey";
NSString * const CaptureServiceNewCaptureDeviceKey = @"CaptureServiceNewCaptureDeviceKey";

NSNotificationName const CaptureServiceDidChangeRecordingStatusNotificationName = @"CaptureServiceDidChangeRecordingStatusNotificationName";
NSString * const CaptureServiceRecordingKey = @"CaptureServiceRecordingKey";

NSNotificationName const CaptureServiceDidChangeCaptureReadinessNotificationName = @"CaptureServiceDidChangeCaptureReadinessNotificationName";
NSString * const CaptureServiceCaptureReadinessKey = @"CaptureServiceCaptureReadinessKey";

#if TARGET_OS_VISION
@interface CaptureService () <CLLocationManagerDelegate>
#else
@interface CaptureService () <AVCapturePhotoCaptureDelegate, AVCaptureSessionControlsDelegate, CLLocationManagerDelegate, AVCapturePhotoOutputReadinessCoordinatorDelegate>
#endif

#if TARGET_OS_VISION
@property (retain, nonatomic, readonly) NSMapTable<__kindof CALayer *, id> *queue_rotationCoordinatorsByPreviewLayer;
@property (retain, nonatomic, readonly) id capturePhotoOutputReadinessCoordinator;
#else
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByPreviewLayer;
@property (retain, nonatomic, readonly) AVCapturePhotoOutputReadinessCoordinator *capturePhotoOutputReadinessCoordinator;
#endif
@property (retain, nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation CaptureService

#if TARGET_OS_VISION
+ (void)load {
    assert(class_addProtocol(self, NSProtocolFromString(@"AVCapturePhotoCaptureDelegate")));
    assert(class_addProtocol(self, NSProtocolFromString(@"AVCaptureSessionControlsDelegate")));
    assert(class_addProtocol(self, NSProtocolFromString(@"AVCapturePhotoOutputReadinessCoordinatorDelegate")));
}
#endif

- (instancetype)init {
    if (self = [super init]) {
        AVCaptureSession *captureSession = [AVCaptureSession new];
        
#if TARGET_OS_VISION
//        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(captureSession, sel_registerName("setSessionPreset:"), @"AVCaptureSessionPresetPhoto");
#else
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
#endif
        
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
#if !TARGET_OS_VISION
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeBuiltInUltraWideCamera,
            AVCaptureDeviceTypeBuiltInTelephotoCamera,
            AVCaptureDeviceTypeBuiltInDualCamera,
            AVCaptureDeviceTypeBuiltInDualWideCamera,
            AVCaptureDeviceTypeBuiltInTripleCamera,
            AVCaptureDeviceTypeContinuityCamera,
            AVCaptureDeviceTypeBuiltInTrueDepthCamera,
            AVCaptureDeviceTypeBuiltInLiDARDepthCamera,
#endif
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            @"AVCaptureDeviceTypeContinuityCamera",
            AVCaptureDeviceTypeExternal,
            
        ]
                                                                                                                                mediaType:AVMediaTypeVideo
                                                                                                                                 position:AVCaptureDevicePositionUnspecified];
        
#if TARGET_OS_VISION
        NSMapTable *rotationCoordinatorsByPreviewLayer = [NSMapTable weakToStrongObjectsMapTable];
#else
        NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByPreviewLayer = [NSMapTable weakToStrongObjectsMapTable];
#endif
        
        //
        
#if TARGET_OS_VISION
        id capturePhotoOutput = [objc_lookUpClass("AVCapturePhotoOutput") new];
        reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(capturePhotoOutput, sel_registerName("setMaxPhotoQualityPrioritization:"), 3);
#else
        AVCapturePhotoOutput *capturePhotoOutput = [AVCapturePhotoOutput new];
        capturePhotoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
#endif
        
        [captureSession beginConfiguration];
        
        assert([captureSession canAddOutput:capturePhotoOutput]);
        [captureSession addOutput:capturePhotoOutput];
        
        //
        
#if TARGET_OS_VISION
        
#else
        AVCapturePhotoOutputReadinessCoordinator *capturePhotoOutputReadinessCoordinator = [[AVCapturePhotoOutputReadinessCoordinator alloc] initWithPhotoOutput:capturePhotoOutput];
        capturePhotoOutputReadinessCoordinator.delegate = self;
#endif
        
        //
        
#if TARGET_OS_VISION
        id captureMovieFileOutput = [objc_lookUpClass("AVCaptureMovieFileOutput") new];
#else
        AVCaptureMovieFileOutput *captureMovieFileOutput = [AVCaptureMovieFileOutput new];
#endif
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
        _queue_rotationCoordinatorsByPreviewLayer = [rotationCoordinatorsByPreviewLayer retain];
        _capturePhotoOutput = capturePhotoOutput;
        _captureMovieFileOutput = captureMovieFileOutput;
        _locationManager = locationManager;
        _capturePhotoOutputReadinessCoordinator = capturePhotoOutputReadinessCoordinator;
        
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
    
#if TARGET_OS_VISION
    for (id previewLayer in _queue_rotationCoordinatorsByPreviewLayer.keyEnumerator)
#else
    for (AVCaptureVideoPreviewLayer *previewLayer in _queue_rotationCoordinatorsByPreviewLayer.keyEnumerator)
#endif
    {
        [[_queue_rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    [_queue_rotationCoordinatorsByPreviewLayer release];
    [_capturePhotoOutputReadinessCoordinator release];
    [_capturePhotoOutput release];
    [_captureMovieFileOutput release];
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if TARGET_OS_VISION
    if ([object isKindOfClass:objc_lookUpClass("AVCaptureDeviceRotationCoordinator")]) {
        if ([keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
            __kindof CALayer *previewLayer = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(object, sel_registerName("previewLayer"));
            AVCaptureConnection *connection = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(previewLayer, sel_registerName("connection"));
            
            CGFloat videoRotationAngleForHorizonLevelPreview = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(object, sel_registerName("videoRotationAngleForHorizonLevelPreview"));
            reinterpret_cast<void (*)(id, SEL, CGFloat)>(objc_msgSend)(connection, sel_registerName("setVideoRotationAngle:"), videoRotationAngleForHorizonLevelPreview);
            return;
        }
    }
#else
    if ([object isKindOfClass:AVCaptureDeviceRotationCoordinator.class] && [keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
        auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
        static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer).connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
        return;
    }
#endif
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
    
#if TARGET_OS_VISION
    NSMapTable<__kindof CALayer *, id> *rotationCoordinatorsByPreviewLayer = self.queue_rotationCoordinatorsByPreviewLayer;
    NSMutableArray<__kindof CALayer *> *previewLayers = [[NSMutableArray alloc] initWithCapacity:rotationCoordinatorsByPreviewLayer.count];
    for (__kindof CALayer *previewLayer in rotationCoordinatorsByPreviewLayer.keyEnumerator) {
        [[rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
        [previewLayers addObject:previewLayer];
    }
    
    [rotationCoordinatorsByPreviewLayer removeAllObjects];
#else
    NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *rotationCoordinatorsByPreviewLayer = self.queue_rotationCoordinatorsByPreviewLayer;
    NSMutableArray<AVCaptureVideoPreviewLayer *> *previewLayers = [[NSMutableArray alloc] initWithCapacity:rotationCoordinatorsByPreviewLayer.count];
    for (AVCaptureVideoPreviewLayer *previewLayer in rotationCoordinatorsByPreviewLayer.keyEnumerator) {
        [[rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
        [previewLayers addObject:previewLayer];
    }
    
    [rotationCoordinatorsByPreviewLayer removeAllObjects];
#endif
    
    
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
        AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
        assert(error == nil);
        assert([captureSession canAddInput:newInput]);
        
        [captureSession addInput:newInput];
        [newInput release];
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
    
    //
    
    [captureSession commitConfiguration];
    
#if TARGET_OS_VISION
    reinterpret_cast<void (*)(Class, SEL, id)>(objc_msgSend)(AVCaptureDevice.class, sel_registerName("setUserPreferredCamera:"), captureDevice);
#else
    AVCaptureDevice.userPreferredCamera = captureDevice;
#endif
    
    //
    
#if TARGET_OS_VISION
    for (__kindof CALayer *previewLayer in previewLayers) {
        id rotationCoodinator = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureDeviceRotationCoordinator") alloc], sel_registerName("initWithDevice:previewLayer:"), captureDevice, previewLayer);
        
        AVCaptureConnection *connection = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(rotationCoodinator, sel_registerName("connection"));
        
        CGFloat videoRotationAngleForHorizonLevelPreview = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(rotationCoodinator, sel_registerName("videoRotationAngleForHorizonLevelPreview"));
        reinterpret_cast<void (*)(id, SEL, CGFloat)>(objc_msgSend)(connection, sel_registerName("setVideoRotationAngle:"), videoRotationAngleForHorizonLevelPreview);
        
        [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
        
        [rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:previewLayer];
        [rotationCoodinator release];
    }
#else
    for (AVCaptureVideoPreviewLayer *previewLayer in previewLayers) {
        AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
        previewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
        [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
        
        [rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:previewLayer];
        [rotationCoodinator release];
    }
#endif
    
    [previewLayers release];
    
    [self postDidChangeSelectedDeviceNotificationWithOldCaptureDevice:oldCaptureDevice newCaptureDevice:captureDevice];
}

- (void)queue_selectDefaultCaptureDevice {
    assert(self.captureSessionQueue);
    
#if TARGET_OS_VISION
    AVCaptureDevice * _Nullable captureDevice = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDevice.class, sel_registerName("userPreferredCamera"));
#else
    AVCaptureDevice * _Nullable captureDevice = AVCaptureDevice.userPreferredCamera;
#endif
    
    if (captureDevice == nil) {
        captureDevice = AVCaptureDevice.systemPreferredCamera;
    }
    
    self.queue_selectedCaptureDevice = captureDevice;
}

#if TARGET_OS_VISION
- (void)queue_registerCaptureVideoPreviewLayer:(__kindof CALayer *)captureVideoPreviewLayer
#else
- (void)queue_registerCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
#endif
{
    assert(self.captureSessionQueue);
    
#if TARGET_OS_VISION
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(captureVideoPreviewLayer, sel_registerName("setSession:"), self.captureSession);
#else
    captureVideoPreviewLayer.session = self.captureSession;
#endif
    
    AVCaptureDevice *selectedCaptureDevice = self.queue_selectedCaptureDevice;
    if (selectedCaptureDevice == nil) {
//        abort();
        return;
    }
    
#if TARGET_OS_VISION
    id rotationCoodinator = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureDeviceRotationCoordinator") alloc], sel_registerName("initWithDevice:previewLayer:"), selectedCaptureDevice, captureVideoPreviewLayer);
    
    AVCaptureConnection *connection = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(captureVideoPreviewLayer, sel_registerName("connection"));
    
    CGFloat videoRotationAngleForHorizonLevelPreview = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(rotationCoodinator, sel_registerName("videoRotationAngleForHorizonLevelPreview"));
    reinterpret_cast<void (*)(id, SEL, CGFloat)>(objc_msgSend)(connection, sel_registerName("setVideoRotationAngle:"), videoRotationAngleForHorizonLevelPreview);
#else
    AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:selectedCaptureDevice previewLayer:captureVideoPreviewLayer];
    captureVideoPreviewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
#endif
    
    [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.queue_rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:captureVideoPreviewLayer];
    [rotationCoodinator release];
}

#if TARGET_OS_VISION
- (void)queue_unregisterCaptureVideoPreviewLayer:(__kindof CALayer *)captureVideoPreviewLayer
#else
- (void)queue_unregisterCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
#endif
{
    assert(self.captureSessionQueue);
    
    [[self.queue_rotationCoordinatorsByPreviewLayer objectForKey:captureVideoPreviewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    [self.queue_rotationCoordinatorsByPreviewLayer removeObjectForKey:captureVideoPreviewLayer];
    
#if TARGET_OS_VISION
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(captureVideoPreviewLayer, sel_registerName("setSession:"), nil);
#else
    captureVideoPreviewLayer.session = nil;
#endif
}

- (void)queue_startPhotoCaptureWithPhotoModel:(PhotoFormatModel *)photoModel {
    assert(self.captureSessionQueue);
    
    NSMutableDictionary<NSString *, id> *format = [NSMutableDictionary new];
    if (NSNumber *photoPixelFormatType = photoModel.photoPixelFormatType) {
        format[(id)kCVPixelBufferPixelFormatTypeKey] = photoModel.photoPixelFormatType;
    } else if (AVVideoCodecType codecType = photoModel.codecType) {
        format[AVVideoCodecKey] = photoModel.codecType;
        format[AVVideoCompressionPropertiesKey] = @{
            AVVideoQualityKey: @(photoModel.quality)
        };
    }
    
#if TARGET_OS_VISION
    id __autoreleasing capturePhotoSettings;
    
    if (photoModel.isRAWEnabled) {
        capturePhotoSettings = reinterpret_cast<id (*)(Class, SEL, OSType, id, id, id)>(objc_msgSend)(objc_lookUpClass("AVCapturePhotoSettings"), sel_registerName("photoSettingsWithRawPixelFormatType:rawFileType:processedFormat:processedFileType:"), photoModel.rawPhotoPixelFormatType.unsignedIntValue, photoModel.rawFileType, format, photoModel.processedFileType);
    } else {
        capturePhotoSettings = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("AVCapturePhotoSettings"), sel_registerName("photoSettingsWithFormat:"), format);
    }
    
    [format release];
    
    CMVideoDimensions maxPhotoDimensions = reinterpret_cast<CMVideoDimensions (*)(id, SEL)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("maxPhotoDimensions"));
    reinterpret_cast<void (*)(id, SEL, CMVideoDimensions)>(objc_msgSend)(capturePhotoSettings, sel_registerName("setMaxPhotoDimensions:"), maxPhotoDimensions);
    
    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(self.capturePhotoOutput, sel_registerName("capturePhotoWithSettings:delegate:"), capturePhotoSettings, self);
#else
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
    
    capturePhotoSettings.maxPhotoDimensions = self.capturePhotoOutput.maxPhotoDimensions;
    
    // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
    if (!photoModel.isRAWEnabled) {
        capturePhotoSettings.photoQualityPrioritization = photoModel.photoQualityPrioritization;
    }
    
    capturePhotoSettings.flashMode = photoModel.flashMode;
    
    //
    
    [self.capturePhotoOutputReadinessCoordinator startTrackingCaptureRequestUsingPhotoSettings:capturePhotoSettings];
    [self.capturePhotoOutput capturePhotoWithSettings:capturePhotoSettings delegate:self];
    [self.capturePhotoOutputReadinessCoordinator stopTrackingCaptureRequestUsingPhotoSettingsUniqueID:capturePhotoSettings.uniqueID];
#endif
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

#if TARGET_OS_VISION
- (void)captureOutput:(id)output didFinishProcessingPhoto:(id)photo error:(NSError *)error
#else
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
#endif
{
    assert(error == nil);
    
#if !TARGET_OS_VISION
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photo.resolvedSettings, sel_registerName("isSpatialPhotoCaptureEnabled"));
    NSLog(@"isSpatialPhotoCaptureEnabled: %d", isSpatialPhotoCaptureEnabled);
#endif
    
#if TARGET_OS_VISION
        NSData * _Nullable fileDataRepresentation = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photo, sel_registerName("fileDataRepresentation"));
#else
        NSData * _Nullable fileDataRepresentation = photo.fileDataRepresentation;
#endif
    
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

#if TARGET_OS_VISION
- (void)captureOutput:(id)output didFinishCapturingDeferredPhotoProxy:(id)deferredPhotoProxy error:(NSError *)error
#else
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCapturingDeferredPhotoProxy:(AVCaptureDeferredPhotoProxy *)deferredPhotoProxy error:(NSError *)error
#endif
{
    assert(error == nil);
    NSData * _Nullable fileDataRepresentation = deferredPhotoProxy.fileDataRepresentation;
    assert(fileDataRepresentation != nil); // AVVideoCodecTypeHEVC이 아니라면 nil일 수 있음
    
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        
#if TARGET_OS_VISION
        NSData * _Nullable fileDataRepresentation = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(deferredPhotoProxy, sel_registerName("fileDataRepresentation"));
        
        assert(fileDataRepresentation != nil);
        [request addResourceWithType:static_cast<PHAssetResourceType>(19) data:fileDataRepresentation options:nil];
#else
        
        [request addResourceWithType:PHAssetResourceTypePhotoProxy data:fileDataRepresentation options:nil];
#endif
        
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

#if TARGET_OS_VISION
- (void)readinessCoordinator:(id)coordinator captureReadinessDidChange:(NSInteger)captureReadiness
#else
- (void)readinessCoordinator:(AVCapturePhotoOutputReadinessCoordinator *)coordinator captureReadinessDidChange:(AVCapturePhotoOutputCaptureReadiness)captureReadiness
#endif
{
    [NSNotificationCenter.defaultCenter postNotificationName:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                      object:self
                                                    userInfo:@{CaptureServiceCaptureReadinessKey: @(captureReadiness)}];
}

@end
