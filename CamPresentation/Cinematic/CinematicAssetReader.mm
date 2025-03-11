//
//  CinematicAssetReader.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/11/25.
//

#import <CamPresentation/CinematicAssetReader.h>

@interface CinematicAssetReader ()
@property (retain, nonatomic, readonly, getter=_avAssetReader) AVAssetReader *avAssetReader;
@property (retain, nonatomic, readonly, getter=_avAssetReaderVideoTrackOutput) AVAssetReaderTrackOutput *avAssetReaderVideoTrackOutput;
@property (retain, nonatomic, readonly, getter=_avAssetReaderDisparityTrackOutput) AVAssetReaderTrackOutput *avAssetReaderDisparityTrackOutput;
@property (retain, nonatomic, readonly, getter=_avAssetReaderMetadataTrackOutput) AVAssetReaderTrackOutput *avAssetReaderMetadataTrackOutput;
@end

@implementation CinematicAssetReader

- (instancetype)initWithAssetData:(CinematicAssetData *)assetData {
    if (self = [super init]) {
        NSError * _Nullable error = nil;
        AVAssetReader *avAssetReader = [[AVAssetReader alloc] initWithAsset:assetData.avAsset error:&error];
        assert(error == nil);
        
        AVAssetReaderTrackOutput *avAssetReaderVideoTrackOutput;
        {
            NSDictionary<NSString *, id> *videoOutputSettings = @{
                (NSString *)kCVPixelBufferPixelFormatTypeKey: CNRenderingSession.sourcePixelFormatTypes
            };
            
            avAssetReaderVideoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:assetData.cnAssetInfo.cinematicVideoTrack outputSettings:videoOutputSettings];
            avAssetReaderVideoTrackOutput.alwaysCopiesSampleData = NO;
            assert([avAssetReader canAddOutput:avAssetReaderVideoTrackOutput]);
            [avAssetReader addOutput:avAssetReaderVideoTrackOutput];
        }
        
        AVAssetReaderTrackOutput *avAssetReaderDisparityTrackOutput;
        {
            NSDictionary<NSString *, id> *disparityOutputSettings = @{
                (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_DisparityFloat16)
            };
            
            avAssetReaderDisparityTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:assetData.cnAssetInfo.cinematicDisparityTrack outputSettings:disparityOutputSettings];
            avAssetReaderDisparityTrackOutput.alwaysCopiesSampleData = NO;
            assert([avAssetReader canAddOutput:avAssetReaderDisparityTrackOutput]);
            [avAssetReader addOutput:avAssetReaderDisparityTrackOutput];
        }
        
        AVAssetReaderTrackOutput *avAssetReaderMetadataTrackOutput;
        {
            avAssetReaderMetadataTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:assetData.cnAssetInfo.cinematicMetadataTrack outputSettings:nil];
            avAssetReaderMetadataTrackOutput.alwaysCopiesSampleData = NO;
            assert([avAssetReader canAddOutput:avAssetReaderMetadataTrackOutput]);
            [avAssetReader addOutput:avAssetReaderMetadataTrackOutput];
        }
        
        _avAssetReader = avAssetReader;
        _avAssetReaderVideoTrackOutput = avAssetReaderVideoTrackOutput;
        _avAssetReaderDisparityTrackOutput = avAssetReaderDisparityTrackOutput;
        _avAssetReaderMetadataTrackOutput = avAssetReaderMetadataTrackOutput;
    }
    
    return self;
}

- (void)dealloc {
    [_avAssetReader release];
    [_avAssetReaderVideoTrackOutput release];
    [_avAssetReaderDisparityTrackOutput release];
    [_avAssetReaderMetadataTrackOutput release];
    [super dealloc];
}

- (void)setupReadingWithTimeRange:(CMTimeRange)timeRange {
    AVAssetReader *avAssetReader = _avAssetReader;
    avAssetReader.timeRange = timeRange;
    assert([avAssetReader startReading]);
}

- (void)cancelReading {
    [_avAssetReader cancelReading];
}

- (CinematicSampleBuffer *)nextSampleBuffer {
    CMSampleBufferRef sourceSampleBuffer = [_avAssetReaderVideoTrackOutput copyNextSampleBuffer];
    CMSampleBufferRef disparitySampleBuffer = [_avAssetReaderDisparityTrackOutput copyNextSampleBuffer];
    CMSampleBufferRef _Nullable metadataSampleBuffer = [_avAssetReaderMetadataTrackOutput copyNextSampleBuffer];
    if (metadataSampleBuffer != NULL) {
        if (CMSampleBufferGetNumSamples(metadataSampleBuffer) == 0) {
            CFRelease(metadataSampleBuffer);
            metadataSampleBuffer = [_avAssetReaderMetadataTrackOutput copyNextSampleBuffer];
        }
    }
    
    CinematicSampleBuffer * _Nullable result;
    if ((sourceSampleBuffer != NULL) and (disparitySampleBuffer != NULL) and (metadataSampleBuffer != NULL)) {
        result = [[CinematicSampleBuffer alloc] initWithImageBuffer:CMSampleBufferGetImageBuffer(sourceSampleBuffer)
                                                    disparityBuffer:CMSampleBufferGetImageBuffer(disparitySampleBuffer)
                                                     metadataBuffer:metadataSampleBuffer
                                              presentationTimestamp:CMSampleBufferGetPresentationTimeStamp(sourceSampleBuffer)];
    } else {
        result = nil;
    }
    
    if (sourceSampleBuffer != NULL) CFRelease(sourceSampleBuffer);
    if (disparitySampleBuffer != NULL) CFRelease(disparitySampleBuffer);
    if (metadataSampleBuffer != NULL) CFRelease(metadataSampleBuffer);
    
    return result;
}

@end
