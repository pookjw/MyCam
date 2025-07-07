//
//  DrawingView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <CamPresentation/DrawingView.h>

@implementation DrawingView

+ (Class)layerClass {
    return [DrawingLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
    }
    
    return self;
}

- (DrawingLayer *)drawingLayer {
    return static_cast<DrawingLayer *>(self.layer);
}

@end
