//
//  UIDeferredMenuElement+Composition.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/18/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CompositionService.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (Composition)
+ (UIDeferredMenuElement *)cp_compositionElementWithCompositionService:(CompositionService *)compositionService didChangeHandler:(void (^ _Nullable)(void))didChangeHandler;
@end

NS_ASSUME_NONNULL_END
