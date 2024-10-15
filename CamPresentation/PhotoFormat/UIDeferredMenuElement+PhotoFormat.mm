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
#import <CamPresentation/NSStringFromAVCaptureColorSpace.h>
#import <CamPresentation/NSStringFromAVCaptureVideoStabilizationMode.h>
#import <CamPresentation/NSStringFromAVCaptureAutoFocusSystem.h>
#import <CamPresentation/NSStringFromAVCaptureFocusMode.h>
#import <CamPresentation/NSStringFromAVCaptureAutoFocusRangeRestriction.h>
#import <CamPresentation/CaptureDeviceZoomInfoView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreMedia/CoreMedia.h>
#include <vector>
#include <ranges>

#warning AVSpatialOverCaptureVideoPreviewLayer
#warning -[AVCaptureDevice isProResSupported]
#warning videoMirrored
#warning lensAperture = Exposure?
#warning Long Press로 Focus 고정

@implementation UIDeferredMenuElement (PhotoFormat)

+ (instancetype)cp_photoFormatElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *result = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *photoFormatModel = [captureService queue_photoFormatModelForCaptureDevice:captureDevice];
            AVCapturePhotoOutput *photoOutput = [captureService queue_photoOutputFromCaptureDevice:captureDevice];
            assert(photoOutput != nil);
            
            NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_photoMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_movieMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_zoomSlidersElementWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_flashModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_torchModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService captureDevice:captureDevice title:@"Format" includeSubtitle:YES filterHandler:nil didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_depthMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_formatsByColorSpaceMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_activeColorSpacesMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_toggleCameraIntrinsicMatrixDeliveryActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_toggleGeometricDistortionCorrectionActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_cameraIntrinsicMatrixDeliverySupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_reactionEffectsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_centerStageMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_focusMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
#warning TODO: autoVideoFrameRateEnabled
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            
            [elements release];
        });
    }];
    
    return result;
}

+ (UIMenu *)_cp_queue_photoMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    PhotoFormatModel *photoFormatModel = [captureService queue_photoFormatModelForCaptureDevice:captureDevice];
    AVCapturePhotoOutput *photoOutput = [captureService queue_photoOutputFromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
    
    //
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_capturePhotoWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_maxPhotoDimensionsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    [elements addObject:[UIDeferredMenuElement _cp_queue_photoPixelFormatTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    [elements addObject:[UIDeferredMenuElement _cp_queue_codecTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_qualitiesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_photoFileTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_rawMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService captureDevice:captureDevice title:@"Spatial Over Capture Formats" includeSubtitle:NO filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isSpatialOverCaptureSupported"));
    } didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleSpatialOverCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleSpatialPhotoCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleDeferredPhotoDeliveryActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleZeroShutterLagActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleResponsiveCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleFastCapturePrioritizationActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_photoQualityPrioritizationMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleCameraCalibrationDataDeliveryActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_cameraCalibrationDataDeliverySupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleVirtualDeviceConstituentPhotoDeliveryActionWithCaptureService:captureService photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleDepthDataDeliveryEnabledActionWithCaptureService:captureService photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_exposureBracketedStillImageSettingsMenuWithCaptureService:captureService captureDevice:captureDevice photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Photo" children:elements];
    [elements release];
    
    return menu;
}

+ (UIMenu *)_cp_queue_movieMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMovieFileOutput *movieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
    assert(movieFileOutput != nil);
    
    NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_movieRecordingMenuWithCaptureService:captureService captureDevice:captureDevice movieFileOutput:movieFileOutput]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_movieOutputSettingsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
    
    if (UIAction *action = [UIDeferredMenuElement _cp_queue_toggleSpatialVideoCaptureActionWithCaptureService:captureService captureDevice:captureDevice movieFileOutput:movieFileOutput didChangeHandler:didChangeHandler]) {
        [elements addObject:action];
    }
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_formatsByVideoStabilizationModeWithCaptureService:captureService
                                                                                             captureDevice:captureDevice
                                                                                                     title:@"Formats by Video Stabilizations for Spatial Video Capture"
                                                                                             modeFilterHandler:^BOOL(AVCaptureVideoStabilizationMode videoStabilizationMode) {
        // -[AVCaptureMovieFileOutput _updateSpatialVideoCaptureSupportedForSourceDevice:]
        return ((0x1 << videoStabilizationMode) & 0x2c) != 0x0;
    }
                                                                                       formatFilterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isSpatialVideoCaptureSupported;
    }
                                                                                          didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_formatsByVideoStabilizationModeWithCaptureService:captureService captureDevice:captureDevice title:@"Formats by all Video Stabilizations" modeFilterHandler:nil formatFilterHandler:nil didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_setPreferredVideoStabilizationModeMenuWithCaptureService:captureService captureDevice:captureDevice connection:[movieFileOutput connectionWithMediaType:AVMediaTypeVideo] didChangeHandler:didChangeHandler]];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Movie" children:elements];
    [elements release];
    
    return menu;
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

