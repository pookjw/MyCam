//
//  BoundingBoxLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BoundingBoxLayer : CALayer
@property (assign, nonatomic) CGRect boundingBox;
@property (assign ,nonatomic) CGColorRef strokeColor;
@property (assign, nonatomic) CGFloat strokeWidth;
@end

NS_ASSUME_NONNULL_END
