//
//  VisionKitDemoViewController.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/8/25.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VisionKitDemoViewController : UICollectionViewController

@end

NS_ASSUME_NONNULL_END

#endif