+ (UIMenu * _Nonnull)_cp_queue_qualitiesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
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
        action.attributes = UIMenuElementAttributesKeepsMenuPresented | ((photoFormatModel.photoPixelFormatType == nil) ? 0 : UIMenuElementAttributesDisabled);
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
    
    [children addObject:[UIDeferredMenuElement _cp_queue_toggleAppleProRAWActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [children addObject:[UIDeferredMenuElement _cp_queue_rawPhotoPixelFormatTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [children addObject:[UIDeferredMenuElement _cp_queue_rawPhotoFileTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
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

+ (UIAction * _Nonnull)_cp_queue_toggleAppleProRAWActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | ((!photoFormatModel.isRAWEnabled || !photoOutput.isAppleProRAWSupported) ? UIMenuElementAttributesDisabled : 0);
    action.state = isAppleProRAWEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_rawPhotoPixelFormatTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
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
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoFormatModel.isRAWEnabled ? 0 : UIMenuElementAttributesDisabled);
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

+ (UIMenu * _Nonnull)_cp_queue_rawPhotoFileTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
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
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoFormatModel.isRAWEnabled ? 0 : UIMenuElementAttributesDisabled);
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

+ (UIAction * _Nonnull)_cp_queue_toggleSpatialOverCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    BOOL isSpatialOverCaptureSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialOverCaptureSupported"));
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (isSpatialOverCaptureSupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isSpatialOverCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleSpatialPhotoCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    BOOL isSpatialPhotoCaptureSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(photoOutput, sel_registerName("isSpatialPhotoCaptureSupported"));
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (isSpatialPhotoCaptureSupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isSpatialPhotoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleDeferredPhotoDeliveryActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoOutput.isAutoDeferredPhotoDeliverySupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isAutoDeferredPhotoDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleZeroShutterLagActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoOutput.isZeroShutterLagSupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isZeroShutterLagEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleResponsiveCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoOutput.isResponsiveCaptureSupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isResponsiveCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleFastCapturePrioritizationActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
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
    
    action.attributes = UIMenuElementAttributesKeepsMenuPresented | (photoOutput.isFastCapturePrioritizationSupported ? 0 : UIMenuElementAttributesDisabled);
    action.state = isFastCapturePrioritizationEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_photoQualityPrioritizationMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    AVCapturePhotoQualityPrioritization photoQualityPrioritization = photoFormatModel.photoQualityPrioritization;
    
    auto vec = std::vector<AVCapturePhotoQualityPrioritization> {
        AVCapturePhotoQualityPrioritizationSpeed,
        AVCapturePhotoQualityPrioritizationBalanced,
        AVCapturePhotoQualityPrioritizationQuality
    }
    | std::views::transform([captureService, captureDevice, photoFormatModel, photoQualityPrioritization, didChangeHandler, max = photoOutput.maxPhotoQualityPrioritization](AVCapturePhotoQualityPrioritization prioritization) {
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
        
        // *** -[AVCapturePhotoSettings setPhotoQualityPrioritization:] Unsupported when capturing RAW
        action.attributes = UIMenuElementAttributesKeepsMenuPresented | ((!photoFormatModel.isRAWEnabled && prioritization <= max) ? 0 : UIMenuElementAttributesDisabled);
        
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

+ (UIMenu * _Nonnull)_cp_queue_torchModesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    auto vec = std::vector<AVCaptureTorchMode> {
        AVCaptureTorchModeOff,
        AVCaptureTorchModeOn,
        AVCaptureTorchModeAuto
    }
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
        
        action.attributes = UIMenuElementAttributesKeepsMenuPresented | ((captureDevice.torchAvailable && [captureDevice isTorchModeSupported:torchMode]) ? 0 : UIMenuElementAttributesDisabled);
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
        slider.enabled = captureDevice.torchAvailable;
        
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

+ (UIMenu * _Nonnull)_cp_queue_reactionEffectsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray new];
    
    //
    
    [menuElements addObject:[UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService captureDevice:captureDevice title:@"Reaction Format" includeSubtitle:NO filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.reactionEffectsSupported;
    } didChangeHandler:didChangeHandler]];
    
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
            
            action.attributes = AVCaptureDevice.reactionEffectsEnabled ? 0 : UIMenuElementAttributesDisabled;
            
            [menuElements addObject:action];
        }
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Reaction" image:nil identifier:nil options:UIMenuOptionsDisplayAsPalette | UIMenuOptionsDisplayInline children:menuElements];
    [menuElements release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_movieRecordingMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice movieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput {
    NSArray<UIAction *> *actions;
    
    if (movieFileOutput.isRecording) {
        UIAction *stopAction = [UIAction actionWithTitle:@"Stop Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [movieFileOutput stopRecording];
            });
        }];
        
        UIAction *partialAction;
        if (movieFileOutput.isRecordingPaused) {
            partialAction = [UIAction actionWithTitle:@"Resume Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    [movieFileOutput resumeRecording];
                });
            }];
        } else {
            partialAction = [UIAction actionWithTitle:@"Pause Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    [movieFileOutput pauseRecording];
                });
            }];
        }
        
        actions = @[stopAction, partialAction];
    } else {
        UIAction *startAction = [UIAction actionWithTitle:@"Start Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startRecordingWithCaptureDevice:captureDevice];
            });
        }];
        
        actions = @[startAction];
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_activeColorSpacesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureColorSpace activeColorSpace = captureDevice.activeColorSpace;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    NSArray<NSNumber *> *supportedColorSpaces = activeFormat.supportedColorSpaces;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allColorSpacesVector]
    | std::views::transform([captureService, captureDevice, activeColorSpace, supportedColorSpaces](AVCaptureColorSpace colorSpace) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureColorSpace(colorSpace)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                AVCaptureMovieFileOutput *output = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
                NSLog(@"%@", [output supportedOutputSettingsKeysForConnection:[output connectionWithMediaType:AVMediaTypeVideo]]);
                
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeColorSpace = colorSpace;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.state = (activeColorSpace == colorSpace) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = [supportedColorSpaces containsObject:@(colorSpace)] ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Color Space" image:nil identifier:nil options:0 children:actions];
    [actions release];
    menu.subtitle = NSStringFromAVCaptureColorSpace(activeColorSpace);
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_movieOutputSettingsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMovieFileOutput *movieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
    NSArray<NSString *> *supportedOutputSettingsKeys = [movieFileOutput supportedOutputSettingsKeysForConnection:[movieFileOutput connectionWithMediaType:AVMediaTypeVideo]];
    
    NSMutableArray<UIMenu *> *menus = [NSMutableArray new];
    
    for (NSString *outputSettingKey in supportedOutputSettingsKeys) {
        if ([outputSettingKey isEqualToString:AVVideoCodecKey]) {
            [menus addObject:[UIDeferredMenuElement _cp_queue_videoCodecTypesMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
        } else if ([outputSettingKey isEqualToString:AVVideoCompressionPropertiesKey]) {
            
        } else {
            abort();
        }
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:menus];
    [menus release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_videoCodecTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMovieFileOutput *movieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
    AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    NSDictionary<NSString *, id> *outputSettings = [movieFileOutput outputSettingsForConnection:connection];
    AVVideoCodecType activeVideoCodecType = outputSettings[AVVideoCodecKey];
    NSArray<AVVideoCodecType> *availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableVideoCodecTypes.count];
    
    for (AVVideoCodecType videoCodecType in availableVideoCodecTypes) {
        UIAction *action = [UIAction actionWithTitle:videoCodecType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                NSMutableDictionary<NSString *, id> *outputSettings = [[movieFileOutput outputSettingsForConnection:connection] mutableCopy];
                NSArray<NSString *> *supportedOutputSettingsKeys = [movieFileOutput supportedOutputSettingsKeysForConnection:[movieFileOutput connectionWithMediaType:AVMediaTypeVideo]];
                
                for (NSString *key in outputSettings.allKeys) {
                    if (![supportedOutputSettingsKeys containsObject:key]) {
                        [outputSettings removeObjectForKey:key];
                    }
                }
                
                outputSettings[AVVideoCodecKey] = videoCodecType;
                
                [movieFileOutput setOutputSettings:outputSettings forConnection:connection];
                [outputSettings release];
                
                didChangeHandler();
            });
        }];
        
        action.state = [activeVideoCodecType isEqualToString:videoCodecType] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Video Codecs" children:actions];
    [actions release];
    menu.subtitle = outputSettings[AVVideoCodecKey];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_formatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice title:(NSString *)title includeSubtitle:(BOOL)includeSubtitle filterHandler:(BOOL (^ _Nullable)(AVCaptureDeviceFormat *format))filterHandler didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureDeviceFormat *> *formats = captureDevice.formats;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    NSMutableArray<UIAction *> *formatActions = [NSMutableArray new];
    
    [formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([captureService.queue_captureSession isKindOfClass:AVCaptureMultiCamSession.class] && !format.multiCamSupported) {
            return;
        }
        
        if (filterHandler) {
            if (!filterHandler(format)) return;
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
    
    UIMenu *menu = [UIMenu menuWithTitle:title
                                   image:nil
                              identifier:nil
                                 options:0
                                children:formatActions];
    [formatActions release];
    
    if (includeSubtitle) {
        menu.subtitle = activeFormat.debugDescription;
    }
    
    return menu;
}

+ (std::vector<AVCaptureColorSpace>)_cp_allColorSpacesVector {
    return {
        AVCaptureColorSpace_sRGB,
        AVCaptureColorSpace_P3_D65,
        AVCaptureColorSpace_HLG_BT2020,
        AVCaptureColorSpace_AppleLog
    };
}

+ (UIMenu * _Nonnull)_cp_queue_formatsByColorSpaceMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    auto menusVec = [UIDeferredMenuElement _cp_allColorSpacesVector]
    | std::views::transform([captureService, captureDevice, didChangeHandler](AVCaptureColorSpace colorSpace) -> UIMenu * {
        UIMenu *menu = [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                                        captureDevice:captureDevice
                                                                                title:NSStringFromAVCaptureColorSpace(colorSpace)
                                                                      includeSubtitle:NO
                                                                        filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
            return [format.supportedColorSpaces containsObject:@(colorSpace)];
        }
                                                                     didChangeHandler:didChangeHandler];
        
        return menu;
    })
    | std::ranges::to<std::vector<UIMenu *>>();
    
    NSArray<UIMenu *> *menus = [[NSArray alloc] initWithObjects:menusVec.data() count:menusVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Formats by Color Space" children:menus];
    [menus release];
    
    return menu;
}

+ (UIAction * _Nullable)_cp_queue_toggleSpatialVideoCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice movieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput didChangeHandler:(void (^)())didChangeHandler {
    if (!movieFileOutput.isSpatialVideoCaptureSupported) return nil;
    
    BOOL isSpatialVideoCaptureEnabled = movieFileOutput.isSpatialVideoCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Spatial Video Capture" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            movieFileOutput.spatialVideoCaptureEnabled = !isSpatialVideoCaptureEnabled;
        });
    }];
    
    action.state = isSpatialVideoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (std::vector<AVCaptureVideoStabilizationMode>)_cp_allVideoStabilizationModes {
    return {
        AVCaptureVideoStabilizationModeOff,
        AVCaptureVideoStabilizationModeStandard,
        AVCaptureVideoStabilizationModeCinematic,
        AVCaptureVideoStabilizationModeCinematicExtended,
        AVCaptureVideoStabilizationModePreviewOptimized,
        AVCaptureVideoStabilizationModeCinematicExtendedEnhanced,
        AVCaptureVideoStabilizationModeAuto
    };
}

