//
//  XRCaptureService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCaptureService.h>
#import <CamPresentation/MovieWriter.h>
#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <Photos/Photos.h>
#import <objc/message.h>
#import <objc/runtime.h>

NSNotificationName const XRCaptureServiceUpdatedPreviewLayerNotificationName = @"XRCaptureServiceUpdatedPreviewLayerNotificationName";
NSNotificationName const XRCaptureServiceAddedCaptureDeviceNotificationName = @"XRCaptureServiceAddedCaptureDeviceNotificationName";
NSNotificationName const XRCaptureServiceRemovedCaptureDeviceNotificationName = @"XRCaptureServiceRemovedCaptureDeviceNotificationName";
NSString * const XRCaptureServiceCaptureDeviceKey = @"XRCaptureServiceCaptureDeviceKey";

@interface XRCaptureService ()
@property (retain, nonatomic, nullable, setter=queue_setRotationCoordinator:) id queue_rotationCoordinator; // TODO
@property (retain, nonatomic, nullable, setter=queue_setPhotoOutputReadinessCoordinator:) id queue_photoOutputReadinessCoordinator; // TODO
@property (retain, nonatomic, nullable) MovieWriter *queue_movieWriter;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureDevice *, XRPhotoSettings *> *queue_photoSettingsByVideoDevice;
@end

@implementation XRCaptureService

+ (void)load {
    if (Protocol *AVCaptureMetadataOutputObjectsDelegate = NSProtocolFromString(@"AVCaptureMetadataOutputObjectsDelegate")) {
        assert(class_addProtocol(self, AVCaptureMetadataOutputObjectsDelegate));
    }
    
    if (Protocol *AVCapturePhotoCaptureDelegate = NSProtocolFromString(@"AVCapturePhotoCaptureDelegate")) {
        assert(class_addProtocol(self, AVCapturePhotoCaptureDelegate));
    }
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t captureSessionAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", captureSessionAttr);
        
        NSArray<AVCaptureDeviceType> *allDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allDeviceTypes"));
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:allDeviceTypes
                                                                                                                                mediaType:nil
                                                                                                                                 position:AVCaptureDevicePositionUnspecified];
        
        AVCaptureSession *captureSession = [AVCaptureSession new];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_didReceiveWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
        
        NSMapTable<AVCaptureDevice *, XRPhotoSettings *> *photoSettingsByVideoDevice = [NSMapTable strongToStrongObjectsMapTable];
        
        _captureSessionQueue = captureSessionQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _captureSession = captureSession;
        _queue_photoSettingsByVideoDevice = [photoSettingsByVideoDevice retain];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    dispatch_release(_captureSessionQueue);
    [_captureSession release];
    [_captureDeviceDiscoverySession release];
    [_queue_rotationCoordinator release];
    [_queue_photoOutputReadinessCoordinator release];
    [_queue_movieWriter release];
    [_queue_photoSettingsByVideoDevice release];
    [super dealloc];
}

- (NSSet<AVCaptureDevice *> *)queue_addedCaptureDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableSet<AVCaptureDevice *> *captureDevices = [NSMutableSet new];
    
    for (__kindof AVCaptureInput *input in self.captureSession.inputs) {
        if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
            AVCaptureDevice *captureDevice = static_cast<AVCaptureDeviceInput *>(input).device;
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}

- (NSSet<AVCaptureDevice *> *)queue_addedVideoDevices {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    NSMutableSet<AVCaptureDevice *> *captureDevices = [NSMutableSet new];
    
    for (AVCaptureDevice *captureDevice in self.queue_addedCaptureDevices) {
        if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
            [captureDevices addObject:captureDevice];
        }
    }
    
    return [captureDevices autorelease];
}

- (void)queue_addCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    
    if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_addVideoDevice:captureDevice];
        return;
    }
    
    abort();
}

- (void)queue_removeCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    assert([self.queue_addedCaptureDevices containsObject:captureDevice]);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    
    if ([allVideoDeviceTypes containsObject:captureDevice.deviceType]) {
        [self _queue_removeVideoDevice:captureDevice];
        return;
    }
    
    abort();
}

