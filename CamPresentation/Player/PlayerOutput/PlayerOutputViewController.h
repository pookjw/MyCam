//
//  PlayerOutputViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputViewController : UIViewController
- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification;
@end

NS_ASSUME_NONNULL_END