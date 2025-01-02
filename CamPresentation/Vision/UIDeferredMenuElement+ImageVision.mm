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
#import <CoreML/CoreML.h>
#import <CamPresentation/MLModelAsset+Category.h>
#import <CamPresentation/ImageVision3DViewController.h>

/*
 (lldb) po [VNRequestSpecifier allAvailableRequestClassNames]
 <__NSFrozenArrayM 0x3038c3840>(
 VNAlignFaceRectangleRequest,✅
 VNCalculateImageAestheticsScoresRequest,✅
 VNClassifyCityNatureImageRequest,✅
 VNClassifyFaceAttributesRequest,✅
 VNClassifyImageAestheticsRequest,✅
 VNClassifyImageRequest,✅
 VNClassifyJunkImageRequest,✅
 VNClassifyMemeImageRequest,✅
 VNVYvzEtX1JlUdu8xx5qhDI,✅
 VNClassifyPotentialLandmarkRequest,✅
 VN5kJNH3eYuyaLxNpZr5Z7zi,✅
 VN6Mb1ME89lyW3HpahkEygIG,✅
 VNCoreMLRequest,✅
 VNCreateAnimalprintRequest,✅
 VNCreateDetectionprintRequest,✅
 VNCreateFaceRegionMapRequest,✅
 VNCreateFaceprintRequest,✅
 VN6kBnCOr2mZlSV6yV1dLwB,✅
 VNCreateImageFingerprintsRequest,✅
 VNCreateImageprintRequest,✅
 VNCreateNeuralHashprintRequest,✅
 VNCreateSceneprintRequest,✅
 VNCreateSmartCamprintRequest,✅
 VNCreateTorsoprintRequest,✅
 VNDetectAnimalBodyPoseRequest,✅
 VNDetectBarcodesRequest,✅
 VNDetectContoursRequest,✅
 VNDetectDocumentSegmentationRequest,✅
 VNDetectFaceCaptureQualityRequest,✅
 VNDetectFaceLandmarksRequest,✅
 VNDetectFace3DLandmarksRequest,✅
 VNDetectFaceExpressionsRequest,✅
 VNDetectFaceGazeRequest,✅
 VNDetectFacePoseRequest,✅
 VNDetectFaceRectanglesRequest,✅
 VNDetectHorizonRequest,✅
 VNDetectHumanBodyPoseRequest,✅
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
 VNGenerateForegroundInstanceMaskRequest,✅
 VNGenerateImageSegmentationRequest,
 VNGenerateInstanceMaskGatingRequest,
 VNGenerateObjectnessBasedSaliencyImageRequest,
 VNGenerateOpticalFlowRequest,
 VN1JC7R3k4455fKQz0dY1VhQ,
 VNGeneratePersonInstanceMaskRequest,✅
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

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    assert(viewModel != nil);
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [viewModel getValuesWithCompletionHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests, NSArray<__kindof VNObservation *> * _Nonnull observations, UIImage * _Nullable image) {
            UIMenu *requestsMenu = [UIDeferredMenuElement _cp_imageVisionRequestsMenuWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer];
            UIAction *humanBodyPose3DObservationSceneAction = [UIDeferredMenuElement _cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:viewModel observations:observations image:image imageLayer:imageVisionLayer];
            UIMenu *imageVisionLayerMenu = [UIDeferredMenuElement _cp_imageVisionMenuWithImageVisionLayer:imageVisionLayer];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[requestsMenu, humanBodyPose3DObservationSceneAction, imageVisionLayerMenu]);
            });
        }];
    }];
}

+ (UIMenu *)_cp_imageVisionRequestsMenuWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    UIMenu *usefulRequestsMenu = [UIMenu menuWithTitle:@"Useful Requests" children:@[
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceLandmarksRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGeneratePersonSegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateAnimalprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCoreMLRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyCityNatureImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyJunkImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyMemeImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyPotentialLandmarkRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCalculateImageAestheticsScoresRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyImageAestheticsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectAnimalBodyPoseRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateForegroundInstanceMaskRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectBarcodesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectContoursRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectDocumentSegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceCaptureQualityRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFace3DLandmarksRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceExpressionsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceGazeRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFacePoseRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHorizonRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanBodyPoseRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanBodyPose3DRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer]
    ]];
    
    UIMenu *uselessRequestsMenu = [UIMenu menuWithTitle:@"Useless Requests" children:@[
        [UIDeferredMenuElement _cp_imageVisionElementForVNAlignFaceRectangleRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNClassifyFaceAttributesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNVYvzEtX1JlUdu8xx5qhDIWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVN5kJNH3eYuyaLxNpZr5Z7ziWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVN6Mb1ME89lyW3HpahkEygIGWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateDetectionprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateFaceRegionMapRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateFaceprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVN6kBnCOr2mZlSV6yV1dLwBWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateImageFingerprintsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateImageprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateSceneprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectFaceRectanglesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateNeuralHashprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateSmartCamprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNCreateTorsoprintRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateAnimalSegmentationRequestWithViewModel:viewModel addedRequests:requests],
    ]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        usefulRequestsMenu, uselessRequestsMenu
    ]];
    
    return menu;
}

+ (UIMenu *)_cp_imageVisionMenuWithImageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    BOOL shouldDrawImage = imageVisionLayer.shouldDrawImage;
    UIAction *shouldDrawImageAction = [UIAction actionWithTitle:@"shouldDrawImage" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        imageVisionLayer.shouldDrawImage = !shouldDrawImage;
    }];
    shouldDrawImageAction.state = shouldDrawImage ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL shouldDrawDetails = imageVisionLayer.shouldDrawDetails;
    UIAction *shouldDrawDetailsAction = [UIAction actionWithTitle:@"shouldDrawDetails" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        imageVisionLayer.shouldDrawDetails = !shouldDrawDetails;
    }];
    shouldDrawDetailsAction.state = shouldDrawDetails ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL shouldDrawContoursSeparately = imageVisionLayer.shouldDrawContoursSeparately;
    UIAction *shouldDrawContoursSeparatelyAction = [UIAction actionWithTitle:@"shouldDrawContoursSeparately" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        imageVisionLayer.shouldDrawContoursSeparately = !shouldDrawContoursSeparately;
    }];
    shouldDrawContoursSeparatelyAction.state = shouldDrawContoursSeparately ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    BOOL shouldDrawOverlay = imageVisionLayer.shouldDrawOverlay;
    UIAction *shouldDrawOverlayAction = [UIAction actionWithTitle:@"shouldDrawOverlay" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        imageVisionLayer.shouldDrawOverlay = !shouldDrawOverlay;
    }];
    shouldDrawOverlayAction.state = shouldDrawOverlay ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Image Vision Layer" children:@[
        shouldDrawImageAction,
        shouldDrawDetailsAction,
        shouldDrawContoursSeparatelyAction,
        shouldDrawOverlayAction
    ]];
    
    return menu;
}

+ (UIAction *)_cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:(ImageVisionViewModel *)viewModel observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage *)image imageLayer:(ImageVisionLayer *)imageLayer {
    NSMutableArray<VNHumanBodyPose3DObservation *> *humanBodyPose3DObservations = [NSMutableArray array];
    for (__kindof VNObservation *observation in observations) {
        if ([observation isKindOfClass:[VNHumanBodyPose3DObservation class]]) {
            [humanBodyPose3DObservations addObject:static_cast<VNHumanBodyPose3DObservation *>(observation)];
        }
    }
    
    if (humanBodyPose3DObservations.count == 0) {
        UIAction *action = [UIAction actionWithTitle:@"Present VNHumanBodyPose3DObservation Scene View" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        action.cp_overrideNumberOfTitleLines = 0;
        action.attributes = UIMenuElementAttributesDisabled;
        return action;
    }
    
    UIAction *action = [UIAction actionWithTitle:@"Present VNHumanBodyPose3DObservation Scene View" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto layerView = static_cast<UIView *>(imageLayer.delegate);
        assert([layerView isKindOfClass:[UIView class]]);
        UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
        assert(viewController != nil);
        
        ImageVision3DDescriptor *descriptor = [[ImageVision3DDescriptor alloc] initWithHumanBodyPose3DObservations:humanBodyPose3DObservations image:image];
        ImageVision3DViewController *visionViewController = [ImageVision3DViewController new];
        visionViewController.descriptor = descriptor;
        [descriptor release];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:visionViewController];
        [visionViewController release];
        navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        [viewController presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }];
    
    action.cp_overrideNumberOfTitleLines = 0;
    return action;
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
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNCalculateImageAestheticsScoresRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyCityNatureImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyCityNatureImageRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyCityNatureImageRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyCityNatureImageRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyCityNatureImageRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyFaceAttributesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyFaceAttributesRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyFaceAttributesRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyFaceAttributesRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyFaceAttributesRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyImageAestheticsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyImageAestheticsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyImageAestheticsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyImageAestheticsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyImageAestheticsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNClassifyImageRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNClassifyImageRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[VNClassifyImageRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNClassifyImageRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyJunkImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyJunkImageRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyJunkImageRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyJunkImageRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyJunkImageRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyMemeImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyMemeImageRequest") addedRequests:requests];
    NSString *subtitle = @"Not Meme. Document, Receipt, Boarding pass, etc...";
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyMemeImageRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyMemeImageRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        action.subtitle = subtitle;
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyMemeImageRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    menu.subtitle = subtitle;
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNVYvzEtX1JlUdu8xx5qhDIWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNVYvzEtX1JlUdu8xx5qhDI") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNVYvzEtX1JlUdu8xx5qhDI")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNVYvzEtX1JlUdu8xx5qhDI") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNVYvzEtX1JlUdu8xx5qhDI")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNClassifyPotentialLandmarkRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNClassifyPotentialLandmarkRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyPotentialLandmarkRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNClassifyPotentialLandmarkRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNClassifyPotentialLandmarkRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVN5kJNH3eYuyaLxNpZr5Z7ziWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VN5kJNH3eYuyaLxNpZr5Z7zi") addedRequests:requests];
    NSString *subtitle = @"landscale_cityscape, food";
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VN5kJNH3eYuyaLxNpZr5Z7zi")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VN5kJNH3eYuyaLxNpZr5Z7zi") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        action.subtitle = subtitle;
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VN5kJNH3eYuyaLxNpZr5Z7zi")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = subtitle;
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVN6Mb1ME89lyW3HpahkEygIGWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VN6Mb1ME89lyW3HpahkEygIG") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VN6Mb1ME89lyW3HpahkEygIG")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VN6Mb1ME89lyW3HpahkEygIG") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VN6Mb1ME89lyW3HpahkEygIG")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCoreMLRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNCoreMLRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNCoreMLRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNCoreMLRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            NSError * _Nullable error = nil;
            MLModelAsset *modelAsset = [MLModelAsset cp_modelAssetWithModelType:NerualAnalyzerModelTypeMobileNetV2 error:&error];
            assert(error == nil);
            
            MLModelConfiguration *configuration = [MLModelConfiguration new];
            configuration.allowLowPrecisionAccumulationOnGPU = NO;
            configuration.computeUnits = MLComputeUnitsAll;
            
            MLOptimizationHints * optimizationHints = [MLOptimizationHints new];
            optimizationHints.reshapeFrequency = MLReshapeFrequencyHintInfrequent;
            optimizationHints.specializationStrategy = MLSpecializationStrategyDefault;
            
            configuration.optimizationHints = optimizationHints;
            [optimizationHints release];
            
            MLModel *model = reinterpret_cast<id (*)(id, SEL, id, id *)>(objc_msgSend)(modelAsset, sel_registerName("modelWithConfiguration:error:"), configuration, &error);
            [configuration release];
            assert(error == nil);
            
            VNCoreMLModel *visionModel = [VNCoreMLModel modelForMLModel:model error:&error];
            assert(error == nil);
            
            VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:visionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                
            }];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNCoreMLRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateAnimalprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateAnimalprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateAnimalprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateAnimalprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateAnimalprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateDetectionprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateDetectionprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateDetectionprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateDetectionprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateDetectionprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateFaceRegionMapRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateFaceRegionMapRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateFaceRegionMapRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateFaceRegionMapRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateFaceRegionMapRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateFaceprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateFaceprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateFaceprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateFaceprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL forceFaceprintCreation = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("forceFaceprintCreation"));
    UIAction *forceFaceprintCreationAction = [UIAction actionWithTitle:@"forceFaceprintCreation" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setForceFaceprintCreation:"), !forceFaceprintCreation);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    forceFaceprintCreationAction.state = forceFaceprintCreation ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateFaceprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        forceFaceprintCreationAction
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVN6kBnCOr2mZlSV6yV1dLwBWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VN6kBnCOr2mZlSV6yV1dLwB") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VN6kBnCOr2mZlSV6yV1dLwB")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VN6kBnCOr2mZlSV6yV1dLwB") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
        action.subtitle = @"???";
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VN6kBnCOr2mZlSV6yV1dLwB")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = @"???";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateImageFingerprintsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateImageFingerprintsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateImageFingerprintsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateImageFingerprintsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateImageFingerprintsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateImageprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateImageprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateImageprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateImageprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateImageprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateNeuralHashprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateNeuralHashprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateNeuralHashprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateNeuralHashprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateNeuralHashprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateSmartCamprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateSmartCamprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateSmartCamprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateSmartCamprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateSmartCamprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateTorsoprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateTorsoprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateTorsoprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateTorsoprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateTorsoprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateSceneprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateSceneprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateSceneprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateSceneprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateSceneprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectAnimalBodyPoseRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectAnimalBodyPoseRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectAnimalBodyPoseRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectAnimalBodyPoseRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectAnimalBodyPoseRequest *request = [[VNDetectAnimalBodyPoseRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    
    //
    
    NSArray<NSString *> *supportedJointNames = [request supportedJointNamesAndReturnError:&error];
    assert(error == nil);
    NSMutableArray<UIAction *> *supportedJointNameActions = [[NSMutableArray alloc] initWithCapacity:supportedJointNames.count];
    for (NSString *jointName in supportedJointNames) {
        UIAction *action = [UIAction actionWithTitle:jointName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedJointNameActions addObject:action];
    }
    UIMenu *supportedJointNamesMenu = [UIMenu menuWithTitle:@"supportedJointNames" children:supportedJointNameActions];
    supportedJointNamesMenu.subtitle = @(supportedJointNameActions.count).stringValue;
    [supportedJointNameActions release];
    
    //
    
    NSArray<NSString *> *supportedJointsGroupNames = [request supportedJointsGroupNamesAndReturnError:&error];
    assert(error == nil);
    NSMutableArray<UIAction *> *supportedJointsGroupNameActions = [[NSMutableArray alloc] initWithCapacity:supportedJointsGroupNames.count];
    for (NSString *jointsGroupName in supportedJointsGroupNames) {
        UIAction *action = [UIAction actionWithTitle:jointsGroupName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedJointsGroupNameActions addObject:action];
    }
    UIMenu *supportedJointsGroupNamesMenu = [UIMenu menuWithTitle:@"supportedJointsGroupNames" children:supportedJointsGroupNameActions];
    supportedJointsGroupNamesMenu.subtitle = @(supportedJointsGroupNameActions.count).stringValue;
    [supportedJointsGroupNameActions release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectAnimalBodyPoseRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        supportedJointNamesMenu,
        supportedJointsGroupNamesMenu
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateAnimalSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateAnimalSegmentationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateAnimalSegmentationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateAnimalSegmentationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    VNGeneratePersonSegmentationRequestQualityLevel currentQualityLevel = reinterpret_cast<VNGeneratePersonSegmentationRequestQualityLevel (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("qualityLevel"));
    
    auto qualityLevelActionsVec = std::vector<VNGeneratePersonSegmentationRequestQualityLevel> {
        VNGeneratePersonSegmentationRequestQualityLevelAccurate,
        VNGeneratePersonSegmentationRequestQualityLevelBalanced,
        VNGeneratePersonSegmentationRequestQualityLevelFast
    }
    | std::views::transform([viewModel, request, currentQualityLevel](const VNGeneratePersonSegmentationRequestQualityLevel qualityLevel) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNGeneratePersonSegmentationRequestQualityLevel(qualityLevel)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, VNGeneratePersonSegmentationRequestQualityLevel)>(objc_msgSend)(request, sel_registerName("setQualityLevel:"), qualityLevel);
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = (currentQualityLevel == qualityLevel) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *qualityLevelActions = [[NSArray alloc] initWithObjects:qualityLevelActionsVec.data() count:qualityLevelActionsVec.size()];
    UIMenu *qualityLevelsMenu = [UIMenu menuWithTitle:@"Quality Levels" children:qualityLevelActions];
    [qualityLevelActions release];
    qualityLevelsMenu.subtitle = NSStringFromVNGeneratePersonSegmentationRequestQualityLevel(currentQualityLevel);
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateAnimalSegmentationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        qualityLevelsMenu
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateForegroundInstanceMaskRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNGenerateForegroundInstanceMaskRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGenerateForegroundInstanceMaskRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGenerateForegroundInstanceMaskRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNGenerateForegroundInstanceMaskRequest *request = [[VNGenerateForegroundInstanceMaskRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGenerateForegroundInstanceMaskRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
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

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectBarcodesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectBarcodesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectBarcodesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectBarcodesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectBarcodesRequest *request = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:nil];
            [viewModel addRequest:request completionHandler:nil];
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    NSArray<VNBarcodeSymbology> *supportedSymbologies = [request supportedSymbologiesAndReturnError:&error];
    assert(error == nil);
    NSArray<VNBarcodeSymbology> *symbologies = request.symbologies;
    NSMutableArray<UIAction *> *supportedSymbologyActions = [[NSMutableArray alloc] initWithCapacity:supportedSymbologies.count];
    for (VNBarcodeSymbology symbology in supportedSymbologies) {
        UIAction *action = [UIAction actionWithTitle:symbology image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            request.symbologies = [request.symbologies arrayByAddingObject:symbology];
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = ([symbologies containsObject:symbology]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [supportedSymbologyActions addObject:action];
    }
    UIMenu *supportedSymbologyMenu = [UIMenu menuWithTitle:@"Supported Symbologies" children:supportedSymbologyActions];
    [supportedSymbologyActions release];
    supportedSymbologyMenu.subtitle = [NSString stringWithFormat:@"%ld selected", symbologies.count];
    
    //
    
    BOOL coalesceCompositeSymbologies = request.coalesceCompositeSymbologies;
    UIAction *coalesceCompositeSymbologiesAction = [UIAction actionWithTitle:@"coalesceCompositeSymbologies" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        request.coalesceCompositeSymbologies = !coalesceCompositeSymbologies;
        [viewModel updateRequest:request completionHandler:nil];
    }];
    coalesceCompositeSymbologiesAction.state = coalesceCompositeSymbologies ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL stopAtFirstPyramidWith2DCode = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("stopAtFirstPyramidWith2DCode"));
    UIAction *stopAtFirstPyramidWith2DCodeAction = [UIAction actionWithTitle:@"stopAtFirstPyramidWith2DCode" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setStopAtFirstPyramidWith2DCode:"), !stopAtFirstPyramidWith2DCode);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    stopAtFirstPyramidWith2DCodeAction.state = stopAtFirstPyramidWith2DCode ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL useSegmentationPregating = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useSegmentationPregating"));
    UIAction *useSegmentationPregatingAction = [UIAction actionWithTitle:@"useSegmentationPregating" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseSegmentationPregating:"), !useSegmentationPregating);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    useSegmentationPregatingAction.state = useSegmentationPregating ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL useMLDetector = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useMLDetector"));
    UIAction *useMLDetectorAction = [UIAction actionWithTitle:@"useMLDetector" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseMLDetector:"), !useMLDetector);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    useMLDetectorAction.state = useMLDetector ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSArray<NSString *> *availableLocateModes = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("availableLocateModesAndReturnError:"), &error);
    assert(error == nil);
    NSString *currentLocateMode = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("locateMode"));
    NSMutableArray<UIAction *> *availableLocateModeActions = [[NSMutableArray alloc] initWithCapacity:availableLocateModes.count];
    for (NSString *locateMode in availableLocateModes) {
        UIAction *action = [UIAction actionWithTitle:locateMode image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setLocateMode:"), locateMode);
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        action.state = ([currentLocateMode isEqualToString:locateMode]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.cp_overrideNumberOfTitleLines = 0;
        
        [availableLocateModeActions addObject:action];
    }
    UIMenu *availableLocateModesMenu = [UIMenu menuWithTitle:@"availableLocateModes" children:availableLocateModeActions];
    [availableLocateModeActions release];
    availableLocateModesMenu.subtitle = currentLocateMode;
    availableLocateModesMenu.cp_overrideNumberOfSubtitleLines = 0;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectBarcodesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        supportedSymbologyMenu,
        coalesceCompositeSymbologiesAction,
        stopAtFirstPyramidWith2DCodeAction,
        useSegmentationPregatingAction,
        useMLDetectorAction,
        availableLocateModesMenu
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectContoursRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectContoursRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectContoursRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectContoursRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectContoursRequest *request = [[VNDetectContoursRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *contrastAdjustmentSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 3.f;
        slider.value = request.contrastAdjustment;
        slider.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            request.contrastAdjustment = value;
            
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIMenu *contrastAdjustmentSliderMenu = [UIMenu menuWithTitle:@"contrastAdjustment" children:@[contrastAdjustmentSliderElement]];
    
    //
    
    __kindof UIMenuElement *contrastPivotSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.contrastPivot.floatValue;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            request.contrastPivot = @(value);
            
            [viewModel updateRequest:request completionHandler:nil];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIAction *resetContrastPivotAction = [UIAction actionWithTitle:@"Reset" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.contrastPivot = nil;
        [viewModel updateRequest:request completionHandler:nil];
    }];
    
    UIMenu *contrastPivotMenu = [UIMenu menuWithTitle:@"contrastPivot" children:@[
        contrastPivotSliderElement,
        resetContrastPivotAction
    ]];
    
    //
    
    BOOL detectsDarkOnLight = request.detectsDarkOnLight;
    
    UIAction *detectsDarkOnLightAction = [UIAction actionWithTitle:@"detectsDarkOnLight" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        request.detectsDarkOnLight = !detectsDarkOnLight;
        [viewModel updateRequest:request completionHandler:nil];
    }];
    
    detectsDarkOnLightAction.state = detectsDarkOnLight ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    __kindof UIMenuElement *maximumImageDimensionStepperElement_1 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.maximumImageDimension).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        
        slider.maximumValue = NSUIntegerMax;
        slider.minimumValue = 64.f;
        slider.value = request.maximumImageDimension;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(static_cast<NSUInteger>(value)).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.maximumImageDimension = value;
                [viewModel updateRequest:request completionHandler:nil];
            }
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[slider, label]];
        [slider release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    __kindof UIMenuElement *maximumImageDimensionStepperElement_2 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.maximumImageDimension).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        
        slider.maximumValue = 2048.f;
        slider.minimumValue = 64.f;
        slider.value = request.maximumImageDimension;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(static_cast<NSUInteger>(value)).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.maximumImageDimension = value;
                [viewModel updateRequest:request completionHandler:nil];
            }
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[slider, label]];
        [slider release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIAction *resetMaximumImageDimensionAction = [UIAction actionWithTitle:@"Reset" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.maximumImageDimension = 64;
        [viewModel updateRequest:request completionHandler:nil];
    }];
    
    UIMenu *maximumImageDimensionMenu = [UIMenu menuWithTitle:@"maximumImageDimension" children:@[
        maximumImageDimensionStepperElement_1,
        maximumImageDimensionStepperElement_2,
        resetMaximumImageDimensionAction
    ]];
    
    //
    
    BOOL forceUseInputCVPixelBufferDirectly = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("forceUseInputCVPixelBufferDirectly"));
    
    UIAction *forceUseInputCVPixelBufferDirectlyAction = [UIAction actionWithTitle:@"forceUseInputCVPixelBufferDirectly" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setForceUseInputCVPixelBufferDirectly:"), !forceUseInputCVPixelBufferDirectly);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    forceUseInputCVPixelBufferDirectlyAction.subtitle = @"???";
    forceUseInputCVPixelBufferDirectlyAction.state = forceUseInputCVPixelBufferDirectly ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL inHierarchy = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("inHierarchy"));
    
    UIAction *inHierarchyAction = [UIAction actionWithTitle:@"inHierarchy" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setInHierarchy:"), !inHierarchy);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    inHierarchyAction.subtitle = @"???";
    inHierarchyAction.state = inHierarchy ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    // TOOD
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectContoursRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        contrastAdjustmentSliderMenu,
        contrastPivotMenu,
        detectsDarkOnLightAction,
        maximumImageDimensionMenu,
        forceUseInputCVPixelBufferDirectlyAction,
        inHierarchyAction
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectDocumentSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectDocumentSegmentationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectDocumentSegmentationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectDocumentSegmentationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectDocumentSegmentationRequest *request = [[VNDetectDocumentSegmentationRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectDocumentSegmentationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceCaptureQualityRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectFaceCaptureQualityRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectFaceCaptureQualityRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectDocumentSegmentationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectFaceCaptureQualityRequest *request = [[VNDetectFaceCaptureQualityRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceCaptureQualityRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFace3DLandmarksRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectFace3DLandmarksRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFace3DLandmarksRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectFace3DLandmarksRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFace3DLandmarksRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceExpressionsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectFaceExpressionsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFaceExpressionsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectFaceExpressionsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFaceExpressionsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFaceGazeRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectFaceGazeRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFaceGazeRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectFaceGazeRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL resolveSomewhereElseDirection = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("resolveSomewhereElseDirection"));
    UIAction *resolveSomewhereElseDirectionAction = [UIAction actionWithTitle:@"resolveSomewhereElseDirection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setResolveSomewhereElseDirection:"), !resolveSomewhereElseDirection);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    resolveSomewhereElseDirectionAction.state = resolveSomewhereElseDirection ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFaceGazeRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        resolveSomewhereElseDirectionAction
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectFacePoseRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectFacePoseRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFacePoseRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectFacePoseRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectFacePoseRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHorizonRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectHorizonRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHorizonRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHorizonRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHorizonRequest *request = [[VNDetectHorizonRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHorizonRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanBodyPoseRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectHumanBodyPoseRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHumanBodyPoseRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHorizonRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHumanBodyPoseRequest *request = [[VNDetectHumanBodyPoseRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:nil];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL detectsHands = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("detectsHands"));
    UIAction *detectsHandsAction = [UIAction actionWithTitle:@"detectsHands" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setDetectsHands:"), !detectsHands);
        [viewModel updateRequest:request completionHandler:nil];
    }];
    detectsHandsAction.state = detectsHands ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSError * _Nullable error = nil;
    
    NSArray<NSString *> *supportedJointNames = [request supportedJointNamesAndReturnError:&error];
    assert(error == nil);
    NSMutableArray<UIAction *> *supportedJointNameActions = [[NSMutableArray alloc] initWithCapacity:supportedJointNames.count];
    for (NSString *jointName in supportedJointNames) {
        UIAction *action = [UIAction actionWithTitle:jointName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedJointNameActions addObject:action];
    }
    UIMenu *supportedJointNamesMenu = [UIMenu menuWithTitle:@"supportedJointNames" children:supportedJointNameActions];
    supportedJointNamesMenu.subtitle = @(supportedJointNameActions.count).stringValue;
    [supportedJointNameActions release];
    
    //
    
    NSArray<NSString *> *supportedJointsGroupNames = [request supportedJointsGroupNamesAndReturnError:&error];
    assert(error == nil);
    NSMutableArray<UIAction *> *supportedJointsGroupNameActions = [[NSMutableArray alloc] initWithCapacity:supportedJointsGroupNames.count];
    for (NSString *jointsGroupName in supportedJointsGroupNames) {
        UIAction *action = [UIAction actionWithTitle:jointsGroupName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedJointsGroupNameActions addObject:action];
    }
    UIMenu *supportedJointsGroupNamesMenu = [UIMenu menuWithTitle:@"supportedJointsGroupNames" children:supportedJointsGroupNameActions];
    supportedJointsGroupNamesMenu.subtitle = @(supportedJointsGroupNameActions.count).stringValue;
    [supportedJointsGroupNameActions release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHumanBodyPoseRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        detectsHandsAction,
        supportedJointNamesMenu,
        supportedJointsGroupNamesMenu
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanBodyPose3DRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNDetectHumanBodyPose3DRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHumanBodyPose3DRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHumanBodyPose3DRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHumanBodyPose3DRequest *request = [[VNDetectHumanBodyPose3DRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
                
                [viewModel getValuesWithCompletionHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests, NSArray<__kindof VNObservation *> * _Nonnull observations, UIImage * _Nullable image) {
                    UIAction *action = [UIDeferredMenuElement _cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:viewModel observations:observations image:image imageLayer:imageVisionLayer];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
                    });
                }];
            }];
            
            [request release];
        }];
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHumanBodyPose3DRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}


#pragma mark - Common

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
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
#warning supportedComputeStageDevicesAndReturnError setComputeDevice:forComputeStage:
    //
    
    UIAction *removeRequestAction = [UIAction actionWithTitle:@"Remove Requrest" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeRequest:request completionHandler:nil];
    }];
    removeRequestAction.attributes = UIMenuElementAttributesDestructive;
    [children addObject:removeRequestAction];
    
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
    [children addObject:publicRevisionsMenu];
    
    //
    
    NSIndexSet *privateRevisionsSet = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)([request class], sel_registerName("privateRevisionsSet"));
    NSMutableArray<UIAction *> *privateRevisionActions = [[NSMutableArray alloc] initWithCapacity:privateRevisionsSet.count];
    [privateRevisionsSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *description = reinterpret_cast<id (*)(Class, SEL, NSUInteger)>(objc_msgSend)([request class], sel_registerName("descriptionForPrivateRevision:"), idx);
        NSString *title = [NSString stringWithFormat:@"%@ (%ld)", description, idx];
        
        UIAction *action = [UIAction actionWithTitle:title
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
    [children addObject:privateRevisionsMenu];
    
    //
    
    if ([request respondsToSelector:@selector(supportedIdentifiersAndReturnError:)]) {
        NSError * _Nullable error = nil;
        NSArray<NSString *> *supportedIdentifiers = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedIdentifiersAndReturnError:"), &error);
        assert(error == nil);
        
        NSMutableArray<UIAction *> *supportedIdentifierActions = [[NSMutableArray alloc] initWithCapacity:supportedIdentifiers.count];
        for (NSString *identifier in supportedIdentifiers) {
            UIAction *action = [UIAction actionWithTitle:identifier image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
            }];
            action.attributes = UIMenuElementAttributesDisabled;
            [supportedIdentifierActions addObject:action];
        }
        UIMenu *suportedIdentifiersMenu = [UIMenu menuWithTitle:@"Supported Identifiers" children:supportedIdentifierActions];
        suportedIdentifiersMenu.subtitle = [NSString stringWithFormat:@"%ld identifiers", supportedIdentifierActions.count];
        [supportedIdentifierActions release];
        
        [children addObject:suportedIdentifiersMenu];
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:children];
    [children release];
    
    return menu;
}

@end
