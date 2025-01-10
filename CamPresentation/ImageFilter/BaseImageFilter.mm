//
//  BaseImageFilter.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/BaseImageFilter.h>

@implementation ImageFilterFloatValueDescriptor

- (instancetype)initWithKey:(NSString *)key minimumValue:(float)minimumValue maximumValue:(float)maximumValue {
    if (self = [super init]) {
        _key = [key copy];
        _minimumValue = minimumValue;
        _maximumValue = maximumValue;
    }
    
    return self;
}

- (void)dealloc {
    [_key release];
    [super dealloc];
}

@end

@implementation BaseImageFilter
@dynamic filterName;
@dynamic inputImageKeys;
@dynamic inputFloatValueKeys;
@end
