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
#import <CamPresentation/Extern.h>
#import <CamPresentation/MovieInputDescriptor.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Spatial https://www.finnvoorhees.com/words/reading-and-writing-spatial-video-with-avfoundation
 */

CP_EXTERN NSNotificationName const MovieWriterChangedStatusNotificationName;

typedef NS_ENUM(NSUInteger, MovieWriterStatus) {
    MovieWriterStatusUnknown,
    MovieWriterStatusPending,
    MovieWriterStatusRecording,
    MovieWriterStatusPaused
};

__attribute__((objc_direct_members))
@interface MovieWriter : NSObject
@property (retain, nonatomic, nullable) __kindof BaseFileOutput *fileOutput;
@property (retain, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;
@property (assign, nonatomic) BOOL useFastRecording;

@property (nonatomic, readonly) MovieWriterStatus status;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^ _Nullable)())locationHandler;

- (void)startRecordingWithAudioDescriptors:(NSArray<MovieInputDescriptor *> *)audioDescriptors metadataDescriptors:(NSArray<MovieInputDescriptor *> *)MovieInputDescriptor metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef _Nullable)metadataSourceFormatHint;
- (void)pauseRecording;
- (void)resumeRecording;
- (void)stopRecordingWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;

- (void)nonisolated_appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer forInputKey:(id)audioInputKey;
- (void)nonisolated_appendTimedMetadataSampleBuffer:(CMSampleBufferRef)sampleBuffer forInputKey:(id)audioInputKey;
- (void)nonisolated_appendTimedMetadataGroup:(AVTimedMetadataGroup *)timedMetadataGroup;

- (void)nonislated_userInfoHandler:(void (^)(NSMutableDictionary *userInfo))userInfoHandler;
@end

NS_ASSUME_NONNULL_END
