//
//  AVCaptureDevice+ValidWhiteBalanceGains.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/26/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(visionos)
@interface AVCaptureDevice (ValidWhiteBalanceGains)
- (BOOL)cp_isValidWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains;
@end

NS_ASSUME_NONNULL_END
