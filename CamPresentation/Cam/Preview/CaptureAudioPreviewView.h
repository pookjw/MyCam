//
//  CaptureAudioPreviewView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/CaptureService.h>
#import <CamPresentation/AudioWaveLayer.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface CaptureAudioPreviewView : UIView
@property (retain, nonatomic, readonly) AVCaptureDevice *audioDevice;
@property (retain, nonatomic, readonly) AudioWaveLayer *audioWaveLayer;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService audioDevice:(AVCaptureDevice *)audioDevice audioWaveLayer:(AudioWaveLayer *)audioWaveLayer;
@end

NS_ASSUME_NONNULL_END
