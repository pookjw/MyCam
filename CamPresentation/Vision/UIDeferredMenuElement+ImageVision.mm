//
//  UIDeferredMenuElement+ImageVision.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>
#import <objc/message.h>
#import <objc/runtime.h>

/*
 [VNDetectFaceRectanglesRequest class],
 [VNDetectHumanRectanglesRequest class]
 */

@implementation UIDeferredMenuElement (ImageVision)

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel {
    assert(viewModel != nil);
    
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [viewModel requestsWithHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests) {
            NSArray<__kindof UIMenuElement *> *elements = @[
                [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:viewModel addedRequests:requests]
            ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
        }];
    }];
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        return action;
    }
    
    //
    
    UIAction *removeRequest = [UIAction actionWithTitle:@"Remove Requrest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeRequest:request completionHandler:nil];
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        removeRequest
    ]];
    
    return menu;
}

+ (__kindof VNRequest * _Nullable)_cp_imageVisionRequestForClass:(Class)requestClass addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    assert([requestClass isSubclassOfClass:[VNRequest class]]);
    
    for (__kindof VNRequest *request in requests) {
        if ([request class] == requestClass) {
            return request;
        }
    }
    
    return nil;
}

@end
