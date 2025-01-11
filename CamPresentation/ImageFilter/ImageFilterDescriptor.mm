//
//  ImageFilterDescriptor.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CamPresentation/ImageFilterDescriptor.h>

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

@implementation ImageFilterDescriptor

- (instancetype)initWithFilterName:(NSString *)filterName {
    self = [super init];
    if (self == nil) {
        [self release];
        return nil;
    }
    
    //
    
    
    
    //
    
    return nil;
}

@end
