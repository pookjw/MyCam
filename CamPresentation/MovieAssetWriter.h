//
//  MovieAssetWriter.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CamPresentation/BaseFileOutput.h>

NS_ASSUME_NONNULL_BEGIN

#warning TODO https://www.finnvoorhees.com/words/reading-and-writing-spatial-video-with-avfoundation

@interface MovieAssetWriter : NSObject
@property (retain, nonatomic, readonly) AVAssetWriter *assetWriter;
@property (retain, nonatomic, readonly) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (retain, nonatomic, readonly, nullable) AVAssetWriterInput *audioWriterInput;
@property (retain, nonatomic, readonly, nullable) AVAssetWriterInputMetadataAdaptor *metadataAdaptor;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoOutputSettings:(NSDictionary<NSString *, id> *)videoOutputSettings audioOutputSettings:(NSDictionary<NSString *, id> * _Nullable)audioOutputSettings metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings locationHandler:(CLLocation * _Nullable (^)(void))locationHandler;
@end

NS_ASSUME_NONNULL_END