+ (UIMenu * _Nonnull)_cp_queue_formatsByVideoStabilizationModeWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice title:(NSString *)title modeFilterHandler:(BOOL (^ _Nullable)(AVCaptureVideoStabilizationMode videoStabilizationMode))modeFilterHandler formatFilterHandler:(BOOL (^ _Nullable)(AVCaptureDeviceFormat *format))formatFilterHandler didChangeHandler:(void (^)())didChangeHandler {
    auto menusVec = [UIDeferredMenuElement _cp_allVideoStabilizationModes]
    | std::views::filter([modeFilterHandler](AVCaptureVideoStabilizationMode videoStabilizationMode) -> bool {
        if (modeFilterHandler) {
            return modeFilterHandler(videoStabilizationMode);
        } else {
            return true;
        }
    })
    | std::views::transform([captureService, captureDevice, didChangeHandler, formatFilterHandler](AVCaptureVideoStabilizationMode videoStabilizationMode) -> UIMenu * {
        return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                                captureDevice:captureDevice
                                                                        title:NSStringFromAVCaptureVideoStabilizationMode(videoStabilizationMode)
                                                              includeSubtitle:NO
                                                                filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
            if (![format isVideoStabilizationModeSupported:videoStabilizationMode]) {
                return NO;
            }
            
            if (formatFilterHandler) {
                return formatFilterHandler(format);
            }
            
            return YES;
        }
                                                             didChangeHandler:didChangeHandler];
    })
    | std::ranges::to<std::vector<UIMenu *>>();
    
    NSArray<UIMenu *> *menus = [[NSArray alloc] initWithObjects:menusVec.data() count:menusVec.size()];
    UIMenu *menu = [UIMenu menuWithTitle:title image:nil identifier:nil options:0 children:menus];
    [menus release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_setPreferredVideoStabilizationModeMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice connection:(AVCaptureConnection *)connection didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    AVCaptureVideoStabilizationMode activeVideoStabilizationMode = connection.activeVideoStabilizationMode;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allVideoStabilizationModes]
    | std::views::transform([captureService, connection, didChangeHandler, activeVideoStabilizationMode, activeFormat](AVCaptureVideoStabilizationMode mode) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureVideoStabilizationMode(mode)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                connection.preferredVideoStabilizationMode = mode;
                if (didChangeHandler != nil) {
                    didChangeHandler();
                }
            });
        }];
        
        action.state = (mode == activeVideoStabilizationMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = [activeFormat isVideoStabilizationModeSupported:mode] ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    UIMenu *menu = [UIMenu menuWithTitle:@"Video Stabilization Mode" image:nil identifier:nil options:0 children:actions];
    [actions release];
    
    return menu;
}

