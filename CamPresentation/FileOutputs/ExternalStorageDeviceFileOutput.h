//
//  ExternalStorageDeviceFileOutput.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/BaseFileOutput.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_VISION

@interface ExternalStorageDeviceFileOutput : BaseFileOutput
@property (retain, nonatomic, readonly) id externalStorageDevice;
- (instancetype)initWithExternalStorageDevice:(id)externalStorageDevice;
@property (retain, nonatomic, readonly) AVExternalStorageDevice *externalStorageDevice;
- (instancetype)initWithExternalStorageDevice:(AVExternalStorageDevice *)externalStorageDevice;
@end

#endif

NS_ASSUME_NONNULL_END
