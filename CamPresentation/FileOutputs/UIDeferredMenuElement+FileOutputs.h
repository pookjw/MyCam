//
//  UIDeferredMenuElement+FileOutputs.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/CaptureService.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_VISION

@interface UIDeferredMenuElement (FileOutputs)
+ (instancetype)cp_fileOutputsElementWithCaptureService:(CaptureService *)captureService;
@end

#endif

NS_ASSUME_NONNULL_END
