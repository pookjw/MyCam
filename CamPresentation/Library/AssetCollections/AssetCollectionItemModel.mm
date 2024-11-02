//
//  AssetCollectionItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#warning TODO: Observer

@interface AssetCollectionItemModel () <PHPhotoLibraryChangeObserver>
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) CGSize targetSize;
@property (copy, nonatomic, nullable) NSString *localizedTitle;
@property (assign, nonatomic) NSInteger assetsCount;
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, readonly) PHPhotoLibrary *photoLibrary;
@property (retain, nonatomic, nullable) UIImage *result;
@property (copy, nonatomic, nullable) NSDictionary *info;
@property (retain, nonatomic, nullable) PHFetchResult<PHAsset *> *queue_assetsFetchResult;
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation AssetCollectionItemModel
@synthesize targetSize = _targetSize;
@synthesize requestID = _requestID;

- (instancetype)initWithCollection:(PHAssetCollection *)collection {
    if (self = [super init]) {
        _collection = [collection retain];
        _imageManager = [PHImageManager.defaultManager retain];
        _photoLibrary = [PHPhotoLibrary.sharedPhotoLibrary retain];
        [_photoLibrary registerChangeObserver:self];
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Asset Collection Item Model Queue", attr);
        _queue = queue;
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    
    [_collection release];
    [_resultHandler release];
    [_localizedTitle release];
    
    if (_requestID != static_cast<PHImageRequestID>(NSNotFound)) {
        [_imageManager cancelImageRequest:_requestID];
    }
    [_imageManager release];
    [_photoLibrary release];
    [_queue_assetsFetchResult release];
    
    [_result release];
    [_info release];
    
    [super dealloc];
}

- (void)requestImageWithTargetSize:(CGSize)targetSize {
    self.targetSize = targetSize;
    [self cancelRequest];
    
    dispatch_async(self.queue, ^{
        PHAssetCollection *collection = self.collection;
        NSString *localizedTitle = collection.localizedTitle;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.localizedTitle = localizedTitle;
            
            if (auto resultHandler = self.resultHandler) {
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
    PHImageRequestID requestID = self.requestID;
    if (requestID != static_cast<PHImageRequestID>(NSNotFound)) {
        [self.imageManager cancelImageRequest:requestID];
        self.requestID = static_cast<PHImageRequestID>(NSNotFound);
    }
}

- (CGSize)targetSize {
    dispatch_assert_queue(dispatch_get_main_queue());
    return _targetSize;
}

- (void)setTargetSize:(CGSize)targetSize {
    dispatch_assert_queue(dispatch_get_main_queue());
    _targetSize = targetSize;
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            targetSize = self.targetSize;
        });
        
        [self queue_updateWithAssetsFetchResult:fetchResultAfterChanges targetSize:targetSize];
    });
}

- (void)queue_updateWithAssetsFetchResult:(PHFetchResult<PHAsset *> *)assetsFetchResult targetSize:(CGSize)targetSize {
    NSUInteger assetsCount = assetsFetchResult.count;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.assetsCount = assetsCount;
        
        if (auto resultHandler = self.resultHandler) {
            resultHandler(nil, nil, self.localizedTitle, assetsCount);
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
    
    __weak auto weakSelf = self;
    
    PHImageManager *imageManager = self.imageManager;
    
    self.requestID = [imageManager requestImageForAsset:asset
                                             targetSize:targetSize
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (auto unretained = weakSelf) {
            if ([AssetCollectionItemModel didFailForInfo:info]) {
                return;
            }
            
            [result prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (auto unretained = weakSelf) {
                        if ([AssetCollectionItemModel didFailForInfo:info]) {
                            return;
                        }
                        
                        if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
                            if (unretained.requestID != requestIDNumber.integerValue && unretained.requestID) {
                                NSLog(@"Request ID does not equal.");
                                [imageManager cancelImageRequest:static_cast<PHImageRequestID>(requestIDNumber.integerValue)];
                                return;
                            }
                        } else {
                            return;
                        }
                        
                        unretained.result = result;
                        unretained.info = info;
                        
                        if (auto resultHandler = unretained.resultHandler) {
                            resultHandler(result, info, unretained.localizedTitle, unretained.assetsCount);
                        }
                    }
                });
            }];
        }
    }];
}

@end
