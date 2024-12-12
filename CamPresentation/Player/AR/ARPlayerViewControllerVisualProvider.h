//
//  ARPlayerViewControllerVisualProvider.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <CamPresentation/ARPlayerViewController.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/ARPlayerRenderType.h>

NS_ASSUME_NONNULL_BEGIN

@class ARPlayerViewControllerVisualProvider;
@protocol ARPlayerViewControllerVisualProviderDelegate <NSObject>
- (ARPlayerRenderType)rednerTypeWithPlayerViewControllerVisualProvider:(ARPlayerViewControllerVisualProvider *)playerViewControllerVisualProvider;
- (void)playerViewControllerVisualProvider:(ARPlayerViewControllerVisualProvider *)playerViewControllerVisualProvider didSelectRenderType:(ARPlayerRenderType)renderType;
@end

@interface ARPlayerViewControllerVisualProvider : NSObject
@property (assign, nonatomic, readonly) ARPlayerViewController *playerViewController;
@property (retain, nonatomic, nullable) AVPlayer *player;
@property (retain, nonatomic, nullable) AVSampleBufferVideoRenderer *videoRenderer;
@property (assign, nonatomic, nullable) id<ARPlayerViewControllerVisualProviderDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlayerViewController:(ARPlayerViewController *)playerViewController;
- (void)viewDidLoad;
@end

NS_ASSUME_NONNULL_END
