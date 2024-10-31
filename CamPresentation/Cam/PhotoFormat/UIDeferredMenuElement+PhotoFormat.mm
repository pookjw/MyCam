//
//  UIDeferredMenuElement+PhotoFormat.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/29/24.
//

#import <CamPresentation/UIDeferredMenuElement+PhotoFormat.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

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
#import <CamPresentation/NSStringFromAVCaptureExposureMode.h>
#import <CamPresentation/NSStringFromAVCaptureSystemUserInterface.h>
#import <CamPresentation/NSStringFromAVCaptureWhiteBalanceMode.h>
#import <CamPresentation/CaptureDeviceZoomInfoView.h>
#import <CamPresentation/CaptureDeviceExposureSlidersView.h>
#import <CamPresentation/CaptureDeviceFrameRateRangeInfoView.h>
#import <CamPresentation/CaptureDeviceWhiteBalanceInfoView.h>
#import <CamPresentation/CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView.h>
#import <CamPresentation/CaptureDeviceWhiteBalanceChromaticitySlidersView.h>
#import <CamPresentation/CaptureDeviceLowLightBoostInfoView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <CoreMedia/CoreMedia.h>
#include <vector>
#include <ranges>

AVF_EXPORT AVMediaType const AVMediaTypeVisionData;
AVF_EXPORT AVMediaType const AVMediaTypePointCloudData;
AVF_EXPORT AVMediaType const AVMediaTypeCameraCalibrationData;

#warning AVSpatialOverCaptureVideoPreviewLayer
#warning -[AVCaptureDevice isProResSupported]
#warning videoMirrored
#warning lensAperture
#warning backgroundReplacementSupported, autoVideoFrameRateSupported

@implementation UIDeferredMenuElement (PhotoFormat)

+ (instancetype)cp_photoFormatElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIDeferredMenuElement *result = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        dispatch_async(captureService.captureSessionQueue, ^{
            PhotoFormatModel *photoFormatModel = [captureService queue_photoFormatModelForCaptureDevice:captureDevice];
            AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
            assert(photoOutput != nil);
            
            NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_photoMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_movieMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_assetWriterMenuWithCaptureService:captureService videoDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_zoomMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_flashModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_torchModesMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService captureDevice:captureDevice title:@"Format" includeSubtitle:YES filterHandler:nil didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_depthMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_visionMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_metadataObjectTypesMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_formatsByColorSpaceMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_activeColorSpacesMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_toggleCameraIntrinsicMatrixDeliveryActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_toggleGeometricDistortionCorrectionActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_cameraIntrinsicMatrixDeliverySupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_reactionEffectsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_centerStageMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_focusMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_exposureMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_whiteBalanceMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_videoFrameRateMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_lowLightBoostMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_lowLightVideoCaptureMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_videoGreenGhostMitigationMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_videoHDRMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_portraitEffectSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_studioLightSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_backgroundReplacementSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_queue_smartStyleRenderingSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
            
            [elements addObject:[UIDeferredMenuElement _cp_showSystemUserInterfaceMenu]];
            
#warning TODO: autoVideoFrameRateEnabled
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(elements);
            });
            
            [elements release];
        });
    }];
    
    return result;
}

+ (UIMenu * _Nonnull)_cp_queue_photoMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    PhotoFormatModel *photoFormatModel = [captureService queue_photoFormatModelForCaptureDevice:captureDevice];
    AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
    
    //
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_capturePhotoWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_livePhotoMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_setAudioDeviceForPhotoOutputWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
    
    for (AVCaptureDeviceInput *deviceInput in [captureService queue_audioDeviceInputsForOutput:photoOutput]) {
        [elements addObject:[UIDeferredMenuElement _cp_queue_toggleWindNoiseRemovalEnabledWithDeviceInput:deviceInput captureService:captureService didChangeHandler:didChangeHandler]];
    }
    
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
    
