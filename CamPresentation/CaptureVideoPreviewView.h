//
//  CaptureVideoPreviewView.h
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CaptureService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CaptureVideoPreviewView : UIView
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (retain, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain, nonatomic, readonly, nullable) CALayer *depthMapLayer;
@property (retain, nonatomic, readonly, nullable) CALayer *visionLayer;
@property (retain, nonatomic, readonly, nullable) CALayer *metadataObjectsLayer;
@property (retain, nonatomic, readonly) UILabel *spatialCaptureDiscomfortReasonLabel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer depthMapLayer:(CALayer * _Nullable)depthMapLayer visionLayer:(CALayer * _Nullable)visionLayer metadataObjectsLayer:(CALayer * _Nullable)metadataObjectsLayer;
#warning deprecated
- (void)reloadMenu;
@end

NS_ASSUME_NONNULL_END
