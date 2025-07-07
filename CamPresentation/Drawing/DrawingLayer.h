//
//  DrawingLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

// Thread-safe를 보장하지 않음
__attribute__((objc_direct_members))
@interface DrawingLayer : CALayer
@property (assign, nonatomic, null_resettable) CGColorRef strokeColor;
@property (assign, nonatomic) CGFloat strokeWidth;
@property (nonatomic, readonly) CGRect normalizedBoundingBox;
- (void)addLineToNormalizedPoint:(CGPoint)normalizedPoint begin:(BOOL)begin;
- (void)clearPoints;
@end

NS_ASSUME_NONNULL_END