#if !TARGET_OS_MACCATALYST
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleDeferredPhotoDeliveryActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
#endif
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleZeroShutterLagActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleResponsiveCaptureActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleFastCapturePrioritizationActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_photoQualityPrioritizationMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleCameraCalibrationDataDeliveryActionWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_cameraCalibrationDataDeliverySupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleVirtualDeviceConstituentPhotoDeliveryActionWithCaptureService:captureService photoOutput:photoOutput didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_toggleDepthDataDeliveryEnabledActionWithCaptureService:captureService photoOutput:photoOutput photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_exposureBracketedStillImageSettingsElementWithCaptureService:captureService captureDevice:captureDevice photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Photo" children:elements];
    [elements release];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_movieMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMovieFileOutput * _Nullable movieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
    
    NSMutableArray<__kindof UIMenuElement *> *elements = [NSMutableArray new];
    
    [elements addObject:[UIDeferredMenuElement _cp_queue_configureMovieFileOutputActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
    
    if (movieFileOutput != nil) {
        [elements addObject:[UIDeferredMenuElement _cp_queue_movieRecordingMenuWithCaptureService:captureService captureDevice:captureDevice movieFileOutput:movieFileOutput]];
        
        [elements addObject:[UIDeferredMenuElement _cp_queue_setAudioDeviceForMovieFileOutputWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
        
        for (AVCaptureDeviceInput *deviceInput in [captureService queue_audioDeviceInputsForOutput:movieFileOutput]) {
            [elements addObject:[UIDeferredMenuElement _cp_queue_toggleWindNoiseRemovalEnabledWithDeviceInput:deviceInput captureService:captureService didChangeHandler:didChangeHandler]];
        }
        
        [elements addObject:[UIDeferredMenuElement _cp_queue_movieOutputSettingsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]];
        
        [elements addObject:[UIDeferredMenuElement _cp_queue_toggleSpatialVideoCaptureActionWithCaptureService:captureService captureDevice:captureDevice movieFileOutput:movieFileOutput didChangeHandler:didChangeHandler]];
        
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
    }
    
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
            MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
            
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
            MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
                
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

#if !TARGET_OS_MACCATALYST
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
#endif

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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
        
        action.cp_overrideNumberOfTitleLines = 0;
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
    
    menu.cp_overrideNumberOfTitleLines = 0;
    
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

+ (UIAction * _Nonnull)_cp_queue_toggleSpatialVideoCaptureActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice movieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput didChangeHandler:(void (^)())didChangeHandler {
    BOOL isSpatialVideoCaptureEnabled = movieFileOutput.isSpatialVideoCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Spatial Video Capture" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            movieFileOutput.spatialVideoCaptureEnabled = !isSpatialVideoCaptureEnabled;
        });
    }];
    
    action.state = isSpatialVideoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = movieFileOutput.isSpatialVideoCaptureSupported ? 0 : UIMenuElementAttributesDisabled;
    
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
    
    menu.cp_overrideNumberOfTitleLines = 0;
    
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
    CGFloat minAvailableVideoZoomFactor = captureDevice.minAvailableVideoZoomFactor;
    CGFloat maxAvailableVideoZoomFactor = captureDevice.maxAvailableVideoZoomFactor;
    
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
        
        UISlider *videoZoomFactorSlider = [UISlider new];
        videoZoomFactorSlider.minimumValue = minAvailableVideoZoomFactor;
        videoZoomFactorSlider.maximumValue = maxAvailableVideoZoomFactor;
        videoZoomFactorSlider.value = videoZoomFactor;
        if ([systemRecommendedVideoZoomRange containsZoomFactor:videoZoomFactor]) {
            videoZoomFactorSlider.tintColor = UIColor.systemGreenColor;
        } else {
            videoZoomFactorSlider.tintColor = UIColor.systemRedColor;
        }
        
        __kindof NSValue *videoZoomFactorSliderValue = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("NSWeakObjectValue") alloc], sel_registerName("initWithObject:"), videoZoomFactorSlider);
        [allSliderValues addObject:videoZoomFactorSliderValue];
        [videoZoomFactorSliderValue release];
        
        //
        
        NSMutableArray<UISlider *> *videoZoomRangesForDepthDataDeliverySliders = [[NSMutableArray alloc] initWithCapacity:supportedVideoZoomRangesForDepthDataDelivery.count];
        
        for (AVZoomRange *range in supportedVideoZoomRangesForDepthDataDelivery) {
            UISlider *slider = [UISlider new];
            slider.minimumValue = range.minZoomFactor;
            slider.maximumValue = range.maxZoomFactor;
            slider.value = videoZoomFactor;
            if ([systemRecommendedVideoZoomRange containsZoomFactor:videoZoomFactor]) {
                slider.tintColor = UIColor.systemGreenColor;
            } else {
                slider.tintColor = UIColor.systemRedColor;
            }
            
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
            if ([systemRecommendedVideoZoomRange containsZoomFactor:videoZoomFactor]) {
                videoZoomFactorForCenterStageSlider.tintColor = UIColor.systemGreenColor;
            } else {
                videoZoomFactorForCenterStageSlider.tintColor = UIColor.systemRedColor;
            }
            
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
            
            for (__kindof NSValue *sliderValue in allSliderValues) {
                UISlider * _Nullable slider = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(sliderValue, sel_registerName("weakObjectValue"));
                if (!slider.isTracking) {
                    slider.value = value;
                }
                
                if ([systemRecommendedVideoZoomRange containsZoomFactor:value]) {
                    slider.tintColor = UIColor.systemGreenColor;
                } else {
                    slider.tintColor = UIColor.systemRedColor;
                }
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
            return videoZoomFactorSlider;
        });
        [videoZoomFactorSlider release];
        
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
        videoZoomFactorUpscaleThresholdAction.cp_overrideNumberOfTitleLines = 0;
        
        //
        
        UIAction *cancelVideoZoomRampAction = [UIAction actionWithTitle:@"Cancel Video Zoom Ramp" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                [captureDevice cancelVideoZoomRamp];
                [captureDevice unlockForConfiguration];
            });
        }];
        
        cancelVideoZoomRampAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        //
        
        UIMenu *menu = [UIMenu menuWithTitle:@"Zoom Sliders" children:@[
            infoViewElement,
            systemRecommendedVideoZoomRangeSliderMenu,
            secondaryNativeResolutionZoomFactorsMenu,
            videoZoomRangesForDepthDataDeliverySlidersMenu,
            virtualDeviceSwitchOverVideoZoomFactorsMenu,
            videoZoomFactorForCenterStageSliderMenu,
            videoZoomFactorUpscaleThresholdAction,
            cancelVideoZoomRampAction
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
            MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
        action.cp_overrideNumberOfSubtitleLines = 0;
    }
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_depthMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Depth Map" children:@[
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
        
        action.cp_overrideNumberOfTitleLines = 0;
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
    AVCaptureDepthDataOutput * _Nullable depthDataOutput = [captureService queue_outputClass:AVCaptureDepthDataOutput.class fromCaptureDevice:captureDevice];
    
    if (depthDataOutput == nil) {
        UIAction *action = [UIAction actionWithTitle:@"No Depth Data Output" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.attributes = UIMenuElementAttributesDisabled;
        
        return action;
    }
    
    AVCaptureConnection * _Nullable connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
    BOOL isEnabled = [captureService queue_updatesDepthMapLayer:captureDevice];
    
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
    AVCaptureDepthDataOutput * _Nullable depthDataOutput = [captureService queue_outputClass:AVCaptureDepthDataOutput.class fromCaptureDevice:captureDevice];
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
        
        slider.minimumValue = 0.f;
        slider.maximumValue = 1.f;
        slider.value = lensPosition;
        slider.continuous = YES;
        slider.enabled = isSupported;
        
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
        
        return [slider autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement * _Nonnull)_cp_queue_exposureBracketedStillImageSettingsElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    if (!photoFormatModel.isRAWEnabled) {
        UIAction *action = [UIAction actionWithTitle:@"Bracketed Settings" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.attributes = UIMenuElementAttributesDisabled;
        action.subtitle = @"Requires RAW";
        
        return action;
    }
    
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    // All elements in the bracketed capture settings array must be of the same class
    Class _Nullable addedClass = nil;
    
    for (__kindof AVCaptureBracketedStillImageSettings *settings in photoFormatModel.bracketedSettings) {
        if (addedClass == nil) {
            addedClass = settings.class;
        } else {
            assert(addedClass == settings.class);
        }
        
        UIAction *removeAction = [UIAction actionWithTitle:@"Remove" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
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
        submenu.cp_overrideNumberOfTitleLines = 0;
        
        [children addObject:submenu];
    }
    
    //
    
    if (addedClass == nil || addedClass == AVCaptureAutoExposureBracketedStillImageSettings.class) {
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
                    MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
                    
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
            
            submenu.cp_overrideNumberOfTitleLines = 0;
            
            completion(@[submenu]);
        }];
        
        [children addObject:autoExposureBracketedStillImageSettingsElement];
    }
    
    //
    
    if (addedClass == nil || addedClass == AVCaptureManualExposureBracketedStillImageSettings.class) {
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
            CMTimeShow(minExposureDuration);
            CMTimeShow(maxExposureDuration);
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
                CMTime exposureDuration = CMTimeMakeWithSeconds(exposureDurationSeconds, minExposureDuration.timescale);
                
                int32_t compareResult = CMTimeCompare(minExposureDuration, exposureDuration);
                assert((compareResult == -1) || (compareResult == 0));
                
                dispatch_async(captureService.captureSessionQueue, ^{
                    MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
                    
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
            
            submenu.cp_overrideNumberOfTitleLines = 0;
            
            completion(@[submenu]);
        }];
        
        [children addObject:manualExposureBracketedStillImageSettingsElement];
    }
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Bracketed Settings" children:children];
    [children release];
    
    menu.subtitle = @(photoFormatModel.bracketedSettings.count).stringValue;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_setAudioDeviceForMovieFileOutputWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    AVCaptureMovieFileOutput *movieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice];
    assert(movieFileOutput != nil);
    
    NSArray<AVCaptureDevice *> *addedAudioCaptureDevices = captureService.queue_addedAudioCaptureDevices;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:addedAudioCaptureDevices.count];
    
    for (AVCaptureDevice *audioDevice in addedAudioCaptureDevices) {
        AVCaptureMovieFileOutput * _Nullable connectedMovileFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:audioDevice];
        
        UIAction *action = [UIAction actionWithTitle:audioDevice.localizedName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                if ([connectedMovileFileOutput isEqual:movieFileOutput]) {
                    [captureService queue_disconnectAudioDevice:audioDevice fromOutput:movieFileOutput];
                } else {
                    [captureService queue_connectAudioDevice:audioDevice withOutput:movieFileOutput];
                }
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = ([connectedMovileFileOutput isEqual:movieFileOutput]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Device" children:actions];
    [actions release];
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    for (AVCaptureDevice *device in [captureService queue_captureDevicesFromOutput:movieFileOutput]) {
        if ([allAudioDeviceTypes containsObject:device.deviceType]) {
            menu.subtitle = device.localizedName;
            break;
        }
    }
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_visionMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Vision Data" children:@[
        [UIDeferredMenuElement _cp_queue_visionDataDeliverySupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_visionDataDeliveryNotSupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleVisionVisibilityActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_visionLayerOpacitySliderElementWithCaptureService:captureService captureDevice:captureDevice]
    ]];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_visionDataDeliverySupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Formats Supported Vision Data Delivery"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isVisionDataDeliverySupported"));
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_visionDataDeliveryNotSupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Formats Not Supported Vision Data Delivery"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return !reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isVisionDataDeliverySupported"));
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_toggleVisionVisibilityActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    __kindof AVCaptureOutput * _Nullable visionDataOutput = [captureService queue_outputClass:objc_lookUpClass("AVCaptureVisionDataOutput") fromCaptureDevice:captureDevice];
    
    if (visionDataOutput == nil) {
        UIAction *action = [UIAction actionWithTitle:@"No Vision Data Output" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        if ([captureService queue_outputClass:AVCaptureDepthDataOutput.class fromCaptureDevice:captureDevice] != nil) {
            action.subtitle = @"Not Supported with Device which has Depth Port";
        }
        
        action.attributes = UIMenuElementAttributesDisabled;
        
        return action;
    }
    
    AVCaptureConnection * _Nullable connection = [visionDataOutput connectionWithMediaType:AVMediaTypeVisionData];
    BOOL isEnabled = [captureService queue_updatesVisionLayer:captureDevice];
    
    UIAction *action = [UIAction actionWithTitle:@"Vision Data Visibility" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            [captureService queue_setUpdatesVisionLayer:!isEnabled captureDevice:captureDevice];
            
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

+ (__kindof UIMenuElement *)_cp_queue_visionLayerOpacitySliderElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof CALayer *layer = [captureService queue_visionLayerFromCaptureDevice:captureDevice];
    
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

+ (__kindof UIMenuElement * _Nonnull)_cp_queue_metadataObjectTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    AVCaptureMetadataOutput * _Nullable metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    
    if (metadataOutput == nil) {
        UIAction *action = [UIAction actionWithTitle:@"Metadata Object Types" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.attributes = UIMenuElementAttributesDisabled;
        action.subtitle = @"No Metadata Output";
        
        return action;
    }
    
    NSArray<AVMetadataObjectType> *availableMetadataObjectTypes = metadataOutput.availableMetadataObjectTypes;
    NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
    
    for (AVMetadataObjectType metadataObjectType in availableMetadataObjectTypes) {
        BOOL contains = [metadataOutput.metadataObjectTypes containsObject:metadataObjectType];
        
        UIAction *action = [UIAction actionWithTitle:metadataObjectType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSMutableArray<AVMetadataObjectType> *metadataObjectTypes = [metadataOutput.metadataObjectTypes mutableCopy];
                
                if (contains) {
                    [metadataObjectTypes removeObject:metadataObjectType];
                } else {
                    [metadataObjectTypes addObject:metadataObjectType];
                }
                
                metadataOutput.metadataObjectTypes = metadataObjectTypes;
                [metadataObjectTypes release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = contains ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [children addObject:action];
    }
    
    //
    
    UIAction *selectAllAction = [UIAction actionWithTitle:@"Select All" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    UIAction *deselectAllAction = [UIAction actionWithTitle:@"Deselect All" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            metadataOutput.metadataObjectTypes = @[];
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    UIMenu *submenu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        selectAllAction,
        deselectAllAction,
        [UIDeferredMenuElement _cp_queue_additionalFaceDetectionFeaturesMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
    
    [children addObject:submenu];
    
    //
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Metadata Object Types" children:children];
    [children release];
    
    menu.subtitle = [NSString stringWithFormat:@"%ld types selected", metadataOutput.metadataObjectTypes.count];
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_livePhotoMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoOutput:(AVCapturePhotoOutput *)photoOutput photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Live Photo" children:@[
        [UIDeferredMenuElement _cp_queue_toggleLivePhotoCaptureEnabledActionWithCaptureService:captureService photoOutput:photoOutput didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_livePhotoSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleLivePhotoCaptureSuspendedActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleLivePhotoAutoTrimmingEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_livePhotoVideoCodecTypesMenuWithCaptureService:captureService captureDevice:captureDevice photoFormatModel:photoFormatModel didChangeHandler:didChangeHandler]
    ]];
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleLivePhotoCaptureEnabledActionWithCaptureService:(CaptureService *)captureService photoOutput:(AVCapturePhotoOutput *)photoOutput didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    if (!photoOutput.isLivePhotoCaptureSupported) {
        UIAction *action = [UIAction actionWithTitle:@"Enable Live Photo" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        action.attributes = UIMenuElementAttributesDisabled;
        
        return action;
    }
    
    BOOL isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Live Photo" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.livePhotoCaptureEnabled = !isLivePhotoCaptureEnabled;
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isLivePhotoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_setAudioDeviceForPhotoOutputWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^ _Nullable)(void))didChangeHandler {
    AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    NSArray<AVCaptureDevice *> *addedAudioCaptureDevices = captureService.queue_addedAudioCaptureDevices;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:addedAudioCaptureDevices.count];
    
    for (AVCaptureDevice *audioDevice in addedAudioCaptureDevices) {
        AVCapturePhotoOutput * _Nullable connectedPhotoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
        
        UIAction *action = [UIAction actionWithTitle:audioDevice.localizedName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                if ([connectedPhotoOutput isEqual:photoOutput]) {
                    [captureService queue_disconnectAudioDevice:audioDevice fromOutput:photoOutput];
                } else {
                    [captureService queue_connectAudioDevice:audioDevice withOutput:photoOutput];
                }
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = ([connectedPhotoOutput isEqual:photoOutput]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Audio Device" children:actions];
    [actions release];
    
    NSArray<AVCaptureDeviceType> *allAudioDeviceTypes = reinterpret_cast<id (*)(Class, SEL)>(objc_msgSend)(AVCaptureDeviceDiscoverySession.class, sel_registerName("allAudioDeviceTypes"));
    
    for (AVCaptureDevice *device in [captureService queue_captureDevicesFromOutput:photoOutput]) {
        if ([allAudioDeviceTypes containsObject:device.deviceType]) {
            menu.subtitle = device.localizedName;
            break;
        }
    }
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_livePhotoSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Live Photo formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        // -[AVCapturePhotoOutput _updateLivePhotoCaptureSupportedForSourceDevice:]
        BOOL isIrisSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isIrisSupported"));
        BOOL isPhotoFormat = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isPhotoFormat"));
        
        return isIrisSupported && isPhotoFormat;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_configureMovieFileOutputActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL hasMovieFileOutput = [captureService queue_movieFileOutputFromCaptureDevice:captureDevice] != nil;
    
    UIAction *action = [UIAction actionWithTitle:hasMovieFileOutput ? @"Remove Movie File Output" : @"Add Movie File Output"
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            if (hasMovieFileOutput) {
                [captureService queue_removeMovieFileOutputWithCaptureDevice:captureDevice];
            } else {
                assert([captureService queue_addMovieFileOutputWithCaptureDevice:captureDevice] != nil);
            }
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = hasMovieFileOutput ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleLivePhotoCaptureSuspendedActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    BOOL isLivePhotoCaptureSuspended = photoOutput.isLivePhotoCaptureSuspended;
    BOOL isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Live Photo Capture Suspended" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.livePhotoCaptureSuspended = !isLivePhotoCaptureSuspended;
        });
    }];
    
    action.state = isLivePhotoCaptureSuspended ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isLivePhotoCaptureEnabled ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleLivePhotoAutoTrimmingEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    BOOL isLivePhotoAutoTrimmingEnabled = photoOutput.isLivePhotoAutoTrimmingEnabled;
    BOOL isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Live Photo Auto Trimming Enabled" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            photoOutput.livePhotoAutoTrimmingEnabled = !isLivePhotoAutoTrimmingEnabled;
        });
    }];
    
    action.state = isLivePhotoAutoTrimmingEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isLivePhotoCaptureEnabled ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_livePhotoVideoCodecTypesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice photoFormatModel:(PhotoFormatModel *)photoFormatModel didChangeHandler:(void (^)())didChangeHandler {
    AVCapturePhotoOutput *photoOutput = [captureService queue_outputClass:AVCapturePhotoOutput.class fromCaptureDevice:captureDevice];
    assert(photoOutput != nil);
    
    NSArray<AVVideoCodecType> *availableLivePhotoVideoCodecTypes = photoOutput.availableLivePhotoVideoCodecTypes;
    AVVideoCodecType livePhotoVideoCodecType = photoFormatModel.livePhotoVideoCodecType;
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:availableLivePhotoVideoCodecTypes.count];
    
    for (AVVideoCodecType codecType in availableLivePhotoVideoCodecTypes) {
        UIAction *action = [UIAction actionWithTitle:codecType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                MutablePhotoFormatModel *copy = [photoFormatModel mutableCopy];
                copy.livePhotoVideoCodecType = codecType;
                [captureService queue_setPhotoFormatModel:copy forCaptureDevice:captureDevice];
                [copy release];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = ([livePhotoVideoCodecType isEqualToString:codecType]) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [actions addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Live Photo Video Codec" children:actions];
    [actions release];
    
    menu.subtitle = livePhotoVideoCodecType;
    
    return menu;
}

+ (UIMenu * _Nonnull)_cp_queue_exposureMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Exposure"
                                children:@[
        [UIDeferredMenuElement _cp_queue_setExposureModeMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_exposureSlidersViewElementWithCaptureService:captureService captureDevice:captureDevice],
        [UIDeferredMenuElement _cp_queue_toggleUnifiedAutoExposureDefaultsEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
    
    return menu;
}

+ (std::vector<AVCaptureExposureMode>)_cp_allExposureModes {
    return {
        AVCaptureExposureModeLocked,
        AVCaptureExposureModeAutoExpose,
        AVCaptureExposureModeContinuousAutoExposure,
        AVCaptureExposureModeCustom,
    };
}

+ (UIMenu * _Nonnull)_cp_queue_setExposureModeMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureExposureMode currentExposureMode = captureDevice.exposureMode;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allExposureModes]
    | std::views::transform([captureService, captureDevice, currentExposureMode](AVCaptureExposureMode exposureMode) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureExposureMode(exposureMode) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.exposureMode = exposureMode;
                [captureDevice unlockForConfiguration];
            });
        }];
        
        action.state = (currentExposureMode == exposureMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = (([captureDevice isExposureModeSupported:exposureMode]) ? 0 : UIMenuElementAttributesDisabled) | UIMenuElementAttributesKeepsMenuPresented;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Exposure Mode" children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVCaptureExposureMode(currentExposureMode);
    
    return menu;
}

