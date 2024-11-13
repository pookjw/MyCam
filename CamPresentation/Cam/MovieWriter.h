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

typedef NS_ENUM(NSUInteger, MovieWriterStatus) {
    MovieWriterStatusPending,
    MovieWriterStatusRecording,
    MovieWriterStatusPaused
} API_UNAVAILABLE(macos, visionos);

API_UNAVAILABLE(visionos)
@interface MovieWriter : NSObject
@property (retain, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;
@property (retain, nonatomic, readonly) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, readonly) MovieWriterStatus status;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*
 toggleConnectionEnabled : 필요에 따라 AVCapture*DataOutput에 연결된 Connection들을 비활성화 한다.
 useFastRecording : 빠른 녹화 시작을 위해 sourceFormatHint을 수집한다. 수집을 위해 Connection이 상시 활성화되어 있어야 한다.
 
 toggleConnectionEnabled와 useFastRecording을 동시에 설정하는 것은 불가능하다. useFastRecording은 Connection이 상시 켜져 있는 상태에서 sourceFormatHint을 수집해야 하기 때문이다.
 */
- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint toggleConnectionEnabled:(BOOL)toggleConnectionEnabled isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)(void))locationHandler;
- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)(void))locationHandler;

- (void)startRecording;
- (void)pauseRecording;
- (void)stopRecording;

- (void)appendTimedMetadataGroup:(AVTimedMetadataGroup *)timedMetadataGroup;
@end

NS_ASSUME_NONNULL_END
