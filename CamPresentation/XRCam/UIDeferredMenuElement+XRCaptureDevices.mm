//
//  UIDeferredMenuElement+XRCaptureDevices.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/UIDeferredMenuElement+XRCaptureDevices.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIDeferredMenuElement (XRCaptureDevices)

+ (instancetype)cp_xr_captureDevicesElementWithCaptureService:(XRCaptureService *)captureService selectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))selectionHandler deselectionHandler:(void (^ _Nullable)(AVCaptureDevice *captureDevice))deselectionHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSArray<AVCaptureDevice *> *devices = captureService.captureDeviceDiscoverySession.devices;
            NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:devices.count];
            NSSet<AVCaptureDevice *> *addedCaptureDevices = captureService.queue_addedCaptureDevices;
            
            for (AVCaptureDevice *device in devices) {
                BOOL isAdded = [addedCaptureDevices containsObject:device];
                
                UIAction *action = [UIAction actionWithTitle:device.localizedName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        if (isAdded) {
                            [captureService queue_removeCaptureDevice:device];
                            if (deselectionHandler) deselectionHandler(device);
                        } else {
                            [captureService queue_addCaptureDevice:device];
                            if (selectionHandler) selectionHandler(device);
                        }
                    });
                }];
                
                action.state = isAdded ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [actions addObject:action];
            }
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions];
            [actions release];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[menu]);
            });
        });
    }];
}

@end

#endif
