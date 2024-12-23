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
#import <CamPresentation/NSStringFromVNGeneratePersonSegmentationRequestQualityLevel.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>

/*
 (lldb) po [VNRequestSpecifier allAvailableRequestClassNames]
 <__NSFrozenArrayM 0x3038c3840>(
 VNAlignFaceRectangleRequest,✅
 VNCalculateImageAestheticsScoresRequest,✅
 VNClassifyCityNatureImageRequest,
 VNClassifyFaceAttributesRequest,
 VNClassifyImageAestheticsRequest,
 VNClassifyImageRequest,
 VNClassifyJunkImageRequest,
 VNClassifyMemeImageRequest,
 VNVYvzEtX1JlUdu8xx5qhDI,
 VNClassifyPotentialLandmarkRequest,
 VN5kJNH3eYuyaLxNpZr5Z7zi,
 VN6Mb1ME89lyW3HpahkEygIG,
 VNCoreMLRequest,
 VNCreateAnimalprintRequest,
 VNCreateDetectionprintRequest,
 VNCreateFaceRegionMapRequest,
 VNCreateFaceprintRequest,
 VN6kBnCOr2mZlSV6yV1dLwB,
 VNCreateImageFingerprintsRequest,
 VNCreateImageprintRequest,
 VNCreateNeuralHashprintRequest,
 VNCreateSceneprintRequest,
 VNCreateSmartCamprintRequest,
 VNCreateTorsoprintRequest,
 VNDetectAnimalBodyPoseRequest,
 VNDetectBarcodesRequest,
 VNDetectContoursRequest,
 VNDetectDocumentSegmentationRequest,
 VNDetectFaceCaptureQualityRequest,
 VNDetectFaceLandmarksRequest,✅
 VNDetectFace3DLandmarksRequest,
 VNDetectFaceExpressionsRequest,
 VNDetectFaceGazeRequest,
 VNDetectFacePoseRequest,
 VNDetectFaceRectanglesRequest,✅
 VNDetectHorizonRequest,
 VNDetectHumanBodyPoseRequest,
 VNDetectHumanBodyPose3DRequest,
 VNDetectHumanHandPoseRequest,
 VNDetectHumanHeadRectanglesRequest,
 VNDetectHumanRectanglesRequest,
 VNDetectRectanglesRequest,
 VNDetectScreenGazeRequest,
 VNDetectTextRectanglesRequest,
 VNDetectTrajectoriesRequest,
 VNGenerateAnimalSegmentationRequest,
 VNGenerateAttentionBasedSaliencyImageRequest,
 VNGenerateFaceSegmentsRequest,
 VNGenerateGlassesSegmentationRequest,
 VNGenerateHumanAttributesSegmentationRequest,
 VNGenerateImageFeaturePrintRequest,
 VNGenerateInstanceMaskRequest,
 VNGenerateForegroundInstanceMaskRequest,
 VNGenerateImageSegmentationRequest,
 VNGenerateInstanceMaskGatingRequest,
 VNGenerateObjectnessBasedSaliencyImageRequest,
 VNGenerateOpticalFlowRequest,
 VN1JC7R3k4455fKQz0dY1VhQ,
 VNGeneratePersonInstanceMaskRequest,
 VNGeneratePersonSegmentationRequest,✅
 VNGenerateSkySegmentationRequest,
 VNHomographicImageRegistrationRequest,
 VNIdentifyJunkRequest,
 VNImageBlurScoreRequest,
 VNImageExposureScoreRequest,
 VNNOPRequest,
 VNRecognizeAnimalsRequest,
 VNRecognizeAnimalHeadsRequest,
 VNRecognizeAnimalFacesRequest,
 VNRecognizeFoodAndDrinkRequest,
 VNRecognizeObjectsRequest,
 VNRecognizeSportBallsRequest,
 VNRecognizeTextRequest,
 VNRecognizeDocumentElementsRequest,
 VNRecognizeDocumentsRequest,
 VNRemoveBackgroundRequest,
 VNSceneClassificationRequest,
 VNTrackHomographyRequest,
 VNTrackHomographicImageRegistrationRequest,
 VNTrackLegacyFaceCoreObjectRequest,
 VNTrackMaskRequest,
 VNTrackObjectRequest,
 VNTrackOpticalFlowRequest,
 VNTrackRectangleRequest,
 VNTrackTranslationalImageRegistrationRequest,
 VNTranslationalImageRegistrationRequest
 )
 */

