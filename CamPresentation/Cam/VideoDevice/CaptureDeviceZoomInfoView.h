//
//  CaptureDeviceZoomInfoView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/13/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface CaptureDeviceZoomInfoView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureDevice:(AVCaptureDevice *)captureDevice NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
