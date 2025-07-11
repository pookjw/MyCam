//
//  UIDeferredMenuElement+Audio.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <CamPresentation/UIDeferredMenuElement+Audio.h>
#import <CamPresentation/NSStringFromAVAudioSessionRouteSharingPolicy.h>
#import <CamPresentation/NSStringFromAVAudioSessionCategoryOptions.h>
#import <CamPresentation/NSStringFromAVAudioStereoOrientation.h>
#import <CamPresentation/NSStringFromAVAudioSessionPortOverride.h>
#import <CamPresentation/NSStringFromAVAudioSessionIOType.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/AudioSessionInfoView.h>
#import <CamPresentation/VolumeSlider.h>
#import <CamPresentation/VolumeStepper.h>
#import <CamPresentation/TVSlider.h>
#import <CamPresentation/TVStepper.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <vector>
#include <ranges>
#import <TargetConditionals.h>
#import <CamPresentation/AudioInputPickerView.h>

#warning TODO visionOS Spatial Experience
#warning 남은 기능 구현하기
#warning Options + Inputs
#warning Player (https://developer.apple.com/videos/play/wwdc2019/501)

@implementation UIDeferredMenuElement (Audio)

static id<NSObject> muteToken;
static id<NSObject> unmuteToken;
static id<NSObject> availableInputsChangeToken;

+ (void)load {
#if TARGET_OS_IOS
    if (@available(iOS 26.0, *)) {
        muteToken = [[NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionOutputMuteStateChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
            NSLog(@"%@", notification);
        }] retain];
        
        unmuteToken = [[NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionUserIntentToUnmuteOutputNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
            NSLog(@"%@", notification);
        }] retain];
        
        availableInputsChangeToken = [[NSNotificationCenter.defaultCenter addObserverForName:AVAudioSessionAvailableInputsChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
            NSLog(@"%@", notification);
        }] retain];
    }
#endif
}

