//
//  UIDeferredMenuElement+NerualAnalyzer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/NerualAnalyzerModelType.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIDeferredMenuElement (NerualAnalyzer)
+ (instancetype)cp_nerualAnalyzerMenuWithModelType:(NerualAnalyzerModelType)modelType image:(UIImage *)image didSelectModelTypeHandler:(void (^ _Nullable)(NerualAnalyzerModelType modelType))didSelectModelTypeHandler;
@end

NS_ASSUME_NONNULL_END