+ (__kindof UIMenuElement * _Nonnull)_cp_queue_exposureSlidersViewElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        CaptureDeviceExposureSlidersView *view = [[CaptureDeviceExposureSlidersView alloc] initWithCaptureService:captureService captureDevice:captureDevice];
        return [view autorelease];
    });
    
    return element;
}

+ (std::vector<AVCaptureSystemUserInterface>)_cp_allSystemUserInterfacesVector {
    return {
        AVCaptureSystemUserInterfaceVideoEffects,
        AVCaptureSystemUserInterfaceMicrophoneModes
    };
}

+ (UIMenu * _Nonnull)_cp_showSystemUserInterfaceMenu {
    auto actionsVec = [UIDeferredMenuElement _cp_allSystemUserInterfacesVector]
    | std::views::transform([](AVCaptureSystemUserInterface systemUserInterface) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureSystemUserInterface(systemUserInterface) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [AVCaptureDevice showSystemUserInterface:systemUserInterface];
        }];
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    UIMenu *menu = [UIMenu menuWithTitle:@"Show System User Interface" children:actions];
    [actions release];
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleUnifiedAutoExposureDefaultsEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureDeviceInput *deviceInput = nil;
    for (AVCaptureDeviceInput *_deviceInput in captureService.queue_captureSession.inputs) {
        if (![_deviceInput isKindOfClass:AVCaptureDeviceInput.class]) continue;
        if ([_deviceInput.device isEqual:captureDevice]) {
            deviceInput = _deviceInput;
            break;
        }
    }
    assert(deviceInput != nil);
    
    BOOL unifiedAutoExposureDefaultsEnabled = deviceInput.unifiedAutoExposureDefaultsEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Unified Auto Exposure Defaults Enabled" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            deviceInput.unifiedAutoExposureDefaultsEnabled = !unifiedAutoExposureDefaultsEnabled;
        });
    }];
    
    action.state = unifiedAutoExposureDefaultsEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
