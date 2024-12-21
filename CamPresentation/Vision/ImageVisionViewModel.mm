//
//  ImageVisionViewModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <CamPresentation/ImageVisionViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CamPresentation/Constants.h>

@interface ImageVisionViewModel ()
@property (assign, nonatomic) PHImageRequestID _queue_imageRequestID;
@property (retain, nonatomic, readonly) NSMutableArray<__kindof VNRequest *> *_queue_requests;
@property (retain, nonatomic, nullable) UIImage *_queue_image;
@end

@implementation ImageVisionViewModel

+ (NSError *)_cancellationError {
    return [NSError errorWithDomain:CamPresentationErrorDomain code:NSUserCancelledError userInfo:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Image Vision Queue", attr);
        
        _queue = queue;
        __queue_imageRequestID = PHInvalidImageRequestID;
        __queue_requests = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    if (dispatch_queue_t queue = _queue) {
        dispatch_release(queue);
    }
    
    if (__queue_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:__queue_imageRequestID];
    }
    
    [__queue_requests release];
    
    [super dealloc];
}

- (NSArray<__kindof VNRequest *> *)queue_requests {
    dispatch_assert_queue(self.queue);
    return [[self._queue_requests copy] autorelease];
}

- (NSProgress *)queue_addRequest:(__kindof VNRequest *)request completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_assert_queue(self.queue);
    NSMutableArray<__kindof VNRequest *> *requests = self._queue_requests;
    assert(![requests containsObject:request]);
    
    [self willChangeValueForKey:@"queue_requests"];
    [requests addObject:request];
    [self didChangeValueForKey:@"queue_requests"];
    
    UIImage *image = self._queue_image;
    if (image == nil) {
        if (completionHandler) {
            completionHandler(nil);
        }
        
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
        progress.totalUnitCount = 1;
        return progress;
    }
    
    return [self _queue_updateImage:image completionHandler:completionHandler];
}

- (void)queue_removeRequest:(__kindof VNRequest *)request {
    dispatch_assert_queue(self.queue);
    NSMutableArray<__kindof VNRequest *> *requests = self._queue_requests;
    assert([requests containsObject:request]);
    
    [self willChangeValueForKey:@"queue_requests"];
    [requests removeObject:request];
    [self didChangeValueForKey:@"queue_requests"];
}

- (NSProgress *)queue_updateImage:(UIImage *)image completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_assert_queue(self.queue);
    self._queue_image = image;
    return [self _queue_updateImage:image completionHandler:completionHandler];
}

- (NSProgress *)queue_updateImageWithPHAsset:(PHAsset *)asset completionHandler:(void (^)(UIImage * _Nullable image, NSError * _Nullable))completionHandler {
    dispatch_assert_queue(self.queue);
    
    if (__queue_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:__queue_imageRequestID];
    }
    
    assert(asset != nil);
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:2 * 1000000UL];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = NO;
    options.progressHandler = ^(double _progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        progress.completedUnitCount = _progress * 1000000UL;
        
        if (error != nil) {
            [progress setUserInfoObject:error forKey:PHImageErrorKey];
            [progress pause];
        }
    };
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), self.queue);
    
    PHImageRequestID requestID = [PHImageManager.defaultManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
            BOOL cancelled = cancelledNumber.boolValue;
            
            if (cancelled) {
                [progress setUserInfoObject:cancelledNumber forKey:PHImageCancelledKey];
                [progress pause];
                
                if (completionHandler) {
                    completionHandler([ImageVisionViewModel _cancellationError]);
                }
                
                return;
            }
        }
        
        if (NSError *error = info[PHImageErrorKey]) {
            if (completionHandler) {
                completionHandler(error);
            }
            
            return;
        }
        
        if (NSNumber * _Nullable isDegraded = info[PHImageResultIsDegradedKey]) {
            if (isDegraded.boolValue) {
                return;
            }
        }
        
        assert(result != nil);
        progress.completedUnitCount = 1000000UL;
        
        self._queue_image = result;
        NSProgress *subprogress = [self _queue_updateImage:result completionHandler:completionHandler];
        
        [progress addChild:subprogress withPendingUnitCount:1000000UL];
    }];
    
    [options release];
    
    __queue_imageRequestID = requestID;
    
    if (progress.cancellationHandler == nil) {
        // -_queue_updateImage:progress:completionHandler:가 먼저 불릴 수도 있기 때문
        progress.cancellationHandler = ^{
            [PHImageManager.defaultManager cancelImageRequest:requestID];
        };
    }
    
    return progress;
}

- (NSProgress *)_queue_updateImage:(UIImage *)image completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_assert_queue(self.queue);
    
    NSArray<__kindof VNImageBasedRequest *> *requests = self._queue_requests;
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    if (requests.count == 0) {
        completionHandler(nil);
        progress.totalUnitCount = 1;
        return progress;
    }
    
    CGImageRef cgImage = reinterpret_cast<CGImageRef (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImageGeneratingIfNecessary"));
    CGImagePropertyOrientation cgImagePropertyOrientation = reinterpret_cast<CGImagePropertyOrientation (*)(id, SEL)>(objc_msgSend)(image, sel_registerName("vk_cgImagePropertyOrientation"));
    
    VNImageRequestHandler *imageRequestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage
                                                                                    orientation:cgImagePropertyOrientation
                                                                                        options:@{
        MLFeatureValueImageOptionCropAndScale: @(VNImageCropAndScaleOptionScaleFill)
    }];
    
    progress.cancellationHandler = ^{
        for (__kindof VNRequest *request in requests) {
            [request cancel];
        }
    };
    
    // 이 사이에 cancel이 불리면 어쩔 수 없음
    
    NSError * _Nullable error = nil;
    [imageRequestHandler performRequests:requests error:&error];
    [imageRequestHandler release];
    
    progress.totalUnitCount = 1;
    assert(progress.isFinished);
    
    if (completionHandler) {
        completionHandler(error);
    }
    
    return progress;
}

@end
