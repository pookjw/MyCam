//
//  NerualAnalyzerModelType.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/18/24.
//

#import <CamPresentation/NerualAnalyzerModelType.h>
#import <ranges>

@interface __CP_NerualAnalyzerModelType : NSObject
@end
@implementation __CP_NerualAnalyzerModelType
@end

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

NerualAnalyzerModelType NerualAnalyzerModelTypeFromNSString(NSString *string) {
    assert(string != nil);
    
    NSUInteger count;
    const NerualAnalyzerModelType * allTypes = allNerualAnalyzerModelTypes(&count);
    
    auto typePtr = std::ranges::find_if(allTypes, allTypes + count, [string](const NerualAnalyzerModelType type) {
        return [NSStringFromNerualAnalyzerModelType(type) isEqualToString:string];
    });
    
    assert(typePtr != nullptr);
    return *typePtr;
}

NSURL *mlmodelcURLFromNerualAnalyzerModelType(NerualAnalyzerModelType type) {
    NSBundle *bundle = [NSBundle bundleForClass:[__CP_NerualAnalyzerModelType class]];
    assert(bundle != nil);
    
    NSString *name = NSStringFromNerualAnalyzerModelType(type);
    
    NSURL *url = [bundle URLForResource:name withExtension:@"mlmodelc"];
    assert(url != nil);
    return url;
}
