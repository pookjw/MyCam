//
//  DrawingView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/7/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/DrawingLayer.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface DrawingView : UIView
@property (nonatomic, readonly) DrawingLayer *drawingLayer;
@end

NS_ASSUME_NONNULL_END
