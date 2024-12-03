//
//  PixelBufferLayerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/1/24.
//

#import <CamPresentation/PixelBufferLayerView.h>

@implementation PixelBufferLayerView

+ (Class)layerClass {
    return [PixelBufferLayer class];
}

- (PixelBufferLayer *)pixelBufferLayer {
    return static_cast<PixelBufferLayer *>(self.layer);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.contentsScale = self.traitCollection.displayScale;
}

@end
