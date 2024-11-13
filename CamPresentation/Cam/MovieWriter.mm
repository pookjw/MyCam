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

@interface MovieWriter () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    CMFormatDescriptionRef _Nullable _videoSourceFormatHint;
    CMFormatDescriptionRef _Nullable _audioSourceFormatHint;
    CMMetadataFormatDescriptionRef _Nullable _metadataSourceFormatHint;
}
@property (retain, nonatomic, nullable) AVAssetWriter *assetWriter;
@property (retain, nonatomic, nullable) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (retain, nonatomic, nullable) AVAssetWriterInput *audioWriterInput;
@property (retain, nonatomic, nullable) AVAssetWriterInputMetadataAdaptor *metadataAdaptor;
@property (retain, nonatomic, readonly) __kindof BaseFileOutput *fileOutput;
@property (copy, nonatomic, readonly) CLLocation * _Nullable (^locationHandler)(void);
@property (retain, nonatomic, readonly) dispatch_queue_t isolatedQueue;
@property (retain, nonatomic, readonly) dispatch_queue_t videoQueue;
@property (retain, nonatomic, readonly) dispatch_queue_t audioQueue;
@property (assign, nonatomic, readonly) BOOL toggleConnectionEnabled;
@property (assign, nonatomic, readonly) BOOL useFastRecording;
@property (assign, nonatomic, getter=isPaused) BOOL paused;
@property (copy, nonatomic, readonly) NSDictionary<NSString *, id> *metadataOutputSettings;
@end

@implementation MovieWriter

+ (BOOL)startSessionCalledForAssetWriter:(AVAssetWriter *)assetWriter {
    id _internal;
    assert(object_getInstanceVariable(assetWriter, "_internal", reinterpret_cast<void **>(&_internal)) != nullptr);
    
    id helper;
    assert(object_getInstanceVariable(_internal, "helper", reinterpret_cast<void **>(&helper)) != nullptr);
    
    BOOL _startSessionCalled;
    assert(object_getInstanceVariable(helper, "_startSessionCalled", reinterpret_cast<void **>(&_startSessionCalled)) != nullptr);
    
    return _startSessionCalled;
}

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput metadataOutputSettings:(NSDictionary<NSString *,id> *)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint toggleConnectionEnabled:(BOOL)toggleConnectionEnabled isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)())locationHandler {
    return [self _initWithFileOutput:fileOutput videoDataOutput:videoDataOutput audioDataOutput:audioDataOutput metadataOutputSettings:metadataOutputSettings metadataSourceFormatHint:metadataSourceFormatHint toggleConnectionEnabled:toggleConnectionEnabled useFastRecording:NO isolatedQueue:isolatedQueue locationHandler:locationHandler];
}

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput metadataOutputSettings:(NSDictionary<NSString *,id> *)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)())locationHandler {
    return [self _initWithFileOutput:fileOutput videoDataOutput:videoDataOutput audioDataOutput:audioDataOutput metadataOutputSettings:metadataOutputSettings metadataSourceFormatHint:metadataSourceFormatHint toggleConnectionEnabled:NO useFastRecording:useFastRecording isolatedQueue:isolatedQueue locationHandler:locationHandler];
}

- (instancetype)_initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput metadataOutputSettings:(NSDictionary<NSString *,id> *)metadataOutputSettings metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint toggleConnectionEnabled:(BOOL)toggleConnectionEnabled useFastRecording:(BOOL)useFastRecording isolatedQueue:(dispatch_queue_t)isolatedQueue locationHandler:(CLLocation * _Nullable (^)())locationHandler {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t videoQueue = dispatch_queue_create("Movie Writer Video Queue", attr);
        dispatch_queue_t audioQueue = dispatch_queue_create("Movie Writer Audio Queue", attr);
        
        dispatch_retain(isolatedQueue);
        _isolatedQueue = isolatedQueue;
        _toggleConnectionEnabled = toggleConnectionEnabled;
        _useFastRecording = useFastRecording;
        _videoQueue = videoQueue;
        _audioQueue = audioQueue;
        _videoDataOutput = [videoDataOutput retain];
        _audioDataOutput = [audioDataOutput retain];
        _fileOutput = [fileOutput retain];
        _locationHandler = [locationHandler copy];
        _toggleConnectionEnabled = toggleConnectionEnabled;
        CFRetain(metadataSourceFormatHint);
        _metadataSourceFormatHint = metadataSourceFormatHint;
        _metadataOutputSettings = [metadataOutputSettings copy];
        
        if (useFastRecording) {
            [self _enableAllConnections];
        } else if (toggleConnectionEnabled) {
            [self _disableAllConnections];
        }
        
        //
        
        assert(videoDataOutput.sampleBufferDelegate == nil);
        assert(reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(videoDataOutput, sel_registerName("delegateOverride")) == nil);
        videoDataOutput.deliversPreviewSizedOutputBuffers = NO;
        videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
        [videoDataOutput setSampleBufferDelegate:self queue:videoQueue];
        
        assert(audioDataOutput.sampleBufferDelegate == nil);
        assert(reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(audioDataOutput, sel_registerName("delegateOverride")) == nil);
        [audioDataOutput setSampleBufferDelegate:self queue:audioQueue];
    }
    
    return self;
}

