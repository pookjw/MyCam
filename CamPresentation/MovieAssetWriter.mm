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

- (instancetype)initWithFileOutput:(__kindof BaseFileOutput *)fileOutput {
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
    }
    
    return self;
}

- (void)dealloc {
    [_fileOutput release];
    [_assetWriter release];
    [super dealloc];
}

@end
