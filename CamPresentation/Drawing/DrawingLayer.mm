//
//  DrawingLayer.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <CamPresentation/DrawingLayer.h>
#import <UIKit/UIKit.h>
#include <cmath>

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
    if (_strokeColor != NULL) {
        CGColorRelease(_strokeColor);
    }
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
        if (CGPointEqualToPoint(lastPoint, normalizedPoint)) return;
        
        CGPathAddLineToPoint(_currentNormalizedPath, NULL, normalizedPoint.x, normalizedPoint.y);
        
        CGRect bounds = self.bounds;
        CGRect r1 = CGRectMake(lastPoint.x, lastPoint.y, 0., 0.);
        CGRect r2 = CGRectMake(normalizedPoint.x, normalizedPoint.y, 0., 0.);
        CGRect updatingRect = CGRectUnion(r1, r2);
        
        if (CGRectIsNull(updatingRect)) {
            return;
        }
        
        updatingRect.origin.x *= CGRectGetWidth(bounds);
        updatingRect.origin.y *= CGRectGetHeight(bounds);
        updatingRect.size.width *= CGRectGetWidth(bounds);
        updatingRect.size.height *= CGRectGetHeight(bounds);
        
        if ((CGRectGetWidth(updatingRect) != 0.) && (CGRectGetHeight(updatingRect) != 0.)) {
            CGFloat radian = std::atan(CGRectGetHeight(updatingRect) / CGRectGetWidth(updatingRect));
            CGFloat sinVal = std::sin(radian);
            CGFloat cosVal = std::cos(radian);
            
            CGFloat xInset = _strokeWidth * 0.5 * sinVal;
            CGFloat yInset = _strokeWidth * 0.5 * cosVal;
            
            updatingRect.origin.x -= xInset;
            updatingRect.origin.y -= yInset;
            updatingRect.size.width += xInset * 2.;
            updatingRect.size.height += yInset * 2.;
        }
        
        if (CGRectGetWidth(updatingRect) == 0.) {
            updatingRect = CGRectInset(updatingRect, _strokeWidth * -0.5, 0.);
        }
        if (CGRectGetHeight(updatingRect) == 0.) {
            updatingRect = CGRectInset(updatingRect, 0., _strokeWidth * -0.5);
        }
        
        [self setNeedsDisplayInRect:updatingRect];
    }
}

- (void)clearPoints {
    CGPathRelease(_currentNormalizedPath);
    _currentNormalizedPath = CGPathCreateMutable();
    [self setNeedsDisplay];
}

@end
