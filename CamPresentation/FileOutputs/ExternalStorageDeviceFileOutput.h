//
//  ExternalStorageDeviceFileOutput.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/BaseFileOutput.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExternalStorageDeviceFileOutput : BaseFileOutput
@property (retain, nonatomic, readonly) AVExternalStorageDevice *externalStorageDevice;
- (instancetype)initWithExternalStorageDevice:(AVExternalStorageDevice *)externalStorageDevice;
@end

NS_ASSUME_NONNULL_END
