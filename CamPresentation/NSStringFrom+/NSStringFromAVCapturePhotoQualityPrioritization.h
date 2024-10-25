//
//  NSStringFromAVCapturePhotoQualityPrioritization.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCapturePhotoQualityPrioritization(NSInteger photoQualityPrioritization);
#else
CP_EXTERN NSString * NSStringFromAVCapturePhotoQualityPrioritization(AVCapturePhotoQualityPrioritization photoQualityPrioritization);
#endif

NS_ASSUME_NONNULL_END
