//
//  NSStringFromAVCaptureColorSpace.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureColorSpace(NSInteger colorSpace);
#else
CP_EXTERN NSString * NSStringFromAVCaptureColorSpace(AVCaptureColorSpace colorSpace);
#endif

NS_ASSUME_NONNULL_END