#warning https://developer.apple.com/documentation/avfoundation/avcapturedeviceinput/2968218-unifiedautoexposuredefaultsenabl (activeVideoMinFrameDuration에 reset 조건 적혀 있음)
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_videoFrameRateMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Video Frame Rate" children:@[
        [UIDeferredMenuElement _cp_queue_toggleAutoVideoFrameRateEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_autoVideoFrameRateSupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_activeVideoFrameDurationSlidersElementWithCaptureService:captureService captureDevice:captureDevice]
    ]];
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAutoVideoFrameRateEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isAutoVideoFrameRateEnabled = captureDevice.isAutoVideoFrameRateEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Auto Video Frame Rate" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.autoVideoFrameRateEnabled = !isAutoVideoFrameRateEnabled;
            [captureDevice unlockForConfiguration];
        });
    }];
    
    action.state = captureDevice.isAutoVideoFrameRateEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = captureDevice.activeFormat.isAutoVideoFrameRateSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_autoVideoFrameRateSupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Video Frame Rate Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isAutoVideoFrameRateSupported;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIDeferredMenuElement *)_cp_queue_activeVideoFrameDurationSlidersElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    AVCaptureDeviceFormat *activeFormat = captureDevice.activeFormat;
    NSArray<AVFrameRateRange *> *videoSupportedFrameRateRanges = activeFormat.videoSupportedFrameRateRanges;
    
    return [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        NSMutableArray<__kindof UIMenuElement *> *children = [[NSMutableArray alloc] initWithCapacity:videoSupportedFrameRateRanges.count];
        
        for (AVFrameRateRange *frameRateRange in videoSupportedFrameRateRanges) {
            __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
                CaptureDeviceFrameRateRangeInfoView *view = [[CaptureDeviceFrameRateRangeInfoView alloc] initWithCaptureService:captureService captureDevice:captureDevice frameRateRange:frameRateRange];
                return [view autorelease];
            });
            
            [children addObject:element];
        }
        
        UIMenu *menu = [UIMenu menuWithTitle:@"Active Video Frame Duration" children:children];
        [children release];
        
        completion(@[menu]);
    }];
}

