//
//  MovieWriter.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/13/24.
//

#import <CamPresentation/MovieWriter.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/NSURL+CP.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface MovieWriter () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    CMFormatDescriptionRef _Nullable _videoSourceFormatHint;
}
@property (retain, atomic, nullable) AVAssetWriter *assetWriter;
@property (retain, atomic, nullable) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (retain, atomic, nullable) AVAssetWriterInput *audioWriterInput;
@property (retain, atomic, nullable) AVAssetWriterInputMetadataAdaptor *metadataAdaptor;
@property (copy, nonatomic, readonly) CLLocation * _Nullable (^locationHandler)(void);
@property (retain, nonatomic, readonly) dispatch_queue_t isolatedQueue;
@property (retain, nonatomic, readonly) dispatch_queue_t videoQueue;
@property (retain, nonatomic, readonly) dispatch_queue_t audioQueue;
@property (assign, atomic, getter=isPaused) BOOL paused;
@end

@implementation MovieWriter
@synthesize fileOutput = _fileOutput;

+ (BOOL)_isFinishWriting:(AVAssetWriter *)assetWriter {
    id _internal;
    assert(object_getInstanceVariable(assetWriter, "_internal", reinterpret_cast<void **>(&_internal)) != nullptr);
    
    id helper;
    assert(object_getInstanceVariable(_internal, "helper", reinterpret_cast<void **>(&helper)) != nullptr);
    
    if ([helper isKindOfClass:objc_lookUpClass("AVAssetWriterFinishWritingHelper")]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)_startSessionCalledForAssetWriter:(AVAssetWriter *)assetWriter {
    id _internal;
    assert(object_getInstanceVariable(assetWriter, "_internal", reinterpret_cast<void **>(&_internal)) != nil);
    
    id helper;
    assert(object_getInstanceVariable(_internal, "helper", reinterpret_cast<void **>(&helper)) != nil);
    
    if (![helper isKindOfClass:objc_lookUpClass("AVAssetWriterWritingHelper")]) {
        abort();
    }
    
    BOOL _startSessionCalled;
    assert(object_getInstanceVariable(helper, "_startSessionCalled", reinterpret_cast<void **>(&_startSessionCalled)) != nil);
    
    return _startSessionCalled;
}

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput metadataOutputSettings:(NSDictionary<NSString *,id> *)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)())locationHandler {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t videoQueue = dispatch_queue_create("Movie Writer Video Queue", attr);
        dispatch_queue_t audioQueue = dispatch_queue_create("Movie Writer Audio Queue", attr);
        
        dispatch_retain(isolatedQueue);
        _isolatedQueue = isolatedQueue;
        _useFastRecording = useFastRecording;
        _videoQueue = videoQueue;
        _audioQueue = audioQueue;
        _videoDataOutput = [videoDataOutput retain];
        _fileOutput = [fileOutput retain];
        _locationHandler = [locationHandler copy];
        CFRetain(metadataSourceFormatHint);
        _metadataSourceFormatHint = metadataSourceFormatHint;
        _metadataOutputSettings = [metadataOutputSettings copy];
        
        if (useFastRecording) {
            [self _enableAllConnections];
        } else {
            [self _disableAllConnections];
        }
        
        //
        
        assert(videoDataOutput.sampleBufferDelegate == nil);
        assert(reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(videoDataOutput, sel_registerName("delegateOverride")) == nil);
        videoDataOutput.automaticallyConfiguresOutputBufferDimensions = NO;
        videoDataOutput.deliversPreviewSizedOutputBuffers = NO;
        videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
        [videoDataOutput setSampleBufferDelegate:self queue:videoQueue];
    }
    
    return self;
}

