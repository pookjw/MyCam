//
//  AVCaptureSession+CP_Private.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/21/24.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVCaptureSession (CP_Private)
@property (retain, nonatomic, readonly) id cp_controlsOverlay;
@end

NS_ASSUME_NONNULL_END
