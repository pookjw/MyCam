//
//  PointCloudPreviewView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/19/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
__attribute__((objc_direct_members))
@interface PointCloudPreviewView : UIView
@property (retain, nonatomic, readonly) CALayer *pointCloudLayer;
@property (retain, nonatomic, readonly) AVCaptureDevice *pointCloudDevice;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithPointCloudLayer:(CALayer *)pointCloudLayer pointCloudDevice:(AVCaptureDevice *)pointCloudDevice;
@end

NS_ASSUME_NONNULL_END
