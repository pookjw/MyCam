//
//  UIDeferredMenuElement+PhotoFormat.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/29/24.
//

#import <CamPresentation/UIDeferredMenuElement+PhotoFormat.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/NSStringFromCMVideoDimensions.h>
#import <CamPresentation/NSStringFromAVCapturePhotoQualityPrioritization.h>
#import <CamPresentation/NSStringFromAVCaptureFlashMode.h>
#import <CamPresentation/NSStringFromAVCaptureTorchMode.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <vector>
#include <ranges>

#warning Spatial Over Capture, AVSpatialOverCaptureVideoPreviewLayer

@implementation UIDeferredMenuElement (PhotoFormat)

+ (instancetype)cp_photoFormatElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *result = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *photoFormatModel = [captureService queue_photoFormatModelForCaptureDevice:captureDevice];
            AVCapturePhotoOutput *photoOutput = [captureService queue_photoOutputFromCaptureDevice:captureDevice];
            assert(photoOutput != nil);
            
            NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_capturePhotoWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            [elements addObject:[UIDeferredMenuElement _cp_queue_maxPhotoDimensionsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
            [elements addObject:[UIDeferredMenuElement _cp_queue_photoPixelFormatTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            [elements addObject:[UIDeferredMenuElement _cp_queue_codecTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_qualitiesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
                [elements addObject:menu];
            }
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_photoFileTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_rawMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_spatialOverCaptureSupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleSpatialOverCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleSpatialPhotoCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleDeferredPhotoDeliveryActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleZeroShutterLagActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleResponsiveCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleFastCapturePrioritizationActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:action];
            }
            
            if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_photoQualityPrioritizationMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
                [elements addObject:menu];
            }
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_flashModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_torchModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
                [elements addObject:menu];
            }
            
            if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_reactionEffectsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]) {
                [elements addObject:menu];
            }
            
            // TODO: autoVideoFrameRateEnabled
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            
            [elements release];
        });
    }];
    
    return result;
}

