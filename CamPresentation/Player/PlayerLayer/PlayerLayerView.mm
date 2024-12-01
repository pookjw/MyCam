//
//  PlayerLayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/9/24.
//

#import <CamPresentation/PlayerLayerView.h>

@interface PlayerLayerView ()
@end

@implementation PlayerLayerView

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayerLayer *)playerLayer {
    return static_cast<AVPlayerLayer *>(self.layer);
}

@end
