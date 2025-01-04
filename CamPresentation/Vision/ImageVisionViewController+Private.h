//
//  ImageVisionViewController+Private.h
//  MyCam
//
//  Created by Jinwoo Kim on 1/5/25.
//

#import <CamPresentation/ImageVisionViewController.h>
#import <CamPresentation/ImageVisionViewModel.h>
#import <CamPresentation/ImageVisionView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageVisionViewController (Private)
@property (retain, nonatomic, readonly) ImageVisionViewModel *_viewModel;
@property (retain, nonatomic, readonly) ImageVisionView *_imageVisionView;
@property (retain, nonatomic, readonly) ImageVisionLayer *_imageVisionLayer;
@end

NS_ASSUME_NONNULL_END
