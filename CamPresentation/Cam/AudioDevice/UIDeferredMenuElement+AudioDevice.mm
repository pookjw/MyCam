//
//  UIDeferredMenuElement+AudioDevice.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIDeferredMenuElement+AudioDevice.h>
#import <CamPresentation/NSStringFromAVCaptureMultichannelAudioMode.h>
#import <CamPresentation/NSStringFromAudioChannelLayoutTag.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#include <ranges>
#include <vector>

@implementation UIDeferredMenuElement (AudioDevice)

+ (UIDeferredMenuElement *)cp_audioDeviceElementWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
            
            [children addObject:[UIDeferredMenuElement _cp_multichannelAudioModeMenuWithWithCaptureService:captureService audioDevice:audioDevice didChangeHandler:didChangeHandler]];
            [children addObject:[UIDeferredMenuElement _cp_audioDataOutputsMenuWithCaptureService:captureService audioDevice:audioDevice didChangeHandler:didChangeHandler]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(children);
            });
            
            [children release];
        });
    }];
    
    return element;
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

+ (UIMenu *)_cp_audioDataOutputsMenuWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureAudioDataOutput *> *outputs = [captureService queue_outputsWithClass:[AVCaptureAudioDataOutput class] fromCaptureDevice:audioDevice];
    NSMutableArray<__kindof UIMenuElement *> *children = [[NSMutableArray alloc] initWithCapacity:outputs.count];
    
    {
        NSMutableArray<__kindof UIMenuElement *> *elements = [[NSMutableArray alloc] initWithCapacity:outputs.count];
        for (AVCaptureAudioDataOutput *output in outputs) {
            UIMenu *menu = [UIDeferredMenuElement _cp_audioDataOutputMenuWithCaptureService:captureService audioDevice:audioDevice audioDataOutput:output didChangeHandler:didChangeHandler];
            [elements addObject:menu];
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:elements];
        [elements release];
        [children addObject:menu];
    }
    
    {
        UIAction *action = [UIAction actionWithTitle:@"Add" image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_addAudioDataOutputWithAudioDevice:audioDevice];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        [children addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Data Outputs" children:children];
    [children release];
    
    return menu;
}

+ (UIMenu *)_cp_audioDataOutputMenuWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput didChangeHandler:(void (^)())didChangeHandler {
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
    
    {
        UIAction *action = [UIAction actionWithTitle:@"Remove" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_removeAudioDataOutput:audioDataOutput];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuOptionsDestructive;
        [children addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Data Output" children:children];
    [children release];
    return menu;
}

@end

#endif
