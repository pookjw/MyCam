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
#import <TargetConditionals.h>

@implementation UIDeferredMenuElement (CaptureSession)

+ (instancetype)cp_captureSessionConfigurationElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            __kindof AVCaptureSession *captureSession = captureService.queue_captureSession;
            
            NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
            
#if !TARGET_OS_VISION
            UIAction *toggleConfiguresApplicationAudioSessionToMixWithOthersAction = [UIDeferredMenuElement _cp_queue_toggleConfiguresApplicationAudioSessionToMixWithOthersActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            
            [children addObect:toggleConfiguresApplicationAudioSessionToMixWithOthersAction];
#endif
            
            UIMenu *sessionPresetsMenu = [UIDeferredMenuElement _cp_queue_sessionPresetsMenuWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            [children addObject:sessionPresetsMenu];
            
#if !TARGET_OS_VISION
            UIAction *toggleMultitaskingCameraAccessEnabledAction = [UIDeferredMenuElement _cp_queue_toggleMultitaskingCameraAccessEnabledActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            [children addObject:toggleMultitaskingCameraAccessEnabledAction];
#endif
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(children);
            });
            
            [children release];
        });
    }];
    
    return element;
}

#if !TARGET_OS_VISION
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
#endif

+ (UIMenu *)_cp_queue_sessionPresetsMenuWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureSessionPreset> *allSessionPresets = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(captureSession.class, sel_registerName("allSessionPresets"));
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:allSessionPresets.count];
    
#if TARGET_OS_VISION
    NSString *currentSessionPreset = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(captureSession, sel_registerName("sessionPreset"));
#else
    AVCaptureSessionPreset currentSessionPreset = captureSession.sessionPreset;
#endif
    
#if TARGET_OS_VISION
    for (NSString *sessionPreset in allSessionPresets) {
#else
    for (AVCaptureSessionPreset sessionPreset in allSessionPresets) {
#endif
        UIAction *action = [UIAction actionWithTitle:sessionPreset image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureSession beginConfiguration];
                
#if TARGET_OS_VISION
                reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(captureSession, sel_registerName("setSessionPreset:"), sessionPreset);
#else
                captureSession.sessionPreset = sessionPreset;
#endif
                
                [captureSession commitConfiguration];
            });
        }];
        
        action.state = ([sessionPreset isEqualToString:currentSessionPreset]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        BOOL canSetSessionPreset;
#if TARGET_OS_VISION
        canSetSessionPreset = reinterpret_cast<BOOL (*)(id, SEL, id)>(objc_msgSend)(captureSession, sel_registerName("canSetSessionPreset:"), sessionPreset);
#else
        canSetSessionPreset = [captureSession canSetSessionPreset:sessionPreset];
#endif
        
        action.attributes = canSetSessionPreset ? 0 : UIMenuElementAttributesDisabled;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Session Presets" children:actions];
    [actions release];
    
    menu.subtitle = currentSessionPreset;
    
    return menu;
}

#if !TARGET_OS_VISION
+ (UIAction *)_cp_queue_toggleMultitaskingCameraAccessEnabledActionWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
    BOOL isMultitaskingCameraAccessEnabled = captureSession.isMultitaskingCameraAccessEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Multitasking Camera" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureSession beginConfiguration];
            captureSession.multitaskingCameraAccessEnabled = !isMultitaskingCameraAccessEnabled;
            [captureSession commitConfiguration];
        });
    }];
    
    action.state = isMultitaskingCameraAccessEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = captureSession.isMultitaskingCameraAccessSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}
#endif

@end
