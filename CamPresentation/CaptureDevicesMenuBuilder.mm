//
//  CaptureDevicesMenuBuilder.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <CamPresentation/CaptureDevicesMenuBuilder.h>

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
        AVCaptureDevice *selectedCaptureDevice = captureService.queue_selectedCaptureDevice;
        NSArray<AVCaptureDevice *> *devices = captureService.captureDeviceDiscoverySession.devices;
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
                    if (![captureService.queue_selectedCaptureDevice isEqual:captureDevice]) {
                        captureService.queue_selectedCaptureDevice = captureDevice;
                        [weakSelf.delegate captureDevicesMenuBuilderElementsDidChange:weakSelf];
                    }
                });
            }];
            
            action.state = ([captureDevice isEqual:selectedCaptureDevice] ? UIMenuElementStateOn : UIMenuElementStateOff);
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
