//
//  UIDeferredMenuElement+CaptureDevices.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/28/24.
//

#import <CamPresentation/UIDeferredMenuElement+CaptureDevices.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <vector>
#include <ranges>

AVF_EXPORT AVMediaType const AVMediaTypeVisionData;
AVF_EXPORT AVMediaType const AVMediaTypePointCloudData;
AVF_EXPORT AVMediaType const AVMediaTypeCameraCalibrationData;

@implementation UIDeferredMenuElement (CaptureDevices)

/*
 isGeometricDistortionCorrectionSupported
 isCameraIntrinsicMatrixDeliverySupported
 autoRedEyeReductionEnabled
 +[AVCaptureDeviceDiscoverySession ...]
 */

+ (instancetype)cp_captureDevicesElementWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSMutableArray<AVCaptureDevice *> *otherDevices = [captureService.captureDeviceDiscoverySession.devices mutableCopy];
            
            auto menusVec = std::vector<SEL> {
                sel_registerName("allVideoDeviceTypes"),
                sel_registerName("allPointCloudDeviceTypes"),
                sel_registerName("allMetadataCameraDeviceTypes"),
                sel_registerName("allAudioDeviceTypes"),
                sel_registerName("allVirtualDeviceTypes")
            }
            | std::views::transform([captureService, selectionHandler, deselectionHandler, otherDevices](SEL cmd) -> UIMenu * {
                NSArray<AVCaptureDeviceType> *deviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, cmd);
                
                UIMenu *menu = [UIDeferredMenuElement _cp_queue_captureDevicesMenuWithCaptureService:captureService
                                                                                               title:NSStringFromSelector(cmd)
                                                                                       filterHandler:^BOOL(AVCaptureDevice *captureDevice) {
                    if ([deviceTypes containsObject:captureDevice.deviceType]) {
                        [otherDevices removeObject:captureDevice];
                        return YES;
                    } else {
                        return NO;
                    }
                }
                                                                                    selectionHandler:selectionHandler
                                                                                  deselectionHandler:deselectionHandler];
                
                return menu;
            })
            | std::ranges::to<std::vector<UIMenu *>>();
            
            //
            
            if (otherDevices.count > 0) {
                UIMenu *menu = [UIDeferredMenuElement _cp_queue_captureDevicesMenuWithCaptureService:captureService
                                                                                               title:@"Other Devices"
                                                                                       filterHandler:^BOOL(AVCaptureDevice *captureDevice) {
                    return [otherDevices containsObject:captureDevice];
                }
                                                                                    selectionHandler:selectionHandler
                                                                                  deselectionHandler:deselectionHandler];
                
                menusVec.push_back(menu);
            }
            
            [otherDevices release];
            
            //
            
            UIMenu *multiCamMenu = [UIDeferredMenuElement _cp_queue_multiCamCaptureDevicesMenuWithCaptureService:captureService title:@"Multi Cam" filterHandler:nil selectionHandler:selectionHandler deselectionHandler:deselectionHandler];
            menusVec.push_back(multiCamMenu);
            
            UIMenu *lowLightSupportedDevicesMenu = [UIDeferredMenuElement _cp_queue_lowLightBoostSupportedDevicesWithCaptureService:captureService selectionHandler:selectionHandler deselectionHandler:deselectionHandler];
            menusVec.push_back(lowLightSupportedDevicesMenu);
            
            UIMenu *spatialVideoCaptureSupportedDevices = [UIDeferredMenuElement _cp_queue_spatialVideoCaptureSupportedDevicesWithCaptureService:captureService selectionHandler:selectionHandler deselectionHandler:deselectionHandler];
            menusVec.push_back(spatialVideoCaptureSupportedDevices);
            
            UIMenu *previewOptimizedStabilizationModeSupportedDevices = [UIDeferredMenuElement _cp_queue_previewOptimizedStabilizationModeSupportedDevicesWithCaptureService:captureService selectionHandler:selectionHandler deselectionHandler:deselectionHandler];
            menusVec.push_back(previewOptimizedStabilizationModeSupportedDevices);
            
            //
            
            NSArray<UIMenu *> *menus = [[NSArray alloc] initWithObjects:menusVec.data() count:menusVec.size()];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(menus);
            });
            
            [menus release];
        });
    }];
}

