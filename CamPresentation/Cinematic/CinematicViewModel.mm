//
//  CinematicViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/Constants.h>

NSString * CinematicViewModelErrorKey = @"CinematicViewModelErrorKey";

@interface CinematicViewModel ()
@end

@implementation CinematicViewModel

+ (NSProgress *)loadCNAssetInfoFromPHAsset:(PHAsset *)phAsset completionHandler:(void (^)(CNAssetInfo * _Nullable, NSError * _Nullable))completionHandler {
    assert(phAsset.mediaType == PHAssetMediaTypeVideo);
    assert((phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoCinematic) != 0);
    
    NSProgress *progress = [NSProgress new];
    progress.totalUnitCount = 1000001UL;
    
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
            [progress setUserInfoObject:error forKey:CinematicViewModelErrorKey];
            [progress cancel];
            completionHandler(nil, error);
            return;
        }
        
        assert(asset != nil);
        
        if (progress.cancelled) {
            NSError *error = [NSError errorWithDomain:CamPresentationErrorDomain code:CPErrorCodeCancelled userInfo:nil];
            completionHandler(nil, error);
            return;
        }
        
        [CNAssetInfo loadFromAsset:asset completionHandler:^(CNAssetInfo * _Nullable cinematicAssetInfo, NSError * _Nullable error) {
            if (error != nil) {
                [progress setUserInfoObject:error forKey:CinematicViewModelErrorKey];
                [progress cancel];
                completionHandler(nil, error);
                return;
            }
            
            assert(cinematicAssetInfo != nil);
            progress.completedUnitCount = progress.totalUnitCount;
            completionHandler(cinematicAssetInfo, nil);
        }];
    }];
    
    progress.cancellationHandler = ^{
        [imageManager cancelImageRequest:requestID];
    };
    
    [options release];
    
    return [progress autorelease];
}

@end
