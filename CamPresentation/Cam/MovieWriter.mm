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

@interface MovieWriter () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (retain, nonatomic, readonly) AVAssetWriter *assetWriter;
@property (retain, nonatomic, readonly) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (retain, nonatomic, readonly) __kindof BaseFileOutput *fileOutput;
@property (copy, nonatomic, readonly) CLLocation * _Nullable (^locationHandler)(void);
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation MovieWriter

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoDataOutput:(AVCaptureVideoDataOutput *)videoDataOutput audioOutputSettings:(NSDictionary<NSString *,id> *)audioOutputSettings metadataOutputSettings:(NSDictionary<NSString *,id> *)metadataOutputSettings videoSourceFormatHint:(CMVideoFormatDescriptionRef)videoSourceFormatHint audioSourceFormatHint:(CMAudioFormatDescriptionRef)audioSourceFormatHint metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint locationHandler:(CLLocation * _Nullable (^)())locationHandler {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Movie Writer Queue", attr);
        
        _queue = queue;
        _fileOutput = [fileOutput retain];
        _locationHandler = [locationHandler copy];
        
        NSError * _Nullable error = nil;
        
        //
        
#warning 하나의 Movie Writer를 여러 번 쓸 수 있게 하면 좋을 것 같다. startRecording 때 URL 새로 발급하고 AVAssetWriter 생성하는 방향으로
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
        
        //
        
        assert(videoDataOutput.sampleBufferDelegate == nil);
        assert(reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(videoDataOutput, sel_registerName("delegateOverride")) == nil);
        videoDataOutput.deliversPreviewSizedOutputBuffers = NO;
        videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
        [videoDataOutput setSampleBufferDelegate:self queue:queue];
        
        //
        
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
        assert(error == nil);
        _assetWriter = assetWriter;
        
        [assetWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        NSDictionary<NSString *, id> *videoOutputSettings = [videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
        
        AVAssetWriterInput *videoPixelBufferInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings sourceFormatHint:videoSourceFormatHint];
        videoPixelBufferInput.expectsMediaDataInRealTime = YES;
        assert([assetWriter canAddInput:videoPixelBufferInput]);
        [assetWriter addInput:videoPixelBufferInput];
        
        AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoPixelBufferInput sourcePixelBufferAttributes:nil];
        _videoPixelBufferAdaptor = videoPixelBufferAdaptor;
        [videoPixelBufferInput release];
        
        //
        
        AVAssetWriterInput *audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings sourceFormatHint:audioSourceFormatHint];
        audioWriterInput.expectsMediaDataInRealTime = YES;
        assert([assetWriter canAddInput:audioWriterInput]);
        [assetWriter addInput:audioWriterInput];
        _audioWriterInput = audioWriterInput;
        
        AVAssetWriterInput *metadataWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeMetadata outputSettings:metadataOutputSettings sourceFormatHint:metadataSourceFormatHint];
        metadataWriterInput.expectsMediaDataInRealTime = YES;
        assert([assetWriter canAddInput:metadataWriterInput]);
        [assetWriter addInput:metadataWriterInput];
        
        AVAssetWriterInputMetadataAdaptor *metadataAdaptor = [[AVAssetWriterInputMetadataAdaptor alloc] initWithAssetWriterInput:metadataWriterInput];
        [metadataWriterInput release];
        
        _metadataAdaptor = metadataAdaptor;
        
        //
        
//        AVAssetWriterInputGroup *inputGroup = [[AVAssetWriterInputGroup alloc] initWithInputs:@[videoPixelBufferInput, audioWriterInput, metadataWriterInput] defaultInput:videoPixelBufferInput];
//        [videoPixelBufferInput release];
//        [metadataWriterInput release];
//        
//        assert([assetWriter canAddInputGroup:inputGroup]);
//        [assetWriter addInputGroup:inputGroup];
//        [inputGroup release];
    }
    
    return self;
}

- (void)dealloc {
    [_videoDataOutput release];
    [_fileOutput release];
    [_videoPixelBufferAdaptor release];
    [_audioWriterInput release];
    [_metadataAdaptor release];
    [_assetWriter removeObserver:self forKeyPath:@"status"];
    [_assetWriter release];
    [_locationHandler release];
    dispatch_release(_queue);
    [super dealloc];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    abort();
}

@end

#endif
