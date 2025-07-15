//
//  UIDeferredMenuElement+NerualAnalyzer.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/UIDeferredMenuElement+NerualAnalyzer.h>
#import <CamPresentation/MLModelAsset+Category.h>
#import <Vision/Vision.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <ranges>
#include <vector>

@implementation UIDeferredMenuElement (NerualAnalyzer)

+ (instancetype)cp_nerualAnalyzerMenuWithModelType:(NerualAnalyzerModelType)modelType asset:(PHAsset *)asset requestIDHandler:(void (^)(PHImageRequestID))requestIDHandler didSelectModelTypeHandler:(void (^)(NerualAnalyzerModelType))didSelectModelTypeHandler {
    return [UIDeferredMenuElement elementWithProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.allowSecondaryDegradedImage = NO;
        
        PHImageRequestID requestID = [PHImageManager.defaultManager requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            assert(imageData != nil);
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                NSError * _Nullable error = nil;
                MLModel *model = [UIDeferredMenuElement _cp_mlModelFromModelType:modelType error:&error];
                assert(error == nil);
                
                MLImageConstraint *constraint = model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
                
                /*
                 {
                     kCGImageSourceShouldCache = 0;
                     kCGImageSourceSkipCRC = 0;
                     kCGImageSourceSkipMetadata = 1;
                 }
                 */
                CGImageRef cgImage;
                if ([dataUTI isEqualToString:UTTypeJPEG.identifier]) {
                    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageData.bytes, imageData.length, NULL);
                    cgImage = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, YES, kCGRenderingIntentDefault);
                    CFRelease(dataProvider);
                } else if ([dataUTI isEqualToString:UTTypePNG.identifier]) {
                    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageData.bytes, imageData.length, NULL);
                    cgImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, YES, kCGRenderingIntentDefault);
                    CFRelease(dataProvider);
                } else {
                    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
                    size_t idx = CGImageSourceGetPrimaryImageIndex(source);
                    cgImage = CGImageSourceCreateImageAtIndex(source, idx, NULL);
                    CFRelease(source);
                }
                
                MLFeatureValue *featureValue = [MLFeatureValue featureValueWithCGImage:cgImage
                                                                           orientation:orientation
                                                                            constraint:constraint
                                                                               options:@{
                    MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
                }
                                                                                 error:&error];
                CGImageRelease(cgImage);
                assert(error == nil);
                
                MLDictionaryFeatureProvider *inputProvider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:@{@"image": featureValue} error:&error];
                assert(error == nil);
                
                id<MLFeatureProvider> outputProvider = [model predictionFromFeatures:inputProvider error:&error];
                [inputProvider release];
                assert(error == nil);
                
                NSString *target = [outputProvider featureValueForName:@"target"].stringValue;
                assert(target != nil);
                NSDictionary<NSString *, NSNumber *> *targetProbability = [outputProvider featureValueForName:@"targetProbability"].dictionaryValue;
                assert(targetProbability != nil);
                
                UIAction *targetAction = [UIAction actionWithTitle:target image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                }];
                targetAction.attributes = UIMenuElementAttributesDisabled;
                targetAction.cp_overrideNumberOfTitleLines = 0;
                
                UIAction *targetProbabilityAction = [UIAction actionWithTitle:targetProbability.description image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                }];
                targetProbabilityAction.attributes = UIMenuElementAttributesDisabled;
                targetProbabilityAction.cp_overrideNumberOfTitleLines = 0;
                
                UIMenu *modelsMenu = [UIDeferredMenuElement _cp_menu_nerualAnalyzerModelTypesMenuWithSelectedModelType:modelType didSelectModelTypeHandler:didSelectModelTypeHandler];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[targetAction, targetProbabilityAction, modelsMenu]);
                });
            });
        }];
        
        [options release];
        
        if (requestIDHandler) {
            requestIDHandler(requestID);
        }
    }];
}

+ (MLModel * _Nullable)_cp_mlModelFromModelType:(NerualAnalyzerModelType)modelType error:(NSError * _Nullable __autoreleasing * _Nullable)errorOut {
    MLModelConfiguration *configuration = [MLModelConfiguration new];
    configuration.modelDisplayName = NSStringFromNerualAnalyzerModelType(modelType);
    configuration.allowLowPrecisionAccumulationOnGPU = YES;
    configuration.computeUnits = MLComputeUnitsAll;
    
    MLOptimizationHints * optimizationHints = [MLOptimizationHints new];
    optimizationHints.reshapeFrequency = MLReshapeFrequencyHintInfrequent;
    optimizationHints.specializationStrategy = MLSpecializationStrategyDefault;
    
    configuration.optimizationHints = optimizationHints;
    [optimizationHints release];
    
    MLModelAsset *modelAsset = [MLModelAsset cp_modelAssetWithModelType:modelType error:errorOut];
    if (modelAsset == nil) {
        [configuration release];
        return nil;
    }
    MLModel *model = reinterpret_cast<id (*)(id, SEL, id, id *)>(objc_msgSend)(modelAsset, sel_registerName("modelWithConfiguration:error:"), configuration, errorOut);
    [configuration release];
    if (model == nil) {
        return nil;
    }
    
    return model;
}

+ (UIMenu *)_cp_menu_nerualAnalyzerModelTypesMenuWithSelectedModelType:(NerualAnalyzerModelType)selectedModelType didSelectModelTypeHandler:(void (^ _Nullable)(NerualAnalyzerModelType modelType))didSelectModelTypeHandler {
    NSUInteger count;
    const NerualAnalyzerModelType *allTypes = allNerualAnalyzerModelTypes(&count);
    
    auto actionsVec = std::views::iota(allTypes, allTypes + count)
    | std::views::transform([selectedModelType, didSelectModelTypeHandler](const NerualAnalyzerModelType *ptr) -> UIAction * {
        const NerualAnalyzerModelType modelType = *ptr;
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromNerualAnalyzerModelType(modelType) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            if (didSelectModelTypeHandler) {
                didSelectModelTypeHandler(modelType);
            }
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = (selectedModelType == modelType) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions];
    [actions release];
    
    return menu;
}

@end
