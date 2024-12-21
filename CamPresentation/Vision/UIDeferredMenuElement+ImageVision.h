//
//  UIDeferredMenuElement+ImageVision.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/22/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ImageVisionViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (ImageVision)
+ (instancetype)cp_imageVisionElementWithViewModel:(ImageVisionViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
