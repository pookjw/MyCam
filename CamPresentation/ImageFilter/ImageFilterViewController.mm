//
//  ImageFilterViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/11/25.
//

#import <CamPresentation/ImageFilterViewController.h>
#import <CoreImage/CoreImage.h>
#import <CoreImage/CIFilterBuiltins.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/AssetCollectionsViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <CamPresentation/UIImage+CP_Category.h>
#include <numbers>

/*
 {
     inputAVCameraCalibrationData =     (
         CICameraCalibrationLensCorrection
     );
     ✅inputAngle =     (
         CIStraightenFilter,
         CICircularWrap,
         CIMotionBlur,
         CICMYKHalftone,
         CIKaleidoscope,
         CIOpTile,
         CIParallelogramTile,
         CITriangleTile,
         CIPageCurlTransition,
         CIPageCurlWithShadowTransition
     );
     inputBackgroundImage =     (
         CIBlendWithAlphaMask,
         CIBlendWithBlueMask,
         CIBlendWithMask,
         CIBlendWithRedMask,
         CIMix,
         CIAdditionCompositing,
         CIColorBlendMode,
         CIColorBurnBlendMode,
         CIColorDodgeBlendMode,
         CIDarkenBlendMode,
         CIDifferenceBlendMode,
         CIDivideBlendMode,
         CIExclusionBlendMode,
         CIHardLightBlendMode,
         CIHueBlendMode,
         CILightenBlendMode,
         CILinearBurnBlendMode,
         CILinearDodgeBlendMode,
         CILinearLightBlendMode,
         CILuminosityBlendMode,
         CIMaximumCompositing,
         CIMinimumCompositing,
         CIMultiplyBlendMode,
         CIMultiplyCompositing,
         CIOverlayBlendMode,
         CIPinLightBlendMode,
         CISaturationBlendMode,
         CIScreenBlendMode,
         CISoftLightBlendMode,
         CISourceAtopCompositing,
         CISourceInCompositing,
         CISourceOutCompositing,
         CISourceOverCompositing,
         CISubtractBlendMode,
         CIVividLightBlendMode,
         CIHardMixBlendMode,
         CIPlusDarkerCompositing,
         CIPlusLighterCompositing
     );
     inputBackgroundSeparationLikehood =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono
     );
     inputBacksideImage =     (
         CIPageCurlTransition,
         CIPageCurlWithShadowTransition
     );
     inputBarcodeDescriptor =     (
         CIBarcodeGenerator
     );
     inputBlurMap =     (
         CIDepthEffectApplyBlurMap,
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputBoundingBoxArray =     (
         CIDynamicFood
     );
     inputCameraModel =     (
         CIRedEyeCorrections
     );
     inputCaptureFolderMiscPath =     (
         CIDepthEffectApplyBlurMap,
         CIDepthEffectMakeBlurMap
     );
     inputCenter =     (
         CICircularWrap,
         CITorusLensDistortion,
         CIZoomBlur,
         CIVignetteEffect,
         CICrystallize,
         CIHexagonalPixellate,
         CIPointillize,
         CICMYKHalftone,
         CIKaleidoscope,
         CIOpTile,
         CIParallelogramTile,
         CITriangleTile,
         CILenticularHaloGenerator,
         CIStarShineGenerator,
         CIStripesGenerator,
         CISunbeamsGenerator,
         CIModTransition,
         CIRippleTransition,
         CICircleGenerator
     );
     inputColorSpace =     (
         CIInpaintFilter
     );
     inputConfidenceMapImage =     (
         CIFastBilateralSolver
     );
     inputContour =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2
     );
     inputContrast =     (
         CIDynamicFood
     );
     inputCorrectionInfo =     (
         CIRedEyeCorrections
     );
     inputDepthMap =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectCommercial,
         CIPortraitEffectContour,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStudio
     );
     inputDepthThreshold =     (
         CIPortraitEffectCommercial,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputDisparity =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputDisparityImage =     (
         CIDepthBlurEffect,
         CIDisparityRefinement,
         CIFastBilateralSolver
     );
     inputDisplacementImage =     (
         CIDisplacementDistortion
     );
     inputEnrich =     (
         CIPortraitEffectCommercial,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputExcludeMask =     (
         CIInpaintFilter
     );
     inputExposure =     (
         CIDynamicFood
     );
     inputExtent =     (
         CIClamp,
         CIAreaAlphaWeightedHistogram,
         CIAreaAverage,
         CIAreaBoundsRed,
         CIAreaHistogram,
         CIAreaLogarithmicHistogram,
         CIAreaMaximum,
         CIAreaMaximumAlpha,
         CIAreaMinimum,
         CIAreaMinimumAlpha,
         CIAreaMinMax,
         CIAreaMinMaxRed,
         CIColumnAverage,
         CIKMeans,
         CIRowAverage,
         CIAreaMinMaxNormalize,
         CIAreaMinMaxRedNormalize,
         CIAreaRedCentroid,
         CIAreaRedRadialCentroid
     );
     inputExtrapolate =     (
         CIColorCubeWithColorSpace
     );
     inputEyes =     (
         CIPortraitEffectCommercial,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputFaceBoxArray =     (
         CIDynamicFood,
         CIDynamicRender
     );
     inputFaceLandmarkArray =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectCommercial,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectLight,
         CIPortraitEffectLightV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputFaceLight =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2
     );
     inputFaceMask =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectCommercial,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectLight,
         CIPortraitEffectLightV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputFill =     (
         CUIShapeEffectBlur1
     );
     inputFocusRect =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono
     );
     inputFullSizeImage =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono
     );
     inputGainMap =     (
         CIDepthBlurEffect,
         CIDepthEffectApplyBlurMap,
         CIDepthEffectMakeBlurMap
     );
     inputGenerateSpillMatte =     (
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputGlassesImage =     (
         CIDepthBlurEffect,
         CIDepthEffectMakeBlurMap
     );
     inputGlowColorOuter =     (
         CUIShapeEffectBlur1
     );
     inputGradientImage =     (
         CIColorMap
     );
     inputGrainAmount =     (
         CIPortraitEffectStageWhite
     );
     inputGuideImage =     (
         CIGuidedFilter
     );
     inputHairImage =     (
         CIDepthBlurEffect,
         CIDepthEffectMakeBlurMap
     );
     inputHairMask =     (
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputImage1 =     (
         CIPassThroughSelectFrom3
     );
     inputImage2 =     (
         CIColorAbsoluteDifference,
         CILabDeltaE,
         CIPassThroughSelectFrom3
     );
     inputIntensity =     (
         CISepiaTone
     );
     inputIsSunsetSunrise =     (
         CIDynamicFood
     );
     inputKickLight =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectContour,
         CIPortraitEffectContourV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2
     );
     inputLightMap =     (
         CISmartToneFilter
     );
     inputLocalContrast =     (
         CIPortraitEffectCommercial,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputLocalLight =     (
         CIDynamicFood
     );
     inputMainImage =     (
         CIMattingSolver
     );
     inputMask =     (
         CIMaskedVariableBlur
     );
     inputMaskImage =     (
         CIColorCubesMixedWithMask,
         CIBlendWithAlphaMask,
         CIBlendWithBlueMask,
         CIBlendWithMask,
         CIBlendWithRedMask,
         CIDisintegrateWithMaskTransition,
         CIInpaintFilter
     );
     inputMatte =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectSpillCorrection,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputMatteImage =     (
         CIDepthBlurEffect,
         CIDepthEffectApplyBlurMap,
         CIDepthEffectMakeBlurMap,
         CIFocalPlane
     );
     inputMeans =     (
         CIKMeans
     );
     inputMesh =     (
         CIMeshGenerator
     );
     inputMinimumEffectLevel =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono
     );
     inputModel =     (
         CICoreMLModelFilter,
         CIInpaintFilter
     );
     inputOriginalSize =     (
         CIDisparityRefinement
     );
     inputPaletteImage =     (
         CIPaletteCentroid,
         CIPalettize
     );
     inputPredicateImage =     (
         CIMattingSolver
     );
     inputPropagateMinWeightSum =     (
         CIDisparityRefinement
     );
     inputPropagateSigmaChma =     (
         CIDisparityRefinement
     );
     inputPropagateSigmaLuma =     (
         CIDisparityRefinement
     );
     inputRadiusImage =     (
         CIVariableBoxBlur
     );
     inputRenderCache =     (
         CIPortraitEffectSpillCorrection
     );
     inputRenderProxy =     (
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputScale =     (
         CIDisparityRefinement,
         CIPortraitEffectCommercial,
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputSelected =     (
         CIPassThroughSelectFrom3
     );
     inputShadingImage =     (
         CIShadedMaterial,
         CIPageCurlTransition,
         CIRippleTransition
     );
     inputShadowColorOuter =     (
         CUIShapeEffectBlur1
     );
     inputSharpenRadius =     (
         CIPortraitEffectStageWhite
     );
     inputShiftmapImage =     (
         CIDepthEffectMakeBlurMap
     );
     inputShowSurround =     (
         CIInpaintFilter
     );
     inputSize =     (
         CIStretch
     );
     inputSkyMask =     (
         CIDynamicFood,
         CIDynamicRender
     );
     inputSmallImage =     (
         CIEdgePreserveUpsampleFilter
     );
     inputSmooth =     (
         CIPortraitEffectCommercial,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputSpillCorrectedRatioImage =     (
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputStrength =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectCommercial,
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputTargetImage =     (
         CIAccordionFoldTransition,
         CIBarsSwipeTransition,
         CICopyMachineTransition,
         CIDisintegrateWithMaskTransition,
         CIDissolveTransition,
         CIFlashTransition,
         CIModTransition,
         CIPageCurlTransition,
         CIPageCurlWithShadowTransition,
         CIRippleTransition,
         CISwipeTransition
     );
     inputTeeth =     (
         CIPortraitEffectBlack,
         CIPortraitEffectBlackoutMono,
         CIPortraitEffectCommercial,
         CIPortraitEffectStage,
         CIPortraitEffectStageMono,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudio,
         CIPortraitEffectStudioV2
     );
     inputTeethMask =     (
         CIPortraitEffectContourV2,
         CIPortraitEffectLightV2,
         CIPortraitEffectStageMonoV2,
         CIPortraitEffectStageV2,
         CIPortraitEffectStageWhite,
         CIPortraitEffectStudioV2
     );
     inputText =     (
         CIAttributedTextImageGenerator,
         CITextImageGenerator
     );
     inputTime =     (
         CIDisintegrateWithMaskTransition,
         CIPageCurlTransition,
         CIPageCurlWithShadowTransition,
         CISwipeTransition
     );
     inputUseAbsoluteDisparity =     (
         CIPortraitEffectStageWhite
     );
 }
 */