+ (UIDeferredMenuElement * _Nonnull)_cp_queue_zoomSlidersElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    CGFloat videoZoomFactor = captureDevice.videoZoomFactor;
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    BOOL isCenterStageActive = captureDevice.isCenterStageActive;
    
    AVZoomRange * _Nullable systemRecommendedVideoZoomRange = activeFormat.systemRecommendedVideoZoomRange;
    NSArray<NSNumber *> *secondaryNativeResolutionZoomFactors = activeFormat.secondaryNativeResolutionZoomFactors;
    NSArray<AVZoomRange *> *supportedVideoZoomRangesForDepthDataDelivery = activeFormat.supportedVideoZoomRangesForDepthDataDelivery;
    NSArray<NSNumber *> *virtualDeviceSwitchOverVideoZoomFactors = captureDevice.virtualDeviceSwitchOverVideoZoomFactors;
    CGFloat videoZoomFactorUpscaleThreshold = activeFormat.videoZoomFactorUpscaleThreshold;
    CGFloat videoMinZoomFactorForCenterStage = activeFormat.videoMinZoomFactorForCenterStage;
    CGFloat videoMaxZoomFactorForCenterStage = activeFormat.videoMaxZoomFactorForCenterStage;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        CaptureDeviceZoomInfoView *infoView = [[CaptureDeviceZoomInfoView alloc] initWithCaptureDevice:captureDevice];
        
        //
        
        NSMutableArray<__kindof NSValue *> *allSliderValues = [NSMutableArray new];
        
        //
        
        UISlider *systemRecommendedVideoZoomRangeSlider = [UISlider new];
        if (systemRecommendedVideoZoomRange != nil) {
            systemRecommendedVideoZoomRangeSlider.minimumValue = systemRecommendedVideoZoomRange.minZoomFactor;
            systemRecommendedVideoZoomRangeSlider.maximumValue = systemRecommendedVideoZoomRange.maxZoomFactor;
            systemRecommendedVideoZoomRangeSlider.value = videoZoomFactor;
        } else {
            systemRecommendedVideoZoomRangeSlider.enabled = NO;
        }
        
        __kindof NSValue *systemRecommendedVideoZoomRangeSliderValue = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("NSWeakObjectValue") alloc], sel_registerName("initWithObject:"), systemRecommendedVideoZoomRangeSlider);
        [allSliderValues addObject:systemRecommendedVideoZoomRangeSliderValue];
        [systemRecommendedVideoZoomRangeSliderValue release];
        
        //
        
        NSMutableArray<UISlider *> *videoZoomRangesForDepthDataDeliverySliders = [[NSMutableArray alloc] initWithCapacity:supportedVideoZoomRangesForDepthDataDelivery.count];
        
        for (AVZoomRange *range in supportedVideoZoomRangesForDepthDataDelivery) {
            UISlider *slider = [UISlider new];
            slider.minimumValue = range.minZoomFactor;
            slider.maximumValue = range.maxZoomFactor;
            slider.value = videoZoomFactor;
            [videoZoomRangesForDepthDataDeliverySliders addObject:slider];
            
            __kindof NSValue *sliderValue = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("NSWeakObjectValue") alloc], sel_registerName("initWithObject:"), slider);
            [allSliderValues addObject:sliderValue];
            [sliderValue release];
            
            [slider release];
        }
        
        //
        
        UISlider *videoZoomFactorForCenterStageSlider = [UISlider new];
        if (isCenterStageActive) {
            videoZoomFactorForCenterStageSlider.minimumValue = videoMinZoomFactorForCenterStage;
            videoZoomFactorForCenterStageSlider.maximumValue = videoMaxZoomFactorForCenterStage;
            videoZoomFactorForCenterStageSlider.value = videoZoomFactor;
            
            __kindof NSValue *sliderValue = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("NSWeakObjectValue") alloc], sel_registerName("initWithObject:"), videoZoomFactorForCenterStageSlider);
            [allSliderValues addObject:sliderValue];
            [sliderValue release];
        } else {
            videoZoomFactorForCenterStageSlider.enabled = NO;
        }
        
        //
        
        UIAction *sliderAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.videoZoomFactor = value;
                [captureDevice unlockForConfiguration];
            });
            
            for (__kindof NSValue *otherSliderValue in allSliderValues) {
                UISlider * _Nullable otherSlider = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(otherSliderValue, sel_registerName("weakObjectValue"));
                if ([otherSlider isEqual:slider]) continue;
                
                otherSlider.value = value;
            }
        }];
        
        for (__kindof NSValue *sliderValue in allSliderValues) {
            UISlider * _Nullable slider = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(sliderValue, sel_registerName("weakObjectValue"));
            [slider addAction:sliderAction forControlEvents:UIControlEventValueChanged];
        }
        
        [allSliderValues release];
        
        //
        
        __kindof UIMenuElement *infoViewElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return infoView;
        });
        [infoView release];
        
        //
        
        NSMutableArray<UIAction *> *secondaryNativeResolutionZoomFactorActions = [[NSMutableArray alloc] initWithCapacity:secondaryNativeResolutionZoomFactors.count];
        for (NSNumber *factor in secondaryNativeResolutionZoomFactors) {
            UIAction *action = [UIAction actionWithTitle:factor.stringValue image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    
#if CGFLOAT_IS_DOUBLE
                    [captureDevice rampToVideoZoomFactor:factor.doubleValue withRate:1.f];
#else
                    [captureDevice rampToVideoZoomFactor:factor.floatValue withRate:1.f];
#endif
                    [captureDevice unlockForConfiguration];
                    
                    if (didChangeHandler) didChangeHandler();
                });
            }];
            
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            
            [secondaryNativeResolutionZoomFactorActions addObject:action];
        }
        
        UIMenu *secondaryNativeResolutionZoomFactorsMenu = [UIMenu menuWithTitle:@"Secondary Native Resolution Zoom Factor" children:secondaryNativeResolutionZoomFactorActions];
        [secondaryNativeResolutionZoomFactorActions release];
        
        //
        
        __kindof UIMenuElement *systemRecommendedVideoZoomRangeSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return systemRecommendedVideoZoomRangeSlider;
        });
        [systemRecommendedVideoZoomRangeSlider release];
        
        UIMenu *systemRecommendedVideoZoomRangeSliderMenu = [UIMenu menuWithTitle:@"System Recommended Video Zoom Range" children:@[
            systemRecommendedVideoZoomRangeSliderElement
        ]];
        
        //
        
        NSMutableArray<UIAction *> *virtualDeviceSwitchOverVideoZoomFactorActions = [[NSMutableArray alloc] initWithCapacity:virtualDeviceSwitchOverVideoZoomFactors.count];
        
        for (NSNumber *factor in virtualDeviceSwitchOverVideoZoomFactors) {
            UIAction *action = [UIAction actionWithTitle:factor.stringValue image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                dispatch_async(captureService.captureSessionQueue, ^{
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    
#if CGFLOAT_IS_DOUBLE
                    [captureDevice rampToVideoZoomFactor:factor.doubleValue withRate:1.f];
#else
                    [captureDevice rampToVideoZoomFactor:factor.floatValue withRate:1.f];
#endif
                    [captureDevice unlockForConfiguration];
                    
                    if (didChangeHandler) didChangeHandler();
                });
            }];
            
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            
            [virtualDeviceSwitchOverVideoZoomFactorActions addObject:action];
        }
        
        UIMenu *virtualDeviceSwitchOverVideoZoomFactorsMenu = [UIMenu menuWithTitle:@"Virtual Device Switch Over Video Zoom Factors" children:virtualDeviceSwitchOverVideoZoomFactorActions];
        [virtualDeviceSwitchOverVideoZoomFactorActions release];
        
        //
        
        NSMutableArray<__kindof UIMenuElement *> *videoZoomRangesForDepthDataDeliverySliderElements = [[NSMutableArray alloc] initWithCapacity:videoZoomRangesForDepthDataDeliverySliders.count];
        for (UISlider *slider in videoZoomRangesForDepthDataDeliverySliders) {
            __kindof UIMenuElement *sliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
                return slider;
            });
            
            [videoZoomRangesForDepthDataDeliverySliderElements addObject:sliderElement];
        }
        [videoZoomRangesForDepthDataDeliverySliders release];
        
        UIMenu *videoZoomRangesForDepthDataDeliverySlidersMenu = [UIMenu menuWithTitle:@"Video Zoom Ranges For Depth Data Delivery" children:videoZoomRangesForDepthDataDeliverySliderElements];
        [videoZoomRangesForDepthDataDeliverySliderElements release];
        
        //
        
        __kindof UIMenuElement *videoZoomFactorForCenterStageSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return videoZoomFactorForCenterStageSlider;
        });
        [videoZoomFactorForCenterStageSlider release];
        
        UIMenu *videoZoomFactorForCenterStageSliderMenu = [UIMenu menuWithTitle:@"Video Zoom Factor For Center Stage" children:@[videoZoomFactorForCenterStageSliderElement]];
        
        //
        
        UIAction *videoZoomFactorUpscaleThresholdAction = [UIAction actionWithTitle:[NSString stringWithFormat:@"Video Zoom Factor Upscale Threshold : %lf", videoZoomFactorUpscaleThreshold] image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.videoZoomFactor = videoZoomFactorUpscaleThreshold;
                [captureDevice unlockForConfiguration];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        videoZoomFactorUpscaleThresholdAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
        videoZoomFactorUpscaleThresholdAction.cp_overrideNumberOfTitleLines = @(0);
        
        //
        
        UIMenu *menu = [UIMenu menuWithTitle:@"Zoom" children:@[
            infoViewElement,
            systemRecommendedVideoZoomRangeSliderMenu,
            secondaryNativeResolutionZoomFactorsMenu,
            videoZoomRangesForDepthDataDeliverySlidersMenu,
            virtualDeviceSwitchOverVideoZoomFactorsMenu,
            videoZoomFactorForCenterStageSliderMenu,
            videoZoomFactorUpscaleThresholdAction
        ]];
        
        //
        
        completion(@[menu]);
    }];
    
    return element;
}