+ (instancetype)cp_audioElementWithDidChangeHandler:(void (^ _Nullable)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // auxiliarySession primarySession
            AVAudioSession *audioSession = AVAudioSession.sharedInstance;
            
            UIMenu *categoriesMenu = [UIDeferredMenuElement _cp_categoriesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *modesMenu = [UIDeferredMenuElement _cp_modesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *routeSharingPoliciesMenu = [UIDeferredMenuElement _cp_routeSharingPoliciesWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *activationMenu = [UIDeferredMenuElement _cp_activationMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *categoryOptionsMenu = [UIDeferredMenuElement _cp_categoryOptionsMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            __kindof UIMenuElement *preferredInputElement = [UIDeferredMenuElement _cp_setPreferredInputElementWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *inputDataSourcesMenu = [UIDeferredMenuElement _cp_inputDataSourcesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *outputDataSourcesMenu = [UIDeferredMenuElement _cp_outputDataSourcesMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            
#if !TARGET_OS_VISION
            __kindof UIMenuElement *routePickerViewElement = [UIDeferredMenuElement _cp_routePickerViewElement];
#endif
            
            UIAction *routePickerAction = [UIDeferredMenuElement _cp_routePickerAction];
            __kindof UIMenuElement *audioSessionInfoViewElement = [UIDeferredMenuElement _cp_infoViewElementWithAudioSession:audioSession];
            UIAction *allowHapticsAndSystemSoundsDuringRecordingAction = [UIDeferredMenuElement _cp_allowHapticsAndSystemSoundsDuringRecordingActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            
#if !TARGET_OS_VISION && !TARGET_OS_TV
            UIAction *generateImpactFeecbackAction = [UIDeferredMenuElement _cp_generateImpactFeecbackAction];
#endif
            
#if TARGET_OS_IOS
            UIAction *prepareRouteSelectionForPlaybackAction = [UIDeferredMenuElement _cp_prepareRouteSelectionForPlaybackActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
#endif
            
            UIAction *setPrefersNoInterruptionsFromSystemAlertsAction = [UIDeferredMenuElement _cp_setPrefersNoInterruptionsFromSystemAlertsActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIAction *setPrefersInterruptionOnRouteDisconnectAction = [UIDeferredMenuElement _cp_setPrefersInterruptionOnRouteDisconnectActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            
#if !TARGET_OS_TV
            UIMenu *inputOrientationsMenu = [UIDeferredMenuElement _cp_inputOrientationsMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
#endif
            
            __kindof UIMenuElement *setPreferredSampleRateElement = [UIDeferredMenuElement _cp_setPreferredSampleRateElementWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            __kindof UIMenuElement *setInputGainElement = [UIDeferredMenuElement _cp_setInputGainElementWithAudioSession:audioSession];
            __kindof UIMenuElement *setPreferredIOBufferDurationElement = [UIDeferredMenuElement _cp_setPreferredIOBufferDurationElementWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            
#if !TARGET_OS_TV
            UIMenu *volumeControlsMenu = [UIDeferredMenuElement _cp_volumeControlsMenu];
#endif
            
            UIMenu *numberOfChannelsSteppersMenuWithAudioSession = [UIDeferredMenuElement _cp_numberOfChannelsSteppersMenuWithAudioSession:audioSession];
            UIAction *setSupportsMultichannelContentWithAudioSession = [UIDeferredMenuElement _cp_setSupportsMultichannelContentActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *currentRouteMenu = [UIDeferredMenuElement _cp_currentRouteMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIMenu *overrideOutputAudioPortMenu = [UIDeferredMenuElement _cp_overrideOutputAudioPortMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            
#if !TARGET_OS_TV
            UIMenu *aggregatedIOPreferenceMenu = [UIDeferredMenuElement _cp_aggregatedIOPreferenceMenuWithAudioSession:audioSession didChangeHandler:didChangeHandler];
            UIAction *togglePrefersEchoCancelledInputAction = [UIDeferredMenuElement _cp_togglePrefersEchoCancelledInputActionWithAudioSession:audioSession didChangeHandler:didChangeHandler];
#endif
            
            NSMutableArray<__kindof UIMenuElement *> *children = [[NSMutableArray alloc] initWithArray:@[
                categoriesMenu,
                modesMenu,
                routeSharingPoliciesMenu,
                activationMenu,
                categoryOptionsMenu,
                preferredInputElement,
                inputDataSourcesMenu,
                outputDataSourcesMenu,
#if !TARGET_OS_VISION
                routePickerViewElement,
#endif
                routePickerAction,
                audioSessionInfoViewElement,
                allowHapticsAndSystemSoundsDuringRecordingAction,
#if !TARGET_OS_VISION && !TARGET_OS_TV
                generateImpactFeecbackAction,
#endif
                
#if TARGET_OS_IOS
                prepareRouteSelectionForPlaybackAction,
#endif
                setPrefersNoInterruptionsFromSystemAlertsAction,
                setPrefersInterruptionOnRouteDisconnectAction,
#if !TARGET_OS_TV
                inputOrientationsMenu,
#endif
                setPreferredSampleRateElement,
                setInputGainElement,
                setPreferredIOBufferDurationElement,
#if !TARGET_OS_TV
                volumeControlsMenu,
#endif
                numberOfChannelsSteppersMenuWithAudioSession,
                setSupportsMultichannelContentWithAudioSession,
                currentRouteMenu,
                overrideOutputAudioPortMenu,
#if !TARGET_OS_TV
                aggregatedIOPreferenceMenu,
                togglePrefersEchoCancelledInputAction
#endif
            ]];
            
            if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                [children addObject:[UIDeferredMenuElement _cp_toggleOutputMutedActionWithAudioSession:audioSession didChangeHandler:didChangeHandler]];
                [children addObject:[UIDeferredMenuElement _cp_inputPickerInteractionMenuWithAudioSession:audioSession]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(children);
            });
            
            [children release];
        });
    }];
    
    return element;
}

+ (UIMenu * _Nonnull)_cp_categoriesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionCategory> *availableCategories = audioSession.availableCategories;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableCategories.count];
    
    AVAudioSessionCategory currentCategory = audioSession.category;
    
    for (AVAudioSessionCategory category in availableCategories) {
        UIAction *action = [UIAction actionWithTitle:category image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setCategory:category error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = [category isEqualToString:currentCategory] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Category" children:actions];
    [actions release];
    
    menu.subtitle = currentCategory;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_activationMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    BOOL isActive = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(session, sel_registerName("isActive"));
    
    if (isActive) {
        UIAction *withNotifyingOthersOnDeactivationAction = [UIAction actionWithTitle:@"Deactive (NotifyOthersOnDeactivation)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        withNotifyingOthersOnDeactivationAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        UIAction *action = [UIAction actionWithTitle:@"Deactive" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [session setActive:NO withOptions:0 error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        [children addObjectsFromArray:@[withNotifyingOthersOnDeactivationAction, action]];
    } else {
        UIAction *withNotifyingOthersOnDeactivationAction = [UIAction actionWithTitle:@"Active (NotifyOthersOnDeactivation)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        withNotifyingOthersOnDeactivationAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        UIAction *action = [UIAction actionWithTitle:@"Active" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [session setActive:YES withOptions:0 error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        [children addObjectsFromArray:@[withNotifyingOthersOnDeactivationAction, action]];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Activation" children:children];
    [children release];
    
    menu.subtitle = isActive ? @"Actived" : @"Deactivated";
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_modesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionMode> *availableModes = audioSession.availableModes;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableModes.count];
    
    AVAudioSessionMode currentMode = audioSession.mode;
    
    for (AVAudioSessionMode mode in availableModes) {
        UIAction *action = [UIAction actionWithTitle:mode image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setMode:mode error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
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
#if !TARGET_OS_TV
        AVAudioSessionRouteSharingPolicyLongFormVideo,
#endif
        AVAudioSessionRouteSharingPolicyIndependent
    };
}

+ (UIMenu * _Nonnull)_cp_routeSharingPoliciesWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionRouteSharingPolicy currentRouteSharingPolicy = audioSession.routeSharingPolicy;
    
    auto actionsVec = std::vector<AVAudioSessionRouteSharingPolicy> {
        AVAudioSessionRouteSharingPolicyDefault,
        AVAudioSessionRouteSharingPolicyLongFormAudio,
#if !TARGET_OS_TV
        AVAudioSessionRouteSharingPolicyLongFormVideo,
#endif
        AVAudioSessionRouteSharingPolicyIndependent
    }
    | std::views::transform([audioSession, currentRouteSharingPolicy, didChangeHandler](AVAudioSessionRouteSharingPolicy policy) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionRouteSharingPolicy(policy)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                AVAudioSessionCategoryOptions categoryOptions = audioSession.categoryOptions;
                
                NSError * _Nullable error = nil;
                [audioSession setCategory:audioSession.category
                                     mode:audioSession.mode
                       routeSharingPolicy:policy
                                  options:categoryOptions
                                    error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
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

+ (std::vector<AVAudioSessionCategoryOptions>)_cp_CategoryOptionsVector {
    std::vector<AVAudioSessionCategoryOptions> options {
        AVAudioSessionCategoryOptionMixWithOthers,
        AVAudioSessionCategoryOptionDuckOthers,
        AVAudioSessionCategoryOptionAllowBluetooth,
#if !TARGET_OS_TV
        AVAudioSessionCategoryOptionDefaultToSpeaker,
#endif
        AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers,
        AVAudioSessionCategoryOptionAllowBluetoothA2DP,
        AVAudioSessionCategoryOptionAllowAirPlay,
#if !TARGET_OS_TV
        AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption
#endif
    };
    
    if (@available(iOS 26.0, *)) {
#if TARGET_OS_IOS
        options.push_back(AVAudioSessionCategoryOptionBluetoothHighQualityRecording);
#else
        options.push_back(1 << 19);
#endif
    } else if (@available(watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, macOS 26.0, *)) {
        options.push_back(1 << 19);
    }
    
    return options;
}

+ (UIMenu * _Nonnull)_cp_categoryOptionsMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSessionCategoryOptions currentCategoryOptions = audioSession.categoryOptions;
    
    auto actionsVec = [UIDeferredMenuElement _cp_CategoryOptionsVector]
    | std::views::transform([audioSession, didChangeHandler, currentCategoryOptions](AVAudioSessionCategoryOptions categoryOptions) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionCategoryOptions(categoryOptions)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
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
            });
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

+ (__kindof UIMenuElement *)_cp_setPreferredInputElementWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
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
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredInput:description error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        NSMutableString *subtitle = [NSMutableString new];
        [subtitle appendFormat:@"%@", description.UID];
        [subtitle appendString:@"\n"];
        [subtitle appendFormat:@"spatialAudioEnabled : %d", description.spatialAudioEnabled];
        
        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *)) {
            AVAudioSessionPortExtensionBluetoothMicrophone *bluetoothMicrophoneExtension = description.bluetoothMicrophoneExtension;
            AVAudioSessionCapability *highQualityRecording = bluetoothMicrophoneExtension.highQualityRecording;
            [subtitle appendString:@"\n"];
            [subtitle appendFormat:@"High Quality Recording Supported : %d", highQualityRecording.supported];
            [subtitle appendString:@"\n"];
            [subtitle appendFormat:@"High Quality Recording Enabled : %d", highQualityRecording.enabled];
        }
        
        action.subtitle = subtitle;
        [subtitle release];
        
        action.cp_overrideNumberOfSubtitleLines = 0;
        
        action.state = ([description isEqual:preferredInput]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Preferred Input" children:actions];
    [actions release];
    
    menu.subtitle = preferredInput.portName;
    
    return menu;
}

#if !TARGET_OS_VISION

+ (__kindof UIMenuElement * _Nonnull)_cp_routePickerViewElement {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        AVRoutePickerView *view = [AVRoutePickerView new];
#warning TODO
        view.prioritizesVideoDevices = YES;
        return [view autorelease];
    });
    
    return element;
}
#endif

+ (UIAction * _Nonnull)_cp_routePickerAction {
    UIAction *action = [UIAction actionWithTitle:@"Present Route Picker" image:[UIImage systemImageNamed:@"airplay.audio"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        assert(dlopen("/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer", RTLD_NOW) != nullptr);
        
        /*
         TODO: https://developer.apple.com/documentation/avrouting/avcustomroutingcontroller?language=objc
         -[AVRoutePickerView _routePickerButtonTapped:]를 보면 알 수 있음
         */
        id controls = [[objc_lookUpClass("MPMediaControls") alloc] init];
        
        id configuration = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(controls, sel_registerName("configuration"));
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(configuration, sel_registerName("setSortByIsVideoRoute:"), NO);
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(configuration, @selector(setValue:forKey:), @NO, @"useGenericDevicesIconInHeader");
        
        reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controls, sel_registerName("startPrewarming"));
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(controls, sel_registerName("setDismissHandler:"), ^{
            
        });
        reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(controls, sel_registerName("present"));
        [controls release];
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    
    return action;
}

+ (__kindof UIMenuElement * _Nonnull)_cp_infoViewElementWithAudioSession:(AVAudioSession *)audioSession {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        AudioSessionInfoView *view = [[AudioSessionInfoView alloc] initWithAudioSession:audioSession];
        return [view autorelease];
    });
    
    return element;
}

+ (UIAction * _Nonnull)_cp_allowHapticsAndSystemSoundsDuringRecordingActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    BOOL allowHapticsAndSystemSoundsDuringRecording = audioSession.allowHapticsAndSystemSoundsDuringRecording;
    
    UIAction *action = [UIAction actionWithTitle:@"Allow Haptics And System Sounds During Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            [audioSession setAllowHapticsAndSystemSoundsDuringRecording:!allowHapticsAndSystemSoundsDuringRecording error:&error];
            assert(error == nil);
        });
    }];
    
    action.state = allowHapticsAndSystemSoundsDuringRecording ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

#if TARGET_OS_IOS
+ (UIAction * _Nonnull)_cp_generateImpactFeecbackAction {
    UIAction *action = [UIAction actionWithTitle:@"Impact Feedback" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto barButtonItem = static_cast<UIBarButtonItem *>(action.sender);
        UIView *view = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(barButtonItem, sel_registerName("view"));
        
        UIImpactFeedbackGenerator *feedbackGenerator = [UIImpactFeedbackGenerator feedbackGeneratorForView:view];
        [feedbackGenerator impactOccurred];
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_prepareRouteSelectionForPlaybackActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Prepare Route Selection For Playback" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        // 사용자에게 Route 선택 화면을 필요에 따라 띄우지만 난 안 뜸 https://developer.apple.com/videos/play/wwdc2019/501
        [audioSession prepareRouteSelectionForPlaybackWithCompletionHandler:^(BOOL shouldStartPlayback, AVAudioSessionRouteSelection routeSelection) {
            if (didChangeHandler) didChangeHandler();
        }];
    }];
    
    return action;
}
#endif

+ (UIAction * _Nonnull)_cp_setPrefersNoInterruptionsFromSystemAlertsActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    BOOL prefersNoInterruptionsFromSystemAlerts = audioSession.prefersNoInterruptionsFromSystemAlerts;
    
    UIAction *action = [UIAction actionWithTitle:@"Prefers No Interruptions From System Alerts" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            [audioSession setPrefersNoInterruptionsFromSystemAlerts:!prefersNoInterruptionsFromSystemAlerts error:&error];
            assert(error == nil);
        });
    }];
    
    action.state = prefersNoInterruptionsFromSystemAlerts ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_setPrefersInterruptionOnRouteDisconnectActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    BOOL prefersInterruptionOnRouteDisconnect = audioSession.prefersInterruptionOnRouteDisconnect;
    
    UIAction *action = [UIAction actionWithTitle:@"Prefers Interruption On Route Disconnect" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            [audioSession setPrefersInterruptionOnRouteDisconnect:!prefersInterruptionOnRouteDisconnect error:&error];
            assert(error == nil);
        });
    }];
    
    action.state = prefersInterruptionOnRouteDisconnect ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (std::vector<AVAudioStereoOrientation>)_cp_allStereoOrientations {
    return {
        AVAudioStereoOrientationNone,
        AVAudioStereoOrientationPortrait,
        AVAudioStereoOrientationPortraitUpsideDown,
        AVAudioStereoOrientationLandscapeLeft,
        AVAudioStereoOrientationLandscapeRight
    };
}

#if !TARGET_OS_TV
+ (UIMenu * _Nonnull)_cp_inputOrientationsMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioStereoOrientation inputOrientation = audioSession.inputOrientation;
    AVAudioStereoOrientation preferredInputOrientation = audioSession.preferredInputOrientation;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allStereoOrientations]
    | std::views::transform([audioSession, inputOrientation, preferredInputOrientation](AVAudioStereoOrientation orientation) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioStereoOrientation(orientation) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredInputOrientation:orientation error:&error];
                assert(error == nil);
            });
        }];
        
        if (inputOrientation == orientation) {
            action.state = UIMenuElementStateOn;
        } else if (preferredInputOrientation == orientation) {
            action.state = UIMenuElementStateMixed;
            action.subtitle = @"Preferred";
        } else {
            action.state = UIMenuElementStateOff;
        }
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Input Orientation" children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVAudioStereoOrientation(inputOrientation);
    
    return menu;
}
#endif

