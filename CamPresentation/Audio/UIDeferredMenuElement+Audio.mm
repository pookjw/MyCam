//
//  UIDeferredMenuElement+Audio.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <CamPresentation/UIDeferredMenuElement+Audio.h>
#import <CamPresentation/NSStringFromAVAudioSessionRouteSharingPolicy.h>
#import <CamPresentation/AudioSessionRenderingModeInfoView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <vector>
#include <ranges>

#warning TODO visionOS Spatial Experience
#warning 남은 기능 구현하기

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
            
            NSArray<__kindof UIMenuElement *> *children = @[
                categoriesMenu,
                modesMenu,
                routeSharingPoliciesMenu,
                activationMenu,
                renderingModeElement
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
            [AVAudioSession.sharedInstance setCategory:category error:&error];
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
#warning TODO options
            NSError * _Nullable error = nil;
            [audioSession setCategory:audioSession.category
                                 mode:audioSession.mode
                   routeSharingPolicy:policy
                              options:0
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

// AVAusioApplication Mute
//+ (UIAction * _Nonnull)

@end
