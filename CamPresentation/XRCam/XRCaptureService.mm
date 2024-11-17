//
//  XRCaptureService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCaptureService.h>
#import <Photos/Photos.h>
#import <objc/message.h>
#import <objc/runtime.h>

NSNotificationName const XRCaptureServiceUpdatedPreviewLayerNotificationName = @"XRCaptureServiceUpdatedPreviewLayerNotificationName";
NSNotificationName const XRCaptureServiceAddedCaptureDeviceNotificationName = @"XRCaptureServiceAddedCaptureDeviceNotificationName";
NSNotificationName const XRCaptureServiceRemovedCaptureDeviceNotificationName = @"XRCaptureServiceRemovedCaptureDeviceNotificationName";
NSString * const XRCaptureServiceCaptureDeviceKey = @"XRCaptureServiceCaptureDeviceKey";

@interface XRCaptureService () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (retain, nonatomic, nullable) id rotationCoordinator;
@property (retain, nonatomic, nullable) id photoOutputReadinessCoordinator;
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
        
        _captureSessionQueue = captureSessionQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _captureSession = captureSession;
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    dispatch_release(_captureSessionQueue);
    [_captureSession release];
    [_captureDeviceDiscoverySession release];
    [_rotationCoordinator release];
    [_photoOutputReadinessCoordinator release];
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

- (void)queue_startPhotoCaptureWithVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert([self.queue_addedVideoDevices containsObject:videoDevice]);
    
    __kindof AVCaptureOutput *photoOutput = [self queue_outputClass:objc_lookUpClass("AVCapturePhotoOutput") fromCaptureDevice:videoDevice].allObjects.firstObject;
    assert(photoOutput != nil);
    
    id photoSettings = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("AVCapturePhotoSettings"), sel_registerName("photoSettings"));
    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(photoOutput, sel_registerName("capturePhotoWithSettings:delegate:"), photoSettings, self);
}

- (void)queue_startVideoRecordingWithVideoDevice:(AVCaptureDevice *)videoDevice {
    abort();
}

- (void)_queue_removeVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:videoDevice.deviceType]);
    
    AVCaptureSession *captureSession = self.captureSession;
    
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
    
    [self _postDidUpdatePreviewLayerNotification];
    [self _postRemovedCaptureDeviceNotificationWithCaptureDevice:videoDevice];
}

- (void)_queue_addVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    assert(![self.queue_addedCaptureDevices containsObject:videoDevice]);
    
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
    
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [videoDataOutput setSampleBufferDelegate:self queue:self.captureSessionQueue];
    assert([captureSession canAddOutput:videoDataOutput]);
    [captureSession addOutputWithNoConnections:videoDataOutput];
    
    AVCaptureConnection *videoDataOutputConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[videoInputPort] output:videoDataOutput];
    [videoDataOutput release];
    assert([captureSession canAddConnection:videoDataOutputConnection]);
    [captureSession addConnection:videoDataOutputConnection];
    [videoDataOutputConnection release];
    
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
