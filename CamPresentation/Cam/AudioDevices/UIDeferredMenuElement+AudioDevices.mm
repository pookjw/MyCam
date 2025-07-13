//
//  UIDeferredMenuElement+AudioDevices.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIDeferredMenuElement+AudioDevices.h>
#import <CamPresentation/NSStringFromAVCaptureMultichannelAudioMode.h>
#import <CamPresentation/NSStringFromAudioChannelLayoutTag.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#include <ranges>
#include <vector>

@implementation UIDeferredMenuElement (AudioDevices)

+ (UIDeferredMenuElement *)cp_audioDevicesElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSArray<AVCaptureDevice *> *audioDevices = captureService.queue_addedAudioCaptureDevices;
            
            if (audioDevices.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAction *action = [UIAction actionWithTitle:@"No Added Audio Device" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
                    action.attributes = UIMenuElementAttributesDisabled;
                    completion(@[action]);
                });
                return;
            }
            
            //
            
            NSMutableArray<__kindof UIMenuElement *> *elements = [[NSMutableArray alloc] initWithCapacity:audioDevices.count];
            
            for (AVCaptureDevice *audioDevice in audioDevices) {
                [elements addObject:[UIDeferredMenuElement _cp_audioDeviceMenuWithCaptureService:captureService audioDevice:audioDevice didChangeHandler:didChangeHandler]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            [elements release];
        });
    }];
    
    return element;
}

+ (UIMenu *)_cp_audioDeviceMenuWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^)())didChangeHandler {
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    [children addObject:[UIDeferredMenuElement _cp_multichannelAudioModeMenuWithWithCaptureService:captureService audioDevice:audioDevice didChangeHandler:didChangeHandler]];
    [children addObject:[UIDeferredMenuElement _cp_audioDataOutputMenuWithCaptureService:captureService audioDevice:audioDevice didChangeHandler:didChangeHandler]];
    
    UIMenu *menu = [UIMenu menuWithTitle:audioDevice.localizedName children:children];
    [children release];
    
    return menu;
}

+ (UIMenu *)_cp_multichannelAudioModeMenuWithWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^)())didChangeHandler {
    auto actionsVec = std::vector<AVCaptureMultichannelAudioMode> {
        AVCaptureMultichannelAudioModeNone,
        AVCaptureMultichannelAudioModeStereo,
        AVCaptureMultichannelAudioModeFirstOrderAmbisonics
    }
    | std::views::transform([captureService, audioDevice, didChangeHandler](AVCaptureMultichannelAudioMode mode) -> UIAction * {
        NSSet<AVCaptureDeviceInput *> *inputs = [captureService queue_addedDeviceInputsFromCaptureDevice:audioDevice];
        assert(inputs.count == 1);
        AVCaptureDeviceInput *input = inputs.allObjects[0];
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureMultichannelAudioMode(mode) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService.queue_captureSession beginConfiguration];
                input.multichannelAudioMode = mode;
                [captureService.queue_captureSession commitConfiguration];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = ([input isMultichannelAudioModeSupported:mode]) ? 0 : UIMenuElementAttributesDisabled;
        action.state = (input.multichannelAudioMode == mode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    UIMenu *menu = [UIMenu menuWithTitle:@"Multichannel Audio Mode" children:actions];
    [actions release];
    
    return menu;
}

+ (UIMenu *)_cp_audioDataOutputMenuWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureAudioDataOutput *audioDataOutput = [captureService queue_outputWithClass:[AVCaptureAudioDataOutput class] fromCaptureDevice:audioDevice];
    assert(audioDataOutput != nil);
    
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
        AudioChannelLayoutTag spatialAudioChannelLayoutTag = audioDataOutput.spatialAudioChannelLayoutTag;
        NSArray<NSNumber *> *allTags = allAudioChannelLayoutTags();
        NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:allTags.count];
        
        for (NSNumber *tagNumber in allTags) {
            NSString *string = NSStringFromAudioChannelLayoutTag(tagNumber.unsignedIntValue);
            
            UIAction *action = [UIAction actionWithTitle:string image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                abort();
            }];
            
            action.cp_overrideNumberOfTitleLines = 0;
            action.state = ((spatialAudioChannelLayoutTag & tagNumber.unsignedIntValue) == spatialAudioChannelLayoutTag) ? UIMenuElementStateOn : UIMenuElementStateOff;
            [actions addObject:action];
        }
        
        [children addObject:[UIMenu menuWithTitle:@"Spatial Audio Channel Layout Tag" children:actions]];
        [actions release];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Data Output" children:children];
    return menu;
}

@end

#endif
