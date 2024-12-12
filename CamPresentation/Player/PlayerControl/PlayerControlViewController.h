//
//  PlayerControlViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/12/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/PlayerControlView.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerControlViewController : UIViewController
@property (retain, nonatomic, readonly) PlayerControlView *controlView;
@end

NS_ASSUME_NONNULL_END