@interface ImageFilterViewController () <AssetCollectionsViewControllerDelegate>
@property (class, nonatomic, readonly) void *inputKey;
@property (retain, nonatomic, readonly, getter=_filter) CIFilter *filter;
@property (retain, nonatomic, readonly, getter=_menuBarButtonItem) UIBarButtonItem *menuBarButtonItem;
@property (assign, nonatomic, getter=_imageRequestID) PHImageRequestID imageRequestID;
@property (assign, nonatomic, getter=_imageView) UIImageView *imageView;
@property (retain, nonatomic, readonly, getter=_queue) dispatch_queue_t queue;
@end

@implementation ImageFilterViewController
@synthesize menuBarButtonItem = _menuBarButtonItem;
@synthesize imageView = _imageView;

+ (void *)inputKey {
    static void *inputKey = &inputKey;
    return inputKey;
}

- (instancetype)initWithFilterName:(NSString *)filterName {
    CIFilter * _Nullable filter = [CIFilter filterWithName:filterName];
    
    if (filter == nil) {
        [self release];
        return nil;
    }
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        _filter = [filter retain];
        _imageRequestID = PHInvalidImageRequestID;
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Image Filter Queue", attr);
        
        _queue = queue;
    }
    
    return self;
}

- (void)dealloc {
    [_filter release];
    [_menuBarButtonItem release];
    
    if (_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:_imageRequestID];
    }
    
    [_imageView release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [super dealloc];
}

