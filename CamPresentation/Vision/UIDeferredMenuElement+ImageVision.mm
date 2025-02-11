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
#import <CamPresentation/AssetCollectionsViewControllerDelegateResolver.h>
#import <CamPresentation/CALayer+CP_UIKit.h>
#import <CamPresentation/NSStringFromVNImageCropAndScaleOption.h>
#import <CamPresentation/NSStringFromVNTrackOpticalFlowRequestComputationAccuracy.h>
#import <CamPresentation/NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy.h>
#import <CamPresentation/NSStringFromVNRequestTextRecognitionLevel.h>
#import <CamPresentation/NSStringFromVNRequestTrackingLevel.h>
#import <TargetConditionals.h>

VN_EXPORT NSString * const VNTextRecognitionOptionNone;
VN_EXPORT NSString * const VNTextRecognitionOptionASCIICharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionEnglishCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionDanishCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionDutchCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionFrenchCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionGermanCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionIcelandicCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionItalianCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionNorwegianCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionPortugueseCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionSpanishCharacterSet;
VN_EXPORT NSString * const VNTextRecognitionOptionSwedishCharacterSet;

@implementation UIDeferredMenuElement (ImageVision)

+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel imageVisionLayer:(ImageVisionLayer *)imageVisionLayer drawingRunLoop:(SVRunLoop *)drawingRunLoop {
    assert(viewModel != nil);
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [viewModel getValuesWithCompletionHandler:^(NSArray<__kindof VNRequest *> * _Nonnull requests, NSArray<__kindof VNObservation *> * _Nonnull observations, UIImage * _Nullable image) {
            UIMenu *requestsMenu = [UIDeferredMenuElement _cp_imageVisionRequestsMenuWithViewModel:viewModel addedRequests:requests observations:observations image:image imageVisionLayer:imageVisionLayer];
            UIMenu *imageVisionLayerMenu = [UIDeferredMenuElement _cp_imageVisionMenuWithImageVisionLayer:imageVisionLayer drawingRunLoop:drawingRunLoop];
            UIMenu *unimplementedRequestsMenu = [UIDeferredMenuElement _cp_imageVisionUnimplementedRequestsMenu];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[requestsMenu, imageVisionLayerMenu, unimplementedRequestsMenu]);
            });
        }];
    }];
}

+ (UIMenu *)_cp_imageVisionRequestsMenuWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage *)image imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
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
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanBodyPose3DRequestWithViewModel:viewModel addedRequests:requests observations:observations image:image imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanHandPoseRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanHeadRectanglesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectHumanRectanglesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectRectanglesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectScreenGazeRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectTextRectanglesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNDetectTrajectoriesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateAttentionBasedSaliencyImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateFaceSegmentsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateGlassesSegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateHumanAttributesSegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateImageFeaturePrintRequestWithViewModel:viewModel addedRequests:requests observations:observations image:image imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateImageSegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateInstanceMaskGatingRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateObjectnessBasedSaliencyImageRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateOpticalFlowRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackOpticalFlowRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateSkySegmentationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNIdentifyJunkRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNImageBlurScoreRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNImageExposureScoreRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeAnimalsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeAnimalHeadsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeAnimalFacesRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeFoodAndDrinkRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeObjectsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeSportBallsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeTextRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeDocumentsRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRemoveBackgroundRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNSceneClassificationRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackObjectRequestWithViewModel:viewModel addedRequests:requests observations:observations],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackLegacyFaceCoreObjectRequestWithViewModel:viewModel addedRequests:requests observations:observations],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackMaskRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackRectangleRequestWithViewModel:viewModel addedRequests:requests observations:observations],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTranslationalImageRegistrationRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackTranslationalImageRegistrationRequestWithViewModel:viewModel addedRequests:requests]
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
        [UIDeferredMenuElement _cp_imageVisionElementForVNGenerateInstanceMaskRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVN1JC7R3k4455fKQz0dY1VhQWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNNOPRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNHomographicImageRegistrationRequestWithViewModel:viewModel addedRequests:requests imageVisionLayer:imageVisionLayer],
        [UIDeferredMenuElement _cp_imageVisionElementForVNRecognizeDocumentElementsRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackHomographyRequestWithViewModel:viewModel addedRequests:requests],
        [UIDeferredMenuElement _cp_imageVisionElementForVNTrackHomographicImageRegistrationRequestWithViewModel:viewModel addedRequests:requests]
    ]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        usefulRequestsMenu, uselessRequestsMenu
    ]];
    
    return menu;
}

+ (UIMenu *)_cp_imageVisionMenuWithImageVisionLayer:(ImageVisionLayer *)imageVisionLayer drawingRunLoop:(SVRunLoop *)drawingRunLoop {
    BOOL shouldDrawImage = imageVisionLayer.shouldDrawImage;
    UIAction *shouldDrawImageAction = [UIAction actionWithTitle:@"shouldDrawImage" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [drawingRunLoop runBlock:^{
            imageVisionLayer.shouldDrawImage = !shouldDrawImage;
        }];
    }];
    shouldDrawImageAction.state = shouldDrawImage ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL shouldDrawDetails = imageVisionLayer.shouldDrawDetails;
    UIAction *shouldDrawDetailsAction = [UIAction actionWithTitle:@"shouldDrawDetails" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [drawingRunLoop runBlock:^{
            imageVisionLayer.shouldDrawDetails = !shouldDrawDetails;
        }];
    }];
    shouldDrawDetailsAction.state = shouldDrawDetails ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL shouldDrawContoursSeparately = imageVisionLayer.shouldDrawContoursSeparately;
    UIAction *shouldDrawContoursSeparatelyAction = [UIAction actionWithTitle:@"shouldDrawContoursSeparately" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [drawingRunLoop runBlock:^{
            imageVisionLayer.shouldDrawContoursSeparately = !shouldDrawContoursSeparately;
        }];
    }];
    shouldDrawContoursSeparatelyAction.state = shouldDrawContoursSeparately ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    BOOL shouldDrawOverlay = imageVisionLayer.shouldDrawOverlay;
    UIAction *shouldDrawOverlayAction = [UIAction actionWithTitle:@"shouldDrawOverlay" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [drawingRunLoop runBlock:^{
            imageVisionLayer.shouldDrawOverlay = !shouldDrawOverlay;
        }];
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

+ (UIAction *)_cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:(ImageVisionViewModel *)viewModel observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage *)image imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    auto emptyAction = ^UIAction * (NSString *subtitle) {
        UIAction *action = [UIAction actionWithTitle:@"Present VNHumanBodyPose3DObservation Scene View" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        action.cp_overrideNumberOfTitleLines = 0;
        action.attributes = UIMenuElementAttributesDisabled;
        action.subtitle = subtitle;
        return action;
    };
    
    if (image == nil) {
        return emptyAction(@"No Image on view Model.");
    }
    
    NSMutableArray<VNHumanBodyPose3DObservation *> *humanBodyPose3DObservations = [NSMutableArray array];
    for (__kindof VNObservation *observation in observations) {
        if ([observation isKindOfClass:[VNHumanBodyPose3DObservation class]]) {
            [humanBodyPose3DObservations addObject:static_cast<VNHumanBodyPose3DObservation *>(observation)];
        }
    }
    
    if (humanBodyPose3DObservations.count == 0) {
        return emptyAction(@"No VNHumanBodyPose3DObservation.");
    }
    
    //
    
    UIAction *action = [UIAction actionWithTitle:@"Present VNHumanBodyPose3DObservation Scene View" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
#if TARGET_OS_VISION
        abort();
#else
        UIView *layerView = imageVisionLayer.cp_associatedView;
        assert(layerView != nil);
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
#endif
    }];
    
    action.cp_overrideNumberOfTitleLines = 0;
    return action;
}