+ (UIMenu * _Nonnull)_cp_queue_whiteBalanceMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"White Balance" children:@[
        [UIDeferredMenuElement _cp_queue_setWhiteBalanceModeMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIMenu menuWithTitle:@"Info" children:@[
            [UIDeferredMenuElement _cp_queue_whiteBalanceInfoViewElementWithCaptureService:captureService captureDevice:captureDevice]
        ]],
        [UIMenu menuWithTitle:@"Temperature And Tint Sliders" children:@[
            [UIDeferredMenuElement _cp_queue_temperatureAndTintSlidersViewElementWithCaptureService:captureService captureDevice:captureDevice]
        ]],
        [UIMenu menuWithTitle:@"Chromaticity Sliders" children:@[
            [UIDeferredMenuElement _cp_queue_chromaticitySlidersViewElementWithCaptureService:captureService captureDevice:captureDevice]
        ]]
    ]];
}

+ (std::vector<AVCaptureWhiteBalanceMode>)_cp_allWhiteBalanceModes {
    return {
        AVCaptureWhiteBalanceModeLocked,
        AVCaptureWhiteBalanceModeAutoWhiteBalance,
        AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance
    };
}

+ (UIMenu *)_cp_queue_setWhiteBalanceModeMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureWhiteBalanceMode currentWhiteBalanceMode = captureDevice.whiteBalanceMode;
    
    auto actionsVec = [UIDeferredMenuElement _cp_allWhiteBalanceModes]
    | std::views::transform([captureService, captureDevice, currentWhiteBalanceMode, didChangeHandler](AVCaptureWhiteBalanceMode whiteBalanceMode) -> UIAction * {
        UIAction *action = [UIAction actionWithTitle:NSStringFromAVCaptureWhiteBalanceMode(whiteBalanceMode)
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                captureDevice.whiteBalanceMode = whiteBalanceMode;
                [captureDevice unlockForConfiguration];
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = (currentWhiteBalanceMode == whiteBalanceMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = ([captureDevice isWhiteBalanceModeSupported:whiteBalanceMode]) ? 0 : UIMenuElementAttributesDisabled;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"White Balance Mode" children:actions];
    [actions release];
    
    menu.subtitle = NSStringFromAVCaptureWhiteBalanceMode(currentWhiteBalanceMode);
    
    return menu;
}

+ (__kindof UIMenuElement *)_cp_queue_whiteBalanceInfoViewElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        CaptureDeviceWhiteBalanceInfoView *view = [[CaptureDeviceWhiteBalanceInfoView alloc] initWithCaptureService:captureService captureDevice:captureDevice];
        return [view autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_queue_temperatureAndTintSlidersViewElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView *view = [[CaptureDeviceWhiteBalanceTemperatureAndTintSlidersView alloc] initWithCaptureService:captureService captureDevice:captureDevice];
        return [view autorelease];
    });
    
    return element;
}

+ (__kindof UIMenuElement *)_cp_queue_chromaticitySlidersViewElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        CaptureDeviceWhiteBalanceChromaticitySlidersView *view = [[CaptureDeviceWhiteBalanceChromaticitySlidersView alloc] initWithCaptureService:captureService captureDevice:captureDevice];
        return [view autorelease];
    });
    
    return element;
}

+ (UIMenu * _Nonnull)_cp_queue_lowLightBoostMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIMenu menuWithTitle:@"Low Light Boost" children:@[
        [UIDeferredMenuElement _cp_queue_toggleAutomaticallyEnablesLowLightBoostWhenAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_lowLightBoostInfoViewElementWithCaptureService:captureService captureDevice:captureDevice]
    ]];
    
    return menu;
}

