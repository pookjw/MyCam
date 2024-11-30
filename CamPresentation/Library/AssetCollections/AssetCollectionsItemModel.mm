//
//  AssetCollectionsItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionsItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include <atomic>

@interface _AssetCollectionsItemModelRequest : NSObject {
@public std::atomic<PHImageRequestID> _requestID;
}
@property (copy, nonatomic, nullable) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount);
@property (assign, nonatomic) CGSize targetSize;
@property (copy, nonatomic, nullable) NSString *localizedTitle;
@property (assign, nonatomic) NSInteger assetsCount;
@property (retain, nonatomic, nullable) UIImage *result;
@property (copy, nonatomic, nullable) NSDictionary *info;
@end

@implementation _AssetCollectionsItemModelRequest

- (instancetype)init {
    if (self = [super init]) {
        _requestID = PHInvalidImageRequestID;
    }
    return self;
}

- (void)dealloc {
    [_resultHandler release];
    [_localizedTitle release];
    [_result release];
    [_info release];
    [super dealloc];
}

@end

@interface AssetCollectionsItemModel () <PHPhotoLibraryChangeObserver>
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
@property (retain, nonatomic, nullable) PHFetchResult<PHAsset *> *queue_assetsFetchResult;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@property (retain, nonatomic, readonly) _AssetCollectionsItemModelRequest *request;
@end

@implementation AssetCollectionsItemModel

- (instancetype)initWithCollection:(PHAssetCollection *)collection {
    if (self = [super init]) {
        _collection = [collection retain];
        _imageManager = [PHImageManager.defaultManager retain];
        _photoLibrary = [PHPhotoLibrary.sharedPhotoLibrary retain];
        [_photoLibrary registerChangeObserver:self];
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Asset Collection Item Model Queue", attr);
        _queue = queue;
        
        _request = [_AssetCollectionsItemModelRequest new];
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    
    [_collection release];
    
    PHImageRequestID requestID = _request->_requestID.load();
    if (requestID != PHLivePhotoRequestIDInvalid) {
        [_imageManager cancelImageRequest:requestID];
    }
    
    [_imageManager release];
    [_photoLibrary release];
    [_queue_assetsFetchResult release];
    [_request release];
    
    [super dealloc];
}

- (void)requestImageWithTargetSize:(CGSize)targetSize resultHandler:(void (^ _Nullable)(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount))resultHandler {
    _AssetCollectionsItemModelRequest *request = self.request;
    request.resultHandler = resultHandler;
    
    if (CGSizeEqualToSize(targetSize, request.targetSize)) {
        resultHandler(request.result, request.info, request.localizedTitle, request.assetsCount);
        return;
    }
    
    [self cancelRequest];
    request.targetSize = targetSize;
    
    PHAssetCollection *collection = self.collection;
    
    dispatch_async(self.queue, ^{
        NSString *localizedTitle = collection.localizedTitle;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            request.localizedTitle = localizedTitle;
            
            if (auto resultHandler = request.resultHandler) {
                resultHandler(nil, nil, localizedTitle, 0);
            }
        });
        
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
    //        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(fetchOptions, sel_registerName("setReverseSortOrder:"), YES);
    //        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(fetchOptions, sel_registerName("setShouldPrefetchCount:"), YES);
        fetchOptions.wantsIncrementalChangeDetails = YES;
        fetchOptions.includeHiddenAssets = NO;
    //        fetchOptions.fetchLimit = 1;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(fetchOptions, sel_registerName("setPhotoLibrary:"), self.photoLibrary);
        
        PHFetchResult<PHAsset *> *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
        [fetchOptions release];
        self.queue_assetsFetchResult = assetsFetchResult;
        
        [self queue_updateWithAssetsFetchResult:assetsFetchResult targetSize:targetSize];
    });
}

- (void)cancelRequest {
    _AssetCollectionsItemModelRequest *request = self.request;
    PHImageRequestID requestID = request->_requestID.load();
    
    if (requestID != PHLivePhotoRequestIDInvalid) {
        [self.imageManager cancelImageRequest:requestID];
        _requestID = PHLivePhotoRequestIDInvalid;
    }
}

+ (BOOL)didFailForInfo:(NSDictionary *)info {
    if (info == nil) {
        return NO;
    }
    
    if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
        if (cancelledNumber.boolValue) {
            return YES;
        }
    }
    
    if (NSError *error = info[PHImageErrorKey]) {
        if (error != nil) {
            return YES;
        }
    }
    
    return NO;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(self.queue, ^{
        PHFetchResult<PHAsset *> * _Nullable assetsFetchResult = self.queue_assetsFetchResult;
        if (assetsFetchResult == nil) return;
        
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:assetsFetchResult];
        if (!changeDetails.hasIncrementalChanges) return;
        
        PHFetchResult<PHAsset *> *fetchResultAfterChanges = changeDetails.fetchResultAfterChanges;
        self.queue_assetsFetchResult = fetchResultAfterChanges;
        
        __block CGSize targetSize;
        __block void (^ _Nullable resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount) = nil;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            targetSize = self.request.targetSize;
            resultHandler = [self.request.resultHandler copy];
        });
        
        [self queue_updateWithAssetsFetchResult:fetchResultAfterChanges targetSize:targetSize];
        [resultHandler release];
    });
}

- (void)queue_updateWithAssetsFetchResult:(PHFetchResult<PHAsset *> *)assetsFetchResult targetSize:(CGSize)targetSize {
    NSUInteger assetsCount = assetsFetchResult.count;
    _AssetCollectionsItemModelRequest *request = self.request;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.request.assetsCount = assetsCount;
        
        if (auto resultHandler = request.resultHandler) {
            resultHandler(nil, nil, request.localizedTitle, assetsCount);
        }
    });
    
    PHAsset * _Nullable asset = assetsFetchResult.lastObject;
    if (asset == nil) return;
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setCannotReturnSmallerImage:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setAllowPlaceholder:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setPreferHDR:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setUseLowMemoryMode:"), YES);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), self.queue);
    
    
    PHImageManager *imageManager = self.imageManager;
    
    request->_requestID = [imageManager requestImageForAsset:asset
                                                  targetSize:targetSize
                                                 contentMode:PHImageContentModeAspectFill
                                                     options:options
                                               resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([AssetCollectionsItemModel didFailForInfo:info]) {
            return;
        }
        
        [result prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable result) {
            if ([AssetCollectionsItemModel didFailForInfo:info]) {
                return;
            }
            
            if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
                if (request->_requestID.load() != requestIDNumber.integerValue) {
                    NSLog(@"Request ID does not equal.");
                    [imageManager cancelImageRequest:static_cast<PHImageRequestID>(requestIDNumber.integerValue)];
                    return;
                }
            } else {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                request.result = result;
                request.info = info;
                
                if (auto resultHandler = request.resultHandler) {
                    resultHandler(result, info, request.localizedTitle, assetsCount);
                }
            });
        }];
    }];
    
    [options release];
}

@end
