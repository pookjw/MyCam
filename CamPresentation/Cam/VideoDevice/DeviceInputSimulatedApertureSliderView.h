//
//  DeviceInputSimulatedApertureSliderView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/9/25.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), macos(26.0))
API_UNAVAILABLE(visionos)
@interface DeviceInputSimulatedApertureSliderView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService deviceInput:(AVCaptureDeviceInput *)deviceInput NS_DESIGNATED_INITIALIZER;
- (void)setToDefaultSimulatedAperture;
@end

NS_ASSUME_NONNULL_END