+ (UIMenu * _Nonnull)_cp_queue_captureDevicesMenuWithCaptureService:(CaptureService *)captureService title:(NSString *)title filterHandler:(BOOL (^)(AVCaptureDevice *captureDevice))filterHandler selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    NSArray<AVCaptureDevice *> *addedCaptureDevices = captureService.queue_addedCaptureDevices;
    NSArray<AVCaptureDevice *> *devices = captureService.captureDeviceDiscoverySession.devices;
    
    NSMutableArray<UIAction *> *actions = [NSMutableArray new];
    
    for (AVCaptureDevice *captureDevice in devices) {
        if (filterHandler != nil) {
            if (!filterHandler(captureDevice)) continue;
        }
        
        BOOL isAdded = [addedCaptureDevices containsObject:captureDevice];
        
        UIAction *action = [UIAction actionWithTitle:captureDevice.localizedName
                                               image:nil
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
        action.subtitle = [NSString stringWithFormat:@"isVirtualDevice : %d, constituentDevices.count: %ld", captureDevice.isVirtualDevice, captureDevice.constituentDevices.count];
        action.cp_overrideNumberOfSubtitleLines = 0;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:title children:actions];
    [actions release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_multiCamCaptureDevicesMenuWithCaptureService:(CaptureService *)captureService title:(NSString *)title filterHandler:(BOOL (^)(NSSet<AVCaptureDevice *> *deviceSet))filterHandler selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    NSArray<AVCaptureDevice *> *addedVideoCaptureDevices = captureService.queue_addedVideoCaptureDevices;
    NSArray<NSSet<AVCaptureDevice *> *> *multiCamDeviceSets = captureService.captureDeviceDiscoverySession.supportedMultiCamDeviceSets;
    
    NSMutableArray<UIMenu *> *enabledMenuArray = [NSMutableArray new];
    NSMutableArray<UIMenu *> *disabledMenuArray = [NSMutableArray new];
    
    for (NSSet<AVCaptureDevice *> *captureDevices in multiCamDeviceSets) {
        if (filterHandler != nil) {
            if (!filterHandler(captureDevices)) continue;
        }
        
        BOOL isSubset = [[NSSet setWithArray:addedVideoCaptureDevices] isSubsetOfSet:captureDevices];
        
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
            
            BOOL isAdded = [addedVideoCaptureDevices containsObject:captureDevice];
            
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
            action.cp_overrideNumberOfSubtitleLines = 0;
            
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
    
    UIMenu *menu = [UIMenu menuWithTitle:title children:allMenuArray];
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_lowLightBoostSupportedDevicesWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement _cp_queue_captureDevicesMenuWithCaptureService:captureService
                                                                           title:@"Low Boost Supported Devices"
                                                                   filterHandler:^BOOL(AVCaptureDevice *captureDevice) {
        return captureDevice.isLowLightBoostSupported;
    }
                                                                selectionHandler:selectionHandler
                                                              deselectionHandler:deselectionHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_spatialVideoCaptureSupportedDevicesWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement _cp_queue_captureDevicesMenuWithCaptureService:captureService
                                                                           title:@"Spatial Video Capture Supported Devices"
                                                                   filterHandler:^BOOL(AVCaptureDevice *captureDevice) {
        for (AVCaptureDeviceFormat *format in captureDevice.formats) {
            if (format.isSpatialVideoCaptureSupported) {
                return YES;
            }
        }
        
        return NO;
    }
                                                                selectionHandler:selectionHandler
                                                              deselectionHandler:deselectionHandler];
}

+ (UIMenu *)_cp_queue_previewOptimizedStabilizationModeSupportedDevicesWithCaptureService:(CaptureService *)captureService selectionHandler:(void (^)(AVCaptureDevice * _Nonnull))selectionHandler deselectionHandler:(void (^)(AVCaptureDevice * _Nonnull))deselectionHandler {
    return [UIDeferredMenuElement _cp_queue_captureDevicesMenuWithCaptureService:captureService
                                                                           title:@"Preview Optimized Stabilization Mode Supported Devices"
                                                                   filterHandler:^BOOL(AVCaptureDevice *captureDevice) {
        for (AVCaptureDeviceFormat *format in captureDevice.formats) {
            if ([format isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModePreviewOptimized]) {
                return YES;
            }
        }
        
        return NO;
    }
                                                                selectionHandler:selectionHandler
                                                              deselectionHandler:deselectionHandler];
}

@end

#endif
