//
//  PixelBufferLayerView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/1/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/PixelBufferLayer.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface PixelBufferLayerView : UIView
@property (readonly) PixelBufferLayer *pixelBufferLayer;
@end

NS_ASSUME_NONNULL_END
