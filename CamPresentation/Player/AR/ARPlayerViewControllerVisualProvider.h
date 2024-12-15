//
//  ARPlayerViewControllerVisualProvider.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <CamPresentation/ARPlayerViewController.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(visionos(1.0), ios(18.0))
@interface ARPlayerViewControllerVisualProvider : NSObject
@property (assign, nonatomic, readonly) ARPlayerViewController *playerViewController;
@property (retain, nonatomic, nullable) AVPlayer *player;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlayerViewController:(ARPlayerViewController *)playerViewController;
- (void)viewDidLoad;
@end

NS_ASSUME_NONNULL_END
