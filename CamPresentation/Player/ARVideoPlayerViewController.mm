//
//  ARVideoPlayerViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#import <CamPresentation/ARVideoPlayerViewController.h>
#import <CamPresentation/CamPresentation-Swift.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

@interface ARVideoPlayerViewController ()
@property (retain, nonatomic, nullable, readonly) PHAsset *asset;
@property (retain, nonatomic, nullable) AVPlayer *player;
@property (retain, nonatomic, nullable, readonly) AVSampleBufferVideoRenderer *videoRenderer;
@property (retain, nonatomic, readonly) UIBarButtonItem *doneBarButtonItem;
@property (assign, nonatomic) PHImageRequestID imageRequestID;
#if TARGET_OS_VISION
#endif
@end

@implementation ARVideoPlayerViewController
@synthesize doneBarButtonItem = _doneBarButtonItem;

- (instancetype)initWithAsset:(PHAsset *)asset {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _asset = [asset retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _player = [player retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (instancetype)initWithVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _videoRenderer = [videoRenderer retain];
        _imageRequestID = PHInvalidImageRequestID;
    }
    
    return self;
}

- (void)dealloc {
    if (_imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:_imageRequestID];
    }
    
    [_asset release];
    [_player release];
    [_videoRenderer release];
    [_doneBarButtonItem release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem = self.doneBarButtonItem;
    
    if (PHAsset *asset = self.asset) {
        UIProgressView *progressView = [UIProgressView new];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:progressView];
        [NSLayoutConstraint activateConstraints:@[
            [progressView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
            [progressView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
            [progressView.centerYAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.centerYAnchor]
        ]];
        
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(options, sel_registerName("setResultHandlerQueue:"), dispatch_get_main_queue());
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressView setProgress:progress animated:YES];
            });
        };
        [progressView release];
        
        __weak auto weakSelf = self;
        
        self.imageRequestID = [PHImageManager.defaultManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
                if (cancelledNumber.boolValue) return;
            }
            
            auto retained = weakSelf;
            if (retained == nil) return;
            
            assert(playerItem != nil);
            
            AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            retained.player = player;
            [player release];
            
            [progressView removeFromSuperview];
            [retained attachPlayerView];
        }];
        
        [options release];
    } else {
        [self attachPlayerView];
    }
}

- (UIBarButtonItem *)doneBarButtonItem {
    if (auto doneBarButtonItem = _doneBarButtonItem) return [[doneBarButtonItem retain] autorelease];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTriggerDoneBarButtonItem:)];
    
    _doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (void)didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    if (self.imageRequestID != PHInvalidImageRequestID) {
        [PHImageManager.defaultManager cancelImageRequest:self.imageRequestID];
        self.imageRequestID = PHInvalidImageRequestID;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)attachPlayerView {
#if TARGET_OS_IOS
    __kindof UIViewController *arVideoPlayerViewController = CamPresentation::newARVideoPlayerHostingController(self.player);
    
    [self addChildViewController:arVideoPlayerViewController];
    arVideoPlayerViewController.view.frame = self.view.bounds;
    arVideoPlayerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:arVideoPlayerViewController.view];
    [arVideoPlayerViewController didMoveToParentViewController:self];
    
    [arVideoPlayerViewController release];
#elif TARGET_OS_VISION
    abort();
#endif
}

@end
