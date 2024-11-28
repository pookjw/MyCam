//
//  VideoPlayerListViewModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/28/24.
//

#import <CamPresentation/VideoPlayerListViewModel.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <atomic>

@interface VideoPlayerListViewModel ()
@property (retain, nonatomic, nullable) AVPlayerItem *playerItem;
@property (retain, nonatomic, readonly) PHAsset *asset;
@property (assign, nonatomic) PHImageRequestID requestID;
@end

@implementation VideoPlayerListViewModel

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super init]) {
        _asset = [asset retain];
        _requestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem {
    if (self = [super init]) {
        _playerItem = [playerItem retain];
        _requestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (void)dealloc {
    [_asset release];
    [_playerItem release];
    
    PHImageRequestID requestID = self.requestID;
    if (requestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:requestID];
    }
    
    [super dealloc];
}

- (AVPlayerItem *)playerItem {
    return [[_playerItem copy] autorelease];
}

- (void)cancelLoading {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    PHImageRequestID requestID = self.requestID;
    if (requestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:requestID];
    }
}

- (void)loadPlayerItemWithProgressHandler:(PHAssetVideoProgressHandler)progressHandler comletionHandler:(void (^)())completionHandler {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (_playerItem != nil) {
        if (completionHandler) completionHandler();
        return;
    }
    
    PHAsset *asset = self.asset;
    assert(asset != nil);
    
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setStreamingAllowed:"), YES);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
    
    options.progressHandler = progressHandler;
    
    PHImageRequestID requestID = [PHImageManager.defaultManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        dispatch_assert_queue(dispatch_get_main_queue());
        self.playerItem = playerItem;
    }];
    
    [options release];
    self.requestID = requestID;
}

@end
