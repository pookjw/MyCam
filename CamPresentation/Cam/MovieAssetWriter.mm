//
//  MovieAssetWriter.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <CamPresentation/MovieAssetWriter.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/NSURL+CP.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface MovieAssetWriter ()
@property (retain, nonatomic, readonly) __kindof BaseFileOutput *fileOutput;
@property (copy, nonatomic, readonly) CLLocation * _Nullable (^locationHandler)(void);
@end

@implementation MovieAssetWriter

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoOutputSettings:(NSDictionary<NSString *, id> *)videoOutputSettings audioOutputSettings:(NSDictionary<NSString *, id> *)audioOutputSettings metadataOutputSettings:(NSDictionary<NSString *, id> *)metadataOutputSettings videoSourceFormatHint:(nullable CMVideoFormatDescriptionRef)videoSourceFormatHint audioSourceFormatHint:(nullable CMAudioFormatDescriptionRef)audioSourceFormatHint metadataSourceFormatHint:(CMMetadataFormatDescriptionRef)metadataSourceFormatHint locationHandler:(CLLocation * _Nullable (^)(void))locationHandler {
    if (self = [super init]) {
        _fileOutput = [fileOutput retain];
        _locationHandler = [locationHandler copy];
        
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
        
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
        assert(error == nil);
        _assetWriter = assetWriter;
        
        [assetWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        AVAssetWriterInput *videoPixelBufferInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings sourceFormatHint:videoSourceFormatHint];
        videoPixelBufferInput.expectsMediaDataInRealTime = YES;
        assert([assetWriter canAddInput:videoPixelBufferInput]);
        [assetWriter addInput:videoPixelBufferInput];
        
        AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoPixelBufferInput sourcePixelBufferAttributes:nil];
        _videoPixelBufferAdaptor = videoPixelBufferAdaptor;
        
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
    [_fileOutput release];
    [_videoPixelBufferAdaptor release];
    [_audioWriterInput release];
    [_metadataAdaptor release];
    [_assetWriter removeObserver:self forKeyPath:@"status"];
    [_assetWriter release];
    [_locationHandler release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.assetWriter]) {
        if ([keyPath isEqualToString:@"status"]) {
            auto statusNumber = static_cast<NSNumber *>(change[NSKeyValueChangeNewKey]);
            auto status = static_cast<AVAssetWriterStatus>(statusNumber.integerValue);
            
            if (status == AVAssetWriterStatusCompleted) {
                [self saveVideoFile];
            }
            
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)saveVideoFile {
    NSURL *outputURL = self.assetWriter.outputURL;
    
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

@end

#endif