+ (UIMenu * _Nonnull)_cp_queue_capturePhotoWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel {
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [captureService queue_readinessCoordinatorFromCaptureDevice:captureDevice];
    
    __kindof UIMenuElement *element;
    
    if (readinessCoordinator.captureReadiness == AVCapturePhotoOutputCaptureReadinessReady) {
        UIAction *captureAction = [UIAction actionWithTitle:@"Take Photo"
                                                      image:nil
                                                 identifier:nil
                                                    handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startPhotoCaptureWithCaptureDevice:captureDevice];
            });
        }];
        
        element = captureAction;
    } else {
        __kindof UIMenuElement *activityIndicatorElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            [activityIndicatorView startAnimating];
            
            return [activityIndicatorView autorelease];
        });
        
        element = activityIndicatorElement;
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        element
    ]];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_formatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureDeviceFormat *> *formats = captureDevice.formats;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    NSMutableArray<UIAction *> *formatActions = [NSMutableArray new];
    
    [formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([captureService.queue_captureSession isKindOfClass:AVCaptureMultiCamSession.class] && !format.multiCamSupported) {
            return;
        }
        
        UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeFormat = format;
                [captureDevice unlockForConfiguration];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.cp_overrideNumberOfTitleLines = @(0);
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [formatActions addObject:action];
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Format"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:formatActions];
    [formatActions release];
    menu.subtitle = activeFormat.debugDescription;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_maxPhotoDimensionsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureDeviceFormat *format = captureDevice.activeFormat;
    assert(photoOutput != nil);
    
    NSArray<NSValue *> *supportedMaxPhotoDimensions = format.supportedMaxPhotoDimensions;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedMaxPhotoDimensions.count];
    
    CMVideoDimensions selectedMaxPhotoDimensions = photoOutput.maxPhotoDimensions;
    
    for (NSValue *maxPhotoDimensionsValue in supportedMaxPhotoDimensions) {
        CMVideoDimensions maxPhotoDimensions = maxPhotoDimensionsValue.CMVideoDimensionsValue;
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromCMVideoDimensions(maxPhotoDimensions)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                photoOutput.maxPhotoDimensions = maxPhotoDimensions;
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
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

+ (UIMenu * _Nonnull)_cp_queue_photoPixelFormatTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    NSArray<NSNumber *> *photoPixelFormatTypes;
    if (photoFormatModel.processedFileType == nil) {
        photoPixelFormatTypes = photoOutput.availablePhotoPixelFormatTypes;
    } else {
        photoPixelFormatTypes = [photoOutput supportedPhotoPixelFormatTypesForFileType:photoFormatModel.processedFileType];
    }
    
    NSMutableArray<UIAction *> *photoPixelFormatTypeActions = [[NSMutableArray alloc] initWithCapacity:photoPixelFormatTypes.count];
    
    for (NSNumber *formatNumber in photoPixelFormatTypes) {
        CMVideoFormatDescriptionRef description;
        OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                         formatNumber.unsignedIntValue,
                                                         0,
                                                         0,
                                                         nullptr,
                                                         &description);
        assert(status == 0);
        
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(description);
        
        NSString *string = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&mediaSubType) length:4 encoding:NSUTF8StringEncoding];
        
        UIAction *action = [UIAction actionWithTitle:string image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.photoPixelFormatType = formatNumber;
                copy.codecType = nil;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [string release];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [photoFormatModel.photoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [photoPixelFormatTypeActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Pixel Format"
                                   image:[UIImage systemImageNamed:@"dot.square"]
                              identifier:nil
                                 options:0
                                children:photoPixelFormatTypeActions];
    [photoPixelFormatTypeActions release];
    
    if (NSNumber *photoPixelFormatType = photoFormatModel.photoPixelFormatType) {
        CMVideoFormatDescriptionRef description;
        OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                         photoPixelFormatType.unsignedIntValue,
                                                         0,
                                                         0,
                                                         nullptr,
                                                         &description);
        assert(status == 0);
        
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(description);
        
        NSString *string = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&mediaSubType) length:4 encoding:NSUTF8StringEncoding];
        menu.subtitle = string;
        [string release];
    }
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_codecTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVVideoCodecType> *availablePhotoCodecTypes;
    if (photoFormatModel.processedFileType == nil) {
        availablePhotoCodecTypes = photoOutput.availablePhotoCodecTypes;
    } else {
        if (photoFormatModel.isRAWEnabled) {
            availablePhotoCodecTypes = [photoOutput supportedRawPhotoCodecTypesForRawPhotoPixelFormatType:photoFormatModel.rawPhotoPixelFormatType.unsignedIntValue fileType:photoFormatModel.processedFileType];
        } else {
            availablePhotoCodecTypes = [photoOutput supportedPhotoCodecTypesForFileType:photoFormatModel.processedFileType];
        }
    }
    
    NSMutableArray<UIAction *> *photoCodecTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoCodecTypes.count];
    
    for (AVVideoCodecType photoCodecType in availablePhotoCodecTypes) {
        UIAction *action = [UIAction actionWithTitle:photoCodecType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.photoPixelFormatType = nil;
                copy.codecType = photoCodecType;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = [photoFormatModel.codecType isEqualToString:photoCodecType] ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        [photoCodecTypeActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Codec"
                                   image:[UIImage systemImageNamed:@"rectangle.on.rectangle.badge.gearshape"]
                              identifier:nil
                                 options:0
                                children:photoCodecTypeActions];
    [photoCodecTypeActions release];
    menu.subtitle = photoFormatModel.codecType;
    
    return menu;
}

+ (UIMenu * _Nullable)_cp_queue_qualitiesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (photoFormatModel.photoPixelFormatType != nil) {
        return nil;
    }
    
    NSMutableArray<UIAction *> *qualityActions = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (NSUInteger count = 1; count <= 10; count++) {
        float quality = static_cast<float>(count) / 10.f;
        
        UIAction *action = [UIAction actionWithTitle:@(quality).stringValue image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.quality = quality;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = (photoFormatModel.quality == quality) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        [qualityActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Quality"
                                   image:[UIImage systemImageNamed:@"slider.horizontal.below.sun.max"]
                              identifier:nil
                                 options:0
                                children:qualityActions];
    [qualityActions release];
    menu.subtitle = @(photoFormatModel.quality).stringValue;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_rawMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    [children addObject:[UIDeferredMenuElement _cp_queue_toggleRAWActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleAppleProRAWActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
        [children addObject:action];
    }
    
    if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_rawPhotoPixelFormatTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
        [children addObject:menu];
    }
    
    if (UIMenu *menu = [UIDeferredMenuElement _cp_queue_rawPhotoFileTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]) {
        [children addObject:menu];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@""
                                   image:nil
                              identifier:nil
                                 options:UIMenuOptionsDisplayInline
                                children:children];
    
    [children release];
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleRAWActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    UIAction *action = [UIAction actionWithTitle:@"Enable RAW"
                                           image:[UIImage systemImageNamed:@"compass.drawing"]
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *copy = [photoFormatModel copy];
            
            copy.isRAWEnabled = !copy.isRAWEnabled;
            if (copy.isRAWEnabled) {
                copy.rawPhotoPixelFormatType = photoOutput.availableRawPhotoPixelFormatTypes.lastObject;
                copy.rawFileType = photoOutput.availableRawPhotoFileTypes.lastObject;
                copy.processedFileType = nil;
            } else {
                copy.rawPhotoPixelFormatType = nil;
                copy.rawFileType = nil;
                copy.processedFileType = nil;
            }
            
            [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
            [copy release];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = photoFormatModel.isRAWEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleAppleProRAWActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (!photoFormatModel.isRAWEnabled) return nil;
    if (!photoOutput.isAppleProRAWSupported) return nil;
    
    BOOL isAppleProRAWEnabled = photoOutput.isAppleProRAWEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Apple Pro RAW"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.appleProRAWEnabled = !isAppleProRAWEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isAppleProRAWEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nullable)_cp_queue_rawPhotoPixelFormatTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (!photoFormatModel.isRAWEnabled) return nil;
    
    NSArray<NSNumber *> *availableRawPhotoPixelFormatTypes;
    if (photoFormatModel.processedFileType == nil) {
        availableRawPhotoPixelFormatTypes = photoOutput.availableRawPhotoPixelFormatTypes;
    } else {
        availableRawPhotoPixelFormatTypes = [photoOutput supportedRawPhotoPixelFormatTypesForFileType:photoFormatModel.processedFileType];
    }
    
    NSMutableArray<UIAction *> *rawPhotoPixelFormatTypeActions = [[NSMutableArray alloc] initWithCapacity:availableRawPhotoPixelFormatTypes.count];
    
    for (NSNumber *formatNumber in availableRawPhotoPixelFormatTypes) {
        CMVideoFormatDescriptionRef description;
        OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                         formatNumber.unsignedIntValue,
                                                         0,
                                                         0,
                                                         nullptr,
                                                         &description);
        assert(status == 0);
        
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(description);
        
        NSString *string = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&mediaSubType) length:4 encoding:NSUTF8StringEncoding];
        
        UIAction *action = [UIAction actionWithTitle:string image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.rawPhotoPixelFormatType = formatNumber;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [string release];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [photoFormatModel.rawPhotoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [rawPhotoPixelFormatTypeActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Raw Photo Pixel Format"
                                   image:[UIImage systemImageNamed:@"squareshape.dotted.squareshape"]
                              identifier:nil
                                 options:0
                                children:rawPhotoPixelFormatTypeActions];
    
    if (NSNumber *rawPhotoPixelFormatType = photoFormatModel.rawPhotoPixelFormatType) {
        CMVideoFormatDescriptionRef description;
        OSStatus status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                                         rawPhotoPixelFormatType.unsignedIntValue,
                                                         0,
                                                         0,
                                                         nullptr,
                                                         &description);
        assert(status == 0);
        
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(description);
        
        NSString *string = [[NSString alloc] initWithBytes:reinterpret_cast<const char *>(&mediaSubType) length:4 encoding:NSUTF8StringEncoding];
        menu.subtitle = string;
        [string release];
    }
    
    [rawPhotoPixelFormatTypeActions release];
    return menu;
}

+ (UIMenu * _Nullable)_cp_queue_rawPhotoFileTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (!photoFormatModel.isRAWEnabled) return nil;
    
    NSArray<AVFileType> *availableRawPhotoFileTypes = photoOutput.availableRawPhotoFileTypes;
    NSMutableArray<UIAction *> *rawFileTypeActions = [[NSMutableArray alloc] initWithCapacity:availableRawPhotoFileTypes.count];
    
    for (AVFileType fileType in availableRawPhotoFileTypes) {
        UIAction *action = [UIAction actionWithTitle:fileType
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.rawFileType = fileType;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [photoFormatModel.rawFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [rawFileTypeActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Raw Photo File Type"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:rawFileTypeActions];
    [rawFileTypeActions release];
    
    if (AVFileType rawFileType = photoFormatModel.rawFileType) {
        menu.subtitle = rawFileType;
    }
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_photoFileTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVFileType> *availablePhotoFileTypes = photoOutput.availablePhotoFileTypes;
    NSMutableArray<UIAction *> *availablePhotoFileTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoFileTypes.count + 1];
    
    UIAction *nullAction = [UIAction actionWithTitle:@"(null)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *copy = [photoFormatModel copy];
            copy.processedFileType = nil;
            [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
            [copy release];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    nullAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
    nullAction.state = (photoFormatModel.processedFileType == nil) ? UIMenuElementStateOn : UIMenuElementStateOff;
    [availablePhotoFileTypeActions addObject:nullAction];
    
    for (AVFileType fileType in availablePhotoFileTypes) {
        UIAction *action = [UIAction actionWithTitle:fileType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                
                //
                
                copy.processedFileType = fileType;
                
                NSArray<NSNumber *> *supportedPhotoPixelFormatTypes = [photoOutput supportedPhotoPixelFormatTypesForFileType:fileType];
                if (![supportedPhotoPixelFormatTypes containsObject:copy.photoPixelFormatType]) {
                    copy.photoPixelFormatType = supportedPhotoPixelFormatTypes.lastObject;
                }
                
                NSArray<AVFileType> *supportedPhotoCodecTypesForFileType = [photoOutput supportedPhotoCodecTypesForFileType:fileType];
                if (![supportedPhotoCodecTypesForFileType containsObject:copy.codecType]) {
                    copy.codecType = supportedPhotoCodecTypesForFileType.lastObject;
                }
                
                NSArray<NSNumber *> *supportedRawPhotoPixelFormatTypesForFileType = [photoOutput supportedRawPhotoPixelFormatTypesForFileType:fileType];
                if (![supportedRawPhotoPixelFormatTypesForFileType containsObject:copy.rawPhotoPixelFormatType]) {
                    copy.rawPhotoPixelFormatType = supportedRawPhotoPixelFormatTypesForFileType.lastObject;
                }
                
                //
                
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [photoFormatModel.processedFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [availablePhotoFileTypeActions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Photo Processed File Type"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:availablePhotoFileTypeActions];
    [availablePhotoFileTypeActions release];
    
    if (AVFileType processedFileType = photoFormatModel.processedFileType) {
        menu.subtitle = processedFileType;
    }
    
    return menu;
}

+ (UIMenu *)_cp_queue_spatialOverCaptureSupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    NSMutableArray<UIAction *> *actions = [NSMutableArray new];
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    
    [captureDevice.formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isSpatialOverCaptureSupported"))) return;
        
        UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeFormat = format;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.cp_overrideNumberOfTitleLines = @(0);
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Spatial Over Capture Formats" image:nil identifier:nil options:0 children:actions];
    [actions release];
    
    return menu;
}

+ (UIAction * _Nullable)_cp_queue_toggleSpatialOverCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialOverCaptureSupported"))) {
        return nil;
    }
    
    BOOL isSpatialOverCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialOverCaptureEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Spatial Over Capture"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            BOOL value = !isSpatialOverCaptureEnabled;
            
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(photoOutput, sel_registerName("setSpatialOverCaptureEnabled:"), value);
            
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevice, sel_registerName("setSpatialOverCaptureEnabled:"), value);
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isSpatialOverCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleSpatialPhotoCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialPhotoCaptureSupported"))) {
        return nil;
    }
    
    BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialPhotoCaptureEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Spatial Photo Capture"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(photoOutput, sel_registerName("setSpatialPhotoCaptureEnabled:"), !isSpatialPhotoCaptureEnabled);
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isSpatialPhotoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleDeferredPhotoDeliveryActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!photoOutput.isAutoDeferredPhotoDeliverySupported) {
        return nil;
    }
    
    BOOL isAutoDeferredPhotoDeliveryEnabled = photoOutput.isAutoDeferredPhotoDeliveryEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Deferred Photo"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.autoDeferredPhotoDeliveryEnabled = !isAutoDeferredPhotoDeliveryEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isAutoDeferredPhotoDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleZeroShutterLagActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!photoOutput.isZeroShutterLagSupported) {
        return nil;
    }
    
    BOOL isZeroShutterLagEnabled = photoOutput.isZeroShutterLagEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Zero Shutter Lag"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.zeroShutterLagEnabled = !isZeroShutterLagEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isZeroShutterLagEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleResponsiveCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!photoOutput.isResponsiveCaptureSupported) {
        return nil;
    }
    
    BOOL isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Responsive Capture"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.responsiveCaptureEnabled = !isResponsiveCaptureEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isResponsiveCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nullable)_cp_queue_toggleFastCapturePrioritizationActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!photoOutput.isFastCapturePrioritizationSupported) return nil;
    
    BOOL isFastCapturePrioritizationEnabled = photoOutput.isFastCapturePrioritizationEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Fast-capture Prioritization"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.fastCapturePrioritizationEnabled = !isFastCapturePrioritizationEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
    action.state = isFastCapturePrioritizationEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nullable)_cp_queue_photoQualityPrioritizationMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (photoFormatModel.isRAWEnabled) {
        // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
        return nil;
    }
    
    AVCapturePhotoQualityPrioritization photoQualityPrioritization = photoFormatModel.photoQualityPrioritization;
    
    auto vec = std::vector<AVCapturePhotoQualityPrioritization> {
        AVCapturePhotoQualityPrioritizationSpeed,
        AVCapturePhotoQualityPrioritizationBalanced,
        AVCapturePhotoQualityPrioritizationQuality
    }
    | std::views::filter([max = photoOutput.maxPhotoQualityPrioritization] (AVCapturePhotoQualityPrioritization prioritization) -> bool {
        return prioritization <= max;
    })
    | std::views::transform([captureService, captureDevice, photoFormatModel, photoQualityPrioritization, didChangeHandler](AVCapturePhotoQualityPrioritization prioritization) {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCapturePhotoQualityPrioritization(prioritization)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.photoQualityPrioritization = prioritization;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = (photoQualityPrioritization == prioritization) ? UIMenuElementStateOn : UIMenuElementStateOff;
        return action;
    })
    | std::ranges::to<std::vector>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:vec.data() count:vec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Quality Prioritization" children:actions];
    [actions release];
    menu.subtitle = NSStringFromAVCapturePhotoQualityPrioritization(photoQualityPrioritization);
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_flashModesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    NSArray<NSNumber *> *supportedFlashModes = photoOutput.supportedFlashModes;
    AVCaptureFlashMode selectedCaptureFlashMode = photoFormatModel.flashMode;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedFlashModes.count];
    
    for (NSNumber *flashModeNumber in supportedFlashModes) {
        auto flashMode = static_cast<AVCaptureFlashMode>(flashModeNumber.integerValue);
        
        UIImage * _Nullable image;
        switch (flashMode) {
            case AVCaptureFlashModeOff:
                image = [UIImage systemImageNamed:@"flashlight.slash"];
                break;
            case AVCaptureFlashModeOn:
                image = [UIImage systemImageNamed:@"flashlight.on.fill"];
                break;
            case AVCaptureFlashModeAuto:
                image = [UIImage systemImageNamed:@"flashlight.on.circle"];
                break;
            default:
                image = nil;
                break;
        }
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureFlashMode(flashMode)
                                               image:image
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                copy.flashMode = flashMode;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = (selectedCaptureFlashMode == flashMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Flash"
                                   image:nil
                              identifier:nil
                                 options:UIMenuOptionsDisplayInline
                                children:actions];
    [actions release];
    menu.subtitle = NSStringFromAVCaptureFlashMode(selectedCaptureFlashMode);
    menu.preferredElementSize = UIMenuElementSizeMedium;
    
    return menu;
}

+ (UIMenu * _Nullable)_cp_queue_torchModesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    if (!captureDevice.torchAvailable) return nil;
    
    auto vec = std::vector<AVCaptureTorchMode> {
        AVCaptureTorchModeOff,
        AVCaptureTorchModeOn,
        AVCaptureTorchModeAuto
    }
    | std::views::filter([captureDevice](AVCaptureTorchMode torchMode) {
        return [captureDevice isTorchModeSupported:torchMode];
    })
    | std::views::transform([captureService, captureDevice, didChangeHandler](AVCaptureTorchMode torchMode) {
        UIImage * _Nullable image;
        switch (torchMode) {
            case AVCaptureTorchModeOff:
                image = [UIImage systemImageNamed:@"flashlight.slash"];
                break;
            case AVCaptureTorchModeOn:
                image = [UIImage systemImageNamed:@"flashlight.on.fill"];
                break;
            case AVCaptureTorchModeAuto:
                image = [UIImage systemImageNamed:@"flashlight.on.circle"];
                break;
            default:
                image = nil;
                break;
        }
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureTorchMode(torchMode)
                                               image:image
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                
                captureDevice.torchMode = torchMode;
                
                [captureDevice unlockForConfiguration];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = (captureDevice.torchMode == torchMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:vec.data() count:vec.size()];
    
    UIMenu *submenu = [UIMenu menuWithTitle:@""
                                      image:nil
                                 identifier:nil
                                    options:UIMenuOptionsDisplayInline
                                   children:actions];
    [actions release];
    submenu.preferredElementSize = UIMenuElementSizeMedium;
    
    //
    
    __kindof UIMenuElement *torchLevelSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0.f;
        slider.maximumValue = std::fminf(1.f, AVCaptureMaxAvailableTorchLevel);
        slider.value = captureDevice.torchLevel;
        
        [slider addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            // fcmp   s8, #0.0
            auto value = std::max(static_cast<UISlider *>(action.sender).value, 0.01f);
            
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                
                [captureDevice setTorchModeOnWithLevel:value error:&error];
                assert(error == nil);
                
                [captureDevice unlockForConfiguration];
            });
        }]
         forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Torch" children:@[
        submenu,
        torchLevelSliderElement
    ]];
    menu.subtitle = NSStringFromAVCaptureTorchMode(captureDevice.torchMode);
    
    return menu;
}

