//
//  AssetItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetItemModel ()
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, nullable) UIImage *prefetchedResult;
@property (copy, nonatomic, nullable) NSDictionary *prefetchedInfo;
@property (assign, nonatomic, getter=isCancelled) BOOL cancelled;
@end

@implementation AssetItemModel
@synthesize imageManager = _imageManager;

+ (instancetype)modelWithAsset:(PHAsset *)asset {
    AssetItemModel *model = [AssetItemModel new];
    model->_asset = [asset retain];
    model->_requestID = static_cast<PHImageRequestID>(NSNotFound);
    return [model autorelease];
}

+ (instancetype)prefetchingModelWithWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    AssetItemModel *model = [AssetItemModel new];
    model->_asset = [asset retain];
    model->_prefetchingModel = YES;
    model->_targetSize = targetSize;
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    __weak auto weakModel = model;
    
    model->_requestID = [model.imageManager requestImageForAsset:asset
                                                      targetSize:targetSize
                                                     contentMode:PHImageContentModeAspectFill
                                                         options:options
                                                   resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        weakModel.prefetchedResult = result;
        weakModel.prefetchedInfo = info;
        
        if (auto unretained = weakModel) {
            if (auto resultHandler = unretained.resultHandler) {
                resultHandler(result, info);
                
                if ([AssetItemModel didCompleteForInfo:info]) {
                    [unretained->_resultHandler release];
                    unretained->_resultHandler = nil;
                }
            }
        }
    }];
    
    [options release];
    
    return [model autorelease];
}

- (void)dealloc {
    [_asset release];
    [_resultHandler release];
    [_imageManager release];
    [_prefetchedResult release];
    [_prefetchedInfo release];
    [super dealloc];
}

+ (BOOL)didCompleteForInfo:(NSDictionary *)info {
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
    
    if (NSNumber *isDegraded = info[PHImageResultIsDegradedKey]) {
        return !isDegraded.boolValue;
    }
    
    return NO;
}

- (void)cancelPrefetchingRequest {
    assert(self.isPrefetchingModel);
    assert(!self.isCancelled);
    [self.imageManager cancelImageRequest:self.requestID];
    self.cancelled = YES;
}

- (void)setResultHandler:(void (^)(UIImage * _Nonnull, NSDictionary * _Nonnull))resultHandler {
    assert(self.isPrefetchingModel);
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_resultHandler release];
    
    UIImage * _Nullable prefetchedResult = self.prefetchedResult;
    NSDictionary * _Nullable prefetchedInfo = self.prefetchedInfo;
    
    if ([AssetItemModel didCompleteForInfo:prefetchedInfo]) {
        _resultHandler = nil;
    } else {
        _resultHandler = [resultHandler copy];
    }
    
    if (prefetchedResult != nil || prefetchedInfo != nil) {
        resultHandler(prefetchedResult, prefetchedInfo);
    }
}

- (PHImageManager *)imageManager {
    if (auto imageManager = _imageManager) return imageManager;
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    
    _imageManager = [imageManager retain];
    return imageManager;
}

@end
