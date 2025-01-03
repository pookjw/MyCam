//
//  UIDeferredMenuElement+ImageVision.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/ImageVisionLayer.h>
#import <CamPresentation/SVRunLoop.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (ImageVision)
+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel imageVisionLayer:(ImageVisionLayer *)imageVisionLayer drawingRunLoop:(SVRunLoop *)drawingRunLoop;
@end

NS_ASSUME_NONNULL_END
