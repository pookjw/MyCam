//
//  CaptureDevicesMenuBuilder.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <CamPresentation/CaptureDevicesMenuBuilder.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface CaptureDevicesMenuBuilder ()
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (weak, nonatomic, readonly) id<CaptureDevicesMenuBuilderDelegate> delegate;
@end

@implementation CaptureDevicesMenuBuilder

- (instancetype)initWithCaptureService:(CaptureService *)captureService delegate:(id<CaptureDevicesMenuBuilderDelegate>)delegate {
    if (self = [super init]) {
        [captureService.captureDeviceDiscoverySession addObserver:self forKeyPath:@"devices" options:NSKeyValueObservingOptionNew context:nullptr];
        
        _captureService = [captureService retain];
        _delegate = delegate;
    }
    
    return self;
}

- (void)dealloc {
    [_captureService.captureDeviceDiscoverySession removeObserver:self forKeyPath:@"devices"];
    [_captureService release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"devices"]) {
        [self.delegate captureDevicesMenuBuilderElementsDidChange:self];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)menuElementsWithCompletionHandler:(void (^)(NSArray<__kindof UIMenuElement *> * _Nonnull))completionHandler {
    CaptureService *captureService = self.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
        __weak auto weakSelf = self;
        NSArray<AVCaptureDevice *> *addedCaptureDevices = captureService.queue_addedCaptureDevices;
        NSArray<AVCaptureDevice *> *devices = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allVideoDevices"));
        
        NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:devices.count];
        
        for (AVCaptureDevice *captureDevice in devices) {
            UIImage *image;
            if (captureDevice.deviceType == AVCaptureDeviceTypeExternal) {
                image = [UIImage systemImageNamed:@"web.camera"];
            } else {
                image = [UIImage systemImageNamed:@"camera"];
            }
            
            UIAction *action = [UIAction actionWithTitle:captureDevice.localizedName
                                                   image:image
                                              identifier:captureDevice.uniqueID
                                                 handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    if ([captureService.queue_addedCaptureDevices containsObject:captureDevice]) {
                        [captureService queue_removeCaptureDevice:captureDevice];
                    } else {
                        // TODO
                        abort();
//                        [captureService queue_addCapureDevice:captureDevice captureVideoPreviewLayer:nil];
                    }
                    
                    [weakSelf.delegate captureDevicesMenuBuilderElementsDidChange:weakSelf];
                });
            }];
            
            action.state = ([addedCaptureDevices containsObject:captureDevice] ? UIMenuElementStateOn : UIMenuElementStateOff);
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            action.subtitle = captureDevice.manufacturer;
            
            [actions addObject:action];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) completionHandler(actions);
        });
        
        [actions release];
    });
}

@end
