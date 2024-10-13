//
//  CaptureVideoPreviewView.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureVideoPreviewView : UIView
@property (retain, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain, nonatomic, readonly) CALayer *depthMapLayer;
@property (retain, nonatomic, readonly) UILabel *spatialCaptureDiscomfortReasonLabel;
@property (copy, nonatomic, nullable) UIMenu *menu;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer * _Nullable)depthMapLayer;
- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons;
- (void)reloadMenu;
@end

NS_ASSUME_NONNULL_END