- (AVCaptureDevice *)defaultVideoDevice {
    AVCaptureDevice * _Nullable captureDevice = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDevice.class, sel_registerName("userPreferredCamera"));
    
    if (captureDevice == nil) {
        captureDevice = AVCaptureDevice.systemPreferredCamera;
    }
    
    if (captureDevice.uniqueID == nil) {
        // Simulator
        return nil;
    }
    
    return captureDevice;
}

- (__kindof CALayer *)queue_previewLayer {
    dispatch_assert_queue(self.captureSessionQueue);
    
    for (AVCaptureConnection *connection in self.captureSession.connections) {
        if (__kindof CALayer *videoPreviewLayer = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("videoPreviewLayer"))) {
            return videoPreviewLayer;
        }
    }
    
    return nil;
}

- (NSSet<__kindof AVCaptureOutput *> *)queue_outputClass:(Class)outputClass fromCaptureDevice:(AVCaptureDevice *)captureDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSMutableSet<__kindof AVCaptureOutput *> *outputs = [NSMutableSet new];
    
    for (AVCaptureConnection *connection in self.captureSession.connections) {
        if (connection.output.class != outputClass) {
            continue;
        }
        
        for (id port in reinterpret_cast<NSArray * (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("inputPorts"))) {
            __kindof AVCaptureInput *input = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(port, sel_registerName("input"));
            
            if ([input isKindOfClass:AVCaptureDeviceInput.class]) {
                auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
                
                if ([deviceInput.device isEqual:captureDevice]) {
                    [outputs addObject:connection.output];
                    break;
                }
            }
        }
    }
    
    return outputs;
}

- (XRPhotoSettings *)queue_photoSettingsForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    XRPhotoSettings *photoSettings = [self.queue_photoSettingsByVideoDevice objectForKey:videoDevice];
    assert(photoSettings != nil);
    return [[photoSettings copy] autorelease];
}

- (void)queue_setPhotoSettings:(XRPhotoSettings *)photoSettings forVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    XRPhotoSettings *copy = [photoSettings copy];
    [self.queue_photoSettingsByVideoDevice setObject:copy forKey:videoDevice];
    [copy release];
}

- (void)queue_startPhotoCaptureWithVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedVideoDevices containsObject:videoDevice]);
    
    __kindof AVCaptureOutput *photoOutput = [self queue_outputClass:objc_lookUpClass("AVCapturePhotoOutput") fromCaptureDevice:videoDevice].allObjects.firstObject;
    assert(photoOutput != nil);
    
    id photoSettings = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("AVCapturePhotoSettings"), sel_registerName("photoSettings"));
    
    XRPhotoSettings *xrPhotoSettings = [self.queue_photoSettingsByVideoDevice objectForKey:videoDevice];
    assert(xrPhotoSettings != nil);
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(photoSettings, sel_registerName("setShutterSoundSuppressionEnabled:"), xrPhotoSettings.isShutterSoundSuppressionEnabled);
    
    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(photoOutput, sel_registerName("capturePhotoWithSettings:delegate:"), photoSettings, self);
}

- (MovieWriter *)queue_movieWriterForVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(self.queue_movieWriter != nil);
    return self.queue_movieWriter;
}

