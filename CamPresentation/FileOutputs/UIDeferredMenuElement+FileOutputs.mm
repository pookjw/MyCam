//
//  UIDeferredMenuElement+FileOutputs.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/UIDeferredMenuElement+FileOutputs.h>
#import <objc/message.h>

#warning +[AVExternalStorageDevice requestAccessWithCompletionHandler:]

@implementation UIDeferredMenuElement (FileOutputs)

+ (instancetype)cp_fileOutputsElementWithCaptureService:(CaptureService *)captureService {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [AVExternalStorageDevice requestAccessWithCompletionHandler:^(BOOL granted) {
            assert(granted);
            
            dispatch_async(captureService.captureSessionQueue, ^{
                __kindof BaseFileOutput *fileOutput = captureService.queue_fileOutput;
                
                //
                
                UIAction *photoLibraryAction = [UIAction actionWithTitle:@"Photo Library" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        PhotoLibraryFileOutput *output = [[PhotoLibraryFileOutput alloc] initWithPhotoLibrary:PHPhotoLibrary.sharedPhotoLibrary];
                        captureService.queue_fileOutput = output;
                        [output release];
                    });
                }];
                
                photoLibraryAction.state = (fileOutput.class == PhotoLibraryFileOutput.class) ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                //
                
                AVExternalStorageDeviceDiscoverySession *session = captureService.externalStorageDeviceDiscoverySession;
                NSArray<AVExternalStorageDevice *> *externalStorageDevices = session.externalStorageDevices;
                
                NSMutableArray<UIAction *> *externalStorageDeviceActions = [[NSMutableArray alloc] initWithCapacity:externalStorageDevices.count];
                
                for (AVExternalStorageDevice *device in externalStorageDevices) {
                    UIAction *action = [UIAction actionWithTitle:device.displayName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        dispatch_async(captureService.captureSessionQueue, ^{
                            ExternalStorageDeviceFileOutput *output = [[ExternalStorageDeviceFileOutput alloc] initWithExternalStorageDevice:device];
                            captureService.queue_fileOutput = output;
                            [output release];
                        });
                    }];
                    
                    NSMeasurement *freeSizeBytesMeasurement = [[NSMeasurement alloc] initWithDoubleValue:device.freeSize unit:NSUnitInformationStorage.bytes];
                    NSMeasurement *freeSizeTerabytesMeasurement = [freeSizeBytesMeasurement measurementByConvertingToUnit:NSUnitInformationStorage.terabytes];
                    [freeSizeBytesMeasurement release];
                    
                    NSMeasurement *totalSizeBytesMeasurement = [[NSMeasurement alloc] initWithDoubleValue:device.totalSize unit:NSUnitInformationStorage.bytes];
                    NSMeasurement *totalSizeTerabytesMeasurement = [totalSizeBytesMeasurement measurementByConvertingToUnit:NSUnitInformationStorage.terabytes];
                    [totalSizeBytesMeasurement release];
                    
                    NSString *_uniqueIdentifier = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(device, sel_registerName("_uniqueIdentifier"));
                    
                    action.subtitle = [NSString stringWithFormat:@"%lfTB / %lfTB, %@", (totalSizeTerabytesMeasurement.doubleValue - freeSizeTerabytesMeasurement.doubleValue), totalSizeTerabytesMeasurement.doubleValue, _uniqueIdentifier];
                    action.attributes = (device.isNotRecommendedForCaptureUse ? UIMenuElementAttributesDisabled : 0);
                    
                    UIMenuElementState state;
                    if (fileOutput.class == ExternalStorageDeviceFileOutput.class) {
                        state = [static_cast<ExternalStorageDeviceFileOutput *>(fileOutput).externalStorageDevice isEqual:device] ? UIMenuElementStateOn : UIMenuElementStateOff;
                    } else {
                        state = UIMenuElementStateOff;
                    }
                    action.state = state;
                    
                    [externalStorageDeviceActions addObject:action];
                }
                
                UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:externalStorageDeviceActions];
                [externalStorageDeviceActions release];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@[photoLibraryAction, menu]);
                });
            });
        }];
    }];
}

@end