- (void)dealloc {
    [_videoDataOutput release];
    [_fileOutput release];
    [_metadataOutputSettings release];
    [_videoPixelBufferAdaptor release];
    [_audioWriterInput release];
    [_metadataAdaptor release];
    [self _unregisterObserversForAssetWriter:_assetWriter];
    [_assetWriter release];
    [_locationHandler release];
    dispatch_release(_isolatedQueue);
    dispatch_release(_videoQueue);
    dispatch_release(_audioQueue);
    
    if (_videoSourceFormatHint) {
        CFRelease(_videoSourceFormatHint);
    }
    
    CFRelease(_metadataSourceFormatHint);
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVAssetWriter.class]) {
        auto assetWriter = static_cast<AVAssetWriter *>(object);
        
        if ([keyPath isEqualToString:@"status"]) {
            dispatch_async(self.isolatedQueue, ^{
                if ([self.assetWriter isEqual:assetWriter]) {
                    [self _didChangeStatusWithAssetWriter:assetWriter];
                }
            });
            return;
        } else if ([keyPath isEqualToString:@"error"]) {
            assert(assetWriter.error == nil);
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (__kindof BaseFileOutput *)fileOutput {
    dispatch_assert_queue(self.isolatedQueue);
    return [[_fileOutput retain] autorelease];
}

- (void)setFileOutput:(__kindof BaseFileOutput *)fileOutput {
    dispatch_assert_queue(self.isolatedQueue);
    assert(self.assetWriter == nil);
    [_fileOutput release];
    _fileOutput = [fileOutput retain];
}

- (MovieWriterStatus)status {
    dispatch_assert_queue(self.isolatedQueue);
    
    if (AVAssetWriter *assetWriter = self.assetWriter) {
        if (self.isPaused) {
            return MovieWriterStatusPaused;
        } else if (assetWriter.status == AVAssetWriterStatusWriting) {
            return MovieWriterStatusRecording;
        } else {
            return MovieWriterStatusUnknown;
        }
    } else {
        return MovieWriterStatusPending;
    }
}

- (void)setUseFastRecording:(BOOL)useFastRecording {
    dispatch_assert_queue(self.isolatedQueue);
    _useFastRecording = useFastRecording;
    
    if (self.assetWriter == nil) {
        if (useFastRecording) {
            [self _enableAllConnections];
        } else {
            [self _disableAllConnections];
        }
    }
}

- (void)startRecordingWithAudioOutputSettings:(NSDictionary<NSString *,id> *)audioOutputSettings audioSourceFormatHint:(CMFormatDescriptionRef)audioSourceFormatHint {
    dispatch_assert_queue(self.isolatedQueue);
    assert(self.assetWriter == nil);
    
    NSURL *url = [self _nextURL];
    NSError * _Nullable error = nil;
    
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    assert(error == nil);
    self.assetWriter = assetWriter;
    
    [self _registerObserversForAssetWriter:assetWriter];
    
    //
    
    NSDictionary<NSString *, id> *videoOutputSettings = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
    
    AVAssetWriterInput *videoPixelBufferInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings sourceFormatHint:_videoSourceFormatHint];
    videoPixelBufferInput.expectsMediaDataInRealTime = YES;
    assert([assetWriter canAddInput:videoPixelBufferInput]);
    [assetWriter addInput:videoPixelBufferInput];
    
    AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoPixelBufferInput sourcePixelBufferAttributes:nil];
    [videoPixelBufferInput release];
    self.videoPixelBufferAdaptor = videoPixelBufferAdaptor;
    [videoPixelBufferAdaptor release];
    
    //
    
    AVAssetWriterInput *audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings sourceFormatHint:audioSourceFormatHint];
    audioWriterInput.expectsMediaDataInRealTime = YES;
    assert([assetWriter canAddInput:audioWriterInput]);
    [assetWriter addInput:audioWriterInput];
    self.audioWriterInput = audioWriterInput;
    [audioWriterInput release];
    
    //
    
    AVAssetWriterInput *metadataWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeMetadata outputSettings:self.metadataOutputSettings sourceFormatHint:self.metadataSourceFormatHint];
    metadataWriterInput.expectsMediaDataInRealTime = YES;
    assert([assetWriter canAddInput:metadataWriterInput]);
    [assetWriter addInput:metadataWriterInput];
    
    AVAssetWriterInputMetadataAdaptor *metadataAdaptor = [[AVAssetWriterInputMetadataAdaptor alloc] initWithAssetWriterInput:metadataWriterInput];
    [metadataWriterInput release];
    
    self.metadataAdaptor = metadataAdaptor;
    [metadataAdaptor release];
    
    //
    
