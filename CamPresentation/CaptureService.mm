//
//  CaptureService.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureService.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureService ()
@property (class, nonatomic, readonly) void *devicesContext;
@property (retain, nonatomic, readonly) NSMapTable<AVCaptureVideoPreviewLayer *, AVCaptureDeviceRotationCoordinator *> *queue_rotationCoordinatorsByPreviewLayer;
@end

@implementation CaptureService

+ (void *)devicesContext {
    static void *devicesContext = &devicesContext;
    return devicesContext;
}

- (instancetype)init {
    if (self = [super init]) {
        AVCaptureSession *captureSession = [AVCaptureSession new];
        
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
        
        [captureDeviceDiscoverySession addObserver:self forKeyPath:@"devices" options:NSKeyValueObservingOptionNew context:CaptureService.devicesContext];
        
        _captureSession = captureSession;
        _captureSessionQueue = dispatch_queue_create("Camera Session Queue", attr);
        _captureDeviceDiscoverySession = [captureDeviceDiscoverySession retain];
        _queue_rotationCoordinatorsByPreviewLayer = [rotationCoordinatorsByPreviewLayer retain];
        
        //
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCaptureDeviceWasDisconnectedNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_captureSession release];
    [_captureSessionQueue release];
    [_captureDeviceDiscoverySession removeObserver:self forKeyPath:@"devices" context:CaptureService.devicesContext];
    [_captureDeviceDiscoverySession release];
    
    for (AVCaptureVideoPreviewLayer *previewLayer in _queue_rotationCoordinatorsByPreviewLayer.keyEnumerator) {
        [[_queue_rotationCoordinatorsByPreviewLayer objectForKey:previewLayer] removeObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview"];
    }
    
    [_queue_rotationCoordinatorsByPreviewLayer release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == CaptureService.devicesContext) {
        [self.delegate didChangeCaptureDeviceStatus:self];
    } else if ([object isKindOfClass:AVCaptureDeviceRotationCoordinator.class] && [keyPath isEqualToString:@"videoRotationAngleForHorizonLevelPreview"]) {
        auto rotationCoordinator = static_cast<AVCaptureDeviceRotationCoordinator *>(object);
        static_cast<AVCaptureVideoPreviewLayer *>(rotationCoordinator.previewLayer).connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview;
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
    
    for (__kindof AVCaptureInput *input in captureSession.inputs) {
        [captureSession removeInput:input];
    }
    
    if (captureDevice != nil) {
        NSError * _Nullable error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        assert(error == nil);
        [captureSession addInput:newInput];
    }
    
    [captureSession commitConfiguration];
    
    //
    
    for (AVCaptureVideoPreviewLayer *previewLayer in previewLayers) {
        AVCaptureDeviceRotationCoordinator *rotationCoodinator = [[AVCaptureDeviceRotationCoordinator alloc] initWithDevice:captureDevice previewLayer:previewLayer];
        previewLayer.connection.videoRotationAngle = rotationCoodinator.videoRotationAngleForHorizonLevelPreview;
        [rotationCoodinator addObserver:self forKeyPath:@"videoRotationAngleForHorizonLevelPreview" options:NSKeyValueObservingOptionNew context:NULL];
        
        [rotationCoordinatorsByPreviewLayer setObject:rotationCoodinator forKey:previewLayer];
        [rotationCoodinator release];
    }
    
    [previewLayers release];
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

- (void)didReceiveCaptureDeviceWasDisconnectedNotification:(NSNotification *)notification {
    dispatch_async(self.captureSessionQueue, ^{
        if (![self.queue_selectedCaptureDevice isEqual:notification.object]) return;
        [self queue_selectDefaultCaptureDevice];
        
        [self.delegate didChangeCaptureDeviceStatus:self];
    });
}

@end
