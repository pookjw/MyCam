//
//  NerualAnalyzerModelType.h
//  MyCam
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NerualAnalyzerModelType) {
    NerualAnalyzerModelTypeCatOrDogV1 = 1, // nullopt일 경우 0과 충돌
    NerualAnalyzerModelTypeCatOrDogV2
};

const NerualAnalyzerModelType * allNerualAnalyzerModelTypes(NSUInteger * _Nullable countOut);

NSString * NSStringFromNerualAnalyzerModelType(NerualAnalyzerModelType type);
NerualAnalyzerModelType NerualAnalyzerModelTypeFromNSString(NSString *string);
NSURL *mlmodelcURLFromNerualAnalyzerModelType(NerualAnalyzerModelType type);

NS_ASSUME_NONNULL_END