+ (UIMenu *)_cp_imageVisionUnimplementedRequestsMenu {
    NSMutableArray<NSString *> *unimplementedClassNames = [reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(objc_lookUpClass("VNRequestSpecifier"), sel_registerName("allAvailableRequestClassNames")) mutableCopy];
    
    NSArray<NSString *> *implementedClassNames = @[
        @"VNAlignFaceRectangleRequest", // ✅
        @"VNCalculateImageAestheticsScoresRequest", // ✅
        @"VNClassifyCityNatureImageRequest", // ✅
        @"VNClassifyFaceAttributesRequest", // ✅
        @"VNClassifyImageAestheticsRequest", // ✅
        @"VNClassifyImageRequest", // ✅
        @"VNClassifyJunkImageRequest", // ✅
        @"VNClassifyMemeImageRequest", // ✅
        @"VNVYvzEtX1JlUdu8xx5qhDI", // ✅
        @"VNClassifyPotentialLandmarkRequest", // ✅
        @"VN5kJNH3eYuyaLxNpZr5Z7zi", // ✅
        @"VN6Mb1ME89lyW3HpahkEygIG", // ✅
        @"VNCoreMLRequest", // ✅
        @"VNCreateAnimalprintRequest", // ✅
        @"VNCreateDetectionprintRequest", // ✅
        @"VNCreateFaceRegionMapRequest", // ✅
        @"VNCreateFaceprintRequest", // ✅
        @"VN6kBnCOr2mZlSV6yV1dLwB", // ✅
        @"VNCreateImageFingerprintsRequest", // ✅
        @"VNCreateImageprintRequest", // ✅
        @"VNCreateNeuralHashprintRequest", // ✅
        @"VNCreateSceneprintRequest", // ✅
        @"VNCreateSmartCamprintRequest", // ✅
        @"VNCreateTorsoprintRequest", // ✅
        @"VNDetectAnimalBodyPoseRequest", // ✅
        @"VNDetectBarcodesRequest", // ✅
        @"VNDetectContoursRequest", // ✅
        @"VNDetectDocumentSegmentationRequest", // ✅
        @"VNDetectFaceCaptureQualityRequest", // ✅
        @"VNDetectFaceLandmarksRequest", // ✅
        @"VNDetectFace3DLandmarksRequest", // ✅
        @"VNDetectFaceExpressionsRequest", // ✅
        @"VNDetectFaceGazeRequest", // ✅
        @"VNDetectFacePoseRequest", // ✅
        @"VNDetectFaceRectanglesRequest", // ✅
        @"VNDetectHorizonRequest", // ✅
        @"VNDetectHumanBodyPoseRequest", // ✅
        @"VNDetectHumanBodyPose3DRequest", // ✅
        @"VNDetectHumanHandPoseRequest", // ✅
        @"VNDetectHumanHeadRectanglesRequest", // ✅
        @"VNDetectHumanRectanglesRequest", // ✅
        @"VNDetectRectanglesRequest", // ✅
        @"VNDetectScreenGazeRequest", // ✅
        @"VNDetectTextRectanglesRequest", // ✅
        @"VNDetectTrajectoriesRequest", // ✅
        @"VNGenerateAnimalSegmentationRequest", // ✅
        @"VNGenerateAttentionBasedSaliencyImageRequest", // ✅
        @"VNGenerateFaceSegmentsRequest", // ✅
        @"VNGenerateGlassesSegmentationRequest", // ✅
        @"VNGenerateHumanAttributesSegmentationRequest", // ✅
        @"VNGenerateImageFeaturePrintRequest", // ✅
        @"VNGenerateInstanceMaskRequest", // ✅
        @"VNGenerateForegroundInstanceMaskRequest", // ✅
        @"VNGenerateImageSegmentationRequest", // ✅
        @"VNGenerateInstanceMaskGatingRequest", // ✅
        @"VNGenerateObjectnessBasedSaliencyImageRequest", // ✅
        @"VNGenerateOpticalFlowRequest", // ✅
        @"VN1JC7R3k4455fKQz0dY1VhQ", // ✅
        @"VNGeneratePersonInstanceMaskRequest", // ✅
        @"VNGeneratePersonSegmentationRequest", // ✅
        @"VNGenerateSkySegmentationRequest", // ✅
        @"VNHomographicImageRegistrationRequest", // ﹖
        @"VNIdentifyJunkRequest", // ✅
        @"VNImageBlurScoreRequest", // ✅
        @"VNImageExposureScoreRequest", // ✅
        @"VNNOPRequest", // ✅
        @"VNRecognizeAnimalsRequest", // ✅
        @"VNRecognizeAnimalHeadsRequest", // ✅
        @"VNRecognizeAnimalFacesRequest", // ✅
        @"VNRecognizeFoodAndDrinkRequest", // ✅
        @"VNRecognizeObjectsRequest", // ✅
        @"VNRecognizeSportBallsRequest", // ✅
        @"VNRecognizeTextRequest", // ✅
        @"VNRecognizeDocumentElementsRequest", // ﹖
        @"VNRecognizeDocumentsRequest", // ✅
        @"VNRemoveBackgroundRequest", // ✅
        @"VNSceneClassificationRequest", // ✅
        @"VNTrackHomographyRequest", // ✅
        @"VNTrackHomographicImageRegistrationRequest", // ✅
        @"VNTrackLegacyFaceCoreObjectRequest", // ✅
        @"VNTrackMaskRequest", // ✅
        @"VNTrackObjectRequest", // ✅
        @"VNTrackOpticalFlowRequest", // ✅
        @"VNTrackRectangleRequest", // ✅
        @"VNTrackTranslationalImageRegistrationRequest", // ✅
        @"VNTranslationalImageRegistrationRequest" // ✅
    ];
    
    for (NSString *name in implementedClassNames) {
        [unimplementedClassNames removeObject:name];
    }
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:unimplementedClassNames.count];
    for (NSString *name in unimplementedClassNames) {
        UIAction *action = [UIAction actionWithTitle:name image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [actions addObject:action];
    }
    [unimplementedClassNames release];
    
    UIMenu *unimplementedRequestsMenu = [UIMenu menuWithTitle:@"Unimplemented Requests" children:actions];
    [actions release];
    
    return unimplementedRequestsMenu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionComputeDistanceElementWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage *)image imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    auto emptyAction = ^UIAction * {
        UIAction *action = [UIAction actionWithTitle:@"Compute Distance" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        action.subtitle = @"VNFeaturePrintObservation is required.";
        
        return action;
    };
    
    //
    
    VNGenerateImageFeaturePrintRequest * _Nullable request = nil;
    for (__kindof VNRequest *_request in requests) {
        if ([_request isKindOfClass:[VNGenerateImageFeaturePrintRequest class]]) {
            request = _request;
            break;
        }
    }
    
    if (request == nil) {
        return emptyAction();
    }
    
    //
    
    NSMutableArray<UIAction *> *actions = [NSMutableArray new];
    
    for (VNFeaturePrintObservation *featurePrintObservation in observations) {
        if (![featurePrintObservation isKindOfClass:[VNFeaturePrintObservation class]]) continue;
        
        UIAction *action = [UIAction actionWithTitle:featurePrintObservation.uuid.UUIDString image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            AssetCollectionsViewController *assetCollectionsViewController = [AssetCollectionsViewController new];
            
            AssetCollectionsViewControllerDelegateResolver *resolver = [AssetCollectionsViewControllerDelegateResolver new];
            resolver.didSelectAssetsHandler = ^(AssetCollectionsViewController * _Nonnull assetCollectionsViewController, NSSet<PHAsset *> * _Nonnull selectedAssets) {
                PHAsset *asset = selectedAssets.allObjects.firstObject;
                assert(asset != nil);
                
                UIViewController *presentingViewController = assetCollectionsViewController.presentingViewController;
                assert(presentingViewController != nil);
                
                [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
                    [viewModel computeDistanceWithPHAsset:asset toFeaturePrintObservation:featurePrintObservation withRequest:request completionHandler:^(float distance, VNFeaturePrintObservation * _Nullable observationFromAsset, NSError * _Nullable error) {
                        assert(error == nil);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Distance" message:[NSString stringWithFormat:@"distance: %lf", distance] preferredStyle:UIAlertControllerStyleAlert];
                            
                            UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                
                            }];
                            
                            [alertController addAction:doneAction];
                            
                            [presentingViewController presentViewController:alertController animated:YES completion:nil];
                        });
                    }];
                }];
            };
            assetCollectionsViewController.delegate = resolver;
            objc_setAssociatedObject(assetCollectionsViewController, resolver, resolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resolver release];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetCollectionsViewController];
            [assetCollectionsViewController release];
            
            //
            
            UIView *layerView = imageVisionLayer.cp_associatedView;
            assert(layerView != nil);
            UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
            assert(viewController != nil);
            
            //
            
            [viewController presentViewController:navigationController animated:YES completion:nil];
            [navigationController release];
        }];
        
        action.cp_overrideNumberOfSubtitleLines = 0;
        
        [actions addObject:action];
    }
    
    if (actions.count == 0) {
        [actions release];
        return emptyAction();
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Compute Distance" children:actions];
    [actions release];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNAlignFaceRectangleRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNAlignFaceRectangleRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNAlignFaceRectangleRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNAlignFaceRectangleRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL forceFaceprintCreation = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("forceFaceprintCreation"));
    UIAction *forceFaceprintCreationAction = [UIAction actionWithTitle:@"forceFaceprintCreation" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setForceFaceprintCreation:"), !forceFaceprintCreation);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateTorsoprintRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = @"Human Detections";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNCreateSceneprintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNCreateSceneprintRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNCreateSceneprintRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNRequest *request = [[objc_lookUpClass("VNCreateSceneprintRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL faceCoreEnhanceEyesAndMouthLocalization = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreEnhanceEyesAndMouthLocalization"));
    
    UIAction *faceCoreEnhanceEyesAndMouthLocalizationAction = [UIAction actionWithTitle:@"faceCoreEnhanceEyesAndMouthLocalization" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreEnhanceEyesAndMouthLocalization:"), !faceCoreEnhanceEyesAndMouthLocalization);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreEnhanceEyesAndMouthLocalizationAction.subtitle = @"???";
    faceCoreEnhanceEyesAndMouthLocalizationAction.state = faceCoreEnhanceEyesAndMouthLocalization ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractBlink = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractBlink"));
    
    UIAction *faceCoreExtractBlinkAction = [UIAction actionWithTitle:@"faceCoreExtractBlink" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractBlink:"), !faceCoreExtractBlink);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreExtractBlinkAction.subtitle = @"Not working";
    faceCoreExtractBlinkAction.state = faceCoreExtractBlink ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractSmile = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractSmile"));
    
    UIAction *faceCoreExtractSmileAction = [UIAction actionWithTitle:@"faceCoreExtractSmile" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractSmile:"), !faceCoreExtractSmile);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    refineMouthRegionAction.subtitle = @"???";
    refineMouthRegionAction.state = refineMouthRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL refineLeftEyeRegion = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("refineLeftEyeRegion"));
    UIAction *refineLeftEyeRegionAction = [UIAction actionWithTitle:@"refineLeftEyeRegion" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setRefineLeftEyeRegion:"), !refineLeftEyeRegion);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    refineLeftEyeRegionAction.subtitle = @"???";
    refineLeftEyeRegionAction.state = refineLeftEyeRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL refineRightEyeRegion = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("refineRightEyeRegion"));
    UIAction *refineRightEyeRegionAction = [UIAction actionWithTitle:@"refineRightEyeRegion" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setRefineRightEyeRegion:"), !refineRightEyeRegion);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    refineRightEyeRegionAction.subtitle = @"???";
    refineRightEyeRegionAction.state = refineRightEyeRegion ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL performBlinkDetection = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("performBlinkDetection"));
    UIAction *performBlinkDetectionAction = [UIAction actionWithTitle:@"performBlinkDetection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setPerformBlinkDetection:"), !performBlinkDetection);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    coalesceCompositeSymbologiesAction.state = coalesceCompositeSymbologies ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL stopAtFirstPyramidWith2DCode = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("stopAtFirstPyramidWith2DCode"));
    UIAction *stopAtFirstPyramidWith2DCodeAction = [UIAction actionWithTitle:@"stopAtFirstPyramidWith2DCode" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setStopAtFirstPyramidWith2DCode:"), !stopAtFirstPyramidWith2DCode);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    stopAtFirstPyramidWith2DCodeAction.state = stopAtFirstPyramidWith2DCode ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL useSegmentationPregating = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useSegmentationPregating"));
    UIAction *useSegmentationPregatingAction = [UIAction actionWithTitle:@"useSegmentationPregating" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseSegmentationPregating:"), !useSegmentationPregating);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    useSegmentationPregatingAction.state = useSegmentationPregating ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL useMLDetector = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useMLDetector"));
    UIAction *useMLDetectorAction = [UIAction actionWithTitle:@"useMLDetector" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseMLDetector:"), !useMLDetector);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIAction *resetContrastPivotAction = [UIAction actionWithTitle:@"Reset" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.contrastPivot = nil;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    
    UIMenu *contrastPivotMenu = [UIMenu menuWithTitle:@"contrastPivot" children:@[
        contrastPivotSliderElement,
        resetContrastPivotAction
    ]];
    
    //
    
    BOOL detectsDarkOnLight = request.detectsDarkOnLight;
    
    UIAction *detectsDarkOnLightAction = [UIAction actionWithTitle:@"detectsDarkOnLight" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        request.detectsDarkOnLight = !detectsDarkOnLight;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    forceUseInputCVPixelBufferDirectlyAction.subtitle = @"???";
    forceUseInputCVPixelBufferDirectlyAction.state = forceUseInputCVPixelBufferDirectly ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL inHierarchy = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("inHierarchy"));
    
    UIAction *inHierarchyAction = [UIAction actionWithTitle:@"inHierarchy" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setInHierarchy:"), !inHierarchy);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    inHierarchyAction.subtitle = @"???";
    inHierarchyAction.state = inHierarchy ? UIMenuElementStateOn : UIMenuElementStateOff;
    
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHumanBodyPoseRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHumanBodyPoseRequest *request = [[VNDetectHumanBodyPoseRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanBodyPose3DRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage * _Nullable)image imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNDetectHumanBodyPose3DRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHumanBodyPose3DRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHumanBodyPose3DRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHumanBodyPose3DRequest *request = [[VNDetectHumanBodyPose3DRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
                
//                UIAction *action = [UIDeferredMenuElement _cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:viewModel observations:observations image:image imageVisionLayer:imageVisionLayer];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
//                });
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
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
    
    UIAction *humanBodyPose3DObservationSceneAction = [UIDeferredMenuElement _cp_imageVisionPresentHumanBodyPose3DObservationSceneViewWithViewModel:viewModel observations:observations image:image imageVisionLayer:imageVisionLayer];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHumanBodyPose3DRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        supportedJointNamesMenu,
        supportedJointsGroupNamesMenu,
        humanBodyPose3DObservationSceneAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanHandPoseRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectHumanHandPoseRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHumanHandPoseRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHumanHandPoseRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectHumanHandPoseRequest *request = [[VNDetectHumanHandPoseRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *maximumHandCountStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSUInteger maximumHandCount = request.maximumHandCount;
        
        UILabel *label = [UILabel new];
        label.text = @(maximumHandCount).stringValue;
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = maximumHandCount;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            NSUInteger value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            request.maximumHandCount = value;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumHandCountMenu = [UIMenu menuWithTitle:@"Maximum Hand Count" children:@[maximumHandCountStepperElement]];
    
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
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHumanHandPoseRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        maximumHandCountMenu,
        supportedJointNamesMenu,
        supportedJointsGroupNamesMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanHeadRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectHumanHeadRectanglesRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectHumanHeadRectanglesRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectHumanHeadRectanglesRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectHumanHeadRectanglesRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectHumanRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectHumanRectanglesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectHumanRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectHumanRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[VNDetectHumanRectanglesRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL upperBodyOnly = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("upperBodyOnly"));
    UIAction *upperBodyOnlyAction = [UIAction actionWithTitle:@"upperBodyOnly" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUpperBodyOnly:"), !upperBodyOnly);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    upperBodyOnlyAction.state = upperBodyOnly ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectHumanRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        upperBodyOnlyAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectRectanglesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *minimumAspectRatioSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.minimumAspectRatio).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.minimumAspectRatio;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.minimumAspectRatio = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *minimumAspectRatioMenu = [UIMenu menuWithTitle:@"Minimum Aspect Ratio" children:@[minimumAspectRatioSliderElement]];
    
    //
    
    __kindof UIMenuElement *maximumAspectRatioSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.maximumAspectRatio).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.maximumAspectRatio;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.maximumAspectRatio = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *maximumAspectRatioMenu = [UIMenu menuWithTitle:@"Maximum Aspect Ratio" children:@[maximumAspectRatioSliderElement]];
    
    //
    
    __kindof UIMenuElement *quadratureToleranceSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.quadratureTolerance).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 45.f;
        slider.value = request.quadratureTolerance;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.quadratureTolerance = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *quadratureToleranceMenu = [UIMenu menuWithTitle:@"Quadrature Tolerance" children:@[quadratureToleranceSliderElement]];
    
    //
    
    __kindof UIMenuElement *minimumSizeSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.minimumSize).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.minimumSize;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.minimumSize = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *minimumSizeMenu = [UIMenu menuWithTitle:@"Minimum Size" children:@[minimumSizeSliderElement]];
    
    //
    
    __kindof UIMenuElement *minimumConfidenceSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.minimumConfidence).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.minimumConfidence;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.minimumConfidence = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *minimumConfidenceMenu = [UIMenu menuWithTitle:@"Minimum Confidence" children:@[minimumConfidenceSliderElement]];
    
    //
    
    __kindof UIMenuElement *maximumObservationsStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.maximumObservations).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = request.maximumObservations;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            double value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            request.maximumObservations = value;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumObservationsMenu = [UIMenu menuWithTitle:@"Maximum Observations" children:@[maximumObservationsStepperElement]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        minimumAspectRatioMenu,
        maximumAspectRatioMenu,
        quadratureToleranceMenu,
        minimumSizeMenu,
        minimumConfidenceMenu,
        maximumObservationsMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectScreenGazeRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNDetectScreenGazeRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectScreenGazeRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNDetectScreenGazeRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *screenSizeStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSUInteger screenSize = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("screenSize"));
        
        //
        
        UILabel *label = [UILabel new];
        label.text = @(screenSize).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = screenSize;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            double value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setScreenSize:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *screenSizeMenu = [UIMenu menuWithTitle:@"Screen Size" children:@[screenSizeStepperElement]];
    screenSizeMenu.subtitle = @"???";
    
    //
    
    __kindof UIMenuElement *temporalSmoothingFrameCountStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSInteger temporalSmoothingFrameCount = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("temporalSmoothingFrameCount"));
        
        //
        
        UILabel *label = [UILabel new];
        label.text = @(temporalSmoothingFrameCount).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSIntegerMax;
        stepper.value = temporalSmoothingFrameCount;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            double value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSInteger)>(objc_msgSend)(request, sel_registerName("setTemporalSmoothingFrameCount:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *temporalSmoothingFrameCountMenu = [UIMenu menuWithTitle:@"Temporal Smoothing Frame Count" children:@[temporalSmoothingFrameCountStepperElement]];
    temporalSmoothingFrameCountMenu.subtitle = @"???";
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNDetectScreenGazeRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        screenSizeMenu,
        temporalSmoothingFrameCountMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectTextRectanglesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectTextRectanglesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectTextRectanglesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectTextRectanglesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectTextRectanglesRequest *request = [[VNDetectTextRectanglesRequest alloc] initWithCompletionHandler:nil];
            request.reportCharacterBoxes = YES;
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setTextRecognition:"), VNTextRecognitionOptionEnglishCharacterSet);
            
            // ???
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setAdditionalCharacters:"), @"두부");
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL reportCharacterBoxes = request.reportCharacterBoxes;
    UIAction *reportCharacterBoxesAction = [UIAction actionWithTitle:@"Report Character Boxes" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.reportCharacterBoxes = !reportCharacterBoxes;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    reportCharacterBoxesAction.state = reportCharacterBoxes ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSString *selectedTextRecognition = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("textRecognition"));
    
    NSArray<NSString *> *allTextRecognitionOptions = @[
        VNTextRecognitionOptionNone,
        VNTextRecognitionOptionASCIICharacterSet,
        VNTextRecognitionOptionEnglishCharacterSet,
        VNTextRecognitionOptionDanishCharacterSet,
        VNTextRecognitionOptionDutchCharacterSet,
        VNTextRecognitionOptionFrenchCharacterSet,
        VNTextRecognitionOptionGermanCharacterSet,
        VNTextRecognitionOptionIcelandicCharacterSet,
        VNTextRecognitionOptionItalianCharacterSet,
        VNTextRecognitionOptionNorwegianCharacterSet,
        VNTextRecognitionOptionPortugueseCharacterSet,
        VNTextRecognitionOptionSpanishCharacterSet,
        VNTextRecognitionOptionSwedishCharacterSet
    ];
    
    NSMutableArray<UIAction *> *textRecognitionActions = [[NSMutableArray alloc] initWithCapacity:allTextRecognitionOptions.count];
    
    for (NSString *textRecognition in allTextRecognitionOptions) {
        UIAction *action = [UIAction actionWithTitle:textRecognition image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setTextRecognition:"), textRecognition);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = ([textRecognition isEqualToString:selectedTextRecognition]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [textRecognitionActions addObject:action];
    }
    
    UIMenu *textRecognitionsMenu = [UIMenu menuWithTitle:@"Text Recognition Options" children:textRecognitionActions];
    [textRecognitionActions release];
    
    //
    
    BOOL detectDiacritics = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("detectDiacritics"));
    UIAction *detectDiacriticsAction = [UIAction actionWithTitle:@"Detect Diacritics" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setDetectDiacritics:"), !detectDiacritics);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    detectDiacriticsAction.subtitle = @"é, á, ó, ä, ö, ü";
    detectDiacriticsAction.state = detectDiacritics ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSUInteger minimumCharacterPixelHeight = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("minimumCharacterPixelHeight"));
    
    __kindof UIMenuElement *minimumCharacterPixelHeightStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(minimumCharacterPixelHeight).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = minimumCharacterPixelHeight;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            double value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setMinimumCharacterPixelHeight:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *minimumCharacterPixelHeightMenu = [UIMenu menuWithTitle:@"Minimum Character Pixel Height" children:@[minimumCharacterPixelHeightStepperElement]];
    
    //
    
    BOOL minimizeFalseDetections = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("minimizeFalseDetections"));
    
    UIAction *minimizeFalseDetectionsAction = [UIAction actionWithTitle:@"Minimize False Detections" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setMinimizeFalseDetections:"), !minimizeFalseDetections);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    
    minimizeFalseDetectionsAction.state = minimizeFalseDetections ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSUInteger algorithm = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("algorithm"));
    
    __kindof UIMenuElement *algorithmStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(algorithm).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = algorithm;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            double value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setAlgorithm:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *algorithmMenu = [UIMenu menuWithTitle:@"Algorithm" children:@[algorithmStepperElement]];
    algorithmMenu.subtitle = @"Confirmed: 0, 1, 2";
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectTextRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        reportCharacterBoxesAction,
        textRecognitionsMenu,
        detectDiacriticsAction,
        minimumCharacterPixelHeightMenu,
        minimizeFalseDetectionsAction,
        algorithmMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNDetectTrajectoriesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNDetectTrajectoriesRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNDetectTrajectoriesRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNDetectTrajectoriesRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNDetectTrajectoriesRequest *request = [[VNDetectTrajectoriesRequest alloc] initWithFrameAnalysisSpacing:CMTimeMake(1, 60) trajectoryLength:6 completionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *objectMinimumNormalizedRadiusSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.objectMinimumNormalizedRadius).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        
        slider.maximumValue = 1.f;
        slider.minimumValue = 0.f;
        slider.value = request.objectMinimumNormalizedRadius;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.objectMinimumNormalizedRadius = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *objectMinimumNormalizedRadiusMenu = [UIMenu menuWithTitle:@"Object Minimum Normalized Radius" children:@[
        objectMinimumNormalizedRadiusSliderElement
    ]];
    
    //
    
    __kindof UIMenuElement *objectMaximumNormalizedRadiusSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(request.objectMaximumNormalizedRadius).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        
        slider.maximumValue = 1.f;
        slider.minimumValue = 0.f;
        slider.value = request.objectMaximumNormalizedRadius;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                request.objectMaximumNormalizedRadius = value;
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *objectMaximumNormalizedRadiusMenu = [UIMenu menuWithTitle:@"Object Maximum Normalized Radius" children:@[
        objectMaximumNormalizedRadiusSliderElement
    ]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectTrajectoriesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        objectMinimumNormalizedRadiusMenu,
        objectMaximumNormalizedRadiusMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateAttentionBasedSaliencyImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNGenerateAttentionBasedSaliencyImageRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGenerateAttentionBasedSaliencyImageRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGenerateAttentionBasedSaliencyImageRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[VNGenerateAttentionBasedSaliencyImageRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGenerateAttentionBasedSaliencyImageRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateFaceSegmentsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateFaceSegmentsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateFaceSegmentsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateFaceSegmentsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    float faceBoundingBoxExpansionRatio = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceBoundingBoxExpansionRatio"));
    
    __kindof UIMenuElement *faceBoundingBoxExpansionRatioSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(faceBoundingBoxExpansionRatio).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        
        slider.maximumValue = 10.f;
        slider.minimumValue = 0.1f;
        slider.value = faceBoundingBoxExpansionRatio;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                reinterpret_cast<void (*)(id, SEL, float)>(objc_msgSend)(request, sel_registerName("setFaceBoundingBoxExpansionRatio:"), faceBoundingBoxExpansionRatio);
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
    
    UIMenu *faceBoundingBoxExpansionRatioMenu = [UIMenu menuWithTitle:@"Face Bounding Box Expansion Ratio" children:@[
        faceBoundingBoxExpansionRatioSliderElement
    ]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateFaceSegmentsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        faceBoundingBoxExpansionRatioMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateGlassesSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateGlassesSegmentationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateGlassesSegmentationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateGlassesSegmentationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateGlassesSegmentationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        qualityLevelsMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateHumanAttributesSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateHumanAttributesSegmentationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateHumanAttributesSegmentationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateHumanAttributesSegmentationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
    
    NSError * _Nullable error = nil;
    NSArray<NSString *> *supportedHumanAttributesNames = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedHumanAttributesNamesAndReturnError:"), &error);
    assert(error == nil);
    
    NSMutableArray<UIAction *> *supportedHumanAttributeActions = [[NSMutableArray alloc] initWithCapacity:supportedHumanAttributesNames.count];
    for (NSString *name in supportedHumanAttributesNames) {
        UIAction *action = [UIAction actionWithTitle:name image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedHumanAttributeActions addObject:action];
    }
    UIMenu *supportedHumanAttributesMenu = [UIMenu menuWithTitle:@"Supported Human Attributes" children:supportedHumanAttributeActions];
    supportedHumanAttributesMenu.subtitle = [NSString stringWithFormat:@"%ld attributes", supportedHumanAttributeActions.count];
    [supportedHumanAttributeActions release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateHumanAttributesSegmentationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        qualityLevelsMenu,
        supportedHumanAttributesMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateImageFeaturePrintRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations image:(UIImage *)image imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNGenerateImageFeaturePrintRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGenerateImageFeaturePrintRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGenerateImageFeaturePrintRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNGenerateImageFeaturePrintRequest *request = [[VNGenerateImageFeaturePrintRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
        //        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *computeDistanceElement = [UIDeferredMenuElement _cp_imageVisionComputeDistanceElementWithViewModel:viewModel addedRequests:requests observations:observations image:image imageVisionLayer:imageVisionLayer];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGenerateImageFeaturePrintRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        computeDistanceElement,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateInstanceMaskRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateInstanceMaskRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateInstanceMaskRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateInstanceMaskRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
        action.subtitle = @"Equivalent to VNGenerateForegroundInstanceMaskRequest";
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateInstanceMaskRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    menu.subtitle = @"Equivalent to VNGenerateForegroundInstanceMaskRequest";
    
    return menu;
}

// TODO: https://x.com/_silgen_name/status/1876233639396295167
+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateImageSegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateImageSegmentationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateImageSegmentationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateImageSegmentationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                NSLog(@"%@", error);
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        action.subtitle = @"Requires Private Entitlement";
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateImageSegmentationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    menu.subtitle = @"Requires Private Entitlement";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateInstanceMaskGatingRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateInstanceMaskGatingRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateInstanceMaskGatingRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateInstanceMaskGatingRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
        action.subtitle = @"Detect that masking is capable";
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    NSString *applicableDetectorType = reinterpret_cast<id (*)(id, SEL, NSUInteger, id *)>(objc_msgSend)(request, sel_registerName("applicableDetectorTypeForRevision:error:"), request.revision, &error);
    assert(error == nil);
    
    UIAction *applicableDetectorTypeAction = [UIAction actionWithTitle:applicableDetectorType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    applicableDetectorTypeAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateInstanceMaskGatingRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        applicableDetectorTypeAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    menu.subtitle = @"Detect that masking is capable";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateObjectnessBasedSaliencyImageRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNGenerateObjectnessBasedSaliencyImageRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGenerateObjectnessBasedSaliencyImageRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGenerateObjectnessBasedSaliencyImageRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNGenerateObjectnessBasedSaliencyImageRequest *request = [[VNGenerateObjectnessBasedSaliencyImageRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    NSString *applicableDetectorType = reinterpret_cast<id (*)(id, SEL, NSUInteger, id *)>(objc_msgSend)(request, sel_registerName("applicableDetectorTypeForRevision:error:"), request.revision, &error);
    assert(error == nil);
    
    UIAction *applicableDetectorTypeAction = [UIAction actionWithTitle:applicableDetectorType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    applicableDetectorTypeAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGenerateObjectnessBasedSaliencyImageRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        applicableDetectorTypeAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackOpticalFlowRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNTrackOpticalFlowRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTrackOpticalFlowRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNTrackOpticalFlowRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNTrackOpticalFlowRequest *request = [[VNTrackOpticalFlowRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    VNTrackOpticalFlowRequestComputationAccuracy selectedComputationAccuracy = request.computationAccuracy;
    
    auto computationAccuracyActionsVec = std::vector<VNTrackOpticalFlowRequestComputationAccuracy> {
        VNTrackOpticalFlowRequestComputationAccuracyLow,
        VNTrackOpticalFlowRequestComputationAccuracyMedium,
        VNTrackOpticalFlowRequestComputationAccuracyHigh,
        VNTrackOpticalFlowRequestComputationAccuracyVeryHigh
    }
    | std::views::transform([viewModel, request, selectedComputationAccuracy](VNTrackOpticalFlowRequestComputationAccuracy computationAccuracy) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNTrackOpticalFlowRequestComputationAccuracy(computationAccuracy) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            request.computationAccuracy = computationAccuracy;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = (selectedComputationAccuracy == computationAccuracy) ? UIMenuElementStateOn : UIMenuElementStateOff;
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *computationAccuracyActions = [[NSArray alloc] initWithObjects:computationAccuracyActionsVec.data() count:computationAccuracyActionsVec.size()];
    UIMenu *computationAccuraciesMenu = [UIMenu menuWithTitle:@"Computation Accuracy" children:computationAccuracyActions];
    [computationAccuracyActions release];
    computationAccuraciesMenu.subtitle = NSStringFromVNTrackOpticalFlowRequestComputationAccuracy(selectedComputationAccuracy);
    
    //
    
    BOOL keepNetworkOutput = request.keepNetworkOutput;
    UIAction *keepNetworkOutputAction = [UIAction actionWithTitle:@"Keep Network Output" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.keepNetworkOutput = !keepNetworkOutput;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    keepNetworkOutputAction.cp_overrideNumberOfSubtitleLines = 0;
    keepNetworkOutputAction.subtitle = @"Setting this to `YES` will keep the raw pixel buffer coming from the the ML network. When set to `YES`, the outputPixelFormat is ignored.";
    keepNetworkOutputAction.state = keepNetworkOutput ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    OSType selectedOutputPixelFormat = request.outputPixelFormat;
    
    NSError * _Nullable error = nil;
    NSArray<NSNumber *> *supportedOutputPixelFormats = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedOutputPixelFormatsAndReturnError:"), &error);
    assert(error == nil);
    NSMutableArray<UIAction *> *supportedOutputPixelFormatActions = [[NSMutableArray alloc] initWithCapacity:supportedOutputPixelFormats.count];
    for (NSNumber *pixelFormatNumber in supportedOutputPixelFormats) {
        static_assert(sizeof(OSType) == sizeof(unsigned int));
        
        OSType pixelFormat = pixelFormatNumber.unsignedIntValue;
        NSString *string = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&pixelFormat) length:4 encoding:NSUTF8StringEncoding];
        
        UIAction *action = [UIAction actionWithTitle:string image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            request.outputPixelFormat = pixelFormat;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = (selectedOutputPixelFormat == pixelFormat) ? UIMenuElementStateOn : UIMenuElementStateOff;
        [supportedOutputPixelFormatActions addObject:action];
    }
    
    UIMenu *supportedOutputPixelFormatsMenu = [UIMenu menuWithTitle:@"Output Pixel Format" children:supportedOutputPixelFormatActions];
    [supportedOutputPixelFormatActions release];
    NSString *selectedOutputPixelFormatString = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&selectedOutputPixelFormat) length:4 encoding:NSUTF8StringEncoding];
    supportedOutputPixelFormatsMenu.subtitle = selectedOutputPixelFormatString;
    [selectedOutputPixelFormatString release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackOpticalFlowRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        computationAccuraciesMenu,
        keepNetworkOutputAction,
        supportedOutputPixelFormatsMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateOpticalFlowRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNGenerateOpticalFlowRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNGenerateOpticalFlowRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNGenerateOpticalFlowRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            AssetCollectionsViewController *assetCollectionsViewController = [AssetCollectionsViewController new];
            
            AssetCollectionsViewControllerDelegateResolver *resolver = [AssetCollectionsViewControllerDelegateResolver new];
            resolver.didSelectAssetsHandler = ^(AssetCollectionsViewController * _Nonnull assetCollectionsViewController, NSSet<PHAsset *> * _Nonnull selectedAssets) {
                PHAsset *asset = selectedAssets.allObjects.firstObject;
                assert(asset != nil);
                
                UIViewController *presentingViewController = assetCollectionsViewController.presentingViewController;
                assert(presentingViewController != nil);
                
                [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
                    [viewModel imageFromPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                        assert(error == nil);
                        
                        CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
                        CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
                        
                        VNGenerateOpticalFlowRequest *request = [[VNGenerateOpticalFlowRequest alloc] initWithTargetedCGImage:cgImage orientation:cgImagePropertyOrientation options:@{
                            MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
                        }];
                        
                        [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                            assert(error == nil);
                        }];
                        
                        [request release];
                    }];
                }];
            };
            
            assetCollectionsViewController.delegate = resolver;
            objc_setAssociatedObject(assetCollectionsViewController, resolver, resolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resolver release];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetCollectionsViewController];
            [assetCollectionsViewController release];
            
            //
            
            UIView *layerView = imageVisionLayer.cp_associatedView;
            assert(layerView != nil);
            UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
            assert(viewController != nil);
            
            //
            
            [viewController presentViewController:navigationController animated:YES completion:nil];
            [navigationController release];
        }];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
//        });
        
        return action;
    }
    
    //
    
    VNGenerateOpticalFlowRequestComputationAccuracy selectedComputationAccuracy = request.computationAccuracy;
    
    auto computationAccuracyActionsVec = std::vector<VNGenerateOpticalFlowRequestComputationAccuracy> {
        VNGenerateOpticalFlowRequestComputationAccuracyLow,
        VNGenerateOpticalFlowRequestComputationAccuracyMedium,
        VNGenerateOpticalFlowRequestComputationAccuracyHigh,
        VNGenerateOpticalFlowRequestComputationAccuracyVeryHigh
    }
    | std::views::transform([viewModel, request, selectedComputationAccuracy](VNGenerateOpticalFlowRequestComputationAccuracy computationAccuracy) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy(computationAccuracy) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            request.computationAccuracy = computationAccuracy;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = (selectedComputationAccuracy == computationAccuracy) ? UIMenuElementStateOn : UIMenuElementStateOff;
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *computationAccuracyActions = [[NSArray alloc] initWithObjects:computationAccuracyActionsVec.data() count:computationAccuracyActionsVec.size()];
    UIMenu *computationAccuraciesMenu = [UIMenu menuWithTitle:@"Computation Accuracy" children:computationAccuracyActions];
    [computationAccuracyActions release];
    computationAccuraciesMenu.subtitle = NSStringFromVNGenerateOpticalFlowRequestComputationAccuracy(selectedComputationAccuracy);
    
    //
    
    BOOL keepNetworkOutput = request.keepNetworkOutput;
    UIAction *keepNetworkOutputAction = [UIAction actionWithTitle:@"Keep Network Output" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.keepNetworkOutput = !keepNetworkOutput;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    keepNetworkOutputAction.cp_overrideNumberOfSubtitleLines = 0;
    keepNetworkOutputAction.subtitle = @"Setting this to `YES` will keep the raw pixel buffer coming from the the ML network. When set to `YES`, the outputPixelFormat is ignored.";
    keepNetworkOutputAction.state = keepNetworkOutput ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNGenerateOpticalFlowRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        computationAccuraciesMenu,
        keepNetworkOutputAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVN1JC7R3k4455fKQz0dY1VhQWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VN1JC7R3k4455fKQz0dY1VhQ") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VN1JC7R3k4455fKQz0dY1VhQ")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VN1JC7R3k4455fKQz0dY1VhQ") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    NSArray<NSString *> *supportedAdjustmentKeys = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedAdjustmentKeysAndReturnError:"), &error);
    assert(error == nil);
    
    NSMutableArray<UIAction *> *supportedAdjustmentKeyActions = [[NSMutableArray alloc] initWithCapacity:supportedAdjustmentKeys.count];
    for (NSString *adjustmentKey in supportedAdjustmentKeys) {
        UIAction *action = [UIAction actionWithTitle:adjustmentKey image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        action.attributes = UIMenuElementAttributesDisabled;
        [supportedAdjustmentKeyActions addObject:action];
    }
    UIMenu *suportedIdentifiersMenu = [UIMenu menuWithTitle:@"Supported Adjustment Keys" children:supportedAdjustmentKeyActions];
    suportedIdentifiersMenu.subtitle = [NSString stringWithFormat:@"%ld keys", supportedAdjustmentKeyActions.count];
    [supportedAdjustmentKeyActions release];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VN1JC7R3k4455fKQz0dY1VhQ")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        suportedIdentifiersMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNGenerateSkySegmentationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNGenerateSkySegmentationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateSkySegmentationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNGenerateSkySegmentationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"dependencyProcessingOrdinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNGenerateSkySegmentationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        qualityLevelsMenu,
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNHomographicImageRegistrationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNHomographicImageRegistrationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNHomographicImageRegistrationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNHomographicImageRegistrationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            AssetCollectionsViewController *assetCollectionsViewController = [AssetCollectionsViewController new];
            
            AssetCollectionsViewControllerDelegateResolver *resolver = [AssetCollectionsViewControllerDelegateResolver new];
            resolver.didSelectAssetsHandler = ^(AssetCollectionsViewController * _Nonnull assetCollectionsViewController, NSSet<PHAsset *> * _Nonnull selectedAssets) {
                PHAsset *asset = selectedAssets.allObjects.firstObject;
                assert(asset != nil);
                
                UIViewController *presentingViewController = assetCollectionsViewController.presentingViewController;
                assert(presentingViewController != nil);
                
                [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
                    [viewModel imageFromPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                        assert(error == nil);
                        
                        CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
                        CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
                        
                        VNHomographicImageRegistrationRequest *request = [[VNHomographicImageRegistrationRequest alloc] initWithTargetedCGImage:cgImage orientation:cgImagePropertyOrientation options:@{
                            MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
                        }];
                        
                        [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                            assert(error == nil);
                        }];
                        
                        [request release];
                    }];
                }];
            };
            
            assetCollectionsViewController.delegate = resolver;
            objc_setAssociatedObject(assetCollectionsViewController, resolver, resolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resolver release];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetCollectionsViewController];
            [assetCollectionsViewController release];
            
            //
            
            UIView *layerView = imageVisionLayer.cp_associatedView;
            assert(layerView != nil);
            UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
            assert(viewController != nil);
            
            //
            
            [viewController presentViewController:navigationController animated:YES completion:nil];
            [navigationController release];
        }];
        
        action.subtitle = @"항등행렬이 나옴?";
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
//        });
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNHomographicImageRegistrationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    menu.subtitle = @"항등행렬이 나옴?";
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNIdentifyJunkRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNIdentifyJunkRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNIdentifyJunkRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNIdentifyJunkRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNIdentifyJunkRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNImageBlurScoreRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNImageBlurScoreRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNImageBlurScoreRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNImageBlurScoreRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSUInteger maximumIntermediateSideLength = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("maximumIntermediateSideLength"));
    
    __kindof UIMenuElement *maximumIntermediateSideLengthStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(maximumIntermediateSideLength).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        
        stepper.maximumValue = NSUIntegerMax;
        stepper.minimumValue = 1;
        stepper.value = maximumIntermediateSideLength;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UIStepper *>(action.sender);
            double value = slider.value;
            
            label.text = @(static_cast<NSUInteger>(value)).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setMaximumIntermediateSideLength:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumIntermediateSideLengthMenu = [UIMenu menuWithTitle:@"Maximum Intermediate Side Length" children:@[maximumIntermediateSideLengthStepperElement]];
    
    //
    
    NSUInteger blurDeterminationMethod = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("blurDeterminationMethod"));
    
    __kindof UIMenuElement *blurDeterminationMethodStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(blurDeterminationMethod).stringValue;
        
        //
        
        UIStepper *stepper = [UIStepper new];
        
        stepper.maximumValue = NSUIntegerMax;
        stepper.minimumValue = 0;
        stepper.value = blurDeterminationMethod;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UIStepper *>(action.sender);
            double value = slider.value;
            
            label.text = @(static_cast<NSUInteger>(value)).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setBlurDeterminationMethod:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *blurDeterminationMethodMenu = [UIMenu menuWithTitle:@"Blur Determination Method" children:@[blurDeterminationMethodStepperElement]];
    blurDeterminationMethodMenu.subtitle = @"Supports: <= 0x1";
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNImageBlurScoreRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        blurDeterminationMethodMenu,
        maximumIntermediateSideLengthMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNImageExposureScoreRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNImageExposureScoreRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNImageExposureScoreRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNImageExposureScoreRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNImageExposureScoreRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNNOPRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNNOPRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNNOPRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNNOPRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNNOPRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeAnimalsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeAnimalsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeAnimalsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"Dependency Processing Ordinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeAnimalHeadsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeAnimalHeadsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalHeadsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeAnimalHeadsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"Dependency Processing Ordinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalHeadsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeAnimalFacesRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeAnimalFacesRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalFacesRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeAnimalFacesRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"Dependency Processing Ordinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeAnimalFacesRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeFoodAndDrinkRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeFoodAndDrinkRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeFoodAndDrinkRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeFoodAndDrinkRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"dependencyProcessingOrdinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeFoodAndDrinkRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeObjectsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeObjectsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeObjectsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeObjectsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL useImageAnalyzerScaling = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("useImageAnalyzerScaling"));
    UIAction *useImageAnalyzerScalingAction = [UIAction actionWithTitle:@"Use Image Analyzer Scaling" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUseImageAnalyzerScaling:"), !useImageAnalyzerScaling);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    useImageAnalyzerScalingAction.state = useImageAnalyzerScaling ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    float modelMinimumDetectionConfidence = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("modelMinimumDetectionConfidence"));
    
    __kindof UIMenuElement *modelMinimumDetectionConfidenceSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(modelMinimumDetectionConfidence).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = modelMinimumDetectionConfidence;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                reinterpret_cast<void (*)(id, SEL, float)>(objc_msgSend)(request, sel_registerName("setModelMinimumDetectionConfidence:"), value);
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *modelMinimumDetectionConfidenceMenu = [UIMenu menuWithTitle:@"Model Minimum Detection Confidence" children:@[modelMinimumDetectionConfidenceSliderElement]];
    
    //
    
    float modelNonMaximumSuppressionThreshold = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("modelNonMaximumSuppressionThreshold"));
    
    __kindof UIMenuElement *modelNonMaximumSuppressionThresholdSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        label.text = @(modelNonMaximumSuppressionThreshold).stringValue;
        
        //
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = modelNonMaximumSuppressionThreshold;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            label.text = @(value).stringValue;
            
            if (!slider.isTracking) {
                [request cancel];
                reinterpret_cast<void (*)(id, SEL, float)>(objc_msgSend)(request, sel_registerName("setModelNonMaximumSuppressionThreshold:"), value);
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
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
    
    UIMenu *modelNonMaximumSuppressionThresholdMenu = [UIMenu menuWithTitle:@"Model Non Maximum Suppression Threshold" children:@[modelNonMaximumSuppressionThresholdSliderElement]];
    
    //
    
    NSError * _Nullable error = nil;
    NSArray<NSString *> * _Nullable supportedIdentifiers = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedIdentifiersAndReturnError:"), &error);
    assert(error == nil);
    NSArray<NSString *> *targetedIdentifiers = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("targetedIdentifiers"));
    
    NSMutableArray<UIAction *> *targetedIdentifierActions = [[NSMutableArray alloc] initWithCapacity:supportedIdentifiers.count];
    for (NSString *identifier in supportedIdentifiers) {
        UIAction *action = [UIAction actionWithTitle:identifier image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [targetedIdentifiers mutableCopy];
            if (copy == nil) {
                copy = [NSMutableArray new];
            }
            
            NSInteger idx = [copy indexOfObject:identifier];
            if (idx == NSNotFound) {
                [copy addObject:identifier];
            } else {
                [copy removeObjectAtIndex:idx];
            }
            
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setTargetedIdentifiers:"), copy);
            [copy release];
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        action.state = ([targetedIdentifiers containsObject:identifier]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [targetedIdentifierActions addObject:action];
    }
    
    UIMenu *targetedIdentifierActionsMenu = [UIMenu menuWithTitle:@"Targeted Identifier Action" children:targetedIdentifierActions];
    [targetedIdentifierActions release];
    targetedIdentifierActionsMenu.subtitle = @"setter는 안 쓰는 기능인듯?";
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeObjectsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        useImageAnalyzerScalingAction,
        modelMinimumDetectionConfidenceMenu,
        modelNonMaximumSuppressionThresholdMenu,
        targetedIdentifierActionsMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeSportBallsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeSportBallsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeSportBallsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeSportBallsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSInteger dependencyProcessingOrdinality = reinterpret_cast<NSInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("dependencyProcessingOrdinality"));
    UIAction *dependencyProcessingOrdinalityAction = [UIAction actionWithTitle:@"dependencyProcessingOrdinality" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    dependencyProcessingOrdinalityAction.attributes = UIMenuElementAttributesDisabled;
    dependencyProcessingOrdinalityAction.subtitle = @(dependencyProcessingOrdinality).stringValue;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeSportBallsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        dependencyProcessingOrdinalityAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeTextRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNRecognizeTextRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNRecognizeTextRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNRecognizeTextRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *minimumTextHeightSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = request.minimumTextHeight;
        slider.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            request.minimumTextHeight = value;
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIMenu *minimumTextHeightSliderMenu = [UIMenu menuWithTitle:@"Minimum Text Height" children:@[minimumTextHeightSliderElement]];
    
    //
    
    VNRequestTextRecognitionLevel selectedRecognitionLevel = request.recognitionLevel;
    
    auto recognitionLevelActionsVec = std::vector<VNRequestTextRecognitionLevel> {
        VNRequestTextRecognitionLevelFast,
        VNRequestTextRecognitionLevelAccurate
    }
    | std::views::transform([viewModel, request, selectedRecognitionLevel](VNRequestTextRecognitionLevel level) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNRequestTextRecognitionLevel(level) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            request.recognitionLevel = level;
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = (selectedRecognitionLevel == level) ? UIMenuElementStateOn : UIMenuElementStateOff;
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *recognitionLevelActions = [[NSArray alloc] initWithObjects:recognitionLevelActionsVec.data() count:recognitionLevelActionsVec.size()];
    UIMenu *recognitionLevelsMenu = [UIMenu menuWithTitle:@"Recognition Level" children:recognitionLevelActions];
    [recognitionLevelActions release];
    recognitionLevelsMenu.subtitle = NSStringFromVNRequestTextRecognitionLevel(selectedRecognitionLevel);
    
    //
    
    BOOL automaticallyDetectsLanguage = request.automaticallyDetectsLanguage;
    UIAction *automaticallyDetectsLanguageAction = [UIAction actionWithTitle:@"Automatically Detects Language" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.automaticallyDetectsLanguage = !automaticallyDetectsLanguage;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    automaticallyDetectsLanguageAction.state = automaticallyDetectsLanguage ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSError * _Nullable error = nil;
    NSArray<NSString *> *supportedRecognitionLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
    assert(error == nil);
    NSArray<NSString *> *recognitionLanguages = request.recognitionLanguages;
    
    NSMutableArray<UIAction *> *recognitionLanguageActions = [[NSMutableArray alloc] initWithCapacity:supportedRecognitionLanguages.count];
    for (NSString *language in supportedRecognitionLanguages) {
        UIAction *action = [UIAction actionWithTitle:language image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [recognitionLanguages mutableCopy];
            NSInteger idx = [copy indexOfObject:language];
            
            if (idx == NSNotFound) {
                [copy addObject:[language stringByReplacingOccurrencesOfString:@"_" withString:@"-"]];
            } else {
                [copy removeObjectAtIndex:idx];
            }
            request.recognitionLanguages = copy;
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        // recognitionLanguages에는 en_US인데 supportedRecognitionLanguages에는 en-US로 적혀 있는 문제가 있음
        BOOL containsObject = [recognitionLanguages containsObject:language];
        if (!containsObject) {
            containsObject = [recognitionLanguages containsObject:[language stringByReplacingOccurrencesOfString:@"-" withString:@"_"]];
        }
        
        action.state = containsObject ? UIMenuElementStateOn : UIMenuElementStateOff;
        [recognitionLanguageActions addObject:action];
    }
    
    UIMenu *recognitionLanguagesMenu = [UIMenu menuWithTitle:@"Recognition Languages" children:recognitionLanguageActions];
    [recognitionLanguageActions release];
    recognitionLanguagesMenu.subtitle = [NSString stringWithFormat:@"%ld languages selected", recognitionLanguages.count];
    
    //
    
    BOOL usesLanguageCorrection = request.usesLanguageCorrection;
    UIAction *usesLanguageCorrectionAction = [UIAction actionWithTitle:@"Uses Language Correction" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.usesLanguageCorrection = !usesLanguageCorrection;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    usesLanguageCorrectionAction.state = usesLanguageCorrection ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    NSArray<NSString *> * _Nullable customWords = request.customWords;
    NSMutableArray<UIAction *> *customWordActions = [[NSMutableArray alloc] initWithCapacity:customWords.count + 1];
    for (NSString *customWord in customWords) {
        UIAction *action = [UIAction actionWithTitle:customWord image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [customWords mutableCopy];
            if (copy == nil) copy = [NSMutableArray new];
            
            [copy removeObject:customWord];
            request.customWords = copy;
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.attributes = UIMenuOptionsDestructive;
        [customWordActions addObject:action];
    }
    
    UIAction *addCustomWordAction = [UIAction actionWithTitle:@"Add Custom Word" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIView *layerView = imageVisionLayer.cp_associatedView;
        assert(layerView != nil);
        UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
        assert(viewController != nil);
        
        //
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Custom Word" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIAlertController *_alertController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(action, sel_registerName("_alertController"));
            UITextField *textField = _alertController.textFields.firstObject;
            assert(textField != nil);
            NSString *text = textField.text;
            
            if (text == nil or text.length == 0) return;
            if ([customWords containsObject:text]) return;
            
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [customWords mutableCopy];
            if (copy == nil) copy = [NSMutableArray new];
            
            [copy addObject:text];
            request.customWords = copy;
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        [alertController addAction:doneAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }];
    [customWordActions addObject:addCustomWordAction];
    
    UIMenu *customWordsMenu = [UIMenu menuWithTitle:@"Custom Words" children:customWordActions];
    customWordsMenu.subtitle = [NSString stringWithFormat:@"%ld words", customWords.count];
    [customWordActions release];
    
    //
    
    BOOL keepResourcesLoaded = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("keepResourcesLoaded"));
    UIAction *keepResourcesLoadedAction = [UIAction actionWithTitle:@"Keep Resources Loaded" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setKeepResourcesLoaded:"), !keepResourcesLoaded);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    keepResourcesLoadedAction.state = keepResourcesLoaded ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNRecognizeTextRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        minimumTextHeightSliderMenu,
        recognitionLevelsMenu,
        automaticallyDetectsLanguageAction,
        recognitionLanguagesMenu,
        usesLanguageCorrectionAction,
        customWordsMenu,
        keepResourcesLoadedAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeDocumentElementsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeDocumentElementsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeDocumentElementsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeDocumentElementsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                NSLog(@"%@", error);
                assert(error == nil);
            }];
            
            [request release];
        }];
        
        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeDocumentElementsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRecognizeDocumentsRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRecognizeDocumentsRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeDocumentsRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRecognizeDocumentsRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                NSLog(@"%@", error);
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    NSError * _Nullable error = nil;
    NSArray<NSString *> *supportedRecognitionLanguages = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(request, sel_registerName("supportedRecognitionLanguagesAndReturnError:"), &error);
    assert(error == nil);
    NSArray<NSString *> *recognitionLanguages = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("recognitionLanguages"));
    NSMutableArray<UIAction *> *recognitionLanguageActions = [[NSMutableArray alloc] initWithCapacity:supportedRecognitionLanguages.count];
    for (NSString *language in supportedRecognitionLanguages) {
        UIAction *action = [UIAction actionWithTitle:language image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [recognitionLanguages mutableCopy];
            NSInteger idx = [copy indexOfObject:language];
            
            if (idx == NSNotFound) {
                [copy addObject:[language stringByReplacingOccurrencesOfString:@"_" withString:@"-"]];
            } else {
                [copy removeObjectAtIndex:idx];
            }
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setRecognitionLanguages:"), copy);
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        BOOL containsObject = [recognitionLanguages containsObject:language];
        if (!containsObject) {
            containsObject = [recognitionLanguages containsObject:[language stringByReplacingOccurrencesOfString:@"-" withString:@"_"]];
        }
        
        action.state = containsObject ? UIMenuElementStateOn : UIMenuElementStateOff;
        [recognitionLanguageActions addObject:action];
    }
    
    UIMenu *recognitionLanguagesMenu = [UIMenu menuWithTitle:@"Recognition Languages" children:recognitionLanguageActions];
    [recognitionLanguageActions release];
    recognitionLanguagesMenu.subtitle = [NSString stringWithFormat:@"%ld selected", recognitionLanguages.count];
    
    //
    
    NSArray<NSString *> * _Nullable customWords = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("customWords"));
    NSMutableArray<UIAction *> *customWordActions = [[NSMutableArray alloc] initWithCapacity:customWords.count + 1];
    for (NSString *customWord in customWords) {
        UIAction *action = [UIAction actionWithTitle:customWord image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [customWords mutableCopy];
            if (copy == nil) copy = [NSMutableArray new];
            
            [copy removeObject:customWord];
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setCustomWords:"), copy);
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.attributes = UIMenuOptionsDestructive;
        [customWordActions addObject:action];
    }
    
    UIAction *addCustomWordAction = [UIAction actionWithTitle:@"Add Custom Word" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIView *layerView = imageVisionLayer.cp_associatedView;
        assert(layerView != nil);
        UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
        assert(viewController != nil);
        
        //
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Custom Word" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIAlertController *_alertController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(action, sel_registerName("_alertController"));
            UITextField *textField = _alertController.textFields.firstObject;
            assert(textField != nil);
            NSString *text = textField.text;
            
            if (text == nil or text.length == 0) return;
            if ([customWords containsObject:text]) return;
            
            [request cancel];
            
            NSMutableArray<NSString *> *copy = [customWords mutableCopy];
            if (copy == nil) copy = [NSMutableArray new];
            
            [copy addObject:text];
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setCustomWords:"), copy);
            [copy release];
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        [alertController addAction:doneAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }];
    [customWordActions addObject:addCustomWordAction];
    
    UIMenu *customWordsMenu = [UIMenu menuWithTitle:@"Custom Words" children:customWordActions];
    customWordsMenu.subtitle = [NSString stringWithFormat:@"%ld words", customWords.count];
    [customWordActions release];
    
    //
    
    VNRequestTextRecognitionLevel selectedRecognitionLevel = reinterpret_cast<VNRequestTextRecognitionLevel (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("recognitionLevel"));
    
    auto recognitionLevelActionsVec = std::vector<VNRequestTextRecognitionLevel> {
        VNRequestTextRecognitionLevelFast,
        VNRequestTextRecognitionLevelAccurate
    }
    | std::views::transform([viewModel, request, selectedRecognitionLevel](VNRequestTextRecognitionLevel level) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromVNRequestTextRecognitionLevel(level) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, VNRequestTextRecognitionLevel)>(objc_msgSend)(request, sel_registerName("setRecognitionLevel:"), level);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        action.state = (selectedRecognitionLevel == level) ? UIMenuElementStateOn : UIMenuElementStateOff;
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *recognitionLevelActions = [[NSArray alloc] initWithObjects:recognitionLevelActionsVec.data() count:recognitionLevelActionsVec.size()];
    UIMenu *recognitionLevelsMenu = [UIMenu menuWithTitle:@"Recognition Level" children:recognitionLevelActions];
    [recognitionLevelActions release];
    recognitionLevelsMenu.subtitle = NSStringFromVNRequestTextRecognitionLevel(selectedRecognitionLevel);
    
    //
    
    BOOL usesLanguageCorrection = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("usesLanguageCorrection"));
    UIAction *usesLanguageCorrectionAction = [UIAction actionWithTitle:@"Uses Language Correction" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUsesLanguageCorrection:"), !usesLanguageCorrection);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    usesLanguageCorrectionAction.state = usesLanguageCorrection ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL usesAlternateLineGrouping = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("usesAlternateLineGrouping"));
    UIAction *usesAlternateLineGroupingAction = [UIAction actionWithTitle:@"Uses Alternate Line Grouping" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setUsesAlternateLineGrouping:"), !usesAlternateLineGrouping);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    usesAlternateLineGroupingAction.state = usesAlternateLineGrouping ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    __kindof UIMenuElement *minimumTextHeightSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = reinterpret_cast<float (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("minimumTextHeight"));
        slider.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            reinterpret_cast<void (*)(id, SEL, float)>(objc_msgSend)(request, sel_registerName("setMinimumTextHeight:"), value);
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIMenu *minimumTextHeightSliderMenu = [UIMenu menuWithTitle:@"Minimum Text Height" children:@[minimumTextHeightSliderElement]];
    
    //
    
    BOOL keepResourcesLoaded = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("keepResourcesLoaded"));
    UIAction *keepResourcesLoadedAction = [UIAction actionWithTitle:@"Keep Resources Loaded" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setKeepResourcesLoaded:"), !keepResourcesLoaded);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    keepResourcesLoadedAction.state = keepResourcesLoaded ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL detectionOnly = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("detectionOnly"));
    UIAction *detectionOnlyAction = [UIAction actionWithTitle:@"Detection Only" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setDetectionOnly:"), !detectionOnly);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    detectionOnlyAction.state = detectionOnly ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    __kindof UIMenuElement *maximumCandidateCountStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSUInteger maximumCandidateCount = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("maximumCandidateCount"));
        
        UILabel *label = [UILabel new];
        label.text = @(maximumCandidateCount).stringValue;
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = maximumCandidateCount;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            NSUInteger value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setMaximumCandidateCount:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumCandidateCountMenu = [UIMenu menuWithTitle:@"Maximum Candidate Count" children:@[maximumCandidateCountStepperElement]];
    
    //
    
    VNDetectBarcodesRequest *barcodeRequest = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("barcodeRequest"));
    UIAction *barcodeRequestAction;
    if (barcodeRequest != nil) {
        barcodeRequestAction = [UIAction actionWithTitle:@"Remove VNDetectBarcodesRequest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setBarcodeRequest:"), nil);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        barcodeRequestAction.state = UIMenuElementStateOn;
    } else {
        VNDetectBarcodesRequest *addedBarcodeRequest = nil;
        for (VNDetectBarcodesRequest *addedRequest in requests) {
            if ([addedRequest class] == [VNDetectBarcodesRequest class]) {
                addedBarcodeRequest = addedRequest;
                break;
            }
        }
        
        if (addedBarcodeRequest != nil) {
            barcodeRequestAction = [UIAction actionWithTitle:@"Add VNDetectBarcodesRequest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [request cancel];
                reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setBarcodeRequest:"), addedBarcodeRequest);
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
            }];
        } else {
            barcodeRequestAction = [UIAction actionWithTitle:@"Add VNDetectBarcodesRequest" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
            }];
            barcodeRequestAction.attributes = UIMenuElementAttributesDisabled;
            barcodeRequestAction.subtitle = @"No VNDetectBarcodesRequest found";
        }
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRecognizeDocumentsRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        recognitionLanguagesMenu,
        customWordsMenu,
        recognitionLevelsMenu,
        usesLanguageCorrectionAction,
        usesAlternateLineGroupingAction,
        minimumTextHeightSliderMenu,
        keepResourcesLoadedAction,
        detectionOnlyAction,
        maximumCandidateCountMenu,
        barcodeRequestAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNRemoveBackgroundRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNRemoveBackgroundRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNRemoveBackgroundRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNRemoveBackgroundRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    BOOL performInPlace = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("performInPlace"));
    UIAction *performInPlaceAction = [UIAction actionWithTitle:@"Perform In Place" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setPerformInPlace:"), !performInPlace);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    performInPlaceAction.state = performInPlace ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL cropResult = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("cropResult"));
    UIAction *cropResultAction = [UIAction actionWithTitle:@"Crop Result" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setCropResult:"), !cropResult);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    cropResultAction.state = cropResult ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL returnMask = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("returnMask"));
    UIAction *returnMaskAction = [UIAction actionWithTitle:@"Return Mask" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setReturnMask:"), !returnMask);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    returnMaskAction.state = returnMask ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNRemoveBackgroundRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        performInPlaceAction,
        cropResultAction,
        returnMaskAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNSceneClassificationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNImageBasedRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNSceneClassificationRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNSceneClassificationRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNImageBasedRequest *request = [[objc_lookUpClass("VNSceneClassificationRequest") alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    __kindof UIMenuElement *maximumLeafObservationsStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSUInteger maximumLeafObservations = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("maximumLeafObservations"));
        
        UILabel *label = [UILabel new];
        label.text = @(maximumLeafObservations).stringValue;
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 1.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = maximumLeafObservations;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            NSUInteger value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setMaximumLeafObservations:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumLeafObservationsMenu = [UIMenu menuWithTitle:@"Maximum Leaf Observations" children:@[maximumLeafObservationsStepperElement]];
    
    //
    
    __kindof UIMenuElement *maximumHierarchicalObservationsStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        NSUInteger maximumHierarchicalObservations = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("maximumHierarchicalObservations"));
        
        UILabel *label = [UILabel new];
        label.text = @(maximumHierarchicalObservations).stringValue;
        
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 1.;
        stepper.maximumValue = NSUIntegerMax;
        stepper.value = maximumHierarchicalObservations;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto stepper = static_cast<UIStepper *>(action.sender);
            NSUInteger value = stepper.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(request, sel_registerName("setMaximumHierarchicalObservations:"), value);
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, stepper]];
        [label release];
        [stepper release];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIMenu *maximumHierarchicalObservationsMenu = [UIMenu menuWithTitle:@"Maximum Hierarchical Observations" children:@[maximumHierarchicalObservationsStepperElement]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNSceneClassificationRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        maximumLeafObservationsMenu,
        maximumHierarchicalObservationsMenu,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackHomographyRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    __kindof VNStatefulRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:objc_lookUpClass("VNTrackHomographyRequest") addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackHomographyRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            __kindof VNStatefulRequest *request = [[objc_lookUpClass("VNTrackHomographyRequest") alloc] initWithFrameAnalysisSpacing:CMTimeMake(1, 60) completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackHomographyRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackHomographicImageRegistrationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNTrackHomographicImageRegistrationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTrackHomographicImageRegistrationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNTrackHomographicImageRegistrationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNTrackHomographicImageRegistrationRequest *request = [[VNTrackHomographicImageRegistrationRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackHomographicImageRegistrationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackLegacyFaceCoreObjectRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations {
    __kindof VNTrackObjectRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[objc_lookUpClass("VNTrackLegacyFaceCoreObjectRequest") class] addedRequests:requests];
    
    if (request == nil) {
        NSMutableArray<UIAction *> *detectedObjectObservationActions = [NSMutableArray new];
        for (__kindof VNObservation *observation in observations) {
            if ([observation isKindOfClass:[VNDetectedObjectObservation class]]) {
                UIAction *action = [UIAction actionWithTitle:observation.uuid.UUIDString image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    __kindof VNTrackingRequest *request = [[objc_lookUpClass("VNTrackLegacyFaceCoreObjectRequest") alloc] initWithDetectedObjectObservation:observation completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    [request release];
                }];
                
                [detectedObjectObservationActions addObject:action];
            }
        }
        
        if (detectedObjectObservationActions.count == 0) {
            [detectedObjectObservationActions release];
            
            UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackLegacyFaceCoreObjectRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
            }];
            
            action.attributes = UIMenuElementAttributesDisabled;
            action.subtitle = @"No VNDetectedObjectObservation";
            
            return action;
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackLegacyFaceCoreObjectRequest")) children:detectedObjectObservationActions];
        [detectedObjectObservationActions release];
        
        return menu;
    }
    
    //
    
    NSNumber * _Nullable faceCoreMinFaceSize = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreMinFaceSize"));
    
    __kindof UIMenuElement *faceCoreMinFaceSizeSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = faceCoreMinFaceSize.floatValue;
        slider.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [request cancel];
            
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setFaceCoreMinFaceSize:"), @(value));
            
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIAction *nullifyFaceCoreMinFaceSizeAction = [UIAction actionWithTitle:@"Set nil" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setFaceCoreMinFaceSize:"), nil);
        
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    
    UIMenu *faceCoreMinFaceSizeMenu = [UIMenu menuWithTitle:@"faceCoreMinFaceSize (???)" children:@[faceCoreMinFaceSizeSliderElement, nullifyFaceCoreMinFaceSizeAction]];
    if (faceCoreMinFaceSize == nil) {
        faceCoreMinFaceSizeMenu.subtitle = @"nil";
    }
    
    //
    
    NSNumber * _Nullable faceCoreNumberOfDetectionAngles = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreNumberOfDetectionAngles"));
    
    __kindof UIMenuElement *faceCoreNumberOfDetectionAnglesStepperElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UILabel *label = [UILabel new];
        if (faceCoreNumberOfDetectionAngles == nil) {
            label.text = @"nil";
        } else {
            label.text = faceCoreNumberOfDetectionAngles.stringValue;
        }
        
        //
        
        UIStepper *stepper = [UIStepper new];
        
        stepper.maximumValue = NSUIntegerMax;
        stepper.minimumValue = 0.;
        stepper.value = faceCoreNumberOfDetectionAngles.unsignedIntegerValue;
        stepper.stepValue = 1.;
        stepper.continuous = NO;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UIStepper *>(action.sender);
            NSUInteger value = slider.value;
            
            label.text = @(value).stringValue;
            
            [request cancel];
            reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setFaceCoreNumberOfDetectionAngles:"), @(value));
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        
        [stepper addAction:action forControlEvents:UIControlEventValueChanged];
        
        //
        
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper, label]];
        [stepper release];
        [label release];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    UIAction *nullifyFaceCoreNumberOfDetectionAnglesAction = [UIAction actionWithTitle:@"Set nil" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setFaceCoreNumberOfDetectionAngles:"), nil);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    
    UIMenu *faceCoreNumberOfDetectionAnglesMenu = [UIMenu menuWithTitle:@"faceCoreNumberOfDetectionAngles (???)" children:@[faceCoreNumberOfDetectionAnglesStepperElement, nullifyFaceCoreNumberOfDetectionAnglesAction]];
    if (faceCoreNumberOfDetectionAngles == nil) {
        faceCoreNumberOfDetectionAnglesMenu.subtitle = @"nil";
    }
    
    //
    
    BOOL faceCoreEnhanceEyesAndMouthLocalization = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreEnhanceEyesAndMouthLocalization"));
    
    UIAction *faceCoreEnhanceEyesAndMouthLocalizationAction = [UIAction actionWithTitle:@"faceCoreEnhanceEyesAndMouthLocalization" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreEnhanceEyesAndMouthLocalization:"), !faceCoreEnhanceEyesAndMouthLocalization);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreEnhanceEyesAndMouthLocalizationAction.subtitle = @"???";
    faceCoreEnhanceEyesAndMouthLocalizationAction.state = faceCoreEnhanceEyesAndMouthLocalization ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractBlink = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractBlink"));
    
    UIAction *faceCoreExtractBlinkAction = [UIAction actionWithTitle:@"faceCoreExtractBlink" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractBlink:"), !faceCoreExtractBlink);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreExtractBlinkAction.subtitle = @"Not working";
    faceCoreExtractBlinkAction.state = faceCoreExtractBlink ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreExtractSmile = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreExtractSmile"));
    
    UIAction *faceCoreExtractSmileAction = [UIAction actionWithTitle:@"faceCoreExtractSmile" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreExtractSmile:"), !faceCoreExtractSmile);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreExtractSmileAction.subtitle = @"???";
    faceCoreExtractSmileAction.state = faceCoreExtractSmile ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    BOOL faceCoreKalmanFilter = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("faceCoreKalmanFilter"));
    
    UIAction *faceCoreKalmanFilterAction = [UIAction actionWithTitle:@"faceCoreKalmanFilter" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setFaceCoreKalmanFilter:"), !faceCoreKalmanFilter);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
    }];
    faceCoreKalmanFilterAction.subtitle = @"???";
    faceCoreKalmanFilterAction.state = faceCoreKalmanFilter ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNDetectFaceRectanglesRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel],
        faceCoreEnhanceEyesAndMouthLocalizationAction,
        faceCoreExtractBlinkAction,
        faceCoreExtractSmileAction,
        faceCoreKalmanFilterAction,
        faceCoreMinFaceSizeMenu,
        faceCoreNumberOfDetectionAnglesMenu
    ]];
    
    menu.cp_overrideNumberOfSubtitleLines = 0;
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackMaskRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    __kindof VNStatefulRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[objc_lookUpClass("VNTrackMaskRequest") class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackMaskRequest")) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            AssetCollectionsViewController *assetCollectionsViewController = [AssetCollectionsViewController new];
            assetCollectionsViewController.navigationItem.prompt = @"Select Initial Mask Image";
            
            AssetCollectionsViewControllerDelegateResolver *resolver = [AssetCollectionsViewControllerDelegateResolver new];
            resolver.didSelectAssetsHandler = ^(AssetCollectionsViewController * _Nonnull assetCollectionsViewController, NSSet<PHAsset *> * _Nonnull selectedAssets) {
                PHAsset *asset = selectedAssets.allObjects.firstObject;
                assert(asset != nil);
                
                UIViewController *presentingViewController = assetCollectionsViewController.presentingViewController;
                assert(presentingViewController != nil);
                
                [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
                    [viewModel imageFromPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                        assert(error == nil);
                        
                        CIImage * __autoreleasing ciImage = image.CIImage;
                        
                        if (ciImage == nil) {
                            CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
                            CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
                            
                            ciImage = [[[CIImage alloc] initWithCGImage:cgImage] autorelease];
                            ciImage = [ciImage imageByApplyingCGOrientation:cgImagePropertyOrientation];
                        }
                        
                        NSDictionary *pixelBufferAttributes = @{
                               (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                               (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
                               (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
                           };
                        CVPixelBufferRef pixelBuffer;
                        assert(CVPixelBufferCreate(kCFAllocatorDefault, CGRectGetWidth(ciImage.extent), CGRectGetHeight(ciImage.extent), kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)pixelBufferAttributes, &pixelBuffer) == kCVReturnSuccess);
                        
                        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                        CIContext *ciContext = [CIContext new];
                        [ciContext render:ciImage toCVPixelBuffer:pixelBuffer bounds:ciImage.extent colorSpace:ciImage.colorSpace];
                        [ciContext release];
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                        
                        __kindof VNStatefulRequest *request = reinterpret_cast<id (*)(id, SEL, CMTime, CVPixelBufferRef, id)>(objc_msgSend)([objc_lookUpClass("VNTrackMaskRequest") alloc], sel_registerName("initWithFrameUpdateSpacing:mask:completionHandler:"), CMTimeMake(1, 60), pixelBuffer, ^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                            assert(error == nil);
                        });
                        CVPixelBufferRelease(pixelBuffer);
                        
                        [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                            assert(error == nil);
                        }];
                        
                        [request release];
                    }];
                }];
            };
            assetCollectionsViewController.delegate = resolver;
            objc_setAssociatedObject(assetCollectionsViewController, resolver, resolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resolver release];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetCollectionsViewController];
            [assetCollectionsViewController release];
            
            //
            
            UIView *layerView = imageVisionLayer.cp_associatedView;
            assert(layerView != nil);
            UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
            assert(viewController != nil);
            
            //
            
            [viewController presentViewController:navigationController animated:YES completion:nil];
            [navigationController release];
        }];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
