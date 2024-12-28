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
@property (retain, atomic, nullable) UIImage *image;
@property (copy, atomic) NSArray<__kindof VNObservation *> *observations;
@property (atomic) BOOL shouldDrawImage;
@property (atomic) BOOL shouldDrawDetails;
@property (atomic) BOOL shouldDrawContoursSeparately;
@property (atomic) BOOL shouldDrawOverlay;
@end

NS_ASSUME_NONNULL_END