+ (__kindof UIMenuElement * _Nonnull)_cp_queue_lowLightBoostInfoViewElementWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice {
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        CaptureDeviceLowLightBoostInfoView *view = [[CaptureDeviceLowLightBoostInfoView alloc] initWithCaptureService:captureService captureDevice:captureDevice];
        return [view autorelease];
    });
    
    return element;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAutomaticallyEnablesLowLightBoostWhenAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isLowLightBoostSupported = captureDevice.isLowLightBoostSupported;
    BOOL automaticallyEnablesLowLightBoostWhenAvailable = captureDevice.automaticallyEnablesLowLightBoostWhenAvailable;
    
    UIAction *action = [UIAction actionWithTitle:@"Automatically Enable" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = !automaticallyEnablesLowLightBoostWhenAvailable;
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = automaticallyEnablesLowLightBoostWhenAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    if (!isLowLightBoostSupported) {
        action.subtitle = @"Not Supported";
        action.attributes = UIMenuElementAttributesDisabled;
    }
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_lowLightVideoCaptureMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Low Light Video Capture" children:@[
        [UIDeferredMenuElement _cp_queue_lowLightVideoCaptureSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleLowLightVideoCaptureEnabledWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
}

+ (UIMenu * _Nonnull)_cp_queue_lowLightVideoCaptureSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Low Light Video Capture Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isLowLightVideoCaptureSupported"));
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_toggleLowLightVideoCaptureEnabledWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isLowLightVideoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("isLowLightVideoCaptureEnabled"));
    BOOL isLowLightVideoCaptureSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice.activeFormat, sel_registerName("isLowLightVideoCaptureSupported"));
    
    UIAction *action = [UIAction actionWithTitle:@"Low Light Video Capture" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevice, sel_registerName("setLowLightVideoCaptureEnabled:"), !isLowLightVideoCaptureEnabled);
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isLowLightVideoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isLowLightVideoCaptureSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_setVideoZoomSmoothingForAllConnections:(BOOL)enabled title:(NSString *)title captureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL supported = NO;
    for (AVCaptureConnection *connection in captureService.queue_captureSession.connections) {
        BOOL isVideoZoomSmoothingSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoZoomSmoothingSupported"));
        
        if (isVideoZoomSmoothingSupported) {
            supported = YES;
            break;
        }
    }
    
    UIAction *action = [UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            for (AVCaptureConnection *connection in captureService.queue_captureSession.connections) {
                BOOL isVideoZoomSmoothingSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoZoomSmoothingSupported"));
                
                if (isVideoZoomSmoothingSupported) {
                    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(connection, sel_registerName("setVideoZoomSmoothingEnabled:"), enabled);
                }
            }
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = supported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_zoomMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Zoom" children:@[
        [UIDeferredMenuElement _cp_queue_zoomSlidersElementWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setVideoZoomSmoothingForAllConnections:YES title:@"Enable Video Zoom Smoothing for all connections" captureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setVideoZoomSmoothingForAllConnections:NO title:@"Disable Video Zoom Smoothing for all connections" captureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_quuee_minimumSizeZoomMenuWithCaptureService:captureService videoDevice:captureDevice]
    ]];
}

+ (UIMenu * _Nonnull)_cp_queue_videoGreenGhostMitigationSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Green Ghost Mitigation Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isVideoGreenGhostMitigationSupported"));
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_setVideoGreenGhostMitigationEnabledActionForAllConnections:(BOOL)enabled title:(NSString *)title captureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL supported = NO;
    for (AVCaptureConnection *connection in captureService.queue_captureSession.connections) {
        BOOL isVideoGreenGhostMitigationSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoGreenGhostMitigationSupported"));
        
        if (isVideoGreenGhostMitigationSupported) {
            supported = YES;
            break;
        }
    }
    
    UIAction *action = [UIAction actionWithTitle:title image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            for (AVCaptureConnection *connection in captureService.queue_captureSession.connections) {
                BOOL isVideoGreenGhostMitigationSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(connection, sel_registerName("isVideoGreenGhostMitigationSupported"));
                
                if (isVideoGreenGhostMitigationSupported) {
                    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(connection, sel_registerName("setVideoGreenGhostMitigationEnabled:"), enabled);
                }
            }
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = supported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_videoGreenGhostMitigationMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Video Green Ghost Mitigation" children:@[
        [UIDeferredMenuElement _cp_queue_videoGreenGhostMitigationSupportedFormatsWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setVideoGreenGhostMitigationEnabledActionForAllConnections:YES title:@"Enable Video Green Ghost Mitigation for all Connections" captureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_setVideoGreenGhostMitigationEnabledActionForAllConnections:NO title:@"Disable Video Green Ghost Mitigation for all Connections" captureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
}

+ (UIMenu * _Nonnull)_cp_queue_videoHDRSupportedFormatsMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"HDR Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isVideoHDRSupported;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIAction * _Nonnull)_cp_queue_toggleVideoHDREnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isVideoHDREnabled = captureDevice.isVideoHDREnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Video HDR" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.videoHDREnabled = !isVideoHDREnabled;
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isVideoHDREnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    BOOL isVideoHDRSupported = captureDevice.activeFormat.isVideoHDRSupported;
    BOOL automaticallyAdjustsVideoHDREnabled = captureDevice.automaticallyAdjustsVideoHDREnabled;
    
//    void *handle = dlopen("/System/Library/PrivateFrameworks/AVFCapture.framework/AVFCapture", RTLD_NOW);
//    auto AVCaptureColorSpaceIsHDR = reinterpret_cast<BOOL (*)(AVCaptureColorSpace)>(dlsym(handle, "AVCaptureColorSpaceIsHDR"));
//    BOOL ColorSpaceIsHDR = AVCaptureColorSpaceIsHDR(captureDevice.activeColorSpace);
    BOOL ColorSpaceIsHDR = captureDevice.activeColorSpace == AVCaptureColorSpace_HLG_BT2020;
    
    action.attributes = (isVideoHDRSupported && !automaticallyAdjustsVideoHDREnabled && !ColorSpaceIsHDR) ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAutomaticallyAdjustsVideoHDREnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL automaticallyAdjustsVideoHDREnabled = captureDevice.automaticallyAdjustsVideoHDREnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Automatically Adjusts Video HDR" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            captureDevice.automaticallyAdjustsVideoHDREnabled = !automaticallyAdjustsVideoHDREnabled;
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = automaticallyAdjustsVideoHDREnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    BOOL isVideoHDRSupported = captureDevice.activeFormat.isVideoHDRSupported;
    
//    void *handle = dlopen("/System/Library/PrivateFrameworks/AVFCapture.framework/AVFCapture", RTLD_NOW);
//    auto AVCaptureColorSpaceIsHDR = reinterpret_cast<BOOL (*)(AVCaptureColorSpace)>(dlsym(handle, "AVCaptureColorSpaceIsHDR"));
//    BOOL ColorSpaceIsHDR = AVCaptureColorSpaceIsHDR(captureDevice.activeColorSpace);
    BOOL ColorSpaceIsHDR = captureDevice.activeColorSpace == AVCaptureColorSpace_HLG_BT2020;
    
    action.attributes = (isVideoHDRSupported && !ColorSpaceIsHDR) ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_videoHDRMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Video HDR" children:@[
        [UIDeferredMenuElement _cp_queue_videoHDRSupportedFormatsMenuWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleVideoHDREnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleAutomaticallyAdjustsVideoHDREnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
}

+ (UIAction * _Nonnull)_cp_queue_toggleWindNoiseRemovalEnabledWithDeviceInput:(AVCaptureDeviceInput *)deviceInput captureService:(CaptureService *)captureService didChangeHandler:(void (^)())didChangeHandler {
    BOOL windNoiseRemovalSupported = deviceInput.windNoiseRemovalSupported;
    BOOL isWindNoiseRemovalEnabled = deviceInput.isWindNoiseRemovalEnabled;
    
    UIAction *action = [UIAction actionWithTitle:@"Wind Noise Removal" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            deviceInput.windNoiseRemovalEnabled = !isWindNoiseRemovalEnabled;
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.attributes = windNoiseRemovalSupported ? 0 : UIMenuElementAttributesDisabled;
    action.state = isWindNoiseRemovalEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_additionalFaceDetectionFeaturesMenuWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Face Detection Features" children:@[
        [UIDeferredMenuElement _cp_queue_toggleSmileDetectionEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleEyeClosedDetectionEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleEyeDetectionEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleAttentionDetectionEnabledActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleHumanHandMetadataObjectTypeAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleHeadMetadataObjectTypesAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleTextRegionMetadataObjectTypeAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleSceneClassificationMetadataObjectTypeAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleVisualIntelligenceMetadataObjectTypeAvailableActionWithCaptureService:captureService captureDevice:captureDevice didChangeHandler:didChangeHandler]
    ]];
}

