//
//  ARPlayerWindowScene.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#import <CamPresentation/ARPlayerWindowScene.h>
#import <CamPresentation/ARPlayerSceneDelegate.h>
#import <CamPresentation/CamPresentation-Swift.h>

@interface ARPlayerWindowScene ()
@property (nonatomic, readonly) __kindof UIViewController *_playerHostingController;
@end

@implementation ARPlayerWindowScene

- (AVPlayer *)player {
    return CamPresentation::avPlayerFromRealityPlayerHostingController_Vision(self._playerHostingController);
}

- (void)setPlayer:(AVPlayer *)player {
    CamPresentation::setAVPlayer_Vision(player, self._playerHostingController);
}

- (AVSampleBufferVideoRenderer *)videoRenderer {
    return CamPresentation::videoRendererFromRealityPlayerHostingController_Vision(self._playerHostingController);
}

- (void)setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    CamPresentation::setVideoRenderer_Vision(videoRenderer, self._playerHostingController);
}

- (__kindof UIViewController *)_playerHostingController {
    auto delegate = static_cast<ARPlayerSceneDelegate *>(self.delegate);
    __kindof UIViewController *rootViewController = delegate.window.rootViewController;
    assert(rootViewController != nil);
    return rootViewController;
}

@end
