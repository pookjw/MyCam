//
//  CaptureActionsMenuElement.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/26/24.
//

#import <CamPresentation/CaptureActionsMenuElement.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/NSStringFromCMVideoDimensions.h>
#import <CamPresentation/NSStringFromAVCapturePhotoQualityPrioritization.h>
#import <CamPresentation/NSStringFromAVCaptureFlashMode.h>
#import <CamPresentation/NSStringFromAVCaptureTorchMode.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <vector>
#include <ranges>

// TODO: Spatial Over Capture

@interface _CaptureActionsMenuElementInternal : NSObject
@property (class, nonatomic, readonly) void *key;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (copy, nonatomic, readonly) PhotoFormatModel *photoFormatModel;
@property (copy, nonatomic, readonly, nullable) void (^completionHandler)(PhotoFormatModel * _Nonnull);
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel completionHandler:(void (^ _Nullable)(PhotoFormatModel *photoFormatModel))completionHandler;
@end

@implementation _CaptureActionsMenuElementInternal

+ (void *)key {
    static void *key = &key;
    return key;
}

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel completionHandler:(void (^)(PhotoFormatModel * _Nonnull))completionHandler {
    if (self = [super init]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        _photoFormatModel = [photoFormatModel copy];
        _completionHandler = [completionHandler copy];
        
        //
        
        [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"formats" options:NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"torchAvailable" options:NSKeyValueObservingOptionNew context:nullptr];
        
        //
        
        AVCapturePhotoOutput *capturePhotoOutput = captureService.capturePhotoOutput;
        
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoCodecTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isSpatialPhotoCaptureSupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isAutoDeferredPhotoDeliverySupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"supportedFlashModes" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isZeroShutterLagSupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isResponsiveCaptureSupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isAppleProRAWSupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isFastCapturePrioritizationSupported" options:NSKeyValueObservingOptionNew context:nullptr];
    }
    
    return self;
}

