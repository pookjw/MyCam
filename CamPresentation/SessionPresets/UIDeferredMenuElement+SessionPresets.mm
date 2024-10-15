//
//  UIDeferredMenuElement+SessionPresets.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/16/24.
//

#import <CamPresentation/UIDeferredMenuElement+SessionPresets.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation UIDeferredMenuElement (SessionPresets)

+ (instancetype)cp_sessionPresetsElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            __kindof AVCaptureSession * _Nullable captureSession = captureService.queue_captureSession;
            
            if (captureSession == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[]);
                });
                return;
            }
            
            NSArray<AVCaptureSessionPreset> *allSessionPresets = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(captureSession.class, sel_registerName("allSessionPresets"));
            
            NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:allSessionPresets.count];
            
            for (AVCaptureSessionPreset sessionPreset in allSessionPresets) {
                UIAction *action = [UIAction actionWithTitle:sessionPreset image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        [captureSession beginConfiguration];
                        captureSession.sessionPreset = sessionPreset;
                        [captureSession commitConfiguration];
                    });
                }];
                
                action.state = ([sessionPreset isEqualToString:captureSession.sessionPreset]) ? UIMenuElementStateOn : UIMenuElementStateOff;
                action.attributes = ([captureSession canSetSessionPreset:sessionPreset]) ? 0 : UIMenuElementAttributesDisabled;
                
                [actions addObject:action];
            }
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions];
            [actions release];
            
            menu.subtitle = captureSession.sessionPreset;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[menu]);
            });
        });
    }];
    
    return element;
}

@end
