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
@property (retain, nonatomic, nullable) AVPlayer *player;
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
        _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        _requestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        _player = [player retain];
        _requestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (void)dealloc {
    [_asset release];
    [_player release];
    
    PHImageRequestID requestID = self.requestID;
    if (requestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:requestID];
    }
    
    [super dealloc];
}

- (void)cancelLoading {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    PHImageRequestID requestID = self.requestID;
    if (requestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:requestID];
    }
}

- (void)loadPlayerWithProgressHandler:(PHAssetVideoProgressHandler)progressHandler comletionHandler:(void (^)())completionHandler {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    if (self.player != nil) {
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
        assert(playerItem != nil);
        
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        self.player = player;
        [player release];
    }];
    
    [options release];
    self.requestID = requestID;
}

@end
