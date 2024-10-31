//
//  UIDeferredMenuElement+CaptureSession.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/19/24.
//

#import <CamPresentation/UIDeferredMenuElement+CaptureSession.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

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
            UIAction *toggleUsesApplicationAudioSessionAction = [UIDeferredMenuElement _cp_queue_toggleUsesApplicationAudioSessionActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            UIAction *toggleAutomaticallyConfiguresApplicationAudioSessionAction = [UIDeferredMenuElement _cp_queue_toggleAutomaticallyConfiguresApplicationAudioSessionActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            UIAction *toggleMultitaskingCameraAccessEnabledAction = [UIDeferredMenuElement _cp_queue_toggleMultitaskingCameraAccessEnabledActionWithCaptureService:captureService captureSession:captureSession didChangeHandler:didChangeHandler];
            
            NSArray<__kindof UIMenuElement *> *children = @[
                toggleUsesApplicationAudioSessionAction,
                toggleAutomaticallyConfiguresApplicationAudioSessionAction,
                toggleConfiguresApplicationAudioSessionToMixWithOthersAction,
                sessionPresetsMenu,
                toggleMultitaskingCameraAccessEnabledAction
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

+ (UIAction *)_cp_queue_toggleUsesApplicationAudioSessionActionWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
    BOOL usesApplicationAudioSession = captureSession.usesApplicationAudioSession;
    
    UIAction *action = [UIAction actionWithTitle:@"Uses Application Audio Session" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            captureSession.usesApplicationAudioSession = !usesApplicationAudioSession;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = usesApplicationAudioSession ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction *)_cp_queue_toggleAutomaticallyConfiguresApplicationAudioSessionActionWithCaptureService:(CaptureService *)captureService captureSession:(AVCaptureSession *)captureSession didChangeHandler:(void (^)())didChangeHandler {
    BOOL usesApplicationAudioSession = captureSession.usesApplicationAudioSession;
    BOOL automaticallyConfiguresApplicationAudioSession = captureSession.automaticallyConfiguresApplicationAudioSession;
    
    UIAction *action = [UIAction actionWithTitle:@"Automatically Configures Application Audio Session" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            captureSession.automaticallyConfiguresApplicationAudioSession = !automaticallyConfiguresApplicationAudioSession;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = automaticallyConfiguresApplicationAudioSession ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = usesApplicationAudioSession ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

@end

#endif