- (void)loadView {
    self.view = self.imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = self.filter.name;
    navigationItem.rightBarButtonItem = self.menuBarButtonItem;
    
//    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"8339F972-DD21-45C4-8194-E633EE673478/L0/001"] options:nil][0];
//    [self _didSelectPHAsset:asset byUpdatingInputKey:@"inputImage"];
    
    dispatch_async(self.queue, ^{
        if ([self.filter.inputKeys containsObject:@"inputImage"]) {
            NSURL *demoImageURL = [NSBundle.mainBundle URLForResource:@"demo" withExtension:@"jpg"];
            assert(demoImageURL != nil);
            NSError * _Nullable error = nil;
            NSData *data = [[NSData alloc] initWithContentsOfURL:demoImageURL options:0 error:&error];
            assert(error == nil);
            CIImage *ciImage = [[CIImage alloc] initWithData:data];
            [data release];
            assert(ciImage != nil);
            
            [self.filter setValue:ciImage forKey:@"inputImage"];
            [ciImage release];
            
            UIImage *outputImage = [UIImage imageWithCIImage:self.filter.outputImage].cp_imageByPreparingForDisplay;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = outputImage;
            });
        }
    });
}

- (UIBarButtonItem *)_menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[[self _menuElement]]];
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal"] menu:menu];
    
    _menuBarButtonItem = menuBarButtonItem;
    return menuBarButtonItem;
}