+ (UIAction * _Nonnull)_cp_queue_toggleSmileDetectionEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isSmileDetectionSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("isSmileDetectionSupported"));
    BOOL smileDetectionEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("smileDetectionEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Smile Detection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevice, sel_registerName("setSmileDetectionEnabled:"), !smileDetectionEnabled);
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = smileDetectionEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isSmileDetectionSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleEyeClosedDetectionEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isEyeClosedDetectionSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("isEyeClosedDetectionSupported"));
    BOOL eyeClosedDetectionEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("eyeClosedDetectionEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Eye Closed Detection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevice, sel_registerName("setEyeClosedDetectionEnabled:"), !eyeClosedDetectionEnabled);
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = eyeClosedDetectionEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isEyeClosedDetectionSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleEyeDetectionEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    BOOL isEyeDetectionSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("isEyeDetectionSupported"));
    BOOL eyeDetectionEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("eyeDetectionEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Eye Detection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureDevice, sel_registerName("setEyeDetectionEnabled:"), !eyeDetectionEnabled);
            [captureDevice unlockForConfiguration];
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = eyeDetectionEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isEyeDetectionSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAttentionDetectionEnabledActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isAttentionDetectionSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureDevice, sel_registerName("isAttentionDetectionSupported"));
    BOOL isAttentionDetectionEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isAttentionDetectionEnabled"));
    
    UIAction *action = [UIAction actionWithTitle:@"Attention Detection" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setAttentionDetectionEnabled:"), !isAttentionDetectionEnabled);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isAttentionDetectionEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isAttentionDetectionSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleHumanHandMetadataObjectTypeAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isHumanHandMetadataSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isHumanHandMetadataSupported"));
    BOOL isHumanHandMetadataObjectTypeAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isHumanHandMetadataObjectTypeAvailable"));
    
    UIAction *action = [UIAction actionWithTitle:@"Human Hand Metadata Object Type Available" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setHumanHandMetadataObjectTypeAvailable:"), !isHumanHandMetadataObjectTypeAvailable);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isHumanHandMetadataObjectTypeAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isHumanHandMetadataSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_portraitEffectSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Portrait Effect Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isPortraitEffectSupported;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_studioLightSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Studio Light Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isStudioLightSupported;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_backgroundReplacementSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Background Replacement Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return format.isBackgroundReplacementSupported;
    }
                                                         didChangeHandler:didChangeHandler];
}

+ (UIMenu * _Nonnull)_cp_queue_smartStyleRenderingSupportedFormatsWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    UIMenu *menu = [UIDeferredMenuElement _cp_queue_formatsMenuWithCaptureService:captureService
                                                            captureDevice:captureDevice
                                                                    title:@"Smart Style Rendering Supported Formats"
                                                          includeSubtitle:NO
                                                            filterHandler:^BOOL(AVCaptureDeviceFormat *format) {
        return reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(format, sel_registerName("isSmartStyleRenderingSupported"));
    }
                                                         didChangeHandler:didChangeHandler];
    
    menu.subtitle = @"com.apple.avfoundation.allow-capture-filter-rendering";
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleHeadMetadataObjectTypesAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isHeadMetadataSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isHeadMetadataSupported"));
    BOOL isHeadMetadataObjectTypesAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isHeadMetadataObjectTypesAvailable"));
    
    UIAction *action = [UIAction actionWithTitle:@"Head Metadata Object Type Available" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setHeadMetadataObjectTypesAvailable:"), !isHeadMetadataObjectTypesAvailable);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isHeadMetadataObjectTypesAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isHeadMetadataSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleTextRegionMetadataObjectTypeAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isTextRegionMetadataSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isTextRegionMetadataSupported"));
    BOOL isTextRegionMetadataObjectTypeAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isTextRegionMetadataObjectTypeAvailable"));
    
    UIAction *action = [UIAction actionWithTitle:@"Text Region Metadata Object Type Available" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setTextRegionMetadataObjectTypeAvailable:"), !isTextRegionMetadataObjectTypeAvailable);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isTextRegionMetadataObjectTypeAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isTextRegionMetadataSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleSceneClassificationMetadataObjectTypeAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isSceneClassificationMetadataSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isSceneClassificationMetadataSupported"));
    BOOL isSceneClassificationMetadataObjectTypeAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isSceneClassificationMetadataObjectTypeAvailable"));
    
    UIAction *action = [UIAction actionWithTitle:@"Scene Classification Metadata Object Type Available" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setSceneClassificationMetadataObjectTypeAvailable:"), !isSceneClassificationMetadataObjectTypeAvailable);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isSceneClassificationMetadataObjectTypeAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isSceneClassificationMetadataSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIAction * _Nonnull)_cp_queue_toggleVisualIntelligenceMetadataObjectTypeAvailableActionWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice didChangeHandler:(void (^)())didChangeHandler {
    AVCaptureMetadataOutput *metadataOutput = [captureService queue_outputClass:AVCaptureMetadataOutput.class fromCaptureDevice:captureDevice];
    assert(metadataOutput != nil);
    
    BOOL isVisualIntelligenceMetadataSupported = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isVisualIntelligenceMetadataSupported"));
    BOOL isVisualIntelligenceMetadataObjectTypeAvailable = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(metadataOutput, sel_registerName("isVisualIntelligenceMetadataObjectTypeAvailable"));
    
    UIAction *action = [UIAction actionWithTitle:@"Visual Intelligence Metadata Object Type Available" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_async(captureService.captureSessionQueue, ^{
            reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(metadataOutput, sel_registerName("setVisualIntelligenceMetadataObjectTypeAvailable:"), !isVisualIntelligenceMetadataObjectTypeAvailable);
            
            if (didChangeHandler) didChangeHandler();
        });
    }];
    
    action.state = isVisualIntelligenceMetadataObjectTypeAvailable ? UIMenuElementStateOn : UIMenuElementStateOff;
    action.attributes = isVisualIntelligenceMetadataSupported ? 0 : UIMenuElementAttributesDisabled;
    
    return action;
}