+ (UIAction * _Nonnull)_cp_queue_toggleCameraIntrinsicMatrixDeliveryActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureConnection * _Nullable connection = nil;
    for (AVCaptureConnection *_connection in captureService.queue_captureSession.connections) {
        for (AVCaptureInputPort *inputPort in _connection.inputPorts) {
            auto deviceInput = static_cast<AVCaptureDeviceInput *>(inputPort.input);
            if (![deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
            
            if ([deviceInput.device isEqual:captureDevice] && [_connection.output isKindOfClass:AVCaptureVideoDataOutput.class]) {
                connection = _connection;
                break;
            }
        }
        
        if (connection != nil) break;
    }
    assert(connection != nil);
    
    BOOL isCameraIntrinsicMatrixDeliveryEnabled = connection.isCameraIntrinsicMatrixDeliveryEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Camera Intrinsic Matrix" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            connection.cameraIntrinsicMatrixDeliveryEnabled = !isCameraIntrinsicMatrixDeliveryEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isCameraIntrinsicMatrixDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = (connection.isCameraIntrinsicMatrixDeliverySupported) ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_cameraIntrinsicMatrixDeliverySupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Camera Intrinsic Matrix Delivery Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        AVFrameRateRange *lastRange = format.videoSupportedFrameRateRanges.lastObject;
        
        if (lastRange == nil) return NO;
        
        return (lastRange.maxFrameRate <= 120.);
    } 
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_toggleCameraCalibrationDataDeliveryActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    BOOL isCameraCalibrationDataDeliveryEnabled = photoFormatModel.isCameraCalibrationDataDeliveryEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Camera Calibration Data Delivery" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *copy = [photoFormatModel copy];
            copy.cameraCalibrationDataDeliveryEnabled = !isCameraCalibrationDataDeliveryEnabled;
            [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
            [copy release];
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isCameraCalibrationDataDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = photoOutput.isCameraCalibrationDataDeliverySupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_cameraCalibrationDataDeliverySupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    BOOL isGeometricDistortionCorrectionEnabled = captureDevice.isGeometricDistortionCorrectionEnabled;
    NSUInteger constituentDevicesCount = captureDevice.constituentDevices.count;
    
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Camera Calibration Data Delivery Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        if (!photoOutput.isVirtualDeviceConstituentPhotoDeliveryEnabled || isGeometricDistortionCorrectionEnabled) return NO;
        if (constituentDevicesCount == 2) {
            return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isStillImageDisparitySupported"));
        } else {
            return YES;
        }
    }
                                                         didChangeHandler:^{
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(photoOutput, sel_registerName("_updateCameraCalibrationDataDeliverySupportedForSourceDevice:"), captureDevice);
        if (didChangeHandler) didChangeHandler();
    }];
}

