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

@implementation UIDeferredMenuElement (NerualAnalyzer)

+ (nonnull instancetype)cp_nerualAnalyzerMenuWithModelType:(NerualAnalyzerModelType)modelType image:(nonnull UIImage *)image didSelectModelTypeHandler:(void (^ _Nullable)(NerualAnalyzerModelType))didSelectModelTypeHandler {
    return [UIDeferredMenuElement elementWithProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            MLModelConfiguration *configuration = [MLModelConfiguration new];
            configuration.modelDisplayName = NSStringFromNerualAnalyzerModelType(modelType);
            configuration.allowLowPrecisionAccumulationOnGPU = YES;
            configuration.computeUnits = MLComputeUnitsAll;
            
            MLOptimizationHints * optimizationHints = [MLOptimizationHints new];
            optimizationHints.reshapeFrequency = MLReshapeFrequencyHintInfrequent;
            optimizationHints.specializationStrategy = MLSpecializationStrategyDefault;
            
            configuration.optimizationHints = optimizationHints;
            [optimizationHints release];
            
            NSError * _Nullable error = nil;
            MLModelAsset *modelAsset = [MLModelAsset cp_modelAssetWithModelType:modelType error:&error];
            assert(error == nil);
            
            MLModel *model = reinterpret_cast<id (*)(id, SEL, id, id *)>(objc_msgSend)(modelAsset, sel_registerName("modelWithConfiguration:error:"), configuration, &error);
            [configuration release];
            assert(error == nil);
            
            CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
            CGImagePropertyOrientation orientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
            assert(cgImage != NULL);
            
            MLImageConstraint *constraint = model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
            
            MLFeatureValue *featureValue = [MLFeatureValue featureValueWithCGImage:cgImage
                                                                       orientation:orientation
                                                                        constraint:constraint
                                                                           options:@{
                MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
            }
                                                                             error:&error];
            assert(error == nil);
            
            MLDictionaryFeatureProvider *inputProvider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:@{@"image": featureValue} error:&error];
            assert(error == nil);
            
            id<MLFeatureProvider> outputProvider = [model predictionFromFeatures:inputProvider error:&error];
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[targetAction, targetProbabilityAction]);
            });
        });
    }];
}

@end
