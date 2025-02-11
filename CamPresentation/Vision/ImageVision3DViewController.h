//
//  ImageVision3DViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/2/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <Vision/Vision.h>
#import <CamPresentation/ImageVision3DDescriptor.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVision3DViewController : UIViewController
@property (retain, nonatomic, nullable) ImageVision3DDescriptor *descriptor;
@end

NS_ASSUME_NONNULL_END

#endif
