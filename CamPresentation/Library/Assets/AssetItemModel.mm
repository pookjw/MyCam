//
//  AssetItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface AssetItemModel ()
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) CGSize targetSize;
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, nullable) UIImage *result;
@property (copy, nonatomic, nullable) NSDictionary *info;
@end

@implementation AssetItemModel
@synthesize imageManager = _imageManager;

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super init]) {
        _asset = [asset retain];
        _requestID = static_cast<PHImageRequestID>(NSNotFound);
    }
    
    return self;
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
    dispatch_assert_queue(dispatch_get_main_queue());
    
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
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [self cancelRequest];
    
    self.targetSize = targetSize;
    
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
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    
    PHImageManager *imageManager = self.imageManager;
    
    __weak auto weakModel = self;
    
    self.requestID = [imageManager requestImageForAsset:self.asset
                                             targetSize:targetSize
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (auto unretained = weakModel) {
            if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
                if (unretained.requestID != requestIDNumber.integerValue && unretained.requestID != static_cast<PHImageRequestID>(NSNotFound)) {
                    NSLog(@"Request ID does not equal.");
                    [imageManager cancelImageRequest:static_cast<PHImageRequestID>(requestIDNumber.integerValue)];
                    return;
                }
            } else {
                return;
            }
            
            [result prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (auto unretained = weakModel) {
                        if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
                            if (unretained.requestID != requestIDNumber.integerValue) {
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
                            resultHandler(result, info);
                        }
                    }
                });
            }];
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
