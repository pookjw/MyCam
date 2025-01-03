//
//  ImageVisionView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ImageVisionLayer.h>
#import <CamPresentation/SVRunLoop.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionView : UIView
@property (retain, nonatomic, readonly) ImageVisionLayer *imageVisionLayer;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithDrawingRunLoop:(SVRunLoop *)drawingRunLoop;
@end

NS_ASSUME_NONNULL_END
