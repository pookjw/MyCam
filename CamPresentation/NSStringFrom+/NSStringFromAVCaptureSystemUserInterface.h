//
//  NSStringFromAVCaptureSystemUserInterface.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/24/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureSystemUserInterface(NSInteger systemUserInterface);
#else
CP_EXTERN NSString * NSStringFromAVCaptureSystemUserInterface(AVCaptureSystemUserInterface systemUserInterface);
#endif

NS_ASSUME_NONNULL_END