@implementation UIDeferredMenuElement (ImageVision)

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel {
    assert(viewModel != nil);
    
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [viewModel requestsWithHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests) {
            NSArray<__kindof UIMenuElement *> *elements = @[
                [UIDeferredMenuElement _cp_imageVisionElementForVNAlignFaceRectangleRequestWithViewModel:viewModel addedRequests:requests],
                [UIDeferredMenuElement _cp_imageVisionElementForVNCalculateImageAestheticsScoresRequestWithViewModel:viewModel addedRequests:requests],
                [UIDeferredMenuElement _cp_imageVisionElementForVNGeneratePersonSegmentationRequestWithViewModel:viewModel addedRequests:requests],
                [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:viewModel addedRequests:requests],
                [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceLandmarksRequestWithViewModel:viewModel addedRequests:requests]
            ];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
        }];
    }];
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNAlignFaceRectangleRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNAlignFaceRectangleRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNAlignFaceRectangleRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNAlignFaceRectangleRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        action.subtitle = @"???";
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNAlignFaceRectangleRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = @"???";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCalculateImageAestheticsScoresRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNCalculateImageAestheticsScoresRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNCalculateImageAestheticsScoresRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[VNCalculateImageAestheticsScoresRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        action.subtitle = @"???";
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNCalculateImageAestheticsScoresRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = @"???";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGeneratePersonSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNGeneratePersonSegmentationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGeneratePersonSegmentationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGeneratePersonSegmentationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNGeneratePersonSegmentationRequest *request = [[VNGeneratePersonSegmentationRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    auto qualityLevelActionsVec = std::vector<VNGeneratePersonSegmentationRequestQualityLevel> {
        VNGeneratePersonSegmentationRequestQualityLevelAccurate,
        VNGeneratePersonSegmentationRequestQualityLevelBalanced,
        VNGeneratePersonSegmentationRequestQualityLevelFast
    }
    | std::views::transform([viewModel, request](const VNGeneratePersonSegmentationRequestQualityLevel qualityLevel) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNGeneratePersonSegmentationRequestQualityLevel(qualityLevel)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            request.qualityLevel = qualityLevel;
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = (request.qualityLevel == qualityLevel) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *qualityLevelActions = [[NSArray alloc] initWithObjects:qualityLevelActionsVec.data() count:qualityLevelActionsVec.size()];
    UIMenu *qualityLevelsMenu = [UIMenu menuWithTitle:@"Quality Levels" children:qualityLevelActions];
    [qualityLevelActions release];
    qualityLevelsMenu.subtitle = NSStringFromVNGeneratePersonSegmentationRequestQualityLevel(request.qualityLevel);
    
    //
    
    BOOL useTiling = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useTiling"));
    UIAction *useTilingAction = [UIAction actionWithTitle:@"Use Tiling" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseTiling:"), !useTiling);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    useTilingAction.state = useTiling ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSError * _Nullable error = nil;
    UIAction *supportedOutputPixelFormatsAction = [UIAction actionWithTitle:[request supportedOutputPixelFormatsAndReturnError:&error].description
                                                                      image:nil
                                                                 identifier:nil
                                                                    handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    assert(error == nil);
    
    supportedOutputPixelFormatsAction.attributes = UIMenuElementAttributesDisabled;
    supportedOutputPixelFormatsAction.cp_overrideNumberOfTitleLines = 0;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGeneratePersonSegmentationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        qualityLevelsMenu,
        useTilingAction,
        supportedOutputPixelFormatsAction
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectFaceRectanglesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:nil];
            
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreEnhanceEyesAndMouthLocalization:"), YES);
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractBlink:"), YES);
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractSmile:"), YES);
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL faceCoreEnhanceEyesAndMouthLocalization = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreEnhanceEyesAndMouthLocalization"));
    
    UIAction *faceCoreEnhanceEyesAndMouthLocalizationAction = [UIAction actionWithTitle:@"faceCoreEnhanceEyesAndMouthLocalization" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreEnhanceEyesAndMouthLocalization:"), !faceCoreEnhanceEyesAndMouthLocalization);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    faceCoreEnhanceEyesAndMouthLocalizationAction.subtitle = @"???";
    faceCoreEnhanceEyesAndMouthLocalizationAction.state = faceCoreEnhanceEyesAndMouthLocalization ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractBlink = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractBlink"));
    
    UIAction *faceCoreExtractBlinkAction = [UIAction actionWithTitle:@"faceCoreExtractBlink" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractBlink:"), !faceCoreExtractBlink);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    faceCoreExtractBlinkAction.subtitle = @"Not working";
    faceCoreExtractBlinkAction.state = faceCoreExtractBlink ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractSmile = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractSmile"));
    
    UIAction *faceCoreExtractSmileAction = [UIAction actionWithTitle:@"faceCoreExtractSmile" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractSmile:"), !faceCoreExtractSmile);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    faceCoreExtractSmileAction.subtitle = @"???";
    faceCoreExtractSmileAction.state = faceCoreExtractSmile ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        faceCoreEnhanceEyesAndMouthLocalizationAction,
        faceCoreExtractBlinkAction,
        faceCoreExtractSmileAction
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceLandmarksRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectFaceLandmarksRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceLandmarksRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectFaceLandmarksRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceLandmarksRequest *request = [VNDetectFaceLandmarksRequest new];
            
            request.constellation = VNRequestFaceLandmarksConstellation76Points;
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setPerformBlinkDetection:"), YES);
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
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
    
    BOOL refineMouthRegion = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("refineMouthRegion"));
    UIAction *refineMouthRegionAction = [UIAction actionWithTitle:@"refineMouthRegion" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setRefineMouthRegion:"), !refineMouthRegion);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    refineMouthRegionAction.subtitle = @"???";
    refineMouthRegionAction.state = refineMouthRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL refineLeftEyeRegion = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("refineLeftEyeRegion"));
    UIAction *refineLeftEyeRegionAction = [UIAction actionWithTitle:@"refineLeftEyeRegion" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setRefineLeftEyeRegion:"), !refineLeftEyeRegion);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    refineLeftEyeRegionAction.subtitle = @"???";
    refineLeftEyeRegionAction.state = refineLeftEyeRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL refineRightEyeRegion = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("refineRightEyeRegion"));
    UIAction *refineRightEyeRegionAction = [UIAction actionWithTitle:@"refineRightEyeRegion" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setRefineRightEyeRegion:"), !refineRightEyeRegion);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    refineRightEyeRegionAction.subtitle = @"???";
    refineRightEyeRegionAction.state = refineRightEyeRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL performBlinkDetection = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("performBlinkDetection"));
    UIAction *performBlinkDetectionAction = [UIAction actionWithTitle:@"performBlinkDetection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setPerformBlinkDetection:"), !performBlinkDetection);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    performBlinkDetectionAction.state = performBlinkDetection ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceLandmarksRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        constellationMenu,
        performBlinkDetectionAction,
        refineMouthRegionAction,
        refineLeftEyeRegionAction,
        refineRightEyeRegionAction
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
    UIAction *removeRequest = [UIAction actionWithTitle:@"Remove Requrest" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeRequest:request completionHandler:nil];
    }];
    removeRequest.attributes = UIMenuElementAttributesDestructive;
    
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
