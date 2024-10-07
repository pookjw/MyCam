//
//  UIDeferredMenuElement+FileOutputs.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/UIDeferredMenuElement+FileOutputs.h>

@implementation UIDeferredMenuElement (FileOutputs)

+ (instancetype)cp_fileOutputsElementWithSelectionHandler:(void (^ _Nullable)(__kindof BaseFileOutput *fileOutput))selectionHandler {
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        UIAction *photoLibraryAction = [UIAction actionWithTitle:@"Photo Library" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            selectionHandler([PhotoLibraryFileOutput output]);
        }];
        
        //
        
        AVExternalStorageDeviceDiscoverySession *session = AVExternalStorageDeviceDiscoverySession.sharedSession;
        NSArray<AVExternalStorageDevice *> *externalStorageDevices = session.externalStorageDevices;
        
        NSMutableArray<UIAction *> *externalStorageDeviceActions = [[NSMutableArray alloc] initWithCapacity:externalStorageDevices.count];
        
        for (AVExternalStorageDevice *device in externalStorageDevices) {
            UIAction *action = [UIAction actionWithTitle:device.displayName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                ExternalStorageDeviceFileOutput *output = [[ExternalStorageDeviceFileOutput alloc] initWithExternalStorageDevice:device];
                selectionHandler(output);
                [output release];
            }];
            
            NSMeasurement *freeSizeBytesMeasurement = [[NSMeasurement alloc] initWithDoubleValue:device.freeSize unit:NSUnitInformationStorage.bytes];
            NSMeasurement *freeSizeTerabytesMeasurement = [freeSizeBytesMeasurement measurementByConvertingToUnit:NSUnitInformationStorage.terabytes];
            [freeSizeBytesMeasurement release];
            
            NSMeasurement *totalSizeBytesMeasurement = [[NSMeasurement alloc] initWithDoubleValue:device.totalSize unit:NSUnitInformationStorage.bytes];
            NSMeasurement *totalSizeTerabytesMeasurement = [totalSizeBytesMeasurement measurementByConvertingToUnit:NSUnitInformationStorage.terabytes];
            [totalSizeBytesMeasurement release];
            
            action.subtitle = [NSString stringWithFormat:@"%lfTB / %lfTB", (totalSizeTerabytesMeasurement.doubleValue - freeSizeTerabytesMeasurement.doubleValue), totalSizeTerabytesMeasurement.doubleValue];
            action.attributes = (device.isNotRecommendedForCaptureUse ? UIMenuElementAttributesDisabled : 0);
            
            [externalStorageDeviceActions addObject:action];
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:externalStorageDeviceActions];
        [externalStorageDeviceActions release];
        
        completion(@[photoLibraryAction, menu]);
    }];
}

@end
