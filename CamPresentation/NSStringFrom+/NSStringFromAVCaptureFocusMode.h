//
//  NSStringFromAVCaptureFocusMode.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/12/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CamPresentation/Extern.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_VISION
CP_EXTERN NSString * NSStringFromAVCaptureFocusMode(NSInteger focusMode);
#else
CP_EXTERN NSString * NSStringFromAVCaptureFocusMode(AVCaptureFocusMode focusMode);
#endif

NS_ASSUME_NONNULL_END
