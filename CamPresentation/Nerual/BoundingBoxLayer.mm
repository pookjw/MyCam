//
//  BoundingBoxLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <CamPresentation/BoundingBoxLayer.h>

@implementation BoundingBoxLayer

- (instancetype)init {
    if (self = [super init]) {
        _boundingBox = CGRectNull;
        _strokeColor = CGColorCreateSRGB(1., 0., 0., 1.);
        _strokeWidth = 10.;
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    assert([layer isKindOfClass:[BoundingBoxLayer class]]);
    
    if (self = [super initWithLayer:layer]) {
        auto casted = static_cast<BoundingBoxLayer *>(layer);
        _boundingBox = casted->_boundingBox;
        _strokeColor = CGColorCreateCopy(casted->_strokeColor);
        _strokeWidth = casted->_strokeWidth;
    }
    
    return self;
}

- (void)dealloc {
    if (_strokeColor) {
        CGColorRelease(_strokeColor);
    }
    
    [super dealloc];
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    CGRect boundingBox = self.boundingBox;
    if (CGRectIsNull(boundingBox)) return;
    CGColorRef strokeColor = self.strokeColor;
    if (strokeColor == NULL) return;
    CGFloat strokeWidth = self.strokeWidth;
    if (strokeWidth == 0.) return;
    
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, strokeColor);
    CGContextStrokeRectWithWidth(ctx, boundingBox, strokeWidth);
    CGContextRestoreGState(ctx);
}

- (void)setBoundingBox:(CGRect)boundingBox {
    _boundingBox = boundingBox;
    [self setNeedsDisplay];
}

- (void)setStrokeColor:(CGColorRef)strokeColor {
    if (CGColorRef oldStrokeColor = _strokeColor) {
        CGColorRelease(oldStrokeColor);
    }
    
    if (strokeColor) {
        _strokeColor = CGColorCreateCopy(strokeColor);
    } else {
        _strokeColor = NULL;
    }
    
    [self setNeedsDisplay];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    [self setNeedsDisplay];
}

@end
