//
//  DrawingLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <CamPresentation/DrawingLayer.h>
#import <UIKit/UIKit.h>

@interface DrawingLayer ()
@property (assign, nonatomic, readonly, getter=_currentNormalizedPath) CGMutablePathRef currentNormalizedPath;
@end

@implementation DrawingLayer

- (instancetype)init {
    if (self = [super init]) {
        [self setNeedsDisplayOnBoundsChange:YES];
        _currentNormalizedPath = CGPathCreateMutable();
        self.strokeColor = nil;
        self.strokeWidth = 3.;
    }
    
    return self;
}

- (instancetype)initWithLayer:(id)layer {
    if ([super initWithLayer:layer]) {
        auto other = static_cast<DrawingLayer *>(layer);
        _currentNormalizedPath = CGPathCreateMutableCopy(other->_currentNormalizedPath);
        _strokeColor = CGColorRetain(other->_strokeColor);
        _strokeWidth = other->_strokeWidth;
    }
    
    return self;
}

- (void)dealloc {
    CGPathRelease(_currentNormalizedPath);
    [super dealloc];
}

- (void)setStrokeColor:(CGColorRef)strokeColor {
    CGColorRelease(_strokeColor);
    
    if (strokeColor == NULL) {
        _strokeColor = CGColorCreateSRGB(1., 0., 0., 1.);
    } else {
        _strokeColor = CGColorRetain(strokeColor);
    }
    
    [self setNeedsDisplay];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    [self setNeedsDisplay];
}

- (CGRect)normalizedBoundingBox {
    return CGPathGetBoundingBox(_currentNormalizedPath);
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    CGContextSaveGState(ctx);
    
    CGRect bounds = self.bounds;
    
    CGContextSetStrokeColorWithColor(ctx, _strokeColor);
    CGContextSetLineWidth(ctx, _strokeWidth);
    
    const CGAffineTransform transform = CGAffineTransformMakeScale(CGRectGetWidth(bounds), CGRectGetHeight(bounds));
    CGMutablePathRef transformedPath = CGPathCreateMutableCopyByTransformingPath(_currentNormalizedPath, &transform);
    CGContextAddPath(ctx, transformedPath);
    CGPathRelease(transformedPath);
    CGContextStrokePath(ctx);
    
    CGContextRestoreGState(ctx);
}

- (void)addLineToNormalizedPoint:(CGPoint)normalizedPoint begin:(BOOL)begin {
    if (begin) {
        CGPathMoveToPoint(_currentNormalizedPath, NULL, normalizedPoint.x, normalizedPoint.y);
        [self setNeedsDisplay];
    } else {
        CGPoint lastPoint = CGPathGetCurrentPoint(_currentNormalizedPath);
        CGPathAddLineToPoint(_currentNormalizedPath, NULL, normalizedPoint.x, normalizedPoint.y);
        
        CGRect bounds = self.bounds;
        CGRect r1 = CGRectMake(lastPoint.x, lastPoint.y, 0., 0.);
        CGRect r2 = CGRectMake(normalizedPoint.x, normalizedPoint.y, 0., 0.);
        CGRect updatingRect = CGRectUnion(r1, r2);
        
        updatingRect.origin.x *= CGRectGetWidth(bounds);
        updatingRect.origin.x -= _strokeWidth * 0.5;
        
        updatingRect.origin.y *= CGRectGetHeight(bounds);
        updatingRect.origin.y -= _strokeWidth * 0.5;
        
        updatingRect.size.width *= CGRectGetWidth(bounds);
        updatingRect.size.width += _strokeWidth;
        
        updatingRect.size.height *= CGRectGetHeight(bounds);
        updatingRect.size.height += _strokeWidth;
        
        
        [self setNeedsDisplayInRect:updatingRect];
    }
}

- (void)clearPoints {
    CGPathRelease(_currentNormalizedPath);
    _currentNormalizedPath = CGPathCreateMutable();
    [self setNeedsDisplay];
}

@end