//        });
        
        return action;
    }
    
    //
    
    BOOL generateCropRect = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("generateCropRect"));
    UIAction *generateCropRectAction = [UIAction actionWithTitle:@"Generate Crop Rect" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(request, sel_registerName("setGenerateCropRect:"), !generateCropRect);
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    generateCropRectAction.state = generateCropRect ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass(objc_lookUpClass("VNTrackMaskRequest")) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        generateCropRectAction,
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackObjectRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations {
    VNTrackObjectRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTrackObjectRequest class] addedRequests:requests];
    
    if (request == nil) {
        NSMutableArray<UIAction *> *detectedObjectObservationActions = [NSMutableArray new];
        for (__kindof VNObservation *observation in observations) {
            if ([observation isKindOfClass:[VNDetectedObjectObservation class]]) {
                UIAction *action = [UIAction actionWithTitle:observation.uuid.UUIDString image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    __kindof VNTrackingRequest *request = [[VNTrackObjectRequest alloc] initWithDetectedObjectObservation:observation completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    [request release];
                }];
                
                [detectedObjectObservationActions addObject:action];
            }
        }
        
        if (detectedObjectObservationActions.count == 0) {
            [detectedObjectObservationActions release];
            
            UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNTrackObjectRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
            }];
            
            action.attributes = UIMenuElementAttributesDisabled;
            action.subtitle = @"No VNDetectedObjectObservation";
            
            return action;
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackObjectRequest class]) children:detectedObjectObservationActions];
        [detectedObjectObservationActions release];
        
        return menu;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackObjectRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackRectangleRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests observations:(NSArray<__kindof VNObservation *> *)observations {
    VNTrackRectangleRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTrackRectangleRequest class] addedRequests:requests];
    
    if (request == nil) {
        NSMutableArray<UIAction *> *rectangleObservationActions = [NSMutableArray new];
        for (__kindof VNObservation *observation in observations) {
            if ([observation isKindOfClass:[VNRectangleObservation class]]) {
                UIAction *action = [UIAction actionWithTitle:observation.uuid.UUIDString image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    VNTrackRectangleRequest *request = [[VNTrackRectangleRequest alloc] initWithRectangleObservation:observation completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    request.lastFrame = YES;
                    
                    [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                        assert(error == nil);
                    }];
                    
                    [request release];
                }];
                
                [rectangleObservationActions addObject:action];
            }
        }
        
        if (rectangleObservationActions.count == 0) {
            [rectangleObservationActions release];
            
            UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNRectangleObservation class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
            }];
            action.attributes = UIMenuElementAttributesDisabled;
            action.subtitle = @"No VNTrackRectangleRequest";
            
            return action;
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNRectangleObservation class]) children:rectangleObservationActions];
        [rectangleObservationActions release];
        
        return menu;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackRectangleRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTranslationalImageRegistrationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests imageVisionLayer:(ImageVisionLayer *)imageVisionLayer {
    VNTranslationalImageRegistrationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTranslationalImageRegistrationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNTranslationalImageRegistrationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            AssetCollectionsViewController *assetCollectionsViewController = [AssetCollectionsViewController new];
            
            AssetCollectionsViewControllerDelegateResolver *resolver = [AssetCollectionsViewControllerDelegateResolver new];
            resolver.didSelectAssetsHandler = ^(AssetCollectionsViewController * _Nonnull assetCollectionsViewController, NSSet<PHAsset *> * _Nonnull selectedAssets) {
                PHAsset *asset = selectedAssets.allObjects.firstObject;
                assert(asset != nil);
                
                UIViewController *presentingViewController = assetCollectionsViewController.presentingViewController;
                assert(presentingViewController != nil);
                
                [assetCollectionsViewController dismissViewControllerAnimated:YES completion:^{
                    [viewModel imageFromPHAsset:asset completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                        assert(error == nil);
                        
                        CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
                        CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
                        
                        VNTranslationalImageRegistrationRequest *request = [[VNTranslationalImageRegistrationRequest alloc] initWithTargetedCGImage:cgImage orientation:cgImagePropertyOrientation options:@{
                            MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
                        }];
                        
                        [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                            assert(error == nil);
                        }];
                        
                        [request release];
                    }];
                }];
            };
            
            assetCollectionsViewController.delegate = resolver;
            objc_setAssociatedObject(assetCollectionsViewController, resolver, resolver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resolver release];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:assetCollectionsViewController];
            [assetCollectionsViewController release];
            
            //
            
            UIView *layerView = imageVisionLayer.cp_associatedView;
            assert(layerView != nil);
            UIViewController *viewController = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)([UIViewController class], sel_registerName("_viewControllerForFullScreenPresentationFromView:"), layerView);
            assert(viewController != nil);
            
            //
            
            [viewController presentViewController:navigationController animated:YES completion:nil];
            [navigationController release];
        }];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
