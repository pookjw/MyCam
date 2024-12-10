//
//  ARPlayerViewControllerVisualProvider.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <CamPresentation/ARPlayerViewControllerVisualProvider.h>

@implementation ARPlayerViewControllerVisualProvider

- (instancetype)initWithPlayerViewController:(ARPlayerViewController *)playerViewController {
    if (self = [super init]) {
        _playerViewController = playerViewController;
    }
    
    return self;
}

- (AVPlayer *)player {
    abort();
}

- (void)setPlayer:(AVPlayer *)player {
    abort();
}

- (AVSampleBufferVideoRenderer *)videoRenderer {
    abort();
}

- (void)setVideoRenderer:(AVSampleBufferVideoRenderer *)videoRenderer {
    abort();
}

- (void)viewDidLoad {
    
}

@end
