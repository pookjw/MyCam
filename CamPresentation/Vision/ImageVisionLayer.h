//
//  ImageVisionLayer.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionLayer : CALayer
@property (retain, nullable) UIImage *image;
@property (copy) NSArray<__kindof VNObservation *> *observations;
@end

NS_ASSUME_NONNULL_END
