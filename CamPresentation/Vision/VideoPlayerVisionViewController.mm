//
//  VideoPlayerVisionViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CamPresentation/VideoPlayerVisionViewController.h>
#import <CamPresentation/ImageVisionViewController+Private.h>
#import <CamPresentation/PlayerOutputViewController.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <utility>

@interface VideoPlayerVisionViewController () <PlayerOutputViewDelegate>
@property (retain, nonatomic, readonly) PlayerOutputViewController *_playerOutputViewController;
@property (retain, nonatomic, readonly) PlayerOutputView *_playerOutputView;
@end

@implementation VideoPlayerVisionViewController
@synthesize _playerOutputViewController = __playerOutputViewController;

- (void)dealloc {
    [__playerOutputViewController release];
    // TODO: _playerOutputView
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PlayerOutputViewController *playerOutputViewController = self._playerOutputViewController;
//    playerOutputViewController.outputView.hidden = YES;
    [self addChildViewController:playerOutputViewController];
    UIView *playerOutputView = playerOutputViewController.view;
    [self.view addSubview:playerOutputView];
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self.view, sel_registerName("_addBoundsMatchingConstraintsForView:"), playerOutputView);
    [playerOutputViewController didMoveToParentViewController:self];
    
    //
    
    ImageVisionView *imageVisionView = self._imageVisionView;
    imageVisionView.userInteractionEnabled = NO;
    imageVisionView.backgroundColor = UIColor.clearColor;
    [self.view bringSubviewToFront:imageVisionView];
}

- (AVPlayer *)player {
    return self._playerOutputViewController.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self._playerOutputViewController.player = player;
}

- (PlayerOutputViewController *)_playerOutputViewController {
    if (auto playerOutputViewController = __playerOutputViewController) return playerOutputViewController;
    
    PlayerOutputViewController *playerOutputViewController = [[PlayerOutputViewController alloc] initWithLayerType:PlayerOutputLayerTypeSampleBufferDisplayLayer];
    playerOutputViewController.outputView.delegate = self;
    
    __playerOutputViewController = [playerOutputViewController retain];
    return [playerOutputViewController autorelease];
}

- (void)playerOutputView:(PlayerOutputView *)playerOutputView didUpdatePixelBufferVariant:(std::variant<CVPixelBufferRef, CMTaggedBufferGroupRef>)pixelBufferVariant {
    if (auto pixelBufferPtr = std::get_if<CVPixelBufferRef>(&pixelBufferVariant)) {
        [self._viewModel updateWithPixelBuffer:*pixelBufferPtr completionHandler:^(NSError * _Nullable error) {
            assert(error == nil);
        }];
    } else {
        // Stereo Video is not supported yet.
        abort();
    }
}

@end