#warning TODO -setPreferredInputSampleRate:, -setPreferredOutputSampleRate:
+ (__kindof UIMenuElement * _Nonnull)_cp_setPreferredSampleRateElementWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.001;
        label.text = [NSString stringWithFormat:@"preferredSampleRate : %f", audioSession.preferredSampleRate];
        
#if TARGET_OS_TV
        TVSlider *slider = [TVSlider new];
#else
        UISlider *slider = [UISlider new];
#endif
        slider.minimumValue = 8000.f;
        slider.maximumValue = 48000.f;
        slider.value = audioSession.preferredSampleRate;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
            auto slider = static_cast<TVSlider *>(action.sender);
#else
            auto slider = static_cast<UISlider *>(action.sender);
#endif
            float value = slider.value;
            
            label.text = [NSString stringWithFormat:@"preferredSampleRate : %f", value];;
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredSampleRate:value error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
#if TARGET_OS_TV
        [slider addAction:action];
#else
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, slider]];
        [label release];
        [slider release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_setInputGainElementWithAudioSession:(AVAudioSession *)audioSession {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.001;
        label.text = [NSString stringWithFormat:@"inputGain : %lf", audioSession.inputGain];
        
#if TARGET_OS_TV
        TVSlider *slider = [TVSlider new];
#else
        UISlider *slider = [UISlider new];
#endif
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = audioSession.inputGain;
        slider.continuous = YES;
        slider.enabled = audioSession.isInputGainSettable;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
            auto slider = static_cast<TVSlider *>(action.sender);
#else
            auto slider = static_cast<UISlider *>(action.sender);
#endif
            float value = slider.value;
            
            label.text = [NSString stringWithFormat:@"inputGain : %lf", value];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setInputGain:value error:&error];
                assert(error == nil);
            });
        }];
        
