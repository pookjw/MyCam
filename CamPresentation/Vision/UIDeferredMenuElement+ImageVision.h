//
//  UIDeferredMenuElement+ImageVision.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/ImageVisionLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (ImageVision)
+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel imageVisionLayer:(ImageVisionLayer *)imageVisionLayer;
@end

NS_ASSUME_NONNULL_END