+ (UIMenu * _Nullable)_cp_queue_reactionEffectsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!AVCaptureDevice.reactionEffectsEnabled) {
        return nil;
    }
    
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray new];
    
    //
    
    NSMutableArray<UIAction *> *formatActions = [NSMutableArray new];
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    
    [captureDevice.formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if (format.reactionEffectsSupported) {
            UIAction *formatAction = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    captureDevice.activeFormat = format;
                    [captureDevice unlockForConfiguration];
                });
            }];
            
            formatAction.cp_overrideNumberOfTitleLines = @(0);
            formatAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            formatAction.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            [formatActions addObject:formatAction];
        }
    }];
    
    UIMenu *formatMenu = [UIMenu menuWithTitle:@"Reaction Format" children:formatActions];
    [formatActions release];
    [menuElements addObject:formatMenu];
    
    //
    
    if (captureDevice.activeFormat.reactionEffectsSupported) {
        NSSet<AVCaptureReactionType> *availableReactionTypes = captureDevice.availableReactionTypes;
        
        for (AVCaptureReactionType reactionType in availableReactionTypes) {
            UIAction *action = [UIAction actionWithTitle:reactionType
                                                   image:[UIImage systemImageNamed:AVCaptureReactionSystemImageNameForType(reactionType)]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    [captureDevice performEffectForReaction:reactionType];
                });
            }];
            
            [menuElements addObject:action];
        }
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Reaction" image:nil identifier:nil options:UIMenuOptionsDisplayAsPalette | UIMenuOptionsDisplayInline children:menuElements];
    [menuElements release];
    
    return menu;
}

@end