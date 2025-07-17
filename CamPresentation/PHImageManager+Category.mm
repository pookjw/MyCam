//
//  PHImageManager+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <CamPresentation/PHImageManager+Category.h>
#include <vector>
#include <algorithm>

@implementation PHImageManager (Category)

- (NSProgress *)cp_requestAVAssetForAssets:(NSArray<PHAsset *> *)assets options:(PHVideoRequestOptions *)options resultHandler:(BOOL (^)(AVAsset * _Nonnull, AVAudioMix * _Nonnull, NSDictionary * _Nonnull, BOOL))resultHandler {
    NSDictionary<PHAsset *, PHVideoRequestOptions *> * _Nullable optionsByAsset;
    if (options == nil) {
        optionsByAsset = nil;
    } else {
        PHAsset **assetsPtr = new PHAsset *[assets.count];
        [assets getObjects:assetsPtr range:NSMakeRange(0, assets.count)];
        
        std::vector<PHVideoRequestOptions *> optionsVec(assets.count);
        std::fill(optionsVec.begin(), optionsVec.end(), options);
        
        optionsByAsset = [[NSDictionary alloc] initWithObjects:optionsVec.data() forKeys:assetsPtr count:assets.count];
        delete[] assetsPtr;
    }
    
    NSProgress *progress = [self cp_requestAVAssetForAssets:assets optionsByAsset:optionsByAsset resultHandler:resultHandler];
    [optionsByAsset release];
    return progress;
}

- (NSProgress *)cp_requestAVAssetForAssets:(NSArray<PHAsset *> *)assets optionsByAsset:(NSDictionary<PHAsset *,PHVideoRequestOptions *> *)optionsByAsset resultHandler:(BOOL (^)(AVAsset * _Nonnull, AVAudioMix * _Nonnull, NSDictionary * _Nonnull, BOOL))resultHandler {
    NSMutableArray<PHAsset *> *remainingAssets = [assets mutableCopy];
    NSMutableDictionary<PHAsset *, PHVideoRequestOptions *> *remainingOptionsByAsset = [optionsByAsset mutableCopy];
    
    NSProgress *parentProgress = [[NSProgress alloc] init];
    parentProgress.totalUnitCount = remainingAssets.count * 1000000UL;
    
    NSProgress *childProgress = [[NSProgress alloc] init];
    childProgress.pausingHandler = ^{
        abort();
    };
    childProgress.totalUnitCount = parentProgress.totalUnitCount;
    [parentProgress addChild:childProgress withPendingUnitCount:parentProgress.totalUnitCount];
    
    [self _cp_requestAVAssetForRemainingAssets:remainingAssets optionsByAsset:remainingOptionsByAsset progress:childProgress resultHandler:resultHandler];
    
    [remainingAssets release];
    [remainingOptionsByAsset release];
    [childProgress release];
    
    return [parentProgress autorelease];
}

- (void)_cp_requestAVAssetForRemainingAssets:(NSMutableArray<PHAsset *> *)remainingAssets optionsByAsset:(NSMutableDictionary<PHAsset *,PHVideoRequestOptions *> *)optionsByAsset progress:(NSProgress *)progress resultHandler:(BOOL (^)(AVAsset * _Nonnull, AVAudioMix * _Nonnull, NSDictionary * _Nonnull, BOOL))resultHandler {
    PHAsset * _Nullable phAsset = [[remainingAssets.firstObject retain] autorelease];
    if (phAsset == nil) {
        return;
    }
    
    if (progress.cancelled) return;
    
    [remainingAssets removeObjectAtIndex:0];
    
    NSProgress *childProgress = [[NSProgress alloc] init];
    childProgress.totalUnitCount = 1000000UL;
    [progress addChild:childProgress withPendingUnitCount:1000000UL];
    
    PHVideoRequestOptions * _Nullable options = [optionsByAsset[phAsset] copy];
    if (options == nil) {
        options = [[PHVideoRequestOptions alloc] init];
    } else {
        [optionsByAsset removeObjectForKey:phAsset];
    }
    
    PHAssetVideoProgressHandler _Nullable progressHandler = [options.progressHandler copy];
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        childProgress.completedUnitCount = static_cast<uint64_t>(progress * static_cast<double>(1000000UL));
        if (progressHandler != nil) {
            progressHandler(progress, error, stop, info);
        }
    };
    [progressHandler release];
    
    PHImageRequestID requestID = [self requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        BOOL isLast = (remainingAssets.count == 0); 
        BOOL resume = resultHandler(asset, audioMix, info, isLast);
        
        if (!isLast and resume and !progress.cancelled) {
            [self _cp_requestAVAssetForRemainingAssets:remainingAssets optionsByAsset:optionsByAsset progress:progress resultHandler:resultHandler];
        }
    }];
    
    childProgress.cancellationHandler = ^{
        [self cancelImageRequest:requestID];
    };
    
    [childProgress release];
}

@end