- (UIDeferredMenuElement *)_menuElement {
    __block auto unretained = self;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        CIFilter *filter = unretained.filter;
        
        UIMenu *filterInfomrationMenu = [unretained _filterInformationMenuWithFilter:filter];
        UIMenu *inputsMenu = [unretained _filterInputsMenuWithFilter:filter];
        
        completion(@[filterInfomrationMenu, inputsMenu]);
    }];
    
    return element;
}

- (UIImageView *)_imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = UIColor.systemBackgroundColor;
    
    _imageView = imageView;
    return imageView;
}

- (UIMenu *)_filterInformationMenuWithFilter:(CIFilter *)filter {
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    //
    
    NSString *filterName = filter.name;
    UIAction *filterNameAction = [UIAction actionWithTitle:@"Filter Name" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    
    filterNameAction.subtitle = filterName;
    filterNameAction.cp_overrideNumberOfSubtitleLines = 0;
    filterNameAction.attributes = UIMenuElementAttributesDisabled;
    [children addObject:filterNameAction];
    
    //
    
    if (NSString *localizedName = [CIFilter localizedNameForFilterName:filterName]) {
        UIAction *localizedNameAction = [UIAction actionWithTitle:@"Localized Name" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        localizedNameAction.subtitle = localizedName;
        localizedNameAction.cp_overrideNumberOfSubtitleLines = 0;
        localizedNameAction.attributes = UIMenuElementAttributesDisabled;
        
        [children addObject:localizedNameAction];
    }
    
    //
    
    if (NSString *localizedDescription = [CIFilter localizedDescriptionForFilterName:filterName]) {
        UIAction *localizedDescriptionAction = [UIAction actionWithTitle:@"Localized Description" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        localizedDescriptionAction.subtitle = localizedDescription;
        localizedDescriptionAction.cp_overrideNumberOfSubtitleLines = 0;
        localizedDescriptionAction.attributes = UIMenuElementAttributesDisabled;
        
        [children addObject:localizedDescriptionAction];
    }
    
    //
    
    if (NSURL *localizedReferenceDocumentation = [CIFilter localizedReferenceDocumentationForFilterName:filterName]) {
        __block auto unretained = self;
        
        UIAction *localizedReferenceDocumentationAction = [UIAction actionWithTitle:@"Localized Reference Documentation" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            if (UIWindowScene *windowScene = unretained.view.window.windowScene) {
                [windowScene openURL:localizedReferenceDocumentation options:nil completionHandler:^(BOOL success) {
                    assert(success);
                }];
            } else {
                [UIApplication.sharedApplication openURL:localizedReferenceDocumentation options:@{} completionHandler:^(BOOL success) {
                    assert(success);
                }];
            }
        }];
        
        localizedReferenceDocumentationAction.subtitle = localizedReferenceDocumentation.absoluteString;
        localizedReferenceDocumentationAction.cp_overrideNumberOfSubtitleLines = 0;
        localizedReferenceDocumentationAction.attributes = UIMenuElementAttributesDisabled;
    }
    
    //
    
    NSDictionary<NSString *, id> *customAttributes = [[filter class] customAttributes];
    NSArray<NSString *> *categories = customAttributes[kCIAttributeFilterCategories];
    [children addObject:[self _filterCategoriesInformationMenuWithWithCategories:categories]];
    
    //
    
    if (NSString *available_Mac = customAttributes[kCIAttributeFilterAvailable_Mac]) {
        UIAction *action = [UIAction actionWithTitle:@"Mac Availability" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.subtitle = available_Mac;
        action.attributes = UIMenuElementAttributesDisabled;
        
        [children addObject:action];
    }
    
    if (NSString *available_iOS = customAttributes[kCIAttributeFilterAvailable_iOS]) {
        UIAction *action = [UIAction actionWithTitle:@"iOS Availability" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.subtitle = available_iOS;
        action.attributes = UIMenuElementAttributesDisabled;
        
        [children addObject:action];
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Filter Infomation" children:children];
    [children release];
    
    return menu;
}

- (UIMenu *)_filterCategoriesInformationMenuWithWithCategories:(NSArray<NSString *> *)categories {
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:categories.count];
    
    for (NSString *category in categories) {
        UIAction *action = [UIAction actionWithTitle:category image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.subtitle = [CIFilter localizedNameForCategory:category];
        action.attributes = UIMenuElementAttributesDisabled;
        action.cp_overrideNumberOfSubtitleLines = 0;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Categories" children:actions];
    [actions release];
    
    return menu;
}

- (UIMenu *)_filterInputsMenuWithFilter:(CIFilter *)filter {
    NSArray<NSString *> *inputKeys = filter.inputKeys;
    NSDictionary<NSString *, id> *customAttributes = [[filter class] customAttributes];
    
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    for (NSString *inputKey in inputKeys) {
        if ([inputKey isEqualToString:@"inputImage"]) {
            __block auto unreainted = self;
            
            UIAction *action = [UIAction actionWithTitle:inputKey image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                AssetCollectionsViewController *viewController = [AssetCollectionsViewController new];
                objc_setAssociatedObject(viewController, ImageFilterViewController.inputKey, inputKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
                viewController.delegate = unreainted;
                
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
                [viewController release];
                
                [unreainted presentViewController:navigationController animated:YES completion:nil];
                [navigationController release];
            }];
            
            [children addObject:action];
            continue;
        }
        
        //
        
        NSDictionary<NSString *, id> *attributes = customAttributes[inputKey];
        NSString * _Nullable attributeType = attributes[kCIAttributeType];
        
        //
        
        if ([attributeType isEqualToString:kCIAttributeTypeTime] or [attributeType isEqualToString:kCIAttributeTypeScalar] or [attributeType isEqualToString:kCIAttributeTypeDistance] or [attributeType isEqualToString:kCIAttributeTypeAngle]) {
            NSNumber * _Nullable maximumNumber = attributes[kCIAttributeMax];
            NSNumber * _Nullable minimumNumber = attributes[kCIAttributeMin];
            NSNumber * _Nullable sliderMaximumNumber = attributes[kCIAttributeSliderMax];
            NSNumber * _Nullable sliderMinimumNumber = attributes[kCIAttributeSliderMin];
            
            [children addObject:[self _slidersWithFilter:filter inputKey:inputKey maximumNumber:maximumNumber minimumNumber:minimumNumber sliderMaximumNumber:sliderMaximumNumber sliderMinimumNumber:sliderMinimumNumber]];
            
            continue;
        }
        
        //
        
        if ([attributeType isEqualToString:kCIAttributeTypeBoolean]) {
            BOOL boolValue = static_cast<NSNumber *>([filter valueForKey:inputKey]).boolValue;
            UIImageView *imageView = self.imageView;
            dispatch_queue_t queue = self.queue;
            
            UIAction *action = [UIAction actionWithTitle:inputKey image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(queue, ^{
                    [filter setValue:@(!boolValue) forKey:inputKey];
                    UIImage *outputImage = [UIImage imageWithCIImage:filter.outputImage].cp_imageByPreparingForDisplay;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = outputImage;
                    });
                });
            }];
            
            action.state = boolValue ? UIMenuElementStateOn : UIMenuElementStateOff;
            [children addObject:action];
            
            continue;
        }
        
        if ([attributeType isEqualToString:kCIAttributeTypeInteger] or [attributeType isEqualToString:kCIAttributeTypeCount]) {
            NSNumber * _Nullable maximumNumber = attributes[kCIAttributeMax];
            NSNumber * _Nullable minimumNumber = attributes[kCIAttributeMin];
            NSNumber * _Nullable sliderMaximumNumber = attributes[kCIAttributeSliderMax];
            NSNumber * _Nullable sliderMinimumNumber = attributes[kCIAttributeSliderMin];
            
            [children addObject:[self _steppersWithFilter:filter inputKey:inputKey maximumNumber:maximumNumber minimumNumber:minimumNumber sliderMaximumNumber:sliderMaximumNumber sliderMinimumNumber:sliderMinimumNumber]];
            
            continue;
        }
        
        //
        
        if ([inputKey isEqualToString:@"inputAngle"]) {
            [children addObject:[self _slidersWithFilter:filter inputKey:inputKey maximumNumber:@(std::numbers::pi * 2.) minimumNumber:@(0.) sliderMaximumNumber:nil sliderMinimumNumber:nil]];
            continue;
        }
        
        //
        
        abort();
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Inputs" children:children];
    [children release];
    
    return menu;
}

- (UIMenu *)_slidersWithFilter:(CIFilter *)filter inputKey:(NSString *)inputKey maximumNumber:(NSNumber * _Nullable)maximumNumber minimumNumber:(NSNumber * _Nullable)minimumNumber sliderMaximumNumber:(NSNumber * _Nullable)sliderMaximumNumber sliderMinimumNumber:(NSNumber * _Nullable)sliderMinimumNumber {
    float currentValue = static_cast<NSNumber *>([filter valueForKey:inputKey]).floatValue;
    
    UIImageView *imageView = self.imageView;
    dispatch_queue_t queue = self.queue;
    
    //
    
    UILabel *label_1 = [UILabel new];
    label_1.text = @(currentValue).stringValue;
    
    UILabel *label_2 = [UILabel new];
    label_2.text = @(currentValue).stringValue;
    
    //
    
    UISlider *slider_1 = [UISlider new];
    
    if (maximumNumber != nil and minimumNumber != nil) {
        slider_1.maximumValue = maximumNumber.floatValue;
        slider_1.minimumValue = minimumNumber.floatValue;
        slider_1.value = currentValue;
        slider_1.continuous = YES;
    } else {
        slider_1.enabled = NO;
    }
    
    UISlider *slider_2 = [UISlider new];
    
    if (sliderMaximumNumber != nil and sliderMinimumNumber != nil) {
        slider_2.maximumValue = sliderMaximumNumber.floatValue;
        slider_2.minimumValue = sliderMinimumNumber.floatValue;
        slider_2.value = currentValue;
        slider_2.continuous = YES;
    } else {
        slider_2.enabled = NO;
    }
    
    __block auto unretainedSlider_1 = slider_1;
    __block auto unretainedSlider_2 = slider_2;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto slider = static_cast<UISlider *>(action.sender);
        float value = slider.value;
        
        label_1.text = @(value).stringValue;
        label_2.text = @(value).stringValue;
        
        if (![slider isEqual:unretainedSlider_1]) {
            if (unretainedSlider_1.isEnabled) {
                unretainedSlider_1.value = value;
            }
        } else if (![slider isEqual:unretainedSlider_2]) {
            if (unretainedSlider_2.isEnabled) {
                unretainedSlider_2.value = value;
            }
        } else {
            abort();
        }
        
//        if (!slider.isTracking) {
            dispatch_async(queue, ^{
                [filter setValue:@(value) forKey:inputKey];
                UIImage *image = [UIImage imageWithCIImage:filter.outputImage].cp_imageByPreparingForDisplay;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = image;
                });
            });
//        }
    }];
    
    [slider_1 addAction:action forControlEvents:UIControlEventValueChanged];
    [slider_2 addAction:action forControlEvents:UIControlEventValueChanged];
    
    //
    
    __kindof UIMenuElement *sliderElement_1 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[slider_1, label_1]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    [slider_1 release];
    [label_1 release];
    
    //
    
    __kindof UIMenuElement *sliderElement_2 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[slider_2, label_2]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    [slider_2 release];
    [label_2 release];
    
    UIMenu *slidersMenu = [UIMenu menuWithTitle:inputKey children:@[sliderElement_1, sliderElement_2]];
    
    return slidersMenu;
}


