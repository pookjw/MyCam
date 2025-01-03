//
//  ImageVisionViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/21/24.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ImageVisionViewController : UIViewController
- (void)updateWithImage:(UIImage *)image; // can be called from any threads
- (void)updateWithAsset:(PHAsset *)asset; // can be called from any threads
@end

NS_ASSUME_NONNULL_END
