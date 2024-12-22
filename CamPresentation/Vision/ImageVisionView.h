//
//  ImageVisionView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ImageVisionLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionView : UIView
@property (retain, nonatomic, readonly) ImageVisionLayer *imageVisionLayer;
@end

NS_ASSUME_NONNULL_END
