//
//  MovieAssetWriter.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/29/24.
//

#import <CamPresentation/MovieAssetWriter.h>
#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/NSURL+CP.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface MovieAssetWriter ()
@property (retain, nonatomic, readonly) __kindof BaseFileOutput *fileOutput;
@end

@implementation MovieAssetWriter

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput videoOutputSettings:(NSDictionary<NSString *, id> *)videoOutputSettings audioOutputSettings:(NSDictionary<NSString *, id> * _Nullable)audioOutputSettings metadataOutputSettings:(NSDictionary<NSString *, id> * _Nullable)metadataOutputSettings {
    if (self = [super init]) {
        _fileOutput = [fileOutput retain];
        
        NSError * _Nullable error = nil;
        
        NSURL *url;
        if (fileOutput.class == PhotoLibraryFileOutput.class) {
            NSURL *tmpURL = [NSURL cp_processTemporaryURLByCreatingDirectoryIfNeeded:YES];
            url = [tmpURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
        } else if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
            auto externalFileOutput = static_cast<ExternalStorageDeviceFileOutput *>(fileOutput);
            url = [externalFileOutput.externalStorageDevice nextAvailableURLsWithPathExtensions:@[UTTypeQuickTimeMovie.preferredFilenameExtension] error:&error].firstObject;
            assert(error == nil);
        } else {
            abort();
        }
        
        assert(url != nil);
        
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
        assert(error == nil);
        _assetWriter = assetWriter;
        
        //
        
        NSMutableArray<AVAssetWriterInput *> *inputs = [NSMutableArray new];
        
        AVAssetWriterInput *videoPixelBufferInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings sourceFormatHint:nil];
        [inputs addObject:videoPixelBufferInput];
        
        AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoPixelBufferInput sourcePixelBufferAttributes:nil];
        _videoPixelBufferAdaptor = videoPixelBufferAdaptor;
        
        //
        
        if (audioOutputSettings != nil) {
            AVAssetWriterInput *audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings sourceFormatHint:nil];
            [inputs addObject:audioWriterInput];
            _audioWriterInput = audioWriterInput;
        }
        
        if (metadataOutputSettings != nil) {
            AVAssetWriterInput *metadataWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeMetadata outputSettings:metadataOutputSettings sourceFormatHint:nil];
            [inputs addObject:metadataWriterInput];
            
            AVAssetWriterInputMetadataAdaptor *metadataAdaptor = [[AVAssetWriterInputMetadataAdaptor alloc] initWithAssetWriterInput:metadataWriterInput];
            [metadataWriterInput release];
            
            _metadataAdaptor = metadataAdaptor;
        }
        
        //
        
        AVAssetWriterInputGroup *inputGroup = [[AVAssetWriterInputGroup alloc] initWithInputs:inputs defaultInput:videoPixelBufferInput];
        [inputs release];
        [videoPixelBufferInput release];
        
        assert([assetWriter canAddInputGroup:inputGroup]);
        [assetWriter addInputGroup:inputGroup];
        [inputGroup release];
    }
    
    return self;
}

- (void)dealloc {
    [_fileOutput release];
    [_videoPixelBufferAdaptor release];
    [_audioWriterInput release];
    [_metadataAdaptor release];
    [_assetWriter release];
    [super dealloc];
}

@end