- (void)_queue_removeVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:videoDevice.deviceType]);
    
    AVCaptureSession *captureSession = self.captureSession;
    
    assert(self.queue_movieWriter != nil);
    assert(self.queue_movieWriter.status == MovieWriterStatusPending);
    self.queue_movieWriter = nil;
    
    BOOL didRemove = NO;
    
    [captureSession beginConfiguration];
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        for (id inputPort in reinterpret_cast<NSArray * (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("inputPorts"))) {
            auto input = reinterpret_cast<__kindof AVCaptureInput * (*)(id, SEL)>(objc_msgSend)(inputPort, sel_registerName("input"));
            if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
            
            if (![deviceInput.device isEqual:videoDevice]) continue;
            
            [captureSession removeConnection:connection];
            [captureSession removeInput:input];
            
            if (__kindof AVCaptureOutput *output = connection.output) {
                [captureSession removeOutput:output];
            }
            
            didRemove = YES;
        }
    }
    
    assert(didRemove);
    
    [captureSession commitConfiguration];
    
    assert([self.queue_photoSettingsByVideoDevice objectForKey:videoDevice] != nil);
    [self.queue_photoSettingsByVideoDevice removeObjectForKey:videoDevice];
    
    [self _postDidUpdatePreviewLayerNotification];
    [self _postRemovedCaptureDeviceNotificationWithCaptureDevice:videoDevice];
}

- (void)_queue_addVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(![self.queue_addedCaptureDevices containsObject:videoDevice]);
    assert(self.queue_movieWriter == nil);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:videoDevice.deviceType]);
    
    AVCaptureSession *captureSession = self.captureSession;
    
    [captureSession beginConfiguration];
    
    //
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&error];
    assert(error == nil);
    [captureSession addInputWithNoConnections:deviceInput];
    
    id videoInputPort = reinterpret_cast<NSArray * (*)(id, SEL, id, id, AVCaptureDevicePosition)>(objc_msgSend)(deviceInput, sel_registerName("portsWithMediaType:sourceDeviceType:sourceDevicePosition:"), AVMediaTypeVideo, nil, AVCaptureDevicePositionUnspecified)[0];
    id metadataObjectInputPort = reinterpret_cast<NSArray * (*)(id, SEL, id, id, AVCaptureDevicePosition)>(objc_msgSend)(deviceInput, sel_registerName("portsWithMediaType:sourceDeviceType:sourceDevicePosition:"), AVMediaTypeMetadataObject, nil, AVCaptureDevicePositionUnspecified)[0];
    
    //
    
    __kindof CALayer *previewLayer = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureVideoPreviewLayer") alloc], sel_registerName("initWithSessionWithNoConnection:"), captureSession);
    
    AVCaptureConnection *previewLayerConnection = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureConnection") alloc], sel_registerName("initWithInputPort:videoPreviewLayer:"), videoInputPort, previewLayer);
    [previewLayer release];
    
    assert([captureSession canAddConnection:previewLayerConnection]);
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    AVCaptureVideoDataOutput *movieWriterVideoDataOutput = [AVCaptureVideoDataOutput new];
    assert([captureSession canAddOutput:movieWriterVideoDataOutput]);
    [captureSession addOutputWithNoConnections:movieWriterVideoDataOutput];
    
    AVCaptureConnection *movieWriterVideoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:movieWriterVideoDataOutput];
    assert([captureSession canAddConnection:movieWriterVideoDataOutputConnection]);
    [captureSession addConnection:movieWriterVideoDataOutputConnection];
    [movieWriterVideoDataOutputConnection release];
    
    PhotoLibraryFileOutput *fileOutput = [[PhotoLibraryFileOutput alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
    MovieWriter *movieWriter = [[MovieWriter alloc] initWithFileOutput:fileOutput videoDataOutput:movieWriterVideoDataOutput useFastRecording:YES isolatedQueue:self.captureSessionQueue locationHandler:nil];
    [fileOutput release];
    self.queue_movieWriter = movieWriter;
    [movieWriter release];
    
    [movieWriterVideoDataOutput release];
    
    //
    
    __kindof AVCaptureOutput *photoOutput = [objc_lookUpClass("AVCapturePhotoOutput") new];
    assert([captureSession canAddOutput:photoOutput]);
    [captureSession addOutputWithNoConnections:photoOutput];
    
    AVCaptureConnection *photoOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:photoOutput];
    [photoOutput release];
    assert([captureSession canAddConnection:photoOutputConnection]);
    [captureSession addConnection:photoOutputConnection];
    [photoOutputConnection release];
    
    //
    
    // Preview Layer가 작동하지 않는 문제가 있음
    //    __kindof AVCaptureOutput *movieFileOutput = [objc_lookUpClass("AVCaptureMovieFileOutput") new];
    //    assert([captureSession canAddOutput:movieFileOutput]);
    //    [captureSession addOutputWithNoConnections:movieFileOutput];
    //
    //    AVCaptureConnection *movieFileOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:movieFileOutput];
    //    [movieFileOutput release];
    //    assert([captureSession canAddConnection:movieFileOutputConnection]);
    //    [captureSession addConnection:movieFileOutputConnection];
    //    [movieFileOutputConnection release];
    
    
    //
    
    if (metadataObjectInputPort) {
        __kindof AVCaptureOutput *metadataOutput = [objc_lookUpClass("AVCaptureMetadataOutput") new];
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(metadataOutput, sel_registerName("setMetadataObjectsDelegate:queue:"), self, self.captureSessionQueue);
        assert([captureSession canAddOutput:metadataOutput]);
        [captureSession addOutputWithNoConnections:metadataOutput];
        
        AVCaptureConnection *metadataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[metadataObjectInputPort] output:metadataOutput];
        [metadataOutput release];
        assert([captureSession canAddConnection:metadataOutputConnection]);
        [captureSession addConnection:metadataOutputConnection];
        [metadataOutputConnection release];
    }
    
    //
    
    [deviceInput release];
    
    [captureSession commitConfiguration];
    
    XRPhotoSettings *photoSettings = [XRPhotoSettings new];
    assert([self.queue_photoSettingsByVideoDevice objectForKey:videoDevice] == nil);
    [self.queue_photoSettingsByVideoDevice setObject:photoSettings forKey:videoDevice];
    [photoSettings release];
    
    reinterpret_cast<void (*)(Class, SEL, id)>(objc_msgSend)(AVCaptureDevice.class, sel_registerName("setUserPreferredCamera:"), videoDevice);
    
    [self _postDidUpdatePreviewLayerNotification];
    [self _postAddedCaptureDeviceNotificationWithCaptureDevice:videoDevice];
}

- (void)_postDidUpdatePreviewLayerNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:XRCaptureServiceUpdatedPreviewLayerNotificationName object:self];
}

- (void)_postAddedCaptureDeviceNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:XRCaptureServiceAddedCaptureDeviceNotificationName
                                                      object:self
                                                    userInfo:@{XRCaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)_postRemovedCaptureDeviceNotificationWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    [NSNotificationCenter.defaultCenter postNotificationName:XRCaptureServiceRemovedCaptureDeviceNotificationName
                                                      object:self
                                                    userInfo:@{XRCaptureServiceCaptureDeviceKey: captureDevice}];
}

- (void)_didReceiveWasDisconnectedNotification:(NSNotification *)notification {
    auto captureDevice = static_cast<AVCaptureDevice *>(notification.object);
    
    dispatch_async(self.captureSessionQueue, ^{
        if ([self.queue_addedCaptureDevices containsObject:captureDevice]) {
            [self queue_removeCaptureDevice:captureDevice];
        }
    });
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // Not working
    NSLog(@"%@", metadataObjects);
}

- (void)captureOutput:(__kindof AVCaptureOutput *)output didFinishProcessingPhoto:(id)photo error:(NSError *)error {
    assert(error == nil);
    
    NSData * _Nullable fileDataRepresentation = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(photo, sel_registerName("fileDataRepresentation"));
    assert(fileDataRepresentation != nil);
    
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        
        assert(fileDataRepresentation != nil);
        [request addResourceWithType:PHAssetResourceTypePhoto data:fileDataRepresentation options:nil];
    }
                                    completionHandler:^(BOOL success, NSError * _Nullable error) {
        assert(success);
        assert(error == nil);
    }];
}

- (void)captureOutput:(__kindof AVCaptureOutput *)output didFinishCaptureForResolvedSettings:(id)resolvedSettings error:(NSError *)error {
    assert(error == nil);
}

@end

#endif