//    AVAssetWriterInputGroup *inputGroup = [[AVAssetWriterInputGroup alloc] initWithInputs:@[videoPixelBufferInput, audioWriterInput, metadataWriterInput] defaultInput:videoPixelBufferInput];
//    [videoPixelBufferInput release];
//    [metadataWriterInput release];
//
//    assert([assetWriter canAddInputGroup:inputGroup]);
//    [assetWriter addInputGroup:inputGroup];
//    [inputGroup release];
    
    //
    
    [self _enableAllConnections];
    
    BOOL started = [assetWriter startWriting];
    
    if (!started) {
        NSLog(@"%@", assetWriter.error);
        abort();
    }
    
    [assetWriter release];
}

- (void)pauseRecording {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    assert(!self.isPaused);
    
    self.paused = YES;
}

- (void)resumeRecording {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    assert(self.isPaused);
    
    self.paused = NO;
}

- (void)stopRecordingWithCompletionHandler:(void (^ _Nullable)(void))completionHandler {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    
    [assetWriter finishWritingWithCompletionHandler:^{
        dispatch_async(self.isolatedQueue, ^{
            [self _didCompleteAssetWriter];
            if (completionHandler) completionHandler();
        });
    }];
}

- (NSURL *)_nextURL {
    __kindof BaseFileOutput *fileOutput = self.fileOutput;
    NSError * _Nullable error = nil;
    
    NSURL *url;
    if (fileOutput.class == PhotoLibraryFileOutput.class) {
        NSURL *tmpURL = [NSURL cp_processTemporaryURLByCreatingDirectoryIfNeeded:YES];
        url = [tmpURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
    } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
        auto externalFileOutput = static_cast<ExternalStorageDeviceFileOutput *>(fileOutput);
        url = [externalFileOutput.externalStorageDevice nextAvailableURLsWithPathExtensions:@[UTTypeQuickTimeMovie.preferredFilenameExtension] error:&error].firstObject;
        assert(error == nil);
        assert([url startAccessingSecurityScopedResource]);
    } else {
        abort();
    }
    
    assert(url != nil);
    NSLog(@"%@", url);
    
    return url;
}

- (void)_appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    dispatch_assert_queue(self.videoQueue);
    
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desc);
    assert(mediaType == kCMMediaType_Video);
    
    CMAttachmentMode mode = 0;
    CFStringRef _Nullable reason = (CFStringRef)CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, &mode);
    if (reason) {
        CFShow(reason);
    }
    
    if (self.useFastRecording) {
        if (CMFormatDescriptionRef _Nullable videoSourceFormatHint = _videoSourceFormatHint) {
            CFRelease(videoSourceFormatHint);
        }
        
        _videoSourceFormatHint = desc;
        CFRetain(desc);
    }
    
    AVAssetWriter *assetWriter = self.assetWriter;
    if (assetWriter == nil) return;
    
    if ([MovieWriter _isFinishWriting:assetWriter]) {
        return;
    }
    
    if (assetWriter.status != AVAssetWriterStatusWriting or self.isPaused) {
        return;
    }
    
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    BOOL startSessionCalled = [MovieWriter _startSessionCalledForAssetWriter:assetWriter];
    if (!startSessionCalled) {
        [assetWriter startSessionAtSourceTime:timestamp];
    }
    
    AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor = self.videoPixelBufferAdaptor;
    assert(videoPixelBufferAdaptor != nil);
    
    if (videoPixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        BOOL success = [videoPixelBufferAdaptor appendPixelBuffer:imageBuffer withPresentationTime:timestamp];
        
        if (!success) {
            NSLog(@"%@", assetWriter.error);
        }
    }
}

