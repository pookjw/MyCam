//
//  CinematicAssetData.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicAssetData.h>
#import <CamPresentation/Constants.h>

NSString * CinematicAssetDataErrorKey = @"CinematicAssetDataErrorKey";

@implementation CinematicAssetData

+ (NSProgress *)loadDataFromPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(CinematicAssetData * _Nullable data, NSError * _Nullable error))completionHandler {
    assert(phAsset.mediaType == PHAssetMediaTypeVideo);
    assert((phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoCinematic) != 0);
    
    NSProgress *progress = [NSProgress new];
    progress.totalUnitCount = 1400000UL;
    
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double _progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (!progress.finished) {
            progress.completedUnitCount = _progress * 1000000UL;
        }
    };
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    
    PHImageRequestID requestID = [imageManager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (auto isDegradedNumber = static_cast<NSNumber *>(info[PHImageResultIsDegradedKey])) {
            if (isDegradedNumber.boolValue) return;
        }
        
        if (auto cancelledNumber = static_cast<NSNumber *>(info[PHImageCancelledKey])) {
            if (cancelledNumber.boolValue) {
                NSError *error = [NSError errorWithDomain:CamPresentationErrorDomain code:CPErrorCodeCancelled userInfo:nil];
                completionHandler(nil, error);
                return;
            }
        }
        
        if (NSError *error = info[PHImageErrorKey]) {
            [progress setUserInfoObject:error forKey:CinematicAssetDataErrorKey];
            [progress cancel];
            completionHandler(nil, error);
            return;
        }
        
        assert(asset != nil);
        assert(!progress.finished);
        assert(progress.completedUnitCount == 1000000UL);
        
        if (progress.cancelled) {
            [progress cancel];
            NSError *error = [NSError errorWithDomain:CamPresentationErrorDomain code:CPErrorCodeCancelled userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        [CNAssetInfo loadFromAsset:asset completionHandler:^(CNAssetInfo * _Nullable cinematicAssetInfo, NSError * _Nullable error) {
            if (error != nil) {
                [progress setUserInfoObject:error forKey:CinematicAssetDataErrorKey];
                [progress cancel];
                completionHandler(nil, error);
                return;
            }
            
            assert(cinematicAssetInfo != nil);
            assert(!progress.finished);
            progress.completedUnitCount = 1100000UL;
            
            NSProgress *childProgress = [NSProgress progressWithTotalUnitCount:100000UL parent:progress pendingUnitCount:100000UL];
            [CNScript loadFromAsset:asset changes:nil progress:childProgress completionHandler:^(CNScript * _Nullable script, NSError * _Nullable error) {
                assert(!progress.finished);
                assert(progress.completedUnitCount = 1200000UL);
                
                if (error != nil) {
                    [progress setUserInfoObject:error forKey:CinematicAssetDataErrorKey];
                    [progress cancel];
                    completionHandler(nil, error);
                    return;
                }
                
                [CNRenderingSessionAttributes loadFromAsset:asset completionHandler:^(CNRenderingSessionAttributes * _Nullable sessionAttributes, NSError * _Nullable error) {
                    if (error != nil) {
                        [progress setUserInfoObject:error forKey:CinematicAssetDataErrorKey];
                        [progress cancel];
                        completionHandler(nil, error);
                        return;
                    }
                    
                    assert(!progress.finished);
                    progress.completedUnitCount = 1300000UL;
                    
                    AVAssetTrack *frameTimingTrack = cinematicAssetInfo.frameTimingTrack;
                    [frameTimingTrack loadValuesAsynchronouslyForKeys:@[@"nominalFrameRate", @"naturalTimeScale"] completionHandler:^{
                        float nominalFrameRate = frameTimingTrack.nominalFrameRate;
                        CMTimeScale naturalTimeScale = frameTimingTrack.naturalTimeScale;
                        
                        assert(!progress.finished);
                        progress.completedUnitCount = 1400000UL;
                        assert(progress.finished);
                        
                        CinematicAssetData *data = [[CinematicAssetData alloc] initWithAVAsset:asset cnAssetInfo:cinematicAssetInfo cnScript:script renderingSessionAttributes:sessionAttributes nominalFrameRate:nominalFrameRate naturalTimeScale:naturalTimeScale];
                        completionHandler(data, nil);
                        [data release];
                    }];
                }];
            }];
        }];
    }];
    
    progress.cancellationHandler = ^{
        [imageManager cancelImageRequest:requestID];
    };
    
    [options release];
    
    return [progress autorelease];
}

- (instancetype)initWithAVAsset:(AVAsset *)avAsset cnAssetInfo:(CNAssetInfo *)cnAssetInfo cnScript:(CNScript *)cnScript renderingSessionAttributes:(CNRenderingSessionAttributes *)renderingSessionAttributes nominalFrameRate:(float)nominalFrameRate naturalTimeScale:(CMTimeScale)naturalTimeScale {
    if (self = [super init]) {
        _avAsset = [avAsset retain];
        _cnAssetInfo = [cnAssetInfo retain];
        _cnScript = [cnScript retain];
        _renderingSessionAttributes = [renderingSessionAttributes retain];
        _nominalFrameRate = nominalFrameRate;
        _naturalTimeScale = naturalTimeScale;
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [_cnAssetInfo release];
    [_cnScript release];
    [_renderingSessionAttributes release];
    [super dealloc];
}

@end