+ (UIMenu * _Nonnull)_cp_queue_assetWriterMenuWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice didChangeHandler:(void (^)())didChangeHandler {
    return [UIMenu menuWithTitle:@"Asset Writer" children:@[
        [UIDeferredMenuElement _cp_queue_configureAudioDeviceForAssetWriterVideoRecordingMenuWithCaptureService:captureService videoDevice:videoDevice didChangeHandler:didChangeHandler],
        [UIDeferredMenuElement _cp_queue_toggleAssetWriterRecordingStatusActionWithCaptureService:captureService videoDevice:videoDevice didChangeHandler:didChangeHandler]
    ]];
}

+ (UIMenu * _Nonnull)_cp_queue_configureAudioDeviceForAssetWriterVideoRecordingMenuWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice didChangeHandler:(void (^)())didChangeHandler {
    NSArray<AVCaptureDevice *> *addedAudioDevices = captureService.queue_addedAudioCaptureDevices;
    
    NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:addedAudioDevices.count];
    
    AVCaptureDevice * _Nullable connectedAudioDevice = nil;
    
    for (AVCaptureDevice *audioDevice in addedAudioDevices) {
        BOOL isConnected = [captureService queue_isAudioDeviceConnected:audioDevice forAssetWriterVideoDevice:videoDevice];
        BOOL isConnectedSomewhere = [captureService queue_isAssetWriterConnectedWithAudioDevice:audioDevice];
        
        UIAction *action = [UIAction actionWithTitle:audioDevice.localizedName image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                BOOL isConnected = [captureService queue_isAudioDeviceConnected:audioDevice forAssetWriterVideoDevice:videoDevice];
                
                if (isConnected) {
                    [captureService queue_disconnectAudioDevice:audioDevice forAssetWriterVideoDevice:videoDevice];
                } else {
                    [captureService queue_connectAudioDevice:audioDevice forAssetWriterVideoDevice:videoDevice];
                }
                
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        action.state = isConnected ? UIMenuElementStateOn : UIMenuElementStateOff;
        action.attributes = (!isConnected && isConnectedSomewhere) ? UIMenuElementAttributesDisabled : 0;
        
        [actions addObject:action];
        
        if (isConnected) {
            assert(connectedAudioDevice == nil);
            connectedAudioDevice = audioDevice;
        }
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Configure Audio Device" children:actions];
    [actions release];
    
    menu.subtitle = connectedAudioDevice.localizedName;
    
    return menu;
}

+ (UIAction * _Nonnull)_cp_queue_toggleAssetWriterRecordingStatusActionWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice didChangeHandler:(void (^)())didChangeHandler {
    AVAssetWriter * _Nullable assetWriter = [captureService queue_recordingAssetWriterWithVideoDevice:videoDevice];
    
#warning Pause Recording
    if (assetWriter == nil) {
        UIAction *action = [UIAction actionWithTitle:@"Start Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                [captureService queue_startRecordingUsingAssetWriterWithVideoDevice:videoDevice];
                if (didChangeHandler) didChangeHandler();
            });
        }];
        
        return action;
    } else {
        UIAction *action = [UIAction actionWithTitle:@"Stop Recording" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_async(captureService.captureSessionQueue, ^{
                dispatch_suspend(captureService.captureSessionQueue);
                
                [assetWriter finishWritingWithCompletionHandler:^{
                    dispatch_resume(captureService.captureSessionQueue);
                    if (didChangeHandler) didChangeHandler();
                }];
            });
        }];
        
        return action;
    }
}

+ (UIMenu * _Nonnull)_cp_quuee_minimumSizeZoomMenuWithCaptureService:(CaptureService *)captureService videoDevice:(AVCaptureDevice *)videoDevice {
    // https://developer.apple.com/videos/play/wwdc2021/10047?time=327
    __kindof UIMenuElement *element = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        UISlider *slider = [UISlider new];
        
        /*
              b
         ------------
              |    /
              |   /
             a|  /
              |θ/
              |/
         
         a = minimumFocusDistance
         θ = videoFieldOfView * 0.5
         b = a * tan(θ) * 2 = 1배수 기준 초점을 맞출 수 있는 거리에서 볼 수 있는 길이
         */
        float dist = 2.f * videoDevice.minimumFocusDistance * tan((videoDevice.activeFormat.videoFieldOfView / 180.f) * M_PI_2);
        
        slider.minimumValue = dist / videoDevice.maxAvailableVideoZoomFactor; // mm
        slider.maximumValue = dist / videoDevice.minAvailableVideoZoomFactor; // mm
        slider.value = dist / videoDevice.videoZoomFactor;
        slider.continuous = YES;
        
        UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            auto slider = static_cast<UISlider *>(action.sender);
            float value = slider.value;
            
            dispatch_async(captureService.captureSessionQueue, ^{
                float zoomFactor = dist / value;
                
                NSError * _Nullable error = nil;
                [videoDevice lockForConfiguration:&error];
                assert(error == nil);
                videoDevice.videoZoomFactor = zoomFactor;
                [videoDevice unlockForConfiguration];
            });
        }];
        
        [slider addAction:action forControlEvents:UIControlEventValueChanged];
        
        return [slider autorelease];
    });
    
    UIMenu *menu = [UIMenu menuWithTitle:@"Minimum Size" children:@[element]];
    
    return menu;
}

#warning isVariableFrameRateVideoCaptureSupported isResponsiveCaptureWithDepthSupported isVideoBinned autoRedEyeReductionSupported

@end

#endif