+ (UIAction * _Nonnull)_cp_queue_toggleGeometricDistortionCorrectionActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isGeometricDistortionCorrectionEnabled = captureDevice.isGeometricDistortionCorrectionEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Geometric Distortion Correction" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.geometricDistortionCorrectionEnabled = !isGeometricDistortionCorrectionEnabled;
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isGeometricDistortionCorrectionEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = captureDevice.isGeometricDistortionCorrectionSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleVirtualDeviceConstituentPhotoDeliveryActionWithCaptureService:(CaptureService *)captureService photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^)())didChangeHandler {
    BOOL isVirtualDeviceConstituentPhotoDeliveryEnabled = photoOutput.isVirtualDeviceConstituentPhotoDeliveryEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Virtual Device Constituent Photo Delivery" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.virtualDeviceConstituentPhotoDeliveryEnabled = !isVirtualDeviceConstituentPhotoDeliveryEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isVirtualDeviceConstituentPhotoDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = photoOutput.isVirtualDeviceConstituentPhotoDeliverySupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleDepthDataDeliveryEnabledActionWithCaptureService:(CaptureService *)captureService photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    BOOL isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Depth Data Delivery" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.depthDataDeliveryEnabled = !isDepthDataDeliveryEnabled;
        });
    }];
    
    action.state = isDepthDataDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = photoOutput.isDepthDataDeliverySupported ? 0 : UIMenuElementAttributesDisabled;
    
    if (photoFormatModel.processedFileType == nil) {
        action.subtitle = [NSString stringWithFormat:@"Requires processedFileType such as %@ or %@", AVFileTypeHEIC, AVFileTypeJPEG];
    }
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_depthMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UIDeferredMenuElement _cp_queue_hasDepthDataFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_noDepthDataFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_depthDataFormatsMenuWithCaptureService:captureService captureDevice:captureDevice title:@"Depth Data Format" includeSubtitle:YES filterHandler:nil didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_depthMapLayerOpacitySliderElementWithCaptureService:captureService captureDevice:captureDevice],
        [UIDeferredMenuElement _cp_queue_toggleDepthMapVisibilityActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleDepthMapFilteringActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_hasDepthDataFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Formats with Depth Data"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.supportedDepthDataFormats.count > 0;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_noDepthDataFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Formats with no Depth Data"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.supportedDepthDataFormats.count == 0;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_depthDataFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice title:(NSString *)title includeSubtitle:(BOOL)includeSubtitle filterHandler:(BOOL (^ _Nullable)(AVCaptureDeviceFormat *format))filterHandler didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureDeviceFormat *> *formats = captureDevice.activeFormat.supportedDepthDataFormats;
    AVCaptureDeviceFormat * _Nullable activeDepthDataFormat = captureDevice.activeDepthDataFormat;
    NSMutableArray<UIAction *> *formatActions = [NSMutableArray new];
    
    [formats enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AVCaptureDeviceFormat * _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([captureService.queue_captureSession isKindOfClass:AVCaptureMultiCamSession.class] && !format.multiCamSupported) {
            return;
        }
        
        if (filterHandler) {
            if (!filterHandler(format)) return;
        }
        
        UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.activeDepthDataFormat = format;
                [captureDevice unlockForConfiguration];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.cp_overrideNumberOfTitleLines = @(0);
        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = [activeDepthDataFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [formatActions addObject:action];
    }];
    
    UIMenu *menu = [UIMenu menuWithTitle:title
                                   image:nil
                              identifier:nil
                                 options:0
                                children:formatActions];
    [formatActions release];
    
    if (includeSubtitle) {
        menu.subtitle = activeDepthDataFormat.debugDescription;
    }
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleDepthMapVisibilityActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureDepthDataOutput * _Nullable depthDataOutput = [captureService queue_depthDataOutputFromCaptureDevice:captureDevice];
    AVCaptureConnection * _Nullable connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert((depthDataOutput == nil && connection == nil) || (depthDataOutput != nil && connection != nil));
    
    BOOL isEnabled;
    if (connection == nil) {
        isEnabled = NO;
    } else {
        isEnabled = connection.isEnabled;
    }
    
    UIAction *action = [UIAction actionWithTitle:@"Depth Map Visibility" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureService queue_setUpdatesDepthMapLayer:!isEnabled captureDevice:captureDevice];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    if (connection == nil) {
        action.attributes = UIMenuElementAttributesDisabled;
    } else {
        action.state = isEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    }
    
    return action;
}

+ (__kindof UIMenuElement *)_cp_queue_depthMapLayerOpacitySliderElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof CALayer *layer = [captureService queue_depthMapLayerFromCaptureDevice:captureDevice];
    
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        if (layer != nil) {
            slider.minimumValue = 0.f;
            slider.maximumValue = 1.f;
            slider.value = layer.opacity;
            slider.continuous = YES;
            
            UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                auto sender = static_cast<UISlider *>(action.sender);
                layer.opacity = sender.value;
            }];
            
            [slider addAction:action forControlEvents:UIControlEventValueChanged];
        } else {
            slider.enabled = NO;
        }
        
        return [slider autorelease];
    });
    
    return element;
}