#if TARGET_OS_TV
        [slider addAction:action];
#else
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, slider]];
        [label release];
        [slider release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_setPreferredIOBufferDurationElementWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.001;
        label.text = [NSString stringWithFormat:@"preferredIOBufferDuration : %lf", audioSession.preferredIOBufferDuration];
        
#if TARGET_OS_TV
        TVSlider *slider = [TVSlider new];
#else
        UISlider *slider = [UISlider new];
#endif
        slider.minimumValue = 0.005;
        slider.maximumValue = 0.093;
        slider.value = audioSession.preferredIOBufferDuration;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
            auto slider = static_cast<TVSlider *>(action.sender);
#else
            auto slider = static_cast<UISlider *>(action.sender);
#endif
            float value = slider.value;
            
            label.text = [NSString stringWithFormat:@"preferredIOBufferDuration : %lf", value];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredIOBufferDuration:value error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
#if TARGET_OS_TV
        [slider addAction:action];
#else
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
#endif
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, slider]];
        [label release];
        [slider release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    return element;
}

#if !TARGET_OS_TV
+ (UIMenu *)_cp_volumeControlsMenu {
    UIMenu *menu = [UIMenu menuWithTitle:@"Volume Controls"
                                children:@[
        [UIDeferredMenuElement _cp_VolumeViewElement],
        [UIDeferredMenuElement _cp_VolumeSliderElement],
        [UIDeferredMenuElement _cp_VolumeStepperElement],
    ]];
    
    return menu;
}
#endif

