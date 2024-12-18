//
//  NerualAnalyzerModelType.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/NerualAnalyzerModelType.h>

const NerualAnalyzerModelType * allNerualAnalyzerModelTypes(NSUInteger * _Nullable countOut) {
    static NerualAnalyzerModelType allTypes[2] = {
        NerualAnalyzerModelTypeCatOrDogV1,
        NerualAnalyzerModelTypeCatOrDogV2
    };
    
    if (countOut != NULL) {
        *countOut = 2;
    }
    
    return allTypes;
}

NSString * NSStringFromNerualAnalyzerModelType(NerualAnalyzerModelType type) {
    switch (type) {
        case NerualAnalyzerModelTypeCatOrDogV1:
            return @"Cat or Dog V1";
        case NerualAnalyzerModelTypeCatOrDogV2:
            return @"Cat or Dog V2";
        default:
            abort();
    }
}
