//
//  BaseImageFilter.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/10/25.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageFilterFloatValueDescriptor : NSObject
@property (copy, nonatomic, readonly) NSString *key;
@property (assign, nonatomic, readonly) float minimumValue;
@property (assign, nonatomic, readonly) float maximumValue;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithKey:(NSString *)key minimumValue:(float)minimumValue maximumValue:(float)maximumValue;
@end

@interface BaseImageFilter : NSObject
@property (copy, nonatomic, readonly) NSString *filterName;
@property (copy, nonatomic, readonly) NSArray<NSString *> *inputImageKeys;
@property (copy, nonatomic, readonly) NSArray<ImageFilterFloatValueDescriptor *> *inputFloatValueKeys;
@end

NS_ASSUME_NONNULL_END
