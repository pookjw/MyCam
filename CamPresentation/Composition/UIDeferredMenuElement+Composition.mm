//
//  UIDeferredMenuElement+Composition.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/18/25.
//

#import <CamPresentation/UIDeferredMenuElement+Composition.h>

@implementation UIDeferredMenuElement (Composition)

+ (UIDeferredMenuElement *)cp_compositionElementWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(compositionService.queue, ^{
            NSMutableArray<__kindof UIMenuElement *> *elements = [[NSMutableArray alloc] init];
            
            [elements addObject:[UIDeferredMenuElement _cp_saveCompositionActionWithCompositionService:compositionService didChangeHandler:didChangeHandler]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            [elements release];
        });
    }];
    
    return element;
}

+ (UIAction *)_cp_saveCompositionActionWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Save" image:[UIImage systemImageNamed:@"square.and.arrow.down"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(compositionService.queue, ^{
            [compositionService queue_saveComposition];
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    return action;
}

@end