+ (__kindof UIMenuElement *)_cp_VolumeViewElement {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        MPVolumeView *volumeView = [MPVolumeView new];
        return [volumeView autorelease];
    });
    
    return element;
}

#if !TARGET_OS_TV
+ (__kindof UIMenuElement *)_cp_VolumeSliderElement {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        VolumeSlider *volumeSlider = [VolumeSlider new];
        return [volumeSlider autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_VolumeStepperElement {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        VolumeStepper *volumeStepper = [VolumeStepper new];
        return [volumeStepper autorelease];
    });
    
    return element;
}
#endif

+ (UIMenu *)_cp_numberOfChannelsSteppersMenuWithAudioSession:(AVAudioSession *)audioSession {
    UIMenu *menu = [UIMenu menuWithTitle:@"Number Of Channels Steppers"
                                children:@[
        [UIDeferredMenuElement _cp_setPreferredInputNumberOfChannelsStepperElementWithAudioSession:audioSession],
        [UIDeferredMenuElement _cp_setPreferredOutputNumberOfChannelsStepperElementWithAudioSession:audioSession]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_setPreferredInputNumberOfChannelsStepperElementWithAudioSession:(AVAudioSession *)audioSession {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.001;
        label.text = [NSString stringWithFormat:@"preferredInputNumberOfChannels : %ld", audioSession.preferredInputNumberOfChannels];
        
#if TARGET_OS_TV
        TVStepper *stepper = [TVStepper new];
#else
        UIStepper *stepper = [UIStepper new];
#endif
        stepper.continuous = YES;
        stepper.minimumValue = 0.;
        stepper.maximumValue = audioSession.maximumInputNumberOfChannels;
        stepper.stepValue = 1.;
        stepper.value = audioSession.preferredInputNumberOfChannels;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
            auto stepper = static_cast<TVStepper *>(action.sender);
#else
            auto stepper = static_cast<UIStepper *>(action.sender);
#endif
            auto value = static_cast<NSInteger>(stepper.value);
            
            label.text = [NSString stringWithFormat:@"preferredInputNumberOfChannels : %ld", value];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredInputNumberOfChannels:value error:&error];
                assert(error == nil);
            });
        }];
        
#if TARGET_OS_TV
        [stepper addAction:action];
