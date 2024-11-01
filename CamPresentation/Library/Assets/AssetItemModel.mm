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
@property (assign, nonatomic) PHImageRequestID requestID;
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, nullable) UIImage *result;
@property (copy, nonatomic, nullable) NSDictionary *info;
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
    model->_requestID = static_cast<PHImageRequestID>(NSNotFound);
    
    return [model autorelease];
}

- (void)dealloc {
    [_asset release];
    [_resultHandler release];
    
    if (_requestID != static_cast<PHImageRequestID>(NSNotFound)) {
        [_imageManager cancelImageRequest:_requestID];
    }
    
    [_imageManager release];
    [_result release];
    [_info release];
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

- (void)cancelRequest {
    PHImageRequestID requestID = self.requestID;
    if (requestID != static_cast<PHImageRequestID>(NSNotFound)) {
        [self.imageManager cancelImageRequest:requestID];
        self.requestID = static_cast<PHImageRequestID>(NSNotFound);
    }
}

- (void)setResultHandler:(void (^)(UIImage * _Nonnull, NSDictionary * _Nonnull))resultHandler {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [_resultHandler release];
    
    UIImage * _Nullable result = self.result;
    NSDictionary * _Nullable info = self.info;
    
    if ([AssetItemModel didCompleteForInfo:info]) {
        _resultHandler = nil;
    } else {
        _resultHandler = [resultHandler copy];
    }
    
    if (result != nil || info != nil) {
        resultHandler(result, info);
    }
}

- (void)requestImageWithTargetSize:(CGSize)targetSize {
    assert(self.requestID == static_cast<PHImageRequestID>(NSNotFound));
    _targetSize = targetSize;
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setCannotReturnSmallerImage:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setAllowPlaceholder:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setPreferHDR:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setUseLowMemoryMode:"), YES);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    __weak auto weakModel = self;
    
    self.requestID = [self.imageManager requestImageForAsset:self.asset
                                                  targetSize:targetSize
                                                 contentMode:PHImageContentModeAspectFill
                                                     options:options
                                               resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (auto unretained = weakModel) {
            unretained.result = result;
            unretained.info = info;
            
            if (auto resultHandler = unretained.resultHandler) {
                resultHandler(result, info);
            }
            
            if ([AssetItemModel didCompleteForInfo:info]) {
                unretained->_requestID = static_cast<PHImageRequestID>(NSNotFound);
            }
        }
    }];
    
    [options release];
}

- (PHImageManager *)imageManager {
    if (auto imageManager = _imageManager) return imageManager;
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    
    _imageManager = [imageManager retain];
    return imageManager;
}

@end