- (UIMenu *)_steppersWithFilter:(CIFilter *)filter inputKey:(NSString *)inputKey maximumNumber:(NSNumber * _Nullable)maximumNumber minimumNumber:(NSNumber * _Nullable)minimumNumber sliderMaximumNumber:(NSNumber * _Nullable)sliderMaximumNumber sliderMinimumNumber:(NSNumber * _Nullable)sliderMinimumNumber {
    float currentValue = static_cast<NSNumber *>([filter valueForKey:inputKey]).floatValue;
    
    UIImageView *imageView = self.imageView;
    dispatch_queue_t queue = self.queue;
    
    //
    
    UILabel *label_1 = [UILabel new];
    label_1.text = @(currentValue).stringValue;
    
    UILabel *label_2 = [UILabel new];
    label_2.text = @(currentValue).stringValue;
    
    //
    
    UIStepper *stepper_1 = [UIStepper new];
    
    if (maximumNumber != nil and minimumNumber != nil) {
        stepper_1.maximumValue = maximumNumber.floatValue;
        stepper_1.minimumValue = minimumNumber.floatValue;
        stepper_1.value = currentValue;
        stepper_1.stepValue = 1.;
        stepper_1.continuous = YES;
    } else {
        stepper_1.enabled = NO;
    }
    
    UIStepper *stepper_2 = [UIStepper new];
    
    if (sliderMaximumNumber != nil and sliderMinimumNumber != nil) {
        stepper_2.maximumValue = sliderMaximumNumber.floatValue;
        stepper_2.minimumValue = sliderMinimumNumber.floatValue;
        stepper_2.value = currentValue;
        stepper_2.stepValue = 1.;
        stepper_2.continuous = YES;
    } else {
        stepper_2.enabled = NO;
    }
    
    __block auto unretainedStepper_1 = stepper_1;
    __block auto unretainedStepper_2 = stepper_2;
    
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto stepper = static_cast<UIStepper *>(action.sender);
        float value = stepper.value;
        
        label_1.text = @(value).stringValue;
        label_2.text = @(value).stringValue;
        
        if (![stepper isEqual:unretainedStepper_1]) {
            if (unretainedStepper_1.isEnabled) {
                unretainedStepper_1.value = value;
            }
        } else if (![stepper isEqual:unretainedStepper_2]) {
            if (unretainedStepper_2.isEnabled) {
                unretainedStepper_2.value = value;
            }
        } else {
            abort();
        }
        
        dispatch_async(queue, ^{
            [filter setValue:@(value) forKey:inputKey];
            UIImage *image = [UIImage imageWithCIImage:filter.outputImage].cp_imageByPreparingForDisplay;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        });
    }];
    
    [stepper_1 addAction:action forControlEvents:UIControlEventValueChanged];
    [stepper_2 addAction:action forControlEvents:UIControlEventValueChanged];
    
    //
    
    __kindof UIMenuElement *sliderElement_1 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper_1, label_1]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    [stepper_1 release];
    [label_1 release];
    
    //
    
    __kindof UIMenuElement *sliderElement_2 = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[stepper_2, label_2]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        return [stackView autorelease];
    });
    
    [stepper_2 release];
    [label_2 release];
    
    UIMenu *steppersMenu = [UIMenu menuWithTitle:inputKey children:@[sliderElement_1, sliderElement_2]];
    
    return steppersMenu;
}

