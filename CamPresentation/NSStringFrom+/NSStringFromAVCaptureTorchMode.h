//
//  NSStringFromAVCaptureTorchMode.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/23/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureTorchMode(NSInteger torchMode);
#else
CP_EXTERN NSString * NSStringFromAVCaptureTorchMode(AVCaptureTorchMode torchMode);
#endif

NS_ASSUME_NONNULL_END
