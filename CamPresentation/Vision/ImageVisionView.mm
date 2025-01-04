//
//  ImageVisionView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <CamPresentation/ImageVisionView.h>

@interface ImageVisionView ()
@property (retain, nonatomic, readonly) SVRunLoop *_drawingRunLoop;
@end

@implementation ImageVisionView

- (instancetype)initWithDrawingRunLoop:(SVRunLoop *)drawingRunLoop {
    if (self = [super initWithFrame:CGRectNull]) {
        __drawingRunLoop = [drawingRunLoop retain];
        
        ImageVisionLayer *imageVisionLayer = [ImageVisionLayer new];
        _imageVisionLayer = imageVisionLayer;
        
        CALayer *layer = self.layer;
        [layer addSublayer:imageVisionLayer];
        imageVisionLayer.frame = layer.bounds;
    }
    
    return self;
}

- (void)dealloc {
    [__drawingRunLoop release];
    [_imageVisionLayer release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    ImageVisionLayer *imageVisionLayer = self.imageVisionLayer;
    CGFloat contentsScale = self.traitCollection.displayScale;
    CGRect frame = self.layer.bounds;
    
    imageVisionLayer.contentsScale = contentsScale;
    imageVisionLayer.frame = frame;
    
    [self._drawingRunLoop runBlock:^{
        [imageVisionLayer setNeedsDisplay];
    }];
}

@end
