//
//  UIDeferredMenuElement+ImageVision.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/UIDeferredMenuElement+ImageVision.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <ranges>
#include <vector>
#import <CamPresentation/NSStringFromVNRequestFaceLandmarksConstellation.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>

@implementation UIDeferredMenuElement (ImageVision)

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel {
    assert(viewModel != nil);
    
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [viewModel requestsWithHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests) {
            NSArray<__kindof UIMenuElement *> *elements = @[
                [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:viewModel addedRequests:requests],
                [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceLandmarksRequestWithViewModel:viewModel addedRequests:requests]
            ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
        }];
    }];
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectFaceRectanglesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceLandmarksRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectFaceLandmarksRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceLandmarksRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceLandmarksRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceLandmarksRequest *request = [VNDetectFaceLandmarksRequest new];
            request.constellation = VNRequestFaceLandmarksConstellation76Points;
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    auto constellationActionsVec = std::vector<VNRequestFaceLandmarksConstellation> {
        VNRequestFaceLandmarksConstellationNotDefined,
        VNRequestFaceLandmarksConstellation65Points,
        VNRequestFaceLandmarksConstellation76Points
    }
    | std::views::transform([viewModel, request](const VNRequestFaceLandmarksConstellation constellation) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNRequestFaceLandmarksConstellation(constellation)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            request.constellation = constellation;
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = (request.constellation == constellation) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = [VNDetectFaceLandmarksRequest revision:request.revision supportsConstellation:constellation] ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *constellationActions = [[NSArray alloc] initWithObjects:constellationActionsVec.data() count:constellationActionsVec.size()];
    UIMenu *constellationMenu = [UIMenu menuWithTitle:@"Constellation" children:constellationActions];
    [constellationActions release];
    
    constellationMenu.subtitle = NSStringFromVNRequestFaceLandmarksConstellation(request.constellation);
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceLandmarksRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        constellationMenu
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

+ (UIMenu *)_cp_imageVissionCommonMenuForRequest:(__kindof VNRequest *)request viewModel:(ImageVisionViewModel *)viewModel {
    UIAction *removeRequest = [UIAction actionWithTitle:@"Remove Requrest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeRequest:request completionHandler:nil];
    }];
    
    //
    
    /*
     supportedRevisions (Public)
     supportedPrivateRevisions (Private)
     allSupportedRevisions (Public + Private)
     
     publicRevisionsSet
     privateRevisionsSet
     
     +supportsAnyRevision:
     +supportsPrivateRevision:
     +supportsRevision:
     */
    
    NSIndexSet *publicRevisionsSet = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([request class], sel_registerName("publicRevisionsSet"));
    NSMutableArray<UIAction *> *publicRevisionActions = [[NSMutableArray alloc] initWithCapacity:publicRevisionsSet.count];
    [publicRevisionsSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        UIAction *action = [UIAction actionWithTitle:@(idx).stringValue
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            request.revision = idx;
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = (request.revision == idx) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = reinterpret_cast<BOOL (*)(Class, SEL, NSUInteger)>(objc_msgSend)([request class], sel_registerName("supportsAnyRevision:"), idx) ? 0 : UIMenuElementAttributesDisabled;
        action.cp_overrideNumberOfTitleLines = 0;
        
        [publicRevisionActions addObject:action];
    }];
    
    UIMenu *publicRevisionsMenu = [UIMenu menuWithTitle:@"Public Revisions" children:publicRevisionActions];
    [publicRevisionActions release];
    
    //
    
    NSIndexSet *privateRevisionsSet = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([request class], sel_registerName("privateRevisionsSet"));
    NSMutableArray<UIAction *> *privateRevisionActions = [[NSMutableArray alloc] initWithCapacity:privateRevisionsSet.count];
    [privateRevisionsSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        UIAction *action = [UIAction actionWithTitle:reinterpret_cast<id (*)(Class, SEL, NSUInteger)>(objc_msgSend)([request class], sel_registerName("descriptionForPrivateRevision:"), idx)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
//            request.revision = idx;
//            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("_setResolvedRevision:"), idx);
            NSError * _Nullable error = nil;
            reinterpret_cast<void (*)(id, SEL, NSUInteger, id *)>(objc_msgSend)(request, sel_registerName("setRevision:error:"), idx, &error);
            assert(error == nil);
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = (request.revision == idx) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = reinterpret_cast<BOOL (*)(Class, SEL, NSUInteger)>(objc_msgSend)([request class], sel_registerName("supportsAnyRevision:"), idx) ? 0 : UIMenuElementAttributesDisabled;
        action.cp_overrideNumberOfTitleLines = 0;
        
        [privateRevisionActions addObject:action];
    }];
    
    UIMenu *privateRevisionsMenu = [UIMenu menuWithTitle:@"Private Revisions" children:privateRevisionActions];
    [privateRevisionActions release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        removeRequest,
        publicRevisionsMenu,
        privateRevisionsMenu
    ]];
    
    return menu;
}

@end
