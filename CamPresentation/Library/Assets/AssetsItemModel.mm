//
//  AssetsItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface _AssetsItemModelRequest : NSObject
@property (copy, nonatomic, nullable) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info);
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) CGSize targetSize;
@property (retain, nonatomic, nullable) UIImage *result;
@property (copy, nonatomic, nullable) NSDictionary *info;
@end

@implementation _AssetsItemModelRequest

- (instancetype)init {
    if (self = [super init]) {
        _requestID = PHInvalidImageRequestID;
    }
    return self;
}

- (void)dealloc {
    [_resultHandler release];
    [_result release];
    [_info release];
    [super dealloc];
}

@end


@interface AssetsItemModel ()
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (retain, nonatomic, readonly) _AssetsItemModelRequest *request;
@end

@implementation AssetsItemModel
@synthesize imageManager = _imageManager;

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super init]) {
        _asset = [asset retain];
        _request = [_AssetsItemModelRequest new];
    }
    
    return self;
}

- (void)dealloc {
    [_asset release];
    
    if (_request.requestID != PHInvalidImageRequestID) {
        [_imageManager cancelImageRequest:_request.requestID];
    }
    
    [_imageManager release];
    [_request release];
    [super dealloc];
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

- (void)cancelRequest {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    PHImageRequestID requestID = self.request.requestID;
    if (requestID != PHInvalidImageRequestID) {
        [self.imageManager cancelImageRequest:requestID];
        self.request.requestID = PHInvalidImageRequestID;
    }
}

- (void)requestImageWithTargetSize:(CGSize)targetSize options:(PHImageRequestOptions * _Nullable)options resultHandler:(void (^ _Nullable)(UIImage * _Nullable result, NSDictionary * _Nullable info))resultHandler {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    _AssetsItemModelRequest *request = self.request;
    
    request.resultHandler = resultHandler;
    
    if (CGSizeEqualToSize(request.targetSize, targetSize)) {
        resultHandler(request.result, request.info);
        return;
    }
    
    [self cancelRequest];
    
    request.targetSize = targetSize;
    
    if (options == nil) {
        options = [PHImageRequestOptions new];
        options.synchronous = NO;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.networkAccessAllowed = YES;
        options.allowSecondaryDegradedImage = YES;
        [options autorelease];
    }
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setCannotReturnSmallerImage:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setAllowPlaceholder:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setPreferHDR:"), YES);
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setUseLowMemoryMode:"), YES);
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    PHImageManager *imageManager = self.imageManager;
    
    request.requestID = [imageManager requestImageForAsset:self.asset
                                             targetSize:targetSize
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([AssetsItemModel didFailForInfo:info]) {
            return;
        }
        
        [result prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([AssetsItemModel didFailForInfo:info]) {
                    return;
                }
                
                if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
                    if (request.requestID != requestIDNumber.integerValue) {
                        NSLog(@"Request ID does not equal.");
                        [imageManager cancelImageRequest:static_cast<PHImageRequestID>(requestIDNumber.integerValue)];
                        return;
                    }
                } else {
                    return;
                }
                
                request.result = result;
                request.info = info;
                
                if (auto resultHandler = request.resultHandler) {
                    resultHandler(result, info);
                }
            });
        }];
    }];
}

- (PHImageManager *)imageManager {
    if (auto imageManager = _imageManager) return imageManager;
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    
    _imageManager = [imageManager retain];
    return imageManager;
}

@end