+ (UIAction * _Nonnull)_cp_queue_toggleDepthMapFilteringActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureDepthDataOutput * _Nullable depthDataOutput = [captureService queue_depthDataOutputFromCaptureDevice:captureDevice];
    AVCaptureConnection * _Nullable connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    assert((depthDataOutput == nil && connection == nil) || (depthDataOutput != nil && connection != nil));
    
    BOOL isUpdating;
    if (connection == nil) {
        isUpdating = NO;
    } else {
        isUpdating = connection.isEnabled;
    }
    
    BOOL isFilteringEnabled;
    if (depthDataOutput == nil) {
        isFilteringEnabled = NO;
    } else {
        isFilteringEnabled = depthDataOutput.isFilteringEnabled;
    }
    
    UIAction *action = [UIAction actionWithTitle:@"Depth Map Filtering" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            depthDataOutput.filteringEnabled = !isFilteringEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isFilteringEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isUpdating ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_centerStageMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                         captureDevice:captureDevice
                                                                 title:@"Center Stage Supported Formats"
                                                       includeSubtitle:NO
                                                         filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
            return format.centerStageSupported;
        }
                                                      didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleCenterStageActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleCenterStageActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isCenterStageSupported = captureDevice.activeFormat.isCenterStageSupported;
    BOOL isCenterStageActive = captureDevice.isCenterStageActive;
    
    AVCaptureDevice.centerStageControlMode = AVCaptureCenterStageControlModeCooperative;
    
    UIAction *action = [UIAction actionWithTitle:@"Center Stage" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            AVCaptureDevice.centerStageEnabled = !isCenterStageActive;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = isCenterStageSupported ? 0 : UIMenuElementAttributesDisabled;
    action.state = isCenterStageActive ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (std::vector<AVCaptureAutoFocusSystem>)_cp_allAutoFocusSystemsVector {
    return {
        AVCaptureAutoFocusSystemNone,
        AVCaptureAutoFocusSystemContrastDetection,
        AVCaptureAutoFocusSystemPhaseDetection
    };
}

+ (UIMenu * _Nonnull)_cp_queue_focusMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Focus"
                                children:@[
        [UIDeferredMenuElement _cp_queue_lensPositionSliderElementWithCaptureService:captureService captureDevice:captureDevice],
        [UIDeferredMenuElement _cp_queue_formatsByAutoFocusSystemMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setFocusModeMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleSmoothAutoFocusActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleFaceDrivenAutoFocusActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleAutomaticallyAdjustsFaceDrivenAutoFocusActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setAutoFocusRangeRestrictionMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_minimumFocusDistanceActionWithCaptureDevice:captureDevice]
    ]];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_formatsByAutoFocusSystemMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    auto menusVector = [UIDeferredMenuElement _cp_allAutoFocusSystemsVector]
    | std::views::transform([captureService, captureDevice, didChangeHandler](AVCaptureAutoFocusSystem focusSystem) -> UIMenu * {
        UIMenu *menu = [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                                        captureDevice:captureDevice
                                                                                title:NSStringFromAVCaptureAutoFocusSystem(focusSystem)
                                                                      includeSubtitle:NO
                                                                        filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
            return format.autoFocusSystem == focusSystem;
        }
                                                                     didChangeHandler:didChangeHandler];
        
        return menu;
    })
    | std::ranges::to<std::vector<UIMenu *>>();
    
    NSArray<UIMenu *> *menus = [[NSArray alloc] initWithObjects:menusVector.data() count:menusVector.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Formats By Auto Focus System"
                                   image:nil
                              identifier:nil
                                 options:0
                                children:menus];
    
    [menus release];
    
    return menu;
}

+ (std::vector<AVCaptureFocusMode>)_cp_allFocusModesVector {
    return {
        AVCaptureFocusModeLocked,
        AVCaptureFocusModeAutoFocus,
        AVCaptureFocusModeContinuousAutoFocus
    };
}

+ (UIMenu * _Nonnull)_cp_queue_setFocusModeMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureFocusMode currentFocusMode = captureDevice.focusMode;
    
    auto actionsVector = [UIDeferredMenuElement _cp_allFocusModesVector]
    | std::views::transform([captureService, captureDevice, didChangeHandler, currentFocusMode](AVCaptureFocusMode focusMode) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureFocusMode(focusMode)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.focusMode = focusMode;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.state = (currentFocusMode == focusMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = [captureDevice isFocusModeSupported:focusMode] ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    }) | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVector.data() count:actionsVector.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Focus Mode" image:nil identifier:nil options:0 children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVCaptureFocusMode(currentFocusMode);
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleSmoothAutoFocusActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isSmoothAutoFocusEnabled = captureDevice.isSmoothAutoFocusEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Smooth Auto Focus" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.smoothAutoFocusEnabled = !isSmoothAutoFocusEnabled;
            [captureDevice unlockForConfiguration];
        });
    }];
    
    action.state = isSmoothAutoFocusEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = (captureDevice.isSmoothAutoFocusSupported ? 0 : UIMenuElementAttributesDisabled);
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleFaceDrivenAutoFocusActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isFaceDrivenAutoFocusEnabled = captureDevice.isFaceDrivenAutoFocusEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Face Driven Auto Focus" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.faceDrivenAutoFocusEnabled = !isFaceDrivenAutoFocusEnabled;
            [captureDevice unlockForConfiguration];
        });
    }];
    
    action.state = isFaceDrivenAutoFocusEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = captureDevice.automaticallyAdjustsFaceDrivenAutoFocusEnabled ? UIMenuElementAttributesDisabled : 0;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAutomaticallyAdjustsFaceDrivenAutoFocusActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL automaticallyAdjustsFaceDrivenAutoFocusEnabled = captureDevice.automaticallyAdjustsFaceDrivenAutoFocusEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Automatically Adjusts Face Driven Auto Focus" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.automaticallyAdjustsFaceDrivenAutoFocusEnabled = !automaticallyAdjustsFaceDrivenAutoFocusEnabled;
            [captureDevice unlockForConfiguration];
        });
    }];
    
    action.state = automaticallyAdjustsFaceDrivenAutoFocusEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (std::vector<AVCaptureAutoFocusRangeRestriction>)_cp_allAutoFocusRangeRestrictionsVector {
    return {
        AVCaptureAutoFocusRangeRestrictionNone,
        AVCaptureAutoFocusRangeRestrictionNear,
        AVCaptureAutoFocusRangeRestrictionFar
    };
}

+ (UIMenu * _Nonnull)_cp_queue_setAutoFocusRangeRestrictionMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isAutoFocusRangeRestrictionSupported = captureDevice.isAutoFocusRangeRestrictionSupported;
    AVCaptureAutoFocusRangeRestriction currentAutoFocusRangeRestriction = captureDevice.autoFocusRangeRestriction;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allAutoFocusRangeRestrictionsVector]
    | std::views::transform([captureService, captureDevice, didChangeHandler, isAutoFocusRangeRestrictionSupported, currentAutoFocusRangeRestriction](AVCaptureAutoFocusRangeRestriction autoFocusRangeRestriction) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureAutoFocusRangeRestriction(autoFocusRangeRestriction)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.autoFocusRangeRestriction = autoFocusRangeRestriction;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.state = (autoFocusRangeRestriction == currentAutoFocusRangeRestriction) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = isAutoFocusRangeRestrictionSupported ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"AutoFocusRangeRestriction" image:nil identifier:nil options:0 children:actions];
    [actions release];
    menu.subtitle = NSStringFromAVCaptureAutoFocusRangeRestriction(currentAutoFocusRangeRestriction);
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_minimumFocusDistanceActionWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    UIAction *action = [UIAction actionWithTitle:[NSString stringWithFormat:@"minimumFocusDistance: %ld%@", captureDevice.minimumFocusDistance, NSUnitLength.millimeters.symbol]
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {}];
    
    action.attributes = UIMenuElementAttributesDisabled;
    
    return action;
}