- (void)dealloc {
    [_videoDataOutput release];
    [_audioDataOutput release];
    [_fileOutput release];
    [_videoPixelBufferAdaptor release];
    [_audioWriterInput release];
    [_metadataAdaptor release];
    [self _unregisterObserversForAssetWriter:_assetWriter];
    [_assetWriter release];
    [_locationHandler release];
    dispatch_release(_isolatedQueue);
    dispatch_release(_videoQueue);
    dispatch_release(_audioQueue);
    CFRelease(_videoSourceFormatHint);
    CFRelease(_audioSourceFormatHint);
    CFRelease(_metadataSourceFormatHint);
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVAssetWriter.class]) {
        <#code to be executed upon observing keypath#>
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (MovieWriterStatus)status {
    dispatch_assert_queue(self.isolatedQueue);
    
    if (self.assetWriter == nil) {
        return MovieWriterStatusPending;
    } else if (self.isPaused) {
        return MovieWriterStatusPaused;
    } else {
        return MovieWriterStatusRecording;
    }
}

- (void)startRecording {
    dispatch_assert_queue(self.isolatedQueue);
    assert(self.assetWriter == nil);
    
    NSURL *url = [self _nextURL];
    NSError * _Nullable error = nil;
    
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    assert(error == nil);
    self.assetWriter = assetWriter;
    
    [assetWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nullptr];
    
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
    
    NSDictionary<NSString *, id> *audioOutputSettings = [self.audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
    
    AVAssetWriterInput *audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings sourceFormatHint:_audioSourceFormatHint];
    audioWriterInput.expectsMediaDataInRealTime = YES;
    assert([assetWriter canAddInput:audioWriterInput]);
    [assetWriter addInput:audioWriterInput];
    self.audioWriterInput = audioWriterInput;
    [audioWriterInput release];
    
    //
    
    AVAssetWriterInput *metadataWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeMetadata outputSettings:self.metadataOutputSettings sourceFormatHint:_metadataSourceFormatHint];
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
    
    abort();
}

- (void)stopRecording {
    dispatch_assert_queue(self.isolatedQueue);
    
    abort();
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
    
    CFRelease(_videoSourceFormatHint);
    _videoSourceFormatHint = desc;
    CFRetain(desc);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    if (assetWriter == nil) return;
    
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    BOOL startSessionCalled = [MovieWriter startSessionCalledForAssetWriter:assetWriter];
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

- (void)_appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    dispatch_assert_queue(self.audioQueue);
    
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desc);
    assert(mediaType == kCMMediaType_Audio);
    
    CFRelease(_audioSourceFormatHint);
    _audioSourceFormatHint = desc;
    CFRetain(desc);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    if (assetWriter == nil) return;
    
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    BOOL startSessionCalled = [MovieWriter startSessionCalledForAssetWriter:assetWriter];
    
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

- (void)appendTimedMetadataGroup:(AVTimedMetadataGroup *)timedMetadataGroup {
    dispatch_assert_queue(self.isolatedQueue);
    
    AVAssetWriter *assetWriter = self.assetWriter;
    assert(assetWriter != nil);
    assert(assetWriter.status == AVAssetWriterStatusWriting);
    
    if ([MovieWriter startSessionCalledForAssetWriter:assetWriter]) {
        AVAssetWriterInputMetadataAdaptor *metadataAdaptor = self.metadataAdaptor;
        
        BOOL success = [metadataAdaptor appendTimedMetadataGroup:timedMetadataGroup];
        
        if (!success) {
            NSLog(@"%@", assetWriter.error);
        }
    }
}

- (void)_enableAllConnections {
    for (AVCaptureConnection *connection in self.videoDataOutput.connections) {
        connection.enabled = YES;
    }
    
    for (AVCaptureConnection *connection in self.audioDataOutput.connections) {
        connection.enabled = YES;
    }
}

- (void)_disableAllConnections {
    for (AVCaptureConnection *connection in self.videoDataOutput.connections) {
        connection.enabled = NO;
    }
    
    for (AVCaptureConnection *connection in self.audioDataOutput.connections) {
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

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(desc);
    
    if (mediaType == kCMMediaType_Video) {
        [self _appendAudioSampleBuffer:sampleBuffer];
    } else if (mediaType == kCMMediaType_Audio) {
        [self _appendVideoSampleBuffer:sampleBuffer];
    }
}

@end

#endif
