//
//  UIDeferredMenuElement+Audio.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/14/24.
//

#import <CamPresentation/UIDeferredMenuElement+Audio.h>

@implementation UIDeferredMenuElement (Audio)

+ (instancetype)cp_audioElementWithCaptureService:(CaptureService *)captureService didChangeHandler:(void (^ _Nullable)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            UIMenu *audioSessionMenu = [UIDeferredMenuElement _cp_audioSessionCategoriesMenuWithDidChangeHandler:didChangeHandler];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[audioSessionMenu]);
            });
        });
    }];
    
    return element;
}

+ (NSArray<AVAudioSessionCategory> *)_cp_allAudioSessionCategories {
    return @[
        AVAudioSessionCategoryAmbient,
        AVAudioSessionCategoryMultiRoute,
        AVAudioSessionCategoryPlayAndRecord,
        AVAudioSessionCategoryPlayback,
        AVAudioSessionCategoryRecord,
        AVAudioSessionCategorySoloAmbient
    ];
}

+ (UIMenu * _Nonnull)_cp_audioSessionCategoriesMenuWithDidChangeHandler:(void (^ _Nullable)())didChangeHandler {
    NSArray<AVAudioSessionCategory> *allAudioSessionCategories = [UIDeferredMenuElement _cp_allAudioSessionCategories];
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:allAudioSessionCategories.count];
    
    AVAudioSession *audioSession = AVAudioSession.sharedInstance;
    AVAudioSessionCategory currentCategory = audioSession.category;
    
    for (AVAudioSessionCategory category in allAudioSessionCategories) {
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

+ (UIMenu * _Nonnull)_cp_audioSesssionActivationMenuWithDidChangeHandler:(void (^ _Nullable)())didChangeHandler {
    AVAudioSession *session = AVAudioSession.sharedInstance;
//    session.isac
//    UIAction *withNotifyingOthersOnDeactivationAction = [UIAction actionWithTitle:@"" image:<#(nullable UIImage *)#> identifier:<#(nullable UIActionIdentifier)#> handler:<#^(__kindof UIAction * _Nonnull action)handler#>]
    abort();
}

@end
