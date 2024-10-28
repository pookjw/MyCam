//
//  MovieAssetWriter.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/BaseFileOutput.h>

NS_ASSUME_NONNULL_BEGIN

@interface MovieAssetWriter : NSObject
@property (retain, nonatomic, readonly) AVAssetWriter *assetWriter;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput;
@end

NS_ASSUME_NONNULL_END
