//
//  CameraRootPhotoModel.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CaptureService;

@interface CameraRootPhotoModel : NSObject <NSCopying, NSSecureCoding>
@property (retain, nonatomic, nullable) CaptureService *captureService;

@property (copy, nullable) NSNumber *photoPixelFormatType;
@property (copy, nullable) AVVideoCodecType codecType;
@property (assign) float quality;

@property (assign, getter=rawEnabled, setter=setRAWEnabled:) BOOL isRAWEnabled;
@property (copy, nullable) NSNumber *rawPhotoPixelFormatType;
@property (copy, nullable) AVFileType rawFileType;
@property (copy, nullable) AVFileType processedFileType;

- (NSArray<UIMenuElement *> *)configurationMenuElementsWithSelectionHandler:(void (^ _Nullable)())selectionHandler;
@end

NS_ASSUME_NONNULL_END