//        });
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTranslationalImageRegistrationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_imageVisionElementForVNTrackTranslationalImageRegistrationRequestWithViewModel:(ImageVisionViewModel *)viewModel addedRequests:(NSArray<__kindof VNRequest *> *)requests {
    VNTrackTranslationalImageRegistrationRequest * _Nullable request = [UIDeferredMenuElement _cp_imageVisionRequestForClass:[VNTrackTranslationalImageRegistrationRequest class] addedRequests:requests];
    
    if (request == nil) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromClass([VNTrackTranslationalImageRegistrationRequest class]) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            VNTrackTranslationalImageRegistrationRequest *request = [[VNTrackTranslationalImageRegistrationRequest alloc] initWithCompletionHandler:nil];
            
            [viewModel addRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
            
            [request release];
        }];
        
//        reinterpret_cast<void (*)(id, SEL, id, id)>(objc_msgSend)(action, sel_registerName("performWithSender:target:"), nil, nil);
        
        return action;
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:NSStringFromClass([VNTrackTranslationalImageRegistrationRequest class]) image:[UIImage systemImageNamed:@"checkmark"] identifier:nil options:0 children:@[
        [UIDeferredMenuElement _cp_imageVissionCommonMenuForRequest:request viewModel:viewModel]
    ]];
    
    return menu;
}


