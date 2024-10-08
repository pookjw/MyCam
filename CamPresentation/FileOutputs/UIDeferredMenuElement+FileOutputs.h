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

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (FileOutputs)
+ (instancetype)cp_fileOutputsElementWithCaptureService:(CaptureService *)captureService;
@end

NS_ASSUME_NONNULL_END
