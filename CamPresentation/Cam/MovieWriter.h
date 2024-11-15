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

/*
 Spatial https://www.finnvoorhees.com/words/reading-and-writing-spatial-video-with-avfoundation
 
 이제 하나의 Video Device는 여러 개의 Video Data Output을 가질 수 있으므로, CaptureService에서 Video Data Output을 다루는 부분을 고려해야함 (VideoDataOutputFromCaptureDevice, queue_outputClass:fromCaptureDevice:)
 
 drop reason 출력하기
 */

typedef NS_ENUM(NSUInteger, MovieWriterStatus) {
    MovieWriterStatusUnknown,
    MovieWriterStatusPending,
    MovieWriterStatusRecording,
    MovieWriterStatusPaused
} API_UNAVAILABLE(macos, visionos);

API_UNAVAILABLE(visionos)
@interface MovieWriter : NSObject
@property (retain, nonatomic, nullable) __kindof BaseFileOutput *fileOutput;
@property (retain, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;
@property (copy, nonatomic, readonly) NSDictionary<NSString *, id> *metadataOutputSettings;
@property (assign, nonatomic) BOOL useFastRecording;
@property (assign, nonatomic, readonly, nullable) CMMetadataFormatDescriptionRef metadataSourceFormatHint;

@property (nonatomic, readonly) MovieWriterStatus status;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput metadataOutputSettings:(NSDictionary<NSString *,id> * _Nullable)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)())locationHandler;

- (void)startRecordingWithAudioOutputSettings:(NSDictionary<NSString *, id> * _Nullable)audioOutputSettings audioSourceFormatHint:(CMFormatDescriptionRef _Nullable)audioSourceFormatHint;
- (void)pauseRecording;
- (void)resumeRecording;
- (void)stopRecordingWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;

- (void)nonisolated_appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)nonisolated_appendTimedMetadataGroup:(AVTimedMetadataGroup *)timedMetadataGroup;
@end

NS_ASSUME_NONNULL_END