#else
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
#endif
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_setPreferredOutputNumberOfChannelsStepperElementWithAudioSession:(AVAudioSession *)audioSession {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.001;
        label.text = [NSString stringWithFormat:@"preferredOutputNumberOfChannels : %ld", audioSession.preferredOutputNumberOfChannels];
        
#if TARGET_OS_TV
        TVStepper *stepper = [TVStepper new];
#else
        UIStepper *stepper = [UIStepper new];
#endif
        stepper.continuous = YES;
        stepper.minimumValue = 0.;
        stepper.maximumValue = audioSession.maximumOutputNumberOfChannels;
        stepper.stepValue = 1.;
        stepper.value = audioSession.preferredOutputNumberOfChannels;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_TV
            auto stepper = static_cast<TVStepper *>(action.sender);
#else
            auto stepper = static_cast<UIStepper *>(action.sender);
#endif
            auto value = static_cast<NSInteger>(stepper.value);
            
            label.text = [NSString stringWithFormat:@"preferredOutputNumberOfChannels : %ld", value];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setPreferredOutputNumberOfChannels:value error:&error];
                assert(error == nil);
            });
        }];
        
#if TARGET_OS_TV
        [stepper addAction:action];
#else
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
#endif
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    return element;
}

+ (UIAction *)_cp_setSupportsMultichannelContentActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    BOOL supportsMultichannelContent = audioSession.supportsMultichannelContent;
    
    UIAction *action = [UIAction actionWithTitle:@"supportsMultichannelContent" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            [audioSession setSupportsMultichannelContent:!supportsMultichannelContent error:&error];
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = supportsMultichannelContent ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu *)_cp_audioSessionDataSourceMenu:(AVAudioSessionDataSourceDescription *)dataSource subtitle:(NSString *)subtitle toggleHandler:(void (^)(void))tggleHandler {
    NSMutableArray<UIAction *> *polarPatternActions = [[NSMutableArray alloc] initWithCapacity:dataSource.supportedPolarPatterns.count];
    for (AVAudioSessionPolarPattern polarPattern in dataSource.supportedPolarPatterns) {
        UIAction *action = [UIAction actionWithTitle:polarPattern image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [dataSource setPreferredPolarPattern:polarPattern error:&error];
                assert(error == nil);
            });
        }];
        
        if ([dataSource.selectedPolarPattern isEqualToString:polarPattern]) {
            action.state = UIMenuElementStateOn;
        } else if ([dataSource.preferredPolarPattern isEqualToString:polarPattern]) {
            action.state = UIMenuElementStateMixed;
        } else {
            action.state = UIMenuElementStateOff;
        }
        
        [polarPatternActions addObject:action];
    }
    UIMenu *polarPatternsMenu = [UIMenu menuWithTitle:@"Polar Patterns" children:polarPatternActions];
    [polarPatternActions release];
    polarPatternsMenu.subtitle = dataSource.selectedPolarPattern;
    
    //
    
    UIAction *orientationAction = [UIAction actionWithTitle:@"Orientation"
                                                      image:nil
                                                 identifier:nil
                                                    handler:^(__kindof UIAction * _Nonnull action) {}];
    orientationAction.subtitle = dataSource.orientation;
    orientationAction.attributes = UIMenuElementAttributesDisabled;
    
    UIAction *locationAction = [UIAction actionWithTitle:@"Location"
                                                   image:nil
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {}];
    locationAction.subtitle = dataSource.location;
    locationAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIAction *toggleAction = [UIAction actionWithTitle:@"Toggle" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        tggleHandler();
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:dataSource.dataSourceName
                                children:@[
        polarPatternsMenu,
        orientationAction,
        locationAction,
        toggleAction
    ]];
    menu.subtitle = subtitle;
    
    return menu;
}

