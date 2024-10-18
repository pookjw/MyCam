//
//  UIDeferredMenuElement+CaptureSession.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/19/24.
//

#import <CamPresentation/UIDeferredMenuElement+CaptureSession.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>

@implementation UIDeferredMenuElement (CaptureSession)

+ (instancetype)cp_captureSessionConfigurationElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            __kindof AVCaptureSession *captureSession = captureService.queue_captureSession;
            
            UIAction *toggleConfiguresApplicationAudioSessionToMixWithOthersAction = [UIDeferredMenuElement _cp_queue_toggleConfiguresApplicationAudioSessionToMixWithOthersActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            UIMenu *sessionPresetsMenu = [UIDeferredMenuElement _cp_queue_sessionPresetsMenuWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            
            NSArray<__kindof UIMenuElement *> *children = @[
                toggleConfiguresApplicationAudioSessionToMixWithOthersAction,
                sessionPresetsMenu
            ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(children);
            });
        });
    }];
    
    return element;
}

+ (UIAction *)_cp_queue_toggleConfiguresApplicationAudioSessionToMixWithOthersActionWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
    BOOL configuresApplicationAudioSessionToMixWithOthers = captureSession.configuresApplicationAudioSessionToMixWithOthers;
    
    UIAction *action = [UIAction actionWithTitle:@"Mix Audio With Others" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureSession beginConfiguration];
            captureSession.configuresApplicationAudioSessionToMixWithOthers = !configuresApplicationAudioSessionToMixWithOthers;
            [captureSession commitConfiguration];
        });
    }];
    
    action.state = configuresApplicationAudioSessionToMixWithOthers ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu *)_cp_queue_sessionPresetsMenuWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
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
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Session Presets" children:actions];
    [actions release];
    
    menu.subtitle = captureSession.sessionPreset;
    
    return menu;
}

@end
