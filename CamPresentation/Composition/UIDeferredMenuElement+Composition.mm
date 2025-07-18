//
//  UIDeferredMenuElement+Composition.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/18/25.
//

#import <CamPresentation/UIDeferredMenuElement+Composition.h>
#import <CamPresentation/CompositionStorage.h>

@implementation UIDeferredMenuElement (Composition)

+ (UIDeferredMenuElement *)cp_compositionElementWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(compositionService.queue, ^{
            NSMutableArray<__kindof UIMenuElement *> *elements = [[NSMutableArray alloc] init];
            
            [elements addObject:[UIDeferredMenuElement _cp_compositionStorageWithCompositionService:compositionService didChangeHandler:didChangeHandler]];
            [elements addObject:[UIDeferredMenuElement _cp_resetCompositionActionWithCompositionService:compositionService didChangeHandler:didChangeHandler]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            [elements release];
        });
    }];
    
    return element;
}

+ (UIMenu *)_cp_compositionStorageWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Composition Storage" children:@[
        [UIDeferredMenuElement _cp_compositionStorageLoadCompositionActionWithCompositionService:compositionService didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_compositionStorageSaveCompositionActionWithCompositionService:compositionService didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_compositionStorageRemoveCompositionActionWithCompositionService:compositionService didChangeHandler:didChangeHandler]
    ]];
    
    return menu;
}

+ (UIAction *)_cp_compositionStorageSaveCompositionActionWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Save" image:[UIImage systemImageNamed:@"square.and.arrow.down"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(compositionService.queue, ^{
            CompositionStorage.composition = compositionService.queue_composition;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    return action;
}

+ (UIAction *)_cp_compositionStorageLoadCompositionActionWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    if (CompositionStorage.composition == nil) {
        UIAction *action = [UIAction actionWithTitle:@"Load" image:[UIImage systemImageNamed:@"envelope.open"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        action.attributes = UIMenuElementAttributesDisabled;
        return action;
    } else {
        UIAction *action = [UIAction actionWithTitle:@"Load" image:[UIImage systemImageNamed:@"envelope.open"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(compositionService.queue, ^{
                [compositionService queue_loadComposition];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        return action;
    }
}

+ (UIAction *)_cp_compositionStorageRemoveCompositionActionWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Remove" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(compositionService.queue, ^{
            CompositionStorage.composition = nil;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesDestructive;
    
    return action;
}

+ (UIAction *)_cp_resetCompositionActionWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Reset" image:[UIImage systemImageNamed:@"xmark"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(compositionService.queue, ^{
            [compositionService queue_resetComposition];
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesDestructive;
    
    return action;
}

@end