- (void)nonisolated_appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desc);
    assert(mediaType == kCMMediaType_Audio);
    
    CMAttachmentMode mode = 0;
    CFStringRef _Nullable reason = (CFStringRef)CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, &mode);
    if (reason) {
        CFShow(reason);
    }
    
    AVAssetWriter *assetWriter = self.assetWriter;
    if (assetWriter == nil) return;
    if (assetWriter.status != AVAssetWriterStatusWriting or self.isPaused) {
        return;
    }
    
    if ([MovieWriter _isFinishWriting:assetWriter]) {
        return;
    }
    
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    BOOL startSessionCalled = [MovieWriter _startSessionCalledForAssetWriter:assetWriter];
    
    if (startSessionCalled) {
        AVAssetWriterInput *audioWriterInput = self.audioWriterInput;
        assert(audioWriterInput != nil);
        
        if (audioWriterInput.isReadyForMoreMediaData) {
            BOOL success = [audioWriterInput appendSampleBuffer:sampleBuffer];
            
            if (!success) {
                NSLog(@"%@", assetWriter.error);
            }
        }
    }
}

- (void)nonisolated_appendTimedMetadataGroup:(AVTimedMetadataGroup *)timedMetadataGroup {
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    if (assetWriter.status == AVAssetWriterStatusCompleted or self.isPaused) {
        return;
    }
    
    if ([MovieWriter _isFinishWriting:assetWriter]) {
        return;
    }
    
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    if ([MovieWriter _startSessionCalledForAssetWriter:assetWriter]) {
        AVAssetWriterInputMetadataAdaptor *metadataAdaptor = self.metadataAdaptor;
        
        BOOL success = [metadataAdaptor appendTimedMetadataGroup:timedMetadataGroup];
        
        if (!success) {
            NSLog(@"%@", assetWriter.error);
        }
    }
}

- (void)_enableAllConnections {
    assert(self.videoDataOutput.connections.count > 0);
    for (AVCaptureConnection *connection in self.videoDataOutput.connections) {
        connection.enabled = YES;
    }
}

- (void)_disableAllConnections {
    assert(self.videoDataOutput.connections.count > 0);
    for (AVCaptureConnection *connection in self.videoDataOutput.connections) {
        connection.enabled = NO;
    }
}

- (void)_registerObserversForAssetWriter:(AVAssetWriter *)assetWriter {
    [assetWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nullptr];
    [assetWriter addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nullptr];
}

- (void)_unregisterObserversForAssetWriter:(AVAssetWriter *)assetWriter {
    [assetWriter removeObserver:self forKeyPath:@"status"];
    [assetWriter removeObserver:self forKeyPath:@"error"];
}

- (void)_didChangeStatusWithAssetWriter:(AVAssetWriter *)assetWriter {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriterStatus status = assetWriter.status;
    
    switch (status) {
        case AVAssetWriterStatusFailed:
        case AVAssetWriterStatusCancelled:
            abort();
        case AVAssetWriterStatusCompleted:
            [self _didCompleteAssetWriter];
            break;
        default:
            break;
    }
}

- (void)_didCompleteAssetWriter {
    dispatch_assert_queue(self.isolatedQueue);
    
    [self _disableAllConnections];
    
    if (self.assetWriter != nil) {
        [self _saveVideoFile];
        [self _flushAssetWriter];
    }
}

- (void)_flushAssetWriter {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    assert(assetWriter.status != AVAssetWriterStatusWriting);
    
    [self _unregisterObserversForAssetWriter:assetWriter];
    self.assetWriter = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioWriterInput = nil;
    self.metadataAdaptor = nil;
}

- (void)_saveVideoFile {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    
    NSURL *outputURL = assetWriter.outputURL;
    
    __kindof BaseFileOutput *fileOutput = self.fileOutput;
    
    if (fileOutput.class == PhotoLibraryFileOutput.class) {
        auto photoLibraryFileOutput = static_cast<PhotoLibraryFileOutput *>(fileOutput);
        
        [photoLibraryFileOutput.photoLibrary performChanges:^{
            PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
            
            [request addResourceWithType:PHAssetResourceTypeVideo fileURL:outputURL options:nil];
            
            request.location = self.locationHandler();
        }
                                        completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"%d %@", success, error);
            assert(error == nil);
            
            [NSFileManager.defaultManager removeItemAtURL:outputURL error:&error];
            [outputURL stopAccessingSecurityScopedResource];
            assert(error == nil);
        }];
    } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
        [outputURL stopAccessingSecurityScopedResource];
    } else {
        abort();
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desc);
    
    if (mediaType == kCMMediaType_Video) {
        [self _appendVideoSampleBuffer:sampleBuffer];
    }
}

@end

#endif
