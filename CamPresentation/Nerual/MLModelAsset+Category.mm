//
//  MLModelAsset+Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/MLModelAsset+Category.h>

@implementation MLModelAsset (Category)

+ (instancetype)cp_modelAssetWithModelType:(NerualAnalyzerModelType)modelType error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [MLModelAsset modelAssetWithURL:mlmodelcURLFromNerualAnalyzerModelType(modelType) error:error];
}

@end
