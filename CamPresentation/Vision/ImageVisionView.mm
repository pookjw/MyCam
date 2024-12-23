//
//  ImageVisionView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/ImageVisionView.h>

@implementation ImageVisionView

+ (Class)layerClass {
    return [ImageVisionLayer class];
}

- (ImageVisionLayer *)imageVisionLayer {
    return static_cast<ImageVisionLayer *>(self.layer);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageVisionLayer.contentsScale = self.traitCollection.displayScale;
    [self.imageVisionLayer setNeedsDisplay];
}

@end
