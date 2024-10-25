//
//  NSStringFromAVCaptureAutoFocusSystem.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureAutoFocusSystem(NSInteger focusSystem);
#else
CP_EXTERN NSString * NSStringFromAVCaptureAutoFocusSystem(AVCaptureAutoFocusSystem focusSystem);
#endif

NS_ASSUME_NONNULL_END
