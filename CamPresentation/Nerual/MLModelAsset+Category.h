//
//  MLModelAsset+Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CoreML/CoreML.h>
#import <CamPresentation/NerualAnalyzerModelType.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface MLModelAsset (Category)
+ (instancetype)cp_modelAssetWithModelType:(NerualAnalyzerModelType)modelType error:(NSError * _Nullable __autoreleasing * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