+ (UIMenu *)_cp_audioSessionPortDescriptionMenu:(AVAudioSessionPortDescription *)portDesc didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    UIAction *portNameAction = [UIAction actionWithTitle:@"portName" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
    portNameAction.subtitle = portDesc.portName;
    portNameAction.attributes = UIMenuElementAttributesDisabled;
    
    UIAction *portTypeAction = [UIAction actionWithTitle:@"portType" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
    portTypeAction.subtitle = portDesc.portType;
    portTypeAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    NSMutableArray<UIMenu *> *channelMenus = [[NSMutableArray alloc] initWithCapacity:portDesc.channels.count];
    for (AVAudioSessionChannelDescription *channelDesc in portDesc.channels) {
        UIAction *channelNameAction = [UIAction actionWithTitle:@"channelName" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        channelNameAction.subtitle = channelDesc.channelName;
        channelNameAction.attributes = UIMenuElementAttributesDisabled;
        
        UIAction *channelNumberAction = [UIAction actionWithTitle:@"channelNumber" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        channelNumberAction.subtitle = @(channelDesc.channelNumber).stringValue;
        channelNumberAction.attributes = UIMenuElementAttributesDisabled;
        
        UIAction *owningPortUIDAction = [UIAction actionWithTitle:@"owningPortUID" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        owningPortUIDAction.subtitle = channelDesc.owningPortUID;
        owningPortUIDAction.attributes = UIMenuElementAttributesDisabled;
        
        UIAction *channelLabelAction = [UIAction actionWithTitle:@"channelLabel" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        channelLabelAction.subtitle = @(channelDesc.channelLabel).stringValue;
        channelLabelAction.attributes = UIMenuElementAttributesDisabled;
        
        UIMenu *menu = [UIMenu menuWithTitle:@"channelDesc.channelName"
                                    children:@[
            channelNameAction,
            channelNumberAction,
            owningPortUIDAction,
            channelLabelAction
        ]];
        
        [channelMenus addObject:menu];
    }
    UIMenu *channelsMenu = [UIMenu menuWithTitle:@"Channels" children:channelMenus];
    [channelMenus release];
    
    //
    
    UIAction *UIDAction = [UIAction actionWithTitle:@"UID" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
    UIDAction.subtitle = portDesc.UID;
    UIDAction.attributes = UIMenuElementAttributesDisabled;
    
    UIAction *hasHardwareVoiceCallProcessingAction = [UIAction actionWithTitle:@"hasHardwareVoiceCallProcessing" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
    hasHardwareVoiceCallProcessingAction.subtitle = @(portDesc.hasHardwareVoiceCallProcessing).stringValue;
    hasHardwareVoiceCallProcessingAction.attributes = UIMenuElementAttributesDisabled;
    
    UIAction *isSpatialAudioEnabledAction = [UIAction actionWithTitle:@"isSpatialAudioEnabled" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
    isSpatialAudioEnabledAction.subtitle = @(portDesc.isSpatialAudioEnabled).stringValue;
    isSpatialAudioEnabledAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    NSMutableArray<UIMenu *> *dataSourceMenus = [[NSMutableArray alloc] initWithCapacity:portDesc.dataSources.count];
    for (AVAudioSessionDataSourceDescription *dataSource in portDesc.dataSources) {
        NSString *subtitle;
        if ([portDesc.selectedDataSource isEqual:dataSource]) {
            subtitle = @"Seleted";
        } else if ([portDesc.preferredDataSource isEqual:dataSource]) {
            subtitle = @"Preferred";
        } else {
            subtitle = nil;
        }
        
        UIMenu *submenu = [UIDeferredMenuElement _cp_audioSessionDataSourceMenu:dataSource
                                                                       subtitle:subtitle
                                                                  toggleHandler:^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [portDesc setPreferredDataSource:dataSource error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [dataSourceMenus addObject:submenu];
    }
    UIMenu *dataSourcesMenu = [UIMenu menuWithTitle:@"Data Sources" children:dataSourceMenus];
    [dataSourceMenus release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:portDesc.portName
                                children:@[
        portNameAction,
        portTypeAction,
        channelsMenu,
        UIDAction,
        hasHardwareVoiceCallProcessingAction,
        isSpatialAudioEnabledAction,
        dataSourcesMenu
    ]];
    
    return menu;
}

+ (UIMenu *)_cp_currentRouteMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSMutableArray<UIMenu *> *inputsMenu = [[NSMutableArray alloc] initWithCapacity:audioSession.currentRoute.inputs.count];
    for (AVAudioSessionPortDescription *portDesc in audioSession.currentRoute.inputs) {
        [inputsMenu addObject:[UIDeferredMenuElement _cp_audioSessionPortDescriptionMenu:portDesc didChangeHandler:didChangeHandler]];
    }
    
    NSMutableArray<UIMenu *> *outputsMenu = [[NSMutableArray alloc] initWithCapacity:audioSession.currentRoute.outputs.count];
    for (AVAudioSessionPortDescription *portDesc in audioSession.currentRoute.outputs) {
        [outputsMenu addObject:[UIDeferredMenuElement _cp_audioSessionPortDescriptionMenu:portDesc didChangeHandler:didChangeHandler]];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"currentRoute" children:@[
        [UIMenu menuWithTitle:@"Inputs" children:inputsMenu],
        [UIMenu menuWithTitle:@"Outputs" children:outputsMenu]
    ]];
    
    [inputsMenu release];
    [outputsMenu release];
    
    return menu;
}

+ (UIMenu *)_cp_inputDataSourcesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSMutableArray<UIMenu *> *dataSourceMenus = [[NSMutableArray alloc] initWithCapacity:audioSession.inputDataSources.count];
    
    for (AVAudioSessionDataSourceDescription *dataSource in audioSession.inputDataSources) {
        NSString *subtitle;
        if ([audioSession.inputDataSource isEqual:dataSource]) {
            subtitle = @"Selected";
        } else {
            subtitle = nil;
        }
        
        UIMenu *submenu = [UIDeferredMenuElement _cp_audioSessionDataSourceMenu:dataSource subtitle:subtitle toggleHandler:^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setInputDataSource:dataSource error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [dataSourceMenus addObject:submenu];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Input Data Sources" children:dataSourceMenus];
    [dataSourceMenus release];
    menu.subtitle = audioSession.inputDataSource.dataSourceName;
    
    return menu;
}

+ (UIMenu *)_cp_outputDataSourcesMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSMutableArray<UIMenu *> *dataSourceMenus = [[NSMutableArray alloc] initWithCapacity:audioSession.outputDataSources.count];
    
    for (AVAudioSessionDataSourceDescription *dataSource in audioSession.outputDataSources) {
        NSString *subtitle;
        if ([audioSession.outputDataSource isEqual:dataSource]) {
            subtitle = @"Selected";
        } else {
            subtitle = nil;
        }
        
        UIMenu *submenu = [UIDeferredMenuElement _cp_audioSessionDataSourceMenu:dataSource subtitle:subtitle toggleHandler:^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setOutputDataSource:dataSource error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [dataSourceMenus addObject:submenu];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Output Data Sources" children:dataSourceMenus];
    [dataSourceMenus release];
    menu.subtitle = audioSession.outputDataSource.dataSourceName;
    
    return menu;
}

+ (std::vector<AVAudioSessionPortOverride>)_cp_allPortOverridesVector {
    return {
        AVAudioSessionPortOverrideNone,
#if !TARGET_OS_TV
        AVAudioSessionPortOverrideSpeaker
#endif
    };
}

+ (UIMenu *)_cp_overrideOutputAudioPortMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    auto actionsVec = [UIDeferredMenuElement _cp_allPortOverridesVector]
    | std::views::transform([audioSession, didChangeHandler](AVAudioSessionPortOverride portOverride) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionPortOverride(portOverride)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession overrideOutputAudioPort:portOverride error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Override Audio Port" children:actions];
    [actions release];
    
    return menu;
}

+ (std::vector<AVAudioSessionIOType>)_cp_allIOTypes {
    return {
        AVAudioSessionIOTypeNotSpecified,
        AVAudioSessionIOTypeAggregated
    };
}

#if !TARGET_OS_TV
// https://developer.apple.com/documentation/avfaudio/avaudiosessioniotype?language=objc
+ (UIMenu *)_cp_aggregatedIOPreferenceMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    auto actionsVec = [UIDeferredMenuElement _cp_allIOTypes]
    | std::views::transform([audioSession, didChangeHandler](AVAudioSessionIOType IOType) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVAudioSessionIOType(IOType)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSError * _Nullable error = nil;
                [audioSession setAggregatedIOPreference:IOType error:&error];
                assert(error == nil);
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Set Aggregated IO Preference" children:actions];
    [actions release];
    
    return menu;
}
#endif

#if !TARGET_OS_TV
+ (UIAction *)_cp_togglePrefersEchoCancelledInputActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    BOOL isEchoCancelledInputAvailable = audioSession.isEchoCancelledInputAvailable;
    
#if TARGET_OS_VISION
    BOOL isEchoCancelledInputEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(audioSession, sel_registerName("isEchoCancelledInputEnabled"));
    BOOL prefersEchoCancelledInput = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(audioSession, sel_registerName("prefersEchoCancelledInput"));
#else
    BOOL isEchoCancelledInputEnabled = audioSession.isEchoCancelledInputEnabled;
    BOOL prefersEchoCancelledInput = audioSession.prefersEchoCancelledInput;
#endif
    
    UIAction *action = [UIAction actionWithTitle:@"prefersEchoCancelledInput" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
#if TARGET_OS_VISION
            reinterpret_cast<void (*)(id, SEL, BOOL, id *)>(objc_msgSend)(audioSession, sel_registerName("setPrefersEchoCancelledInput:error:"), !prefersEchoCancelledInput, &error);
#else
            [audioSession setPrefersEchoCancelledInput:!prefersEchoCancelledInput error:&error];
#endif
            assert(error == nil);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.subtitle = [NSString stringWithFormat:@"isEchoCancelledInputEnabled: %d", isEchoCancelledInputEnabled];
    action.attributes = isEchoCancelledInputAvailable ? 0 : UIMenuElementAttributesDisabled;
    action.state = prefersEchoCancelledInput ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}
#endif

#if !TARGET_OS_TV
//+ (UIMenu * _Nonnull)_cp_categoryOptionsMenuWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler {
//    abort();
//}
#endif

+ (UIAction *)_cp_toggleOutputMutedActionWithAudioSession:(AVAudioSession *)audioSession didChangeHandler:(void (^ _Nullable)())didChangeHandler API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0)) {
#if TARGET_OS_IOS
    BOOL outputMuted = audioSession.outputMuted;
    
    UIAction *action = [UIAction actionWithTitle:@"Output Muted" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            BOOL result = [audioSession setOutputMuted:!outputMuted error:&error];
            assert(result);
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = outputMuted ? UIMenuElementStateOn : UIMenuElementStateOff;
    return action;
#else
    BOOL outputMuted = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(audioSession, sel_registerName("isOutputMuted"));
    
    UIAction *action = [UIAction actionWithTitle:@"Output Muted" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError * _Nullable error = nil;
            BOOL result = reinterpret_cast<BOOL (*)(id, SEL, BOOL, id *)>(objc_msgSend)(audioSession, sel_registerName("setOutputMuted:error:"), !outputMuted, &error);
            assert(result);
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = outputMuted ? UIMenuElementStateOn : UIMenuElementStateOff;
    return action;
#endif
}

#if TARGET_OS_IOS
+ (UIMenu *)_cp_inputPickerInteractionMenuWithAudioSession:(AVAudioSession *)audioSession API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0)) {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        AudioInputPickerView *view = [[AudioInputPickerView alloc] initWithAudioSession:audioSession];
        return [view autorelease];
    });
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Input Picker" children:@[element]];
    return menu;
}
#endif

@end
