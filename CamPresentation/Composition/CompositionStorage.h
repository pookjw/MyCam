//
//  CompositionStorage.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/18/25.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompositionStorage : NSObject
@property (class, nonatomic, nullable) AVComposition *composition;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
