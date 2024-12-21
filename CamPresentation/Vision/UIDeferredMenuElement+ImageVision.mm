//
//  UIDeferredMenuElement+ImageVision.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>

/*
 [VNDetectFaceRectanglesRequest class],
 [VNDetectHumanRectanglesRequest class]
 */

@implementation UIDeferredMenuElement (ImageVision)

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(viewModel.queue, ^{
            NSArray<__kindof UIMenuElement *> *elements = @[
                [UIDeferredMenuElement _cp_queue_imageVisionElementForVNDetectFaceRectanglesRequestWithVieWModel:viewModel]
            ];
            
            completion(elements);
        });
    }];
}

+ (__kindof UIMenuElement *)_cp_queue_imageVisionElementForVNDetectFaceRectanglesRequestWithVieWModel:(ImageVisionViewModel *)viewModel {
    if (![UIDeferredMenuElement _cp_queue_imageVisionHasRequestForClass:[VNDetectFaceRectanglesRequest class] vieWModel:viewModel]) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        return action;
    }
    
    abort();
}

+ (BOOL)_cp_queue_imageVisionHasRequestForClass:(Class)requestClass vieWModel:(ImageVisionViewModel *)viewModel {
    assert([requestClass isKindOfClass:[VNRequest class]]);
    
    for (__kindof VNRequest *request in viewModel.queue_requests) {
        if ([request class] == requestClass) {
            return YES;
        }
    }
    
    return NO;
}

@end
