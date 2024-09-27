//
//  CaptureDevicesMenuElement.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/27/24.
//

#import <CamPresentation/CaptureDevicesMenuElement.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface _CaptureDevicesMenuElementStorage : NSObject
@property (class, nonatomic, readonly) void *key;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic, readonly, nullable) void (^selectionHandler)(AVCaptureDevice *);
@property (copy, nonatomic, readonly, nullable) void (^deselectionHandler)(AVCaptureDevice *);
@property (copy, nonatomic, readonly, nullable) void (^reloadHandler)();
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler reloadHandler:(void (^ _Nullable)())reloadHandler;
@end

@implementation _CaptureDevicesMenuElementStorage

+ (void *)key {
    static void *key = &key;
    return key;
}

- (instancetype)initWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler reloadHandler:(void (^ _Nullable)())reloadHandler {
    if (self = [super init]) {
        _captureService = [captureService retain];
        _selectionHandler = [selectionHandler copy];
        _deselectionHandler = [deselectionHandler copy];
        _reloadHandler = [reloadHandler copy];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_selectionHandler release];
    [_deselectionHandler release];
    [_reloadHandler release];
    [super dealloc];
}

@end


@interface CaptureDevicesMenuElement ()
@property (retain, nonatomic, readonly) _CaptureDevicesMenuElementStorage *storage;
@end

@implementation CaptureDevicesMenuElement

+ (instancetype)elementWithCaptureDevice:(CaptureService *)captureDevice selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler reloadHandler:(void (^ _Nullable)())reloadHandler {
    __block CaptureDevicesMenuElement *result = static_cast<CaptureDevicesMenuElement *>([UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        assert(object_getClass(result) == CaptureDevicesMenuElement.class);
        [result menuElementsWithcompletionHandler:completion];
    }]);
    
    assert(object_setClass(result, CaptureDevicesMenuElement.class) != nil);
    
    _CaptureDevicesMenuElementStorage *storage = [[_CaptureDevicesMenuElementStorage alloc] initWithCaptureService:captureDevice selectionHandler:selectionHandler deselectionHandler:deselectionHandler reloadHandler:reloadHandler];
    
    objc_setAssociatedObject(result, _CaptureDevicesMenuElementStorage.key, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [storage release];
    
    [captureDevice.captureDeviceDiscoverySession addObserver:result forKeyPath:@"devices" options:NSKeyValueObservingOptionNew context:nullptr];
    
    return result;
}

- (void)dealloc {
    [self.storage.captureService removeObserver:self forKeyPath:@"devices"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.storage.captureService.captureDeviceDiscoverySession]) {
        if ([keyPath isEqualToString:@"devices"]) {
            if (auto reloadHandler = self.storage.reloadHandler) {
                reloadHandler();
            }
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (_CaptureDevicesMenuElementStorage *)storage {
    return objc_getAssociatedObject(self, _CaptureDevicesMenuElementStorage.key);
}

- (void)menuElementsWithcompletionHandler:(void (^)(NSArray<__kindof UIMenuElement *> *))completionHandler {
    _CaptureDevicesMenuElementStorage *storage = self.storage;
    CaptureService *captureService = storage.captureService;
    
    dispatch_async(captureService.captureSessionQueue, ^{
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
            
            BOOL isAdded = [addedCaptureDevices containsObject:captureDevice];
            
            UIAction *action = [UIAction actionWithTitle:captureDevice.localizedName
                                                   image:image
                                              identifier:captureDevice.uniqueID
                                                 handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    if (isAdded) {
                        if (auto deselectionHandler = storage.deselectionHandler) {
                            deselectionHandler(captureDevice);
                        }
                    } else {
                        if (auto selectionHandler = storage.selectionHandler) {
                            selectionHandler(captureDevice);
                        }
                    }
                });
            }];
            
            action.state = (isAdded ? UIMenuElementStateOn : UIMenuElementStateOff);
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            action.subtitle = captureDevice.manufacturer;
            
            [actions addObject:action];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(actions);
        });
        
        [actions release];
    });
}

@end
