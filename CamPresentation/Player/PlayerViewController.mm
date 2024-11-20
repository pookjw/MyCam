//
//  PlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/10/24.
//

#import <CamPresentation/PlayerViewController.h>
#import <CamPresentation/PlayerView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#include <variant>

@interface PlayerViewController () {
    std::variant<PHAsset *, AVPlayerItem *> _input;
}
@property (retain, nonatomic, readonly, nullable) PHAsset *asset;
@property (retain, nonatomic, readonly, nullable) AVPlayerItem *playerItem;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (nonatomic, readonly) PlayerView *playerView;
@property (retain, nonatomic, readonly) UIBarButtonItem *doneBarButtonItem;
@property (retain, nonatomic, readonly) __kindof UIView *progressView;
@property (retain, nonatomic, readonly) UIBarButtonItem *progressBarButtonItem;
@end

@implementation PlayerViewController
@synthesize doneBarButtonItem = _doneBarButtonItem;
@synthesize progressView = _progressView;
@synthesize progressBarButtonItem = _progressBarButtonItem;

- (instancetype)initWithAsset:(PHAsset *)asset {
    assert(asset.mediaType == PHAssetMediaTypeVideo);
    
    if (self = [super init]) {
        _requestID = PHLivePhotoRequestIDInvalid;
        _input = [asset retain];
    }
    
    return self;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem {
    if (self = [super init]) {
        _requestID = PHLivePhotoRequestIDInvalid;
        _input = [playerItem retain];
    }
    
    return self;
}

- (void)dealloc {
    if (PHAsset **ptr = std::get_if<PHAsset *>(&_input)) {
        [*ptr release];
    } else if (AVPlayerItem **ptr = std::get_if<AVPlayerItem *>(&_input)) {
        return [*ptr release];
    }
    
    if (_requestID != PHLivePhotoRequestIDInvalid) {
        [PHImageManager.defaultManager cancelImageRequest:_requestID];
    }
    
    [_doneBarButtonItem release];
    [_progressView release];
    [_progressBarButtonItem release];
    
    [super dealloc];
}

- (void)loadView {
    PlayerView *playerView = [PlayerView new];
    self.view = playerView;
    [playerView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
#if !TARGET_OS_TV
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
#endif
    navigationItem.rightBarButtonItems = @[self.doneBarButtonItem, self.progressBarButtonItem];
    
    if (PHAsset *asset = self.asset) {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(options, sel_registerName("setStreamingAllowed:"), YES);
        
        __kindof UIView *progressView = self.progressView;
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            assert(error == nil);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                reinterpret_cast<void (*)(id, SEL, double, BOOL, id)>(objc_msgSend)(progressView, sel_registerName("setProgress:animated:completion:"), progress, YES, nil);
            });
        };
        
        AVPlayer *player = [AVPlayer new];
        
        PHImageRequestID requestID = [PHImageManager.defaultManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            [player replaceCurrentItemWithPlayerItem:playerItem];
        }];
        
        self.requestID = requestID;
        self.playerView.playerLayer.player = player;
        [player release];
        
        [options release];
    }
}

- (PHAsset *)asset {
    if (PHAsset **ptr = std::get_if<PHAsset *>(&_input)) {
        return *ptr;
    }
    
    return nil;
}

- (AVPlayerItem *)playerItem {
    if (AVPlayerItem **ptr = std::get_if<AVPlayerItem *>(&_input)) {
        return *ptr;
    }
    
    return nil;
}

- (PlayerView *)playerView {
    return static_cast<PlayerView *>(self.view);
}

- (UIBarButtonItem *)doneBarButtonItem {
    if (auto doneBarButtonItem = _doneBarButtonItem) return doneBarButtonItem;
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(didTriggerDoneBarButtonItem:)];
    
    _doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (__kindof UIView *)progressView {
    if (auto progressView = _progressView) return progressView;
    
    __kindof UIView *progressView = [objc_lookUpClass("_UICircleProgressView") new];
    
    [NSLayoutConstraint activateConstraints:@[
        [progressView.widthAnchor constraintEqualToConstant:44.],
        [progressView.heightAnchor constraintEqualToConstant:44.]
    ]];
    
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(progressView, sel_registerName("setShowProgressTray:"), YES);
    
    _progressView = [progressView retain];
    return [progressView autorelease];
}

- (UIBarButtonItem *)progressBarButtonItem {
    if (auto progressBarButtonItem = _progressBarButtonItem) return progressBarButtonItem;
    
    UIBarButtonItem *progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.progressView];
    
    _progressBarButtonItem = [progressBarButtonItem retain];
    return [progressBarButtonItem autorelease];
}

- (void)didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