- (void)dealloc {
    AVCapturePhotoOutput *capturePhotoOutput = _captureService.capturePhotoOutput;
    
    [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoPixelFormatTypes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoCodecTypes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoFileTypes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoFileTypes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isSpatialPhotoCaptureSupported"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isAutoDeferredPhotoDeliverySupported"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"supportedFlashModes"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isZeroShutterLagSupported"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isResponsiveCaptureSupported"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isAppleProRAWSupported"];
    [capturePhotoOutput removeObserver:self forKeyPath:@"isFastCapturePrioritizationSupported"];
    
    //
    
    [_captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [_captureDevice removeObserver:self forKeyPath:@"formats"];
    [_captureDevice removeObserver:self forKeyPath:@"torchAvailable"];
    
    //
    
    [_captureService release];
    [_captureDevice release];
    [_photoFormatModel release];
    [_completionHandler release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.captureService.capturePhotoOutput]) {
        auto capturePhotoOutput = static_cast<AVCapturePhotoOutput *>(object);
        
        if ([keyPath isEqualToString:@"availablePhotoPixelFormatTypes"]) {
            NSArray<NSNumber *> *photoPixelFormatTypes;
            if (self.photoFormatModel.processedFileType == nil) {
                photoPixelFormatTypes = capturePhotoOutput.availablePhotoPixelFormatTypes;
            } else {
                photoPixelFormatTypes = [capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:self.photoFormatModel.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.photoFormatModel.photoPixelFormatType == nil) {
                if (self.photoFormatModel.codecType == nil) {
                    shouldUpdate = YES;
                } else {
                    shouldUpdate = NO;
                }
            } else if (![photoPixelFormatTypes containsObject:self.photoFormatModel.photoPixelFormatType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoFormatModel.photoPixelFormatType = photoPixelFormatTypes.lastObject;
            }
            
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoCodecTypes"]) {
            NSArray<AVVideoCodecType> *photoCodecTypes;
            if (self.photoFormatModel.processedFileType == nil) {
                photoCodecTypes = capturePhotoOutput.availablePhotoCodecTypes;
            } else {
                photoCodecTypes = [capturePhotoOutput supportedPhotoCodecTypesForFileType:self.photoFormatModel.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.photoFormatModel.codecType == nil) {
                if (self.photoFormatModel.photoPixelFormatType == nil) {
                    shouldUpdate = YES;
                } else {
                    shouldUpdate = NO;
                }
            } else if (![photoCodecTypes containsObject:self.photoFormatModel.codecType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoFormatModel.codecType = photoCodecTypes.lastObject;
            }
            
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoPixelFormatTypes"]) {
            NSArray<NSNumber *> *rawPhotoPixelFormatTypes;
            if (self.photoFormatModel.processedFileType == nil) {
                rawPhotoPixelFormatTypes = capturePhotoOutput.availableRawPhotoPixelFormatTypes;
            } else {
                rawPhotoPixelFormatTypes = [capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:self.photoFormatModel.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.photoFormatModel.rawPhotoPixelFormatType == nil) {
                shouldUpdate = YES;
            } else if (![rawPhotoPixelFormatTypes containsObject:self.photoFormatModel.rawPhotoPixelFormatType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoFormatModel.rawPhotoPixelFormatType = rawPhotoPixelFormatTypes.lastObject;
            }
            
            return;
        } else if ([keyPath isEqualToString:@"availableRawPhotoFileTypes"]) {
            NSArray<AVFileType> *availableRawPhotoFileTypes = capturePhotoOutput.availableRawPhotoFileTypes;
            
            BOOL shouldUpdate;
            if (self.photoFormatModel.rawFileType == nil) {
                shouldUpdate = YES;
            } else if (![availableRawPhotoFileTypes containsObject:self.photoFormatModel.rawFileType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoFormatModel.rawFileType = availableRawPhotoFileTypes.lastObject;
            }
            
            return;
        } else if ([keyPath isEqualToString:@"availablePhotoFileTypes"]) {
            NSArray<AVFileType> *availablePhotoFileTypes = capturePhotoOutput.availablePhotoFileTypes;
            
            BOOL shouldUpdate;
            if (self.photoFormatModel.processedFileType == nil) {
                shouldUpdate = YES;
            } else if (![availablePhotoFileTypes containsObject:self.photoFormatModel.processedFileType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoFormatModel.processedFileType = nil;
            }
            
            return;
        } else if ([keyPath isEqualToString:@"isSpatialPhotoCaptureSupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"isAutoDeferredPhotoDeliverySupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"supportedFlashModes"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"isZeroShutterLagSupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"isResponsiveCaptureSupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"isAppleProRAWSupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"isFastCapturePrioritizationSupported"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        }
    } else if ([object isEqual:self.captureDevice]) {
        if ([keyPath isEqualToString:@"activeFormat"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"formats"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        } else if ([keyPath isEqualToString:@"torchAvailable"]) {
            if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)menuElementsWithcompletionHandler:(void (^)(NSArray<__kindof UIMenuElement *> *))completionHandler {
    // self를 어딘가에서 capture하고 있어야함. UIMenu는 UIMenuElement를 retain하지 않아, Menu가 뜨기 전에 -dealloc되기 때문.
    
    NSMutableArray<__kindof UIMenuElement *> *actions = [NSMutableArray new];
    
    [actions addObject:[self queue_formatMenu]];
    [actions addObject:[self queue_maxPhotoDimensionsMenu]];
    
    completionHandler(actions);
    [actions release];
}

- (UIMenu *)queue_formatMenu {
    AVCaptureDevice *captureDevice = self.captureDevice;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    NSArray<AVCaptureDeviceFormat *> *formats = captureDevice.formats;
    NSMutableArray<UIAction *> *formatActions = [[NSMutableArray alloc] initWithCapacity:captureDevice.formats.count];
    
    [formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeFormat = format;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.cp_overrideNumberOfTitleLines = @(0);
        action.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [formatActions addObject:action];
    }];
    
    UIMenu *formatsMenu = [UIMenu menuWithTitle:@"Format"
                                          image:nil
                                     identifier:nil
                                        options:0
                                       children:formatActions];
    [formatActions release];
    formatsMenu.subtitle = activeFormat.debugDescription;
    
    return formatsMenu;
}

- (UIMenu *)queue_maxPhotoDimensionsMenu {
    AVCaptureDeviceFormat *format = self.captureDevice.activeFormat;
    NSArray<NSValue *> *supportedMaxPhotoDimensions = format.supportedMaxPhotoDimensions;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedMaxPhotoDimensions.count];
    CMVideoDimensions selectedMaxPhotoDimensions = self.captureService.capturePhotoOutput.maxPhotoDimensions;
    
    for (NSValue *maxPhotoDimensionsValue in supportedMaxPhotoDimensions) {
        CMVideoDimensions maxPhotoDimensions = maxPhotoDimensionsValue.CMVideoDimensionsValue;
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromCMVideoDimensions(maxPhotoDimensions)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(self.captureService.captureSessionQueue, ^{
                self.captureService.capturePhotoOutput.maxPhotoDimensions = maxPhotoDimensions;
                if (auto completionHandler = self.completionHandler) completionHandler(self.photoFormatModel);
            });
        }];
        
        action.state = ((selectedMaxPhotoDimensions.width == maxPhotoDimensions.width) && (selectedMaxPhotoDimensions.height == maxPhotoDimensions.height)) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Max Photo Dimensions"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromCMVideoDimensions(selectedMaxPhotoDimensions);
    
    return menu;
}

@end


@interface CaptureActionsMenuElement ()
@property (retain, nonatomic, readonly) _CaptureActionsMenuElementInternal *internal;
@end

@implementation CaptureActionsMenuElement

+ (instancetype)elementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel completionHandler:(void (^)(PhotoFormatModel * _Nonnull))completionHandler {
    _CaptureActionsMenuElementInternal *internal = [[_CaptureActionsMenuElementInternal alloc] initWithCaptureService:captureService captureDevice:captureDevice photoFormatModel:photoFormatModel completionHandler:completionHandler];
    
    CaptureActionsMenuElement *result = static_cast<CaptureActionsMenuElement *>([UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        [internal menuElementsWithcompletionHandler:completion];
    }]);
    
    assert(object_setClass(result, CaptureActionsMenuElement.class) != NULL);
    
    objc_setAssociatedObject(result, _CaptureActionsMenuElementInternal.key, internal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [internal release];
    
    //
    
    return result;
}

- (_CaptureActionsMenuElementInternal *)internal {
    return objc_getAssociatedObject(self, _CaptureActionsMenuElementInternal.key);
}

@end
