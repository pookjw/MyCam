//
//  VideoDeviceZoomFactorSliderView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/10/25.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface VideoDeviceZoomFactorSliderView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
