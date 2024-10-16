//
//  UIDeferredMenuElement+Audio.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <CamPresentation/UIDeferredMenuElement+Audio.h>
#import <CamPresentation/NSStringFromAVAudioSessionRouteSharingPolicy.h>
#import <CamPresentation/NSStringFromAVAudioSessionCategoryOptions.h>
#import <CamPresentation/AudioSessionRenderingModeInfoView.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <vector>
#include <ranges>

AVKIT_EXTERN const char * audit_stringMediaPlayer;

#warning TODO visionOS Spatial Experience
#warning 남은 기능 구현하기
#warning Options + Inputs

@implementation UIDeferredMenuElement (Audio)

+ (instancetype)cp_audioElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            AVAudioSession *audioSession = AVAudioSession.sharedInstance;
            
            UIMenu *categoriesMenu = [UIDeferredMenuElement _cp_audioSessionCategoriesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *modesMenu = [UIDeferredMenuElement _cp_audioSessionModesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *routeSharingPoliciesMenu = [UIDeferredMenuElement _cp_audioSessionRouteSharingPoliciesWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *activationMenu = [UIDeferredMenuElement _cp_audioSesssionActivationMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            __kindof UIMenuElement *renderingModeElement = [UIDeferredMenuElement _cp_audioSessionRenderingModeInfoElementWithAudioSession:audioSession];
            UIMenu *categoryOptionsMenu = [UIDeferredMenuElement _cp_audioSessionCategoryOptionsMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            __kindof UIMenuElement *preferredInputElement = [UIDeferredMenuElement _cp_audioSessionSetPreferredInputElementWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *inputDataSourcesMenu = [UIDeferredMenuElement _cp_audioSessionInputDataSourcesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *portPatternsForInputMenu = [UIDeferredMenuElement _cp_audioSessionPolarPatternsMenuForInputWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *outputDataSourcesMenu = [UIDeferredMenuElement _cp_audioSessionOutputDataSourcesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *portPatternsForOutputMenu = [UIDeferredMenuElement _cp_audioSessionPolarPatternsMenuForOutputWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            __kindof UIMenuElement *routePickerViewElement = [UIDeferredMenuElement _cp_routePickerViewElement];
            UIAction *routePickerAction = [UIDeferredMenuElement _cp_routePickerAction];
            
            NSArray<__kindof UIMenuElement *> *children = @[
                categoriesMenu,
                modesMenu,
                routeSharingPoliciesMenu,
                activationMenu,
                renderingModeElement,
                categoryOptionsMenu,
                preferredInputElement,
                inputDataSourcesMenu,
                portPatternsForInputMenu,
                outputDataSourcesMenu,
                portPatternsForOutputMenu,
                routePickerViewElement,
                routePickerAction
            ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(children);
            });
        });
    }];
    
    return element;
}

+ (UIMenu * _Nonnull)_cp_audioSessionCategoriesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionCategory> *availableCategories = audioSession.availableCategories;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableCategories.count];
    
    AVAudioSessionCategory currentCategory = audioSession.category;
    
    for (AVAudioSessionCategory category in availableCategories) {
        UIAction *action = [UIAction actionWithTitle:category image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [audioSession setCategory:category error:&error];
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        }];
        
        action.state = [category isEqualToString:currentCategory] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Category" children:actions];
    [actions release];
    
    menu.subtitle = currentCategory;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_audioSesssionActivationMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    BOOL isActive = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(session, sel_registerName("isActive"));
    
    if (isActive) {
        UIAction *withNotifyingOthersOnDeactivationAction = [UIAction actionWithTitle:@"Deactive (NotifyOthersOnDeactivation)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
            assert(error == nil);
        }];
        
        UIAction *action = [UIAction actionWithTitle:@"Deactive" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [session setActive:NO withOptions:0 error:&error];
            assert(error == nil);
        }];
        
        [children addObjectsFromArray:@[withNotifyingOthersOnDeactivationAction, action]];
    } else {
        UIAction *withNotifyingOthersOnDeactivationAction = [UIAction actionWithTitle:@"Active (NotifyOthersOnDeactivation)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
            assert(error == nil);
        }];
        
        UIAction *action = [UIAction actionWithTitle:@"Active" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [session setActive:YES withOptions:0 error:&error];
            assert(error == nil);
        }];
        
        [children addObjectsFromArray:@[withNotifyingOthersOnDeactivationAction, action]];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Activation" children:children];
    [children release];
    
    menu.subtitle = isActive ? @"Actived" : @"Deactivated";
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_audioSessionModesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionMode> *availableModes = audioSession.availableModes;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableModes.count];
    
    AVAudioSessionMode currentMode = audioSession.mode;
    
    for (AVAudioSessionMode mode in availableModes) {
        UIAction *action = [UIAction actionWithTitle:mode image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [audioSession setMode:mode error:&error];
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        }];
        
        action.state = [mode isEqualToString:currentMode] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Mode" children:actions];
    [actions release];
    
    menu.subtitle = currentMode;
    
    return menu;
}

