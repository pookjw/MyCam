//
//  UIDeferredMenuElement+FileOutputs.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <UIKit/UIKit.h>
#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/PhotoLibraryFileOutput.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDeferredMenuElement (FileOutputs)
+ (instancetype)cp_fileOutputsElementWithSelectionHandler:(void (^ _Nullable)(__kindof BaseFileOutput *fileOutput))selectionHandler;
@end

NS_ASSUME_NONNULL_END
