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

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.layer.contentsScale = self.traitCollection.displayScale;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.contentsScale = self.traitCollection.displayScale;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.contentsScale = self.traitCollection.displayScale;
}

@end
