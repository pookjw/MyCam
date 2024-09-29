//
//  UIDeferredMenuElement+CaptureDevices.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/28/24.
//

#import <CamPresentation/UIDeferredMenuElement+CaptureDevices.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIDeferredMenuElement (CaptureDevices)

+ (instancetype)cp_captureDevicesElementWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
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
                            if (deselectionHandler != nil) {
                                deselectionHandler(captureDevice);
                            }
                        } else {
                            if (selectionHandler != nil) {
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
                completion(actions);
            });
            
            [actions release];
        });
    }];
}

@end