#warning TODO: VNRequest 내부도 보기
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
            [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
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
    
    NSError * _Nullable error = nil;
    NSDictionary<VNComputeStage, NSArray<id<MLComputeDeviceProtocol>> *> *supportedComputeStageDevices = [request supportedComputeStageDevicesAndReturnError:&error];
    assert(error == nil);
    
    NSArray<VNComputeStage> *sortedComputeStages = [supportedComputeStageDevices.allKeys sortedArrayUsingComparator:^NSComparisonResult(VNComputeStage _Nonnull obj1, VNComputeStage _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableArray<UIMenu *> *computeStageMenus = [[NSMutableArray alloc] initWithCapacity:supportedComputeStageDevices.count];
    for (VNComputeStage computeState in sortedComputeStages) {
        NSArray<id<MLComputeDeviceProtocol>> *devices = supportedComputeStageDevices[computeState];
        NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:devices.count];
        
        for (id<MLComputeDeviceProtocol> device in devices) {
            NSString *title;
            if ([device isKindOfClass:objc_lookUpClass("MLGPUComputeDevice")]) {
                id<MTLDevice> metalDevice = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(device, sel_registerName("metalDevice"));
                title = metalDevice.name;
            } else {
                title = NSStringFromClass([device class]);
            }
            
            UIAction *action = [UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [request cancel];
                [request setComputeDevice:device forComputeStage:computeState];
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
            }];
            
            action.state = ([[request computeDeviceForComputeStage:computeState] isEqual:device]) ? UIMenuElementStateOn : UIMenuElementStateOff;
            action.cp_overrideNumberOfSubtitleLines = 0;
            [actions addObject:action];
        }
        
        //
        
        UIMenu *menu = [UIMenu menuWithTitle:computeState children:actions];
        [actions release];
        
        [computeStageMenus addObject:menu];
    }
    
    UIMenu *computeDevicesMenu = [UIMenu menuWithTitle:@"Compute Devices" children:computeStageMenus];
    [computeStageMenus release];
    
    [children addObject:computeDevicesMenu];
    
    //
    
    BOOL preferBackgroundProcessing = request.preferBackgroundProcessing;
    UIAction *preferBackgroundProcessingAction = [UIAction actionWithTitle:@"preferBackgroundProcessing" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [request cancel];
        request.preferBackgroundProcessing = !preferBackgroundProcessing;
        [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    }];
    preferBackgroundProcessingAction.state = preferBackgroundProcessing ? UIMenuElementStateOn : UIMenuElementStateOff;
    [children addObject:preferBackgroundProcessingAction];
    
    //
    
    BOOL cancellationTriggered = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("cancellationTriggered"));
    UIAction *cancellationTriggeredAction = [UIAction actionWithTitle:@"cancellationTriggered" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    cancellationTriggeredAction.attributes = UIMenuElementAttributesDisabled;
    cancellationTriggeredAction.state = cancellationTriggered ? UIMenuElementStateOn : UIMenuElementStateOff;
    [children addObject:cancellationTriggeredAction];
    
    //
    
    NSTimeInterval executionTimeInternal = reinterpret_cast<NSTimeInterval (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("executionTimeInternal"));
    UIAction *executionTimeInternalAction = [UIAction actionWithTitle:@"executionTimeInternal" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    executionTimeInternalAction.subtitle = @(executionTimeInternal).stringValue;
    executionTimeInternalAction.attributes = UIMenuElementAttributesDisabled;
    [children addObject:executionTimeInternalAction];
    
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
            action.cp_overrideNumberOfTitleLines = 0;
            [supportedIdentifierActions addObject:action];
        }
        UIMenu *suportedIdentifiersMenu = [UIMenu menuWithTitle:@"Supported Identifiers" children:supportedIdentifierActions];
        suportedIdentifiersMenu.subtitle = [NSString stringWithFormat:@"%ld identifiers", supportedIdentifierActions.count];
        [supportedIdentifierActions release];
        
        [children addObject:suportedIdentifiersMenu];
    }
    
    //
    
    if ([request respondsToSelector:@selector(imageCropAndScaleOption)]) {
        VNImageCropAndScaleOption selectedImageCropAndScaleOption = reinterpret_cast<VNImageCropAndScaleOption (*)(id, SEL)>(objc_msgSend)(request, @selector(imageCropAndScaleOption));
        
        auto imageCropAndScaleOptionActionsVec = std::vector<VNImageCropAndScaleOption> {
            VNImageCropAndScaleOptionCenterCrop,
            VNImageCropAndScaleOptionScaleFit,
            VNImageCropAndScaleOptionScaleFill,
            VNImageCropAndScaleOptionScaleFitRotate90CCW,
            VNImageCropAndScaleOptionScaleFillRotate90CCW
        }
        | std::views::transform([viewModel, request, selectedImageCropAndScaleOption](VNImageCropAndScaleOption option) {
            UIAction *action = [UIAction actionWithTitle:NSStringFromVNImageCropAndScaleOption(option) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [request cancel];
                reinterpret_cast<void (*)(id, SEL, VNImageCropAndScaleOption)>(objc_msgSend)(request, sel_registerName("setImageCropAndScaleOption:"), option);
                [viewModel updateRequest:request completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
            }];
            
            action.state = (selectedImageCropAndScaleOption == option) ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            return action;
        })
        | std::ranges::to<std::vector<UIAction *>>();
        
        NSArray<UIAction *> *imageCropAndScaleOptionActions = [[NSArray alloc] initWithObjects:imageCropAndScaleOptionActionsVec.data() count:imageCropAndScaleOptionActionsVec.size()];
        UIMenu *imageCropAndScaleOptionActionsMenu = [UIMenu menuWithTitle:@"Image Crop And Scale Options" children:imageCropAndScaleOptionActions];
        [imageCropAndScaleOptionActions release];
        imageCropAndScaleOptionActionsMenu.subtitle = NSStringFromVNImageCropAndScaleOption(selectedImageCropAndScaleOption);
        
        [children addObject:imageCropAndScaleOptionActionsMenu];
    }
    
    //
    
    if ([request isKindOfClass:[VNTrackingRequest class]]) {
        auto trackingRequest = static_cast<VNTrackingRequest *>(request);
        
        //
        
        BOOL isLastFrame = trackingRequest.isLastFrame;
        UIAction *isLastFrameAction = [UIAction actionWithTitle:@"isLastFrame" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [trackingRequest cancel];
            trackingRequest.lastFrame = !isLastFrame;
            [viewModel updateRequest:trackingRequest completionHandler:^(NSError * _Nullable error) {
                assert(error == nil);
            }];
        }];
        isLastFrameAction.state = isLastFrame ? UIMenuElementStateOn : UIMenuElementStateOff;
        [children addObject:isLastFrameAction];
        
        //
        
        VNRequestTrackingLevel selectedTrackingLevel = trackingRequest.trackingLevel;
        
        auto trackingLevelActionsVec = std::vector<VNRequestTrackingLevel> {
            VNRequestTrackingLevelAccurate,
            VNRequestTrackingLevelFast
        }
        | std::views::transform([viewModel, trackingRequest, selectedTrackingLevel](VNRequestTrackingLevel level) {
            UIAction *action = [UIAction actionWithTitle:NSStringFromVNRequestTrackingLevel(level) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [trackingRequest cancel];
                trackingRequest.trackingLevel = level;
                [viewModel updateRequest:trackingRequest completionHandler:^(NSError * _Nullable error) {
                    assert(error == nil);
                }];
            }];
            
            action.state = (selectedTrackingLevel == level) ? UIMenuElementStateOn : UIMenuElementStateOff;
            return action;
        })
        | std::ranges::to<std::vector<UIAction *>>();
        
        NSArray<UIAction *> *trackingLevelActions = [[NSArray alloc] initWithObjects:trackingLevelActionsVec.data() count:trackingLevelActionsVec.size()];
        
        UIMenu *trackingLevelsMenu = [UIMenu menuWithTitle:@"Tracking Levels" children:trackingLevelActions];
        [trackingLevelActions release];
        trackingLevelsMenu.subtitle = NSStringFromVNRequestTrackingLevel(selectedTrackingLevel);
        
        [children addObject:trackingLevelsMenu];
        
        //
        
        NSError * _Nullable error = nil;
        NSUInteger supportedNumberOfTrackers = reinterpret_cast<NSUInteger (*)(id, SEL, id *)>(objc_msgSend)(trackingRequest, sel_registerName("supportedNumberOfTrackersAndReturnError:"), &error);
        assert(error == nil);
        UIAction *supportedNumberOfTrackersAction = [UIAction actionWithTitle:@"Supported Number Of Trackers" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        supportedNumberOfTrackersAction.subtitle = @(supportedNumberOfTrackers).stringValue;
        supportedNumberOfTrackersAction.attributes = UIMenuElementAttributesDisabled;
        [children addObject:supportedNumberOfTrackersAction];
    }
    
    //
    
    if ([request isKindOfClass:[VNImageBasedRequest class]]) {
        auto imageBasedRequest = static_cast<VNImageBasedRequest *>(request);
        
        NSArray *supportedImageSizeSet = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(request, sel_registerName("supportedImageSizeSet"));
        if (supportedImageSizeSet.count > 0) {
            NSMutableArray<UIMenu *> *supportedImageSizeMenus = [[NSMutableArray alloc] initWithCapacity:supportedImageSizeSet.count];
            
            // VNSupportedImageSize
            for (id supportedImageSize in supportedImageSizeSet) {
                auto sizeRangeMenu = ^UIMenu * (NSString *title, id sizeRange) {
                    NSUInteger minimumDimension = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(sizeRange, sel_registerName("minimumDimension"));
                    UIAction *minimumDimensionAction = [UIAction actionWithTitle:@"Minimum Dimension" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        
                    }];
                    minimumDimensionAction.subtitle = @(minimumDimension).stringValue;
                    minimumDimensionAction.attributes = UIMenuElementAttributesDisabled;
                    
                    //
                    
                    NSUInteger maximumDimension = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(sizeRange, sel_registerName("maximumDimension"));
                    UIAction *maximumDimensionAction = [UIAction actionWithTitle:@"Maximum Dimension" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        
                    }];
                    maximumDimensionAction.subtitle = @(maximumDimension).stringValue;
                    maximumDimensionAction.attributes = UIMenuElementAttributesDisabled;
                    
                    //
                    
                    NSUInteger idealDimension = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(sizeRange, sel_registerName("idealDimension"));
                    UIAction *idealDimensionAction = [UIAction actionWithTitle:@"Ideal Dimension" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        
                    }];
                    idealDimensionAction.subtitle = @(idealDimension).stringValue;
                    idealDimensionAction.attributes = UIMenuElementAttributesDisabled;
                    
                    //
                    
                    UIMenu *menu = [UIMenu menuWithTitle:title children:@[minimumDimensionAction, maximumDimensionAction, idealDimensionAction]];
                    return menu;
                };
                
                //
                
                id pixelsWideRange = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(supportedImageSize, sel_registerName("pixelsWideRange"));
                UIMenu *pixelsWideRangeMenu = sizeRangeMenu(@"Pixels Wide Range", pixelsWideRange);
                
                //
                
                id pixelsHighRange = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(supportedImageSize, sel_registerName("pixelsHighRange"));
                UIMenu *pixelsHighRangeMenu = sizeRangeMenu(@"Pixels High Range", pixelsHighRange);
                
                //
                
                NSUInteger aspectRatioHandling = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(supportedImageSize, sel_registerName("aspectRatioHandling"));
                UIAction *aspectRatioHandlingAction = [UIAction actionWithTitle:@"Aspect Ratio Handling" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                }];
                aspectRatioHandlingAction.subtitle = @(aspectRatioHandling).stringValue;
                aspectRatioHandlingAction.attributes = UIMenuElementAttributesDisabled;
                
                //
                
                NSUInteger idealImageFormat = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(supportedImageSize, sel_registerName("idealImageFormat"));
                UIAction *idealImageFormatAction = [UIAction actionWithTitle:@"Ideal Image Format" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                }];
                idealImageFormatAction.subtitle = @(idealImageFormat).stringValue;
                idealImageFormatAction.attributes = UIMenuElementAttributesDisabled;
                
                //
                
                NSUInteger idealOrientation = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(supportedImageSize, sel_registerName("idealOrientation"));
                UIAction *idealOrientationAction = [UIAction actionWithTitle:@"Ideal Orientation" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                }];
                idealOrientationAction.subtitle = @(idealOrientation).stringValue;
                idealOrientationAction.attributes = UIMenuElementAttributesDisabled;
                
                //
                
                UIMenu *menu = [UIMenu menuWithTitle:[supportedImageSize description] children:@[
                    pixelsWideRangeMenu,
                    pixelsHighRangeMenu,
                    aspectRatioHandlingAction,
                    idealImageFormatAction,
                    idealOrientationAction
                ]];
                
                [supportedImageSizeMenus addObject:menu];
            }
            
            UIMenu *supportedImageSizesMenu = [UIMenu menuWithTitle:@"Supported Image Sizes" children:supportedImageSizeMenus];
            [supportedImageSizeMenus release];
            
            [children addObject:supportedImageSizesMenu];
        }
        
        //
        
        CGRect regionOfInterest = imageBasedRequest.regionOfInterest;
        UIAction *regionOfInterestAction = [UIAction actionWithTitle:@"Region Of Interest (TODO: setter)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        regionOfInterestAction.attributes = UIMenuElementAttributesDisabled;
        regionOfInterestAction.subtitle = NSStringFromCGRect(regionOfInterest);
        [children addObject:regionOfInterestAction];
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:children];
    [children release];
    
    return menu;
}

@end
