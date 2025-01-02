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

NSNotificationName const ImageVisionViewModelDidChangeObservationsNotificationName = @"ImageVisionViewModelDidChangeObservationsNotificationName";

@interface ImageVisionViewModel ()
@property (retain, nonatomic, readonly) dispatch_queue_t _queue;
@property (assign, nonatomic) PHImageRequestID _queue_imageRequestID;
@property (retain, nonatomic, readonly) NSMutableArray<__kindof VNRequest *> *_queue_requests;
@property (retain, nonatomic, nullable) UIImage *_queue_image;
@property (assign, atomic, getter=isLoading) BOOL loading;
@end

@implementation ImageVisionViewModel

+ (NSError *)_cancellationError {
    return [NSError errorWithDomain:CamPresentationErrorDomain code:NSUserCancelledError userInfo:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Image Vision Queue", attr);
        
        __queue = queue;
        __queue_imageRequestID = PHInvalidImageRequestID;
        __queue_requests = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    if (dispatch_queue_t queue = __queue) {
        dispatch_release(queue);
    }
    
    if (__queue_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:__queue_imageRequestID];
    }
    
    [__queue_requests release];
    
    [super dealloc];
}

- (NSProgress *)addRequest:(__kindof VNRequest *)request completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    dispatch_async(self._queue, ^{
        NSMutableArray<__kindof VNRequest *> *requests = self._queue_requests;
        assert(![requests containsObject:request]);
        [requests addObject:request];
        
        if (UIImage *image = self._queue_image) {
            NSProgress *subprogress = [self _queue_performRequests:@[request] forImage:image completionHandler:completionHandler];
            [progress addChild:subprogress withPendingUnitCount:1];
            
            if (request.results.count > 0) {
                [self _postDidChangeObservationsNotification];
            }
        } else {
            progress.completedUnitCount = 1;
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    });
   
    return progress;
}

- (void)removeRequest:(__kindof VNRequest *)request completionHandler:(void (^)())completionHandler {
    dispatch_async(self._queue, ^{
        NSMutableArray<__kindof VNRequest *> *requests = self._queue_requests;
        assert([requests containsObject:request]);
        [requests removeObject:request];
        
        if (request.results.count > 0) {
            [self _postDidChangeObservationsNotification];
        }
        
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (NSProgress *)updateRequest:(__kindof VNRequest *)request completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    dispatch_async(self._queue, ^{
        NSArray<__kindof VNRequest *> *requests = self._queue_requests;
        assert([requests containsObject:request]);
        
        if (UIImage *image = self._queue_image) {
            NSProgress *subprogress = [self _queue_performRequests:@[request] forImage:image completionHandler:completionHandler];
            [progress addChild:subprogress withPendingUnitCount:1];
            
            if (request.results.count > 0) {
                [self _postDidChangeObservationsNotification];
            }
        } else {
            progress.completedUnitCount = 1;
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    });
    
    return progress;
}

- (NSProgress *)updateImage:(UIImage *)image completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    assert(image != nil);
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    dispatch_async(self._queue, ^{
        self._queue_image = image;
        NSProgress *subprogress = [self _queue_performRequests:self._queue_requests forImage:image completionHandler:completionHandler];
        [progress addChild:subprogress withPendingUnitCount:1];
    });
    
    return progress;
}

- (NSProgress *)updateImageWithPHAsset:(PHAsset *)asset completionHandler:(void (^)(UIImage * _Nullable image, NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:2 * 1000000UL];
    
    dispatch_async(self._queue, ^{
        if (__queue_imageRequestID != PHInvalidImageRequestID) {
            [PHImageManager.defaultManager cancelImageRequest:__queue_imageRequestID];
        }
        
        assert(asset != nil);
        
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
        
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), self._queue);
        
        PHImageRequestID requestID = [PHImageManager.defaultManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
                BOOL cancelled = cancelledNumber.boolValue;
                
                if (cancelled) {
                    [progress setUserInfoObject:cancelledNumber forKey:PHImageCancelledKey];
                    [progress pause];
                    
                    if (completionHandler) {
                        completionHandler(nil, [ImageVisionViewModel _cancellationError]);
                    }
                    
                    return;
                }
            }
            
            if (NSError *error = info[PHImageErrorKey]) {
                if (completionHandler) {
                    completionHandler(nil, error);
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
            NSProgress *subprogress = [self _queue_performRequests:self._queue_requests forImage:result completionHandler:^(NSError * _Nullable error) {
                if (completionHandler) {
                    if (error) {
                        completionHandler(nil, error);
                    } else {
                        completionHandler(result, nil);
                    }
                }
            }];
            
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
    });
    
    return progress;
}

- (void)getValuesWithCompletionHandler:(void (^)(NSArray<__kindof VNRequest *> * _Nonnull, NSArray<__kindof VNObservation *> * _Nonnull, UIImage * _Nullable))completionHandler {
    dispatch_block_t block = ^{
        NSArray<__kindof VNRequest *> *requests = [self._queue_requests copy];
        
        NSMutableArray<__kindof VNObservation *> *observations = [NSMutableArray new];
        for (__kindof VNRequest *request in requests) {
            [observations addObjectsFromArray:request.results];
        }
        
        UIImage *image = self._queue_image;
        
        completionHandler(requests, observations, image);
        [requests release];
        [observations release];
    };
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == self._queue) {
#pragma clang diagnostic pop
        block();
    } else {
        dispatch_async(self._queue, block);
    }
}

- (NSProgress *)_queue_performRequests:(NSArray<__kindof VNRequest *> *)requests forImage:(UIImage *)image completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    dispatch_assert_queue(self._queue);
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    if (requests.count == 0) {
        completionHandler(nil);
        progress.totalUnitCount = 1;
        return progress;
    }
    
    assert(!self.isLoading);
    self.loading = YES;
    
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
    
    [self _postDidChangeObservationsNotification];
    
    progress.completedUnitCount += 1;
    assert(progress.isFinished);
    
    self.loading = NO;
    
    if (completionHandler) {
        completionHandler(error);
    }
    
    return progress;
}

- (void)_postDidChangeObservationsNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:ImageVisionViewModelDidChangeObservationsNotificationName object:self];
}

@end
