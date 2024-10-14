//
//  UIDeferredMenuElement+CaptureDevices.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/28/24.
//

#import <CamPresentation/UIDeferredMenuElement+CaptureDevices.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIDeferredMenuElement (CaptureDevices)

/*
 isGeometricDistortionCorrectionSupported
 isCameraIntrinsicMatrixDeliverySupported
 autoRedEyeReductionEnabled
 */

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
                action.subtitle = [NSString stringWithFormat:@"manufacturer : %@, isVirtualDevice : %d, constituentDevices.count: %ld", captureDevice.manufacturer, captureDevice.isVirtualDevice, captureDevice.constituentDevices.count];
                action.cp_overrideNumberOfSubtitleLines = @0;
                
                [actions addObject:action];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(actions);
            });
            
            [actions release];
        });
    }];
}

+ (instancetype)cp_multiCamDevicesElementWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSArray<AVCaptureDevice *> *addedCaptureDevices = captureService.queue_addedCaptureDevices;
            NSArray<NSSet<AVCaptureDevice *> *> *multiCamDeviceSets = captureService.videoCaptureDeviceDiscoverySession.supportedMultiCamDeviceSets;
            
            NSMutableArray<UIMenu *> *enabledMenuArray = [NSMutableArray new];
            NSMutableArray<UIMenu *> *disabledMenuArray = [NSMutableArray new];
            
            for (NSSet<AVCaptureDevice *> *captureDevices in multiCamDeviceSets) {
                BOOL isSubset = [[NSSet setWithArray:addedCaptureDevices] isSubsetOfSet:captureDevices];
                
                NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:captureDevices.count];
                NSArray<AVCaptureDevice *> *sortedCaptureDevices = [captureDevices.allObjects sortedArrayUsingComparator:^NSComparisonResult(AVCaptureDevice * _Nonnull obj1, AVCaptureDevice * _Nonnull obj2) {
                    return [obj1.uniqueID compare:obj2.uniqueID];
                }];
                
                for (AVCaptureDevice *captureDevice in sortedCaptureDevices) {
                    UIImage *image;
                    if (captureDevice.deviceType == AVCaptureDeviceTypeExternal) {
                        image = [UIImage systemImageNamed:@"web.camera"];
                    } else {
                        image = [UIImage systemImageNamed:@"camera"];
                    }
                    
                    BOOL isAdded = [addedCaptureDevices containsObject:captureDevice];
                    
                    UIAction *action = [UIAction actionWithTitle:captureDevice.localizedName
                                                           image:image
                                                      identifier:nil
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
                    
                    action.state = ((isAdded) ? UIMenuElementStateOn : UIMenuElementStateOff);
                    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (isSubset ? 0 : UIMenuElementAttributesDisabled);
                    action.subtitle = [NSString stringWithFormat:@"manufacturer : %@, isVirtualDevice : %d, constituentDevices.count: %ld", captureDevice.manufacturer, captureDevice.isVirtualDevice, captureDevice.constituentDevices.count];
                    action.cp_overrideNumberOfSubtitleLines = @0;
                    
                    [actions addObject:action];
                }
                
                UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions];
                [actions release];
                
                if (isSubset) {
                    [enabledMenuArray addObject:menu];
                } else {
                    [disabledMenuArray addObject:menu];
                }
            }
            
            assert(enabledMenuArray.count + disabledMenuArray.count == multiCamDeviceSets.count);
            
            NSArray<UIMenu *> *allMenuArray = [enabledMenuArray arrayByAddingObjectsFromArray:disabledMenuArray];
            
            [enabledMenuArray release];
            [disabledMenuArray release];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(allMenuArray);
            });
        });
    }];
}

@end
