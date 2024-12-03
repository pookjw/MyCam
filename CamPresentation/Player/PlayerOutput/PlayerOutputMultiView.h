//
//  PlayerOutputMultiView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/1/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerOutputMultiView : UIView
- (void)updateWithPlayer:(AVPlayer *)player specification:(AVVideoOutputSpecification *)specification;
@end

NS_ASSUME_NONNULL_END