+ (std::vector<AVAudioSessionRouteSharingPolicy>)_cp_allAudioSessionRouteSharingPolicies {
    return {
        AVAudioSessionRouteSharingPolicyDefault,
        AVAudioSessionRouteSharingPolicyLongFormAudio,
        AVAudioSessionRouteSharingPolicyLongFormVideo,
        AVAudioSessionRouteSharingPolicyIndependent
    };
}

+ (UIMenu * _Nonnull)_cp_audioSessionRouteSharingPoliciesWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionRouteSharingPolicy currentRouteSharingPolicy = audioSession.routeSharingPolicy;
    
    auto actionsVec = std::vector<AVAudioSessionRouteSharingPolicy> {
        AVAudioSessionRouteSharingPolicyDefault,
        AVAudioSessionRouteSharingPolicyLongFormAudio,
        AVAudioSessionRouteSharingPolicyLongFormVideo,
        AVAudioSessionRouteSharingPolicyIndependent
    }
    | std::views::transform([audioSession, currentRouteSharingPolicy](AVAudioSessionRouteSharingPolicy policy) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionRouteSharingPolicy(policy)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            AVAudioSessionCategoryOptions categoryOptions = audioSession.categoryOptions;
            
            NSError * _Nullable error = nil;
            [audioSession setCategory:audioSession.category
                                 mode:audioSession.mode
                   routeSharingPolicy:policy
                              options:categoryOptions
                                error:&error];
            assert(error == nil);
        }];
        
        action.state = (currentRouteSharingPolicy == policy) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Route Sharing Policy" children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVAudioSessionRouteSharingPolicy(currentRouteSharingPolicy);
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_audioSessionRenderingModeInfoElementWithAudioSession:(AVAudioSession *)audioSession {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        AudioSessionRenderingModeInfoView *view = [[AudioSessionRenderingModeInfoView alloc] initWithAudioSession:audioSession];
        return [view autorelease];
    });
    
    return element;
}

+ (std::vector<AVAudioSessionCategoryOptions>)_cp_audioSessionCategoryOptionsVector {
    return {
        AVAudioSessionCategoryOptionMixWithOthers,
        AVAudioSessionCategoryOptionDuckOthers,
        AVAudioSessionCategoryOptionAllowBluetooth,
        AVAudioSessionCategoryOptionDefaultToSpeaker,
        AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers,
        AVAudioSessionCategoryOptionAllowBluetoothA2DP,
        AVAudioSessionCategoryOptionAllowAirPlay,
        AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption
    };
}

+ (UIMenu * _Nonnull)_cp_audioSessionCategoryOptionsMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionCategoryOptions currentCategoryOptions = audioSession.categoryOptions;
    
    auto actionsVec = [UIDeferredMenuElement _cp_audioSessionCategoryOptionsVector]
    | std::views::transform([audioSession, didChangeHandler, currentCategoryOptions](AVAudioSessionCategoryOptions categoryOptions) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionCategoryOptions(categoryOptions)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            
            AVAudioSessionCategoryOptions newCategoryOptions;
            if ((currentCategoryOptions & categoryOptions) == categoryOptions) {
                newCategoryOptions = (currentCategoryOptions & ~categoryOptions);
                
                if (categoryOptions == AVAudioSessionCategoryOptionMixWithOthers) {
                    newCategoryOptions &= ~AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers;
                }
            } else {
                newCategoryOptions = (currentCategoryOptions | categoryOptions);
            }
            
            reinterpret_cast<void (*)(id, SEL, AVAudioSessionCategoryOptions, id *)>(objc_msgSend)(audioSession, sel_registerName("setCategoryOptions:error:"), newCategoryOptions, &error);
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        }];
        
        action.state = ((currentCategoryOptions & categoryOptions) == categoryOptions) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Category Options" children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVAudioSessionCategoryOptions(currentCategoryOptions);
    menu.cp_overrideNumberOfSubtitleLines = 0;
    
    return menu;
}

#warning Output
+ (__kindof UIMenuElement *)_cp_audioSessionSetPreferredInputElementWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    if (!audioSession.inputAvailable) {
        UIAction *action = [UIAction actionWithTitle:@"Input Unavailable" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.attributes = UIMenuElementAttributesDisabled;
        
        return action;
    }
    
    NSArray<AVAudioSessionPortDescription *> *availableInputs = audioSession.availableInputs;
    NSMutableArray<UIAction *> *actions = [NSMutableArray new];
    
    AVAudioSessionPortDescription *preferredInput = audioSession.preferredInput;
    
    for (AVAudioSessionPortDescription *description in availableInputs) {
        UIAction *action = [UIAction actionWithTitle:description.portName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [audioSession setPreferredInput:description error:&error];
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        }];
        
        action.subtitle = [NSString stringWithFormat:@"%@, spatialAudioEnabled : %d", description.UID, description.spatialAudioEnabled];
        action.state = ([description isEqual:preferredInput]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Preferred Input" children:actions];
    [actions release];
    
    menu.subtitle = preferredInput.portName;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_audioSessionInputDataSourcesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionDataSourceDescription *> *inputDataSources = audioSession.inputDataSources;
    AVAudioSessionDataSourceDescription *inputDataSource = audioSession.inputDataSource;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:inputDataSources.count];
    
    for (AVAudioSessionDataSourceDescription *description in inputDataSources) {
        UIAction *action = [UIAction actionWithTitle:description.dataSourceName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [audioSession setInputDataSource:description error:&error];
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        }];
        
        action.subtitle = description.dataSourceID.stringValue;
        action.state = ([inputDataSource isEqual:description]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Input Data Source" children:actions];
    [actions release];
    
    menu.subtitle = inputDataSource.dataSourceName;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_audioSessionPolarPatternsMenuForInputWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionDataSourceDescription *inputDataSource = audioSession.inputDataSource;
    NSArray<AVAudioSessionPolarPattern> *supportedPolarPatterns = inputDataSource.supportedPolarPatterns;
    AVAudioSessionPolarPattern selectedPolarPattern = inputDataSource.selectedPolarPattern;
    AVAudioSessionPolarPattern preferredPolarPattern = inputDataSource.preferredPolarPattern;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedPolarPatterns.count];
    
    for (AVAudioSessionPolarPattern polorPattern in supportedPolarPatterns) {
        UIAction *action = [UIAction actionWithTitle:polorPattern image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [inputDataSource setPreferredPolarPattern:polorPattern error:&error];
            assert(error == nil);
        }];
        
        if ([selectedPolarPattern isEqualToString:polorPattern]) {
            action.state = UIMenuElementStateOn;
        } else if ([preferredPolarPattern isEqualToString:polorPattern]) {
            action.state = UIMenuElementStateMixed;
        } else {
            action.state = UIMenuElementStateOff;
        }
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Polar Pattern" children:actions];
    [actions release];
    
    menu.subtitle = selectedPolarPattern;
    
    return menu;
}

#warning HomePod로 하면 뭔가 될지도?
+ (UIMenu * _Nonnull)_cp_audioSessionOutputDataSourcesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionDataSourceDescription *> *outputDataSources = audioSession.outputDataSources;
    AVAudioSessionDataSourceDescription *outputDataSource = audioSession.outputDataSource;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:outputDataSources.count];
    
    for (AVAudioSessionDataSourceDescription *description in outputDataSources) {
        UIAction *action = [UIAction actionWithTitle:description.dataSourceName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [audioSession setOutputDataSource:description error:&error];
            assert(error == nil);
        }];
        
        action.subtitle = description.dataSourceID.stringValue;
        action.state = ([outputDataSource isEqual:description]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:outputDataSource.dataSourceName children:actions];
    [actions release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_audioSessionPolarPatternsMenuForOutputWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionDataSourceDescription *outputDataSource = audioSession.outputDataSource;
    NSArray<AVAudioSessionPolarPattern> *supportedPolarPatterns = outputDataSource.supportedPolarPatterns;
    AVAudioSessionPolarPattern selectedPolarPattern = outputDataSource.selectedPolarPattern;
    AVAudioSessionPolarPattern preferredPolarPattern = outputDataSource.preferredPolarPattern;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedPolarPatterns.count];
    
    for (AVAudioSessionPolarPattern polorPattern in supportedPolarPatterns) {
        UIAction *action = [UIAction actionWithTitle:polorPattern image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            [outputDataSource setPreferredPolarPattern:polorPattern error:&error];
            assert(error == nil);
        }];
        
        if ([selectedPolarPattern isEqualToString:polorPattern]) {
            action.state = UIMenuElementStateOn;
        } else if ([preferredPolarPattern isEqualToString:polorPattern]) {
            action.state = UIMenuElementStateMixed;
        } else {
            action.state = UIMenuElementStateOff;
        }
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Polar Pattern" children:actions];
    [actions release];
    
    menu.subtitle = selectedPolarPattern;
    
    return menu;
}

+ (__kindof UIMenuElement * _Nonnull)_cp_routePickerViewElement {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        AVRoutePickerView *view = [AVRoutePickerView new];
        return [view autorelease];
    });
    
    return element;
}

+ (UIAction * _Nonnull)_cp_routePickerAction {
    UIAction *action = [UIAction actionWithTitle:@"Present Route Picker" image:[UIImage systemImageNamed:@"airplay.audio"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
#warning dlopen 어케 하는지 보기
        assert(dlopen("/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer", RTLD_NOW));
        // TODO: https://developer.apple.com/documentation/avrouting/avcustomroutingcontroller?language=objc
        id controls = [[objc_lookUpClass("MPMediaControls") alloc] init];
        
#warning configuration -[AVRoutePickerView _routePickerButtonTapped:]
        reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controls, sel_registerName("startPrewarming"));
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(controls, sel_registerName("setDismissHandler:"), ^{
            
        });
        reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controls, sel_registerName("present"));
        [controls release];
    }];
    
    return action;
}

// AVAusioApplication Mute
//+ (UIAction * _Nonnull)

@end
