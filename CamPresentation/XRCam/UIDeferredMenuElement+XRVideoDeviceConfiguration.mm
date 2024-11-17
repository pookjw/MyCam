//
//  UIDeferredMenuElement+XRVideoDeviceConfiguration.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/17/24.
//

#import <CamPresentation/UIDeferredMenuElement+XRVideoDeviceConfiguration.h>
#import <CamPresentation/XRCaptureService.h>
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            
            [elements release];
        });
    }];
}

@end
