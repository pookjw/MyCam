//
//  UIGestureRecognizer+CP_Category.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (CP_Category)
@property (assign, nonatomic, setter=cp_setRecognizesWithoutEdge:) BOOL cp_recognizesWithoutEdge;
@end

NS_ASSUME_NONNULL_END
