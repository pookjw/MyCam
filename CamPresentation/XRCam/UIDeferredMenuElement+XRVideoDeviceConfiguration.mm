//
//  UIDeferredMenuElement+XRVideoDeviceConfiguration.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <CamPresentation/UIDeferredMenuElement+XRVideoDeviceConfiguration.h>
#import <CamPresentation/XRCaptureService.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace cp {
namespace xr {
namespace deviceConfiguration {

UIMenu *setMetadataObjectTypesMenu(XRCaptureService *captureService, AVCaptureDevice *videoDevice, void (^ _Nullable didChangeHandler)()) {
    NSSet<__kindof AVCaptureOutput *> *metadataOutputs = [captureService queue_outputClass:objc_lookUpClass("AVCaptureMetadataOutput") fromCaptureDevice:videoDevice];
    assert(metadataOutputs.count == 1);
    __kindof AVCaptureOutput *metadataOutput = metadataOutputs.allObjects[0];
    
    NSArray<NSString *> *availableMetadataObjectTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("availableMetadataObjectTypes"));
    NSArray<NSString *> *metadataObjectTypes = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("metadataObjectTypes"));
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableMetadataObjectTypes.count];
    
    for (NSString *type in availableMetadataObjectTypes) {
        BOOL isAdded = [metadataObjectTypes containsObject:type];
        
        UIAction *action = [UIAction actionWithTitle:type image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSMutableArray<NSString *> *metadataObjectTypes = [reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("metadataObjectTypes")) mutableCopy];
                
                if (isAdded) {
                    [metadataObjectTypes removeObject:type];
                } else {
                    [metadataObjectTypes addObject:type];
                }
                
                reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(metadataOutput, sel_registerName("setMetadataObjectTypes:"), metadataObjectTypes);
                [metadataObjectTypes release];
            });
        }];
        
        action.state = isAdded ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Metadata Object Types" children:actions];
    [actions release];
    
    return menu;
}

UIMenu *formatsMenu(XRCaptureService *captureService, AVCaptureDevice *videoDevice, NSString *title, BOOL includeSubtitle, BOOL (^ _Nullable filterHandler)(AVCaptureDeviceFormat *format), void (^ _Nullable didChangeHandler)()) {
    NSArray<AVCaptureDeviceFormat *> *formats = videoDevice.formats;
    AVCaptureDeviceFormat *activeFormat = videoDevice.activeFormat;
    NSMutableArray<UIAction *> *formatActions = [NSMutableArray new];
    
    [formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([captureService.captureSession isKindOfClass:AVCaptureMultiCamSession.class] && !format.multiCamSupported) {
            return;
        }
        
        if (filterHandler) {
            if (!filterHandler(format)) return;
        }
        
        UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [videoDevice lockForConfiguration:&error];
                assert(error == nil);
                videoDevice.activeFormat = format;
                [videoDevice unlockForConfiguration];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.cp_overrideNumberOfTitleLines = 0;
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [formatActions addObject:action];
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:title
                                   image:nil
                              identifier:nil
                                 options:0
                                children:formatActions];
    [formatActions release];
    
    if (includeSubtitle) {
        menu.subtitle = activeFormat.debugDescription;
    }
    
    menu.cp_overrideNumberOfTitleLines = 0;
    
    return menu;
}

}
}
}

@implementation UIDeferredMenuElement (XRVideoDeviceConfiguration)

+ (instancetype)cp_xr_videoDeviceConfigurationElementWithCaptureService:(XRCaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
            
            using namespace cp::xr::deviceConfiguration;
            
            [elements addObject:setMetadataObjectTypesMenu(captureService, videoDevice, didChangeHandler)];
            [elements addObject:formatsMenu(captureService, videoDevice, @"Formats", YES, nil, didChangeHandler)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            
            [elements release];
        });
    }];
}

@end

#endif