- (void)_didSelectPHAsset:(PHAsset *)asset byUpdatingInputKey:(NSString *)inputKey {
    assert(asset != nil);
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = NO;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setCannotReturnSmallerImage:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setPreferHDR:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setUseLowMemoryMode:"), NO);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    if (self.imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:self.imageRequestID];
    }
    
    CIFilter *filter = self.filter;
    UIImageView *imageView = self.imageView;
    dispatch_queue_t queue = self.queue;
    
    self.imageRequestID = [PHImageManager.defaultManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
            BOOL cancelled = cancelledNumber.boolValue;
            
            if (cancelled) {
                NSLog(@"Cancelled!");
                return;
            }
        }
        
        if (NSError *error = info[PHImageErrorKey]) {
            abort();
        }
        
        if (NSNumber * _Nullable isDegraded = info[PHImageResultIsDegradedKey]) {
            if (isDegraded.boolValue) {
                return;
            }
        }
        
        if (result) {
            dispatch_async(queue, ^{
                CIImage *ciImage = result.CIImage;
                if (ciImage == nil) {
                    CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(result, sel_registerName("vk_cgImageGeneratingIfNecessary"));
                    CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(result, sel_registerName("vk_cgImagePropertyOrientation"));
                    
                    ciImage = [[[CIImage alloc] initWithCGImage:cgImage] autorelease];
                    ciImage = [ciImage imageByApplyingCGOrientation:cgImagePropertyOrientation];
                }
                
                [filter setValue:ciImage forKey:inputKey];
                UIImage *image = [UIImage imageWithCIImage:filter.outputImage].cp_imageByPreparingForDisplay;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = image;
                });
            });
        }
    }];
    
    [options release];
}

- (void)assetCollectionsViewController:(AssetCollectionsViewController *)assetCollectionsViewController didSelectAssets:(NSSet<PHAsset *> *)selectedAssets {
    [assetCollectionsViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSString *inputKey = objc_getAssociatedObject(assetCollectionsViewController, ImageFilterViewController.inputKey);
    assert(inputKey != nil);
    
    PHAsset *asset = selectedAssets.allObjects.firstObject;
    if (asset == nil) return;
    
    [self _didSelectPHAsset:asset byUpdatingInputKey:inputKey];
}

@end
