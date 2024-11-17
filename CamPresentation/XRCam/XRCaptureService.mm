//
//  XRCaptureService.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/XRCaptureService.h>
#import <objc/message.h>
#import <objc/runtime.h>

NSNotificationName const XRCaptureServiceDidUpdatePreviewLayerNotificationName = @"XRCaptureServiceDidUpdatePreviewLayerNotificationName";

@interface XRCaptureService ()
@property (retain, nonatomic, nullable) id rotationCoordinator;
@property (retain, nonatomic, nullable) id photoOutputReadinessCoordinator;
@end

@implementation XRCaptureService

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t captureSessionAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t captureSessionQueue = dispatch_queue_create("Camera Session Queue", captureSessionAttr);
        
        NSArray<AVCaptureDeviceType> *allDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allDeviceTypes"));
        
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:allDeviceTypes
                                                                                                                                     mediaType:nil
                                                                                                                                      position:AVCaptureDevicePositionUnspecified];
        
        AVCaptureSession *captureSession = [AVCaptureSession new];
        
        _captureSessionQueue = captureSessionQueue;
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _captureSession = captureSession;
    }
    
    return self;
}

- (void)dealloc {
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

- (NSSet<__kindof AVCaptureOutput *> *)queue_outputClass:(Class)outputClass {
    abort();
}

- (void)queue_startPhotoCapture {
    abort();
}

- (void)queue_startVideoRecording {
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
}

- (void)_queue_addVideoDevice:(AVCaptureDevice *)videoDevice {
    dispatch_assert_queue(self.captureSessionQueue);
    
    NSArray<AVCaptureDeviceType> *allVideoDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDeviceTypes"));
    assert([allVideoDeviceTypes containsObject:videoDevice.deviceType]);
    
    AVCaptureSession *captureSession = self.captureSession;
    
    for (AVCaptureConnection *connection in captureSession.connections) {
        for (id inputPort in reinterpret_cast<NSArray * (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("inputPorts"))) {
            auto input = reinterpret_cast<__kindof AVCaptureInput * (*)(id, SEL)>(objc_msgSend)(inputPort, sel_registerName("input"));
            if (![input isKindOfClass:AVCaptureDeviceInput.class]) continue;
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(input);
            
            assert(![deviceInput.device isEqual:videoDevice]);
        }
    }
    
    //
    
    [captureSession beginConfiguration];
    
    //
    
    NSError * _Nullable error = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&error];
    assert(error == nil);
    [captureSession addInputWithNoConnections:deviceInput];
    
    id videoInputPort = reinterpret_cast<NSArray * (*)(id, SEL, id, id, AVCaptureDevicePosition)>(objc_msgSend)(deviceInput, sel_registerName("portsWithMediaType:sourceDeviceType:sourceDevicePosition:"), AVMediaTypeVideo, nil, AVCaptureDevicePositionUnspecified)[0];
    
    //
    
#warning TODO : Face Metadata
    
    __kindof CALayer *previewLayer = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureVideoPreviewLayer") alloc], sel_registerName("initWithSessionWithNoConnection:"), captureSession);
    
    AVCaptureConnection *previewLayerConnection = reinterpret_cast<id (*)(id, SEL, id, id)>(objc_msgSend)([objc_lookUpClass("AVCaptureConnection") alloc], sel_registerName("initWithInputPort:videoPreviewLayer:"), videoInputPort, previewLayer);
    [previewLayer release];
    
    assert([captureSession canAddConnection:previewLayerConnection]);
    [captureSession addConnection:previewLayerConnection];
    [previewLayerConnection release];
    
    //
    
    [deviceInput release];
    
    [captureSession commitConfiguration];
    
    [self _postDidUpdatePreviewLayerNotification];
}

- (void)_postDidUpdatePreviewLayerNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:XRCaptureServiceDidUpdatePreviewLayerNotificationName object:self];
}

@end

#endif
