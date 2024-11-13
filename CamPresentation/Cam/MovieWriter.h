//
//  MovieWriter.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/13/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMedia/CoreMedia.h>
#import <CamPresentation/BaseFileOutput.h>

NS_ASSUME_NONNULL_BEGIN

#warning 이제 하나의 Video Device는 여러 개의 Video Data Output을 가질 수 있으므로, CaptureService에서 Video Data Output을 다루는 부분을 고려해야함
#warning TODO https://www.finnvoorhees.com/words/reading-and-writing-spatial-video-with-avfoundation

API_UNAVAILABLE(visionos)
@interface MovieWriter : NSObject
@property (retain, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;
@property (retain, nonatomic, readonly) AVAssetWriterInput *audioWriterInput;
@property (retain, nonatomic, readonly) AVAssetWriterInputMetadataAdaptor *metadataAdaptor;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioOutputSettings:(NSDictionary<NSString *, id> * _Nullable)audioOutputSettings metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings videoSourceFormatHint:(nullable CMVideoFormatDescriptionRef)videoSourceFormatHint audioSourceFormatHint:(nullable CMAudioFormatDescriptionRef)audioSourceFormatHint metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint locationHandler:(CLLocation * _Nullable (^)(void))locationHandler;
- (void)startRecording;
- (void)stopRecording;
- (void)pauseRecording;
@end

NS_ASSUME_NONNULL_END