+ (__kindof UIMenuElement *)_cp_queue_lensPositionSliderElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    BOOL isSupported = [captureDevice isFocusModeSupported:AVCaptureFocusModeLocked];
    float lensPosition = captureDevice.lensPosition;
    
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        if (isSupported) {
            slider.minimumValue = 0.f;
            slider.maximumValue = 1.f;
            slider.value = lensPosition;
            slider.continuous = YES;
            
            UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                auto sender = static_cast<UISlider *>(action.sender);
                float lensPosition = sender.value;
                
                dispatch_async(captureService.captureSessionQueue, ^{
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    
                    captureDevice.focusMode = AVCaptureFocusModeLocked;
                    [captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:^(CMTime syncTime) {
                        
                    }];
                    
                    [captureDevice unlockForConfiguration];
                });
            }];
            
            [slider addAction:action forControlEvents:UIControlEventValueChanged];
        } else {
            slider.enabled = NO;
        }
        
        return [slider autorelease];
    });
    
    return element;
}

+ (UIMenu * _Nonnull)_cp_queue_exposureBracketedStillImageSettingsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    for (__kindof AVCaptureBracketedStillImageSettings *settings in photoFormatModel.bracketedSettings) {
        UIAction *removeAction = [UIAction actionWithTitle:@"Remove" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                NSMutableArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings = [copy.bracketedSettings mutableCopy];
                [bracketedSettings removeObject:settings];
                copy.bracketedSettings = bracketedSettings;
                [bracketedSettings release];
                
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        removeAction.attributes = UIMenuElementAttributesDestructive;
        
        NSString *title;
        if (settings.class == AVCaptureAutoExposureBracketedStillImageSettings.class) {
            auto casted = static_cast<AVCaptureAutoExposureBracketedStillImageSettings *>(settings);
            title = [NSString stringWithFormat:@"Auto - exposureTargetBias: %lf", casted.exposureTargetBias];
        } else if (settings.class == AVCaptureManualExposureBracketedStillImageSettings.class) {
            auto casted = static_cast<AVCaptureManualExposureBracketedStillImageSettings *>(settings);
            CFStringRef descStr = CMTimeCopyDescription(kCFAllocatorDefault, casted.exposureDuration);
            title = [NSString stringWithFormat:@"Manual - ISO: %lf, exposureDuration: %@", casted.ISO, (id)descStr];
            CFRelease(descStr);
        } else {
            abort();
        }
        
        UIMenu *submenu = [UIMenu menuWithTitle:title children:@[removeAction]];
        submenu.cp_overrideNumberOfTitleLines = @(0);
        
        [children addObject:submenu];
    }
    
    //
    
    float minExposureTargetBias = captureDevice.minExposureTargetBias;
    float maxExposureTargetBias = captureDevice.maxExposureTargetBias;
    float exposureTargetBias = captureDevice.exposureTargetBias;
    
    UIDeferredMenuElement *autoExposureBracketedStillImageSettingsElement = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        UISlider *slider = [UISlider new];
        
        slider.minimumValue = minExposureTargetBias;
        slider.maximumValue = maxExposureTargetBias;
        slider.value = exposureTargetBias;
        
        __kindof UIMenuElement *sliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return slider;
        });
        
        UIAction *addAction = [UIAction actionWithTitle:@"Add" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            float value = slider.value;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                
                AVCaptureAutoExposureBracketedStillImageSettings *settings = [AVCaptureAutoExposureBracketedStillImageSettings autoExposureSettingsWithExposureTargetBias:value];
                
                NSMutableArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings = [copy.bracketedSettings mutableCopy];
                [bracketedSettings addObject:settings];
                copy.bracketedSettings = bracketedSettings;
                [bracketedSettings release];
                
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [slider release];
        
        UIMenu *submenu = [UIMenu menuWithTitle:@"Add Auto Exposure Bracketed Still Image Settings" children:@[
            sliderElement,
            addAction
        ]];
        
        submenu.cp_overrideNumberOfTitleLines = @(0);
        
        completion(@[submenu]);
    }];
    
    [children addObject:autoExposureBracketedStillImageSettingsElement];
    
    //
    
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    float maxISO = activeFormat.maxISO;
    float minISO = activeFormat.minISO;
    float ISO = captureDevice.ISO;
    CMTime maxExposureDuration = activeFormat.maxExposureDuration;
    CMTime minExposureDuration = activeFormat.minExposureDuration;
    CMTime exposureDuration = captureDevice.exposureDuration;
    
    UIDeferredMenuElement *manualExposureBracketedStillImageSettingsElement = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        UISlider *ISOSlider = [UISlider new];
        ISOSlider.maximumValue = maxISO;
        ISOSlider.minimumValue = minISO;
        ISOSlider.value = ISO;
        
        UISlider *exposureDurationSlider = [UISlider new];
        exposureDurationSlider.maximumValue = CMTimeGetSeconds(maxExposureDuration);
        exposureDurationSlider.minimumValue = CMTimeGetSeconds(minExposureDuration);
        exposureDurationSlider.value = CMTimeGetSeconds(exposureDuration);
        
        __kindof UIMenuElement *ISOSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return ISOSlider;
        });
        
        __kindof UIMenuElement *exposureDurationSliderElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
            return exposureDurationSlider;
        });
        
        UIAction *addAction = [UIAction actionWithTitle:@"Add" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            float ISO = ISOSlider.value;
            float exposureDurationSeconds = exposureDurationSlider.value;
            CMTime exposureDuration = CMTimeMakeWithSeconds(exposureDurationSeconds, 1);
            
            dispatch_async(captureService.captureSessionQueue, ^{
                PhotoFormatModel *copy = [photoFormatModel copy];
                
                AVCaptureManualExposureBracketedStillImageSettings *settings = [AVCaptureManualExposureBracketedStillImageSettings manualExposureSettingsWithExposureDuration:exposureDuration ISO:ISO];
                
                NSMutableArray<__kindof AVCaptureBracketedStillImageSettings *> *bracketedSettings = [copy.bracketedSettings mutableCopy];
                [bracketedSettings addObject:settings];
                copy.bracketedSettings = bracketedSettings;
                [bracketedSettings release];
                
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        [ISOSlider release];
        [exposureDurationSlider release];
        
        UIMenu *submenu = [UIMenu menuWithTitle:@"Add Manual Exposure Bracketed Still Image Settings" children:@[
            ISOSliderElement,
            exposureDurationSliderElement,
            addAction
        ]];
        
        submenu.cp_overrideNumberOfTitleLines = @(0);
        
        completion(@[submenu]);
    }];
    
    [children addObject:manualExposureBracketedStillImageSettingsElement];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Bracketed Settings" children:children];
    [children release];
    
    menu.subtitle = @(photoFormatModel.bracketedSettings.count).stringValue;
    
    return menu;
}

@end
