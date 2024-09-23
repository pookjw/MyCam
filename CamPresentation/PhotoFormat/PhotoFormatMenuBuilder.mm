//
//  PhotoFormatMenuBuilder.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/18/24.
//

#import <CamPresentation/PhotoFormatMenuBuilder.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/NSStringFromCMVideoDimensions.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface PhotoFormatMenuBuilder ()
@property (weak, nonatomic, readonly) id<PhotoFormatMenuBuilderDelegate> delegate;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@end

@implementation PhotoFormatMenuBuilder

- (instancetype)initWithPhotoFormatModel:(PhotoFormatModel *)photoFormatModel captureService:(CaptureService *)captureService delegate:(id<PhotoFormatMenuBuilderDelegate>)delegate {
    if (self = [super init]) {
        AVCapturePhotoOutput *capturePhotoOutput = captureService.capturePhotoOutput;
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoCodecTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isSpatialPhotoCaptureSupported" options:NSKeyValueObservingOptionNew context:nullptr];
        [capturePhotoOutput addObserver:self forKeyPath:@"isAutoDeferredPhotoDeliverySupported" options:NSKeyValueObservingOptionNew context:nullptr];
        
        _delegate = delegate;
        _captureService = [captureService retain];
        _photoFormatModel = [photoFormatModel copy];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didChangeSelectedDeviceNotification:) name:CaptureServiceDidChangeSelectedDeviceNotificationName object:captureService];
        
        dispatch_async(captureService.captureSessionQueue, ^{
            if (AVCaptureDevice *selectedCaptureDevice = captureService.queue_selectedCaptureDevice) {
                [self registerCaptureDeviceObservatoins:selectedCaptureDevice];
            }
        });
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
    
    [_captureService release];
    [_photoFormatModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVCapturePhotoOutput.class]) {
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
            [self.delegate photoFormatMenuBuilderElementsDidChange:self];
            return;
        } else if ([keyPath isEqualToString:@"isAutoDeferredPhotoDeliverySupported"]) {
            [self.delegate photoFormatMenuBuilderElementsDidChange:self];
            return;
        }
    } else if ([object isKindOfClass:AVCaptureDevice.class]) {
        if ([keyPath isEqualToString:@"activeFormat"] || [keyPath isEqualToString:@"formats"]) {
            assert([self.captureService.queue_selectedCaptureDevice isEqual:object]);
            [self.delegate photoFormatMenuBuilderElementsDidChange:self];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)menuElementsWithCompletionHandler:(void (^)(NSArray<__kindof UIMenuElement *> * _Nonnull))completionHandler {
    dispatch_async(self.captureService.captureSessionQueue, ^{
        __weak auto weakSelf = self;
        CaptureService *captureService = self.captureService;
        
        NSMutableArray<__kindof UIMenuElement *> *children = [NSMutableArray new];
        
        //
        
        {
            AVCaptureDevice *selectedCaptureDevice = captureService.queue_selectedCaptureDevice;
            NSArray<AVCaptureDeviceFormat *> *formats = selectedCaptureDevice.formats;
            AVCaptureDeviceFormat *activeFormat = selectedCaptureDevice.activeFormat;
            NSMutableArray<UIAction *> *formatActions = [[NSMutableArray alloc] initWithCapacity:formats.count];
            
            for (AVCaptureDeviceFormat *format in formats) {
                UIAction *action = [UIAction actionWithTitle:format.debugDescription image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        NSError * _Nullable error = nil;
                        [selectedCaptureDevice lockForConfiguration:&error];
                        assert(error == nil);
                        selectedCaptureDevice.activeFormat = format;
                        [selectedCaptureDevice unlockForConfiguration];
                    });
                }];
                
                action.cp_overrideNumberOfTitleLines = @(0);
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = [activeFormat isEqual:format] ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [formatActions addObject:action];
            }
            
            UIMenu *formatsMenu = [UIMenu menuWithTitle:@"Format"
                                                  image:nil
                                             identifier:nil
                                                options:0
                                               children:formatActions];
            [formatActions release];
            formatsMenu.subtitle = activeFormat.debugDescription;
            [children addObject:formatsMenu];
        }
        
        //
        
        {
            AVCaptureDeviceFormat *format = captureService.queue_selectedCaptureDevice.activeFormat;
            NSArray<NSValue *> *supportedMaxPhotoDimensions = format.supportedMaxPhotoDimensions;
            NSMutableArray<UIAction *> *actions = [[NSMutableArray alloc] initWithCapacity:supportedMaxPhotoDimensions.count];
            CMVideoDimensions selectedMaxPhotoDimensions = captureService.capturePhotoOutput.maxPhotoDimensions;
            
            for (NSValue *maxPhotoDimensionsValue in supportedMaxPhotoDimensions) {
                CMVideoDimensions maxPhotoDimensions = maxPhotoDimensionsValue.CMVideoDimensionsValue;
                
                UIAction *action = [UIAction actionWithTitle:NSStringFromCMVideoDimensions(maxPhotoDimensions)
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        captureService.capturePhotoOutput.maxPhotoDimensions = maxPhotoDimensions;
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
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
            
            [children addObject:menu];
        }
        
        //
        
        {
            NSArray<NSNumber *> *photoPixelFormatTypes;
            if (self.photoFormatModel.processedFileType == nil) {
                photoPixelFormatTypes = captureService.capturePhotoOutput.availablePhotoPixelFormatTypes;
            } else {
                photoPixelFormatTypes = [captureService.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:self.photoFormatModel.processedFileType];
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
                    weakSelf.photoFormatModel.photoPixelFormatType = formatNumber;
                    weakSelf.photoFormatModel.codecType = nil;
                    [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                }];
                
                [string release];
                
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = [self.photoFormatModel.photoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [photoPixelFormatTypeActions addObject:action];
            }
            
            UIMenu *photoPixelFormatTypesMenu = [UIMenu menuWithTitle:@"Pixel Format"
                                                                image:[UIImage systemImageNamed:@"dot.square"]
                                                           identifier:nil
                                                              options:0
                                                             children:photoPixelFormatTypeActions];
            [photoPixelFormatTypeActions release];
            
            if (NSNumber *photoPixelFormatType = self.photoFormatModel.photoPixelFormatType) {
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
                photoPixelFormatTypesMenu.subtitle = string;
                [string release];
            }
            
            [children addObject:photoPixelFormatTypesMenu];
        }
        
        //
        
        {
            NSArray<AVVideoCodecType> *availablePhotoCodecTypes;
            if (self.photoFormatModel.processedFileType == nil) {
                availablePhotoCodecTypes = captureService.capturePhotoOutput.availablePhotoCodecTypes;
            } else {
                availablePhotoCodecTypes = [captureService.capturePhotoOutput supportedPhotoCodecTypesForFileType:self.photoFormatModel.processedFileType];
            }
            
            NSMutableArray<UIAction *> *photoCodecTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoCodecTypes.count];
            
            for (AVVideoCodecType photoCodecType in availablePhotoCodecTypes) {
                UIAction *action = [UIAction actionWithTitle:photoCodecType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    weakSelf.photoFormatModel.photoPixelFormatType = nil;
                    weakSelf.photoFormatModel.codecType = photoCodecType;
                    [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                }];
                
                action.state = [self.photoFormatModel.codecType isEqualToString:photoCodecType] ? UIMenuElementStateOn : UIMenuElementStateOff;
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                
                [photoCodecTypeActions addObject:action];
            }
            
            UIMenu *photoCodecTypesMenu = [UIMenu menuWithTitle:@"Codec"
                                                          image:[UIImage systemImageNamed:@"rectangle.on.rectangle.badge.gearshape"]
                                                     identifier:nil
                                                        options:0
                                                       children:photoCodecTypeActions];
            [photoCodecTypeActions release];
            photoCodecTypesMenu.subtitle = self.photoFormatModel.codecType;
            [children addObject:photoCodecTypesMenu];
        }
        
        //
        
        {
            if (self.photoFormatModel.photoPixelFormatType == nil) {
                NSMutableArray<UIAction *> *qualityActions = [[NSMutableArray alloc] initWithCapacity:10];
                
                for (NSUInteger count = 1; count <= 10; count++) {
                    float quality = static_cast<float>(count) / 10.f;
                    
                    UIAction *action = [UIAction actionWithTitle:@(quality).stringValue image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        weakSelf.photoFormatModel.quality = quality;
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    }];
                    
                    action.state = (self.photoFormatModel.quality == quality) ? UIMenuElementStateOn : UIMenuElementStateOff;
                    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                    [qualityActions addObject:action];
                }
                
                UIMenu *qualityMenu = [UIMenu menuWithTitle:@"Quality"
                                                      image:[UIImage systemImageNamed:@"slider.horizontal.below.sun.max"]
                                                 identifier:nil
                                                    options:0
                                                   children:qualityActions];
                [qualityActions release];
                qualityMenu.subtitle = @(self.photoFormatModel.quality).stringValue;
                
                [children addObject:qualityMenu];
            }
        }
        
        //
        
        NSMutableArray<UIMenuElement *> *rawMenuElements = [[NSMutableArray alloc] initWithCapacity:self.photoFormatModel.isRAWEnabled ? 4 : 1];
        
        {
            UIAction *rawEnabledAction = [UIAction actionWithTitle:@"Enable RAW"
                                                             image:[UIImage systemImageNamed:@"compass.drawing"]
                                                        identifier:nil
                                                           handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.photoFormatModel.isRAWEnabled = !weakSelf.photoFormatModel.isRAWEnabled;
                if (weakSelf.photoFormatModel.isRAWEnabled) {
                    weakSelf.photoFormatModel.rawPhotoPixelFormatType = captureService.capturePhotoOutput.availableRawPhotoPixelFormatTypes.lastObject;
                    weakSelf.photoFormatModel.rawFileType = captureService.capturePhotoOutput.availableRawPhotoFileTypes.lastObject;
                    weakSelf.photoFormatModel.processedFileType = nil;
                } else {
                    weakSelf.photoFormatModel.rawPhotoPixelFormatType = nil;
                    weakSelf.photoFormatModel.rawFileType = nil;
                    weakSelf.photoFormatModel.processedFileType = nil;
                }
                
                [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
            }];
            
            rawEnabledAction.state = self.photoFormatModel.isRAWEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
            rawEnabledAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            
            [rawMenuElements addObject:rawEnabledAction];
        }
        
        //
        
        if (self.photoFormatModel.isRAWEnabled) {
            {
                NSArray<NSNumber *> *availableRawPhotoPixelFormatTypes;
                if (self.photoFormatModel.processedFileType == nil) {
                    availableRawPhotoPixelFormatTypes = captureService.capturePhotoOutput.availableRawPhotoPixelFormatTypes;
                } else {
                    availableRawPhotoPixelFormatTypes = [captureService.capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:self.photoFormatModel.processedFileType];
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
                        weakSelf.photoFormatModel.rawPhotoPixelFormatType = formatNumber;
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    }];
                    
                    [string release];
                    
                    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                    action.state = [self.photoFormatModel.rawPhotoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
                    
                    [rawPhotoPixelFormatTypeActions addObject:action];
                }
                
                UIMenu *rawPhotoPixelFormatTypesMenu = [UIMenu menuWithTitle:@"Raw Photo Pixel Format"
                                                                       image:[UIImage systemImageNamed:@"squareshape.dotted.squareshape"]
                                                                  identifier:nil
                                                                     options:0
                                                                    children:rawPhotoPixelFormatTypeActions];
                
                if (NSNumber *rawPhotoPixelFormatType = self.photoFormatModel.rawPhotoPixelFormatType) {
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
                    rawPhotoPixelFormatTypesMenu.subtitle = string;
                    [string release];
                }
                
                [rawPhotoPixelFormatTypeActions release];
                [rawMenuElements addObject:rawPhotoPixelFormatTypesMenu];
            }
            
            //
            
            {
                NSArray<AVFileType> *availableRawPhotoFileTypes = captureService.capturePhotoOutput.availableRawPhotoFileTypes;
                NSMutableArray<UIAction *> *rawFileTypeActions = [[NSMutableArray alloc] initWithCapacity:availableRawPhotoFileTypes.count];
                
                for (AVFileType fileType in availableRawPhotoFileTypes) {
                    UIAction *action = [UIAction actionWithTitle:fileType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        weakSelf.photoFormatModel.rawFileType = fileType;
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    }];
                    
                    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                    action.state = [self.photoFormatModel.rawFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
                    
                    [rawFileTypeActions addObject:action];
                }
                
                UIMenu *rawFileTypesMenu = [UIMenu menuWithTitle:@"Raw Photo File Type"
                                                           image:nil
                                                      identifier:nil
                                                         options:0
                                                        children:rawFileTypeActions];
                [rawFileTypeActions release];
                
                if (AVFileType rawFileType = self.photoFormatModel.rawFileType) {
                    rawFileTypesMenu.subtitle = rawFileType;
                }
                
                [rawMenuElements addObject:rawFileTypesMenu];
                
                //
                
                NSArray<AVFileType> *availablePhotoFileTypes = captureService.capturePhotoOutput.availablePhotoFileTypes;
                NSMutableArray<UIAction *> *availablePhotoFileTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoFileTypes.count + 1];
                
                UIAction *nullAction = [UIAction actionWithTitle:@"(null)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    weakSelf.photoFormatModel.processedFileType = nil;
                    [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                }];
                nullAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
                nullAction.state = (self.photoFormatModel.processedFileType == nil) ? UIMenuElementStateOn : UIMenuElementStateOff;
                [availablePhotoFileTypeActions addObject:nullAction];
                
                for (AVFileType fileType in availablePhotoFileTypes) {
                    UIAction *action = [UIAction actionWithTitle:fileType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                        weakSelf.photoFormatModel.processedFileType = fileType;
                        
                        NSArray<NSNumber *> *supportedPhotoPixelFormatTypes = [captureService.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:fileType];
                        if (![supportedPhotoPixelFormatTypes containsObject:weakSelf.photoFormatModel.photoPixelFormatType]) {
                            weakSelf.photoFormatModel.photoPixelFormatType = supportedPhotoPixelFormatTypes.lastObject;
                        }
                        
                        NSArray<AVFileType> *supportedPhotoCodecTypesForFileType = [captureService.capturePhotoOutput supportedPhotoCodecTypesForFileType:fileType];
                        if (![supportedPhotoCodecTypesForFileType containsObject:weakSelf.photoFormatModel.codecType]) {
                            weakSelf.photoFormatModel.codecType = supportedPhotoCodecTypesForFileType.lastObject;
                        }
                        
                        NSArray<NSNumber *> *supportedRawPhotoPixelFormatTypesForFileType = [captureService.capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:fileType];
                        if (![supportedRawPhotoPixelFormatTypesForFileType containsObject:weakSelf.photoFormatModel.rawPhotoPixelFormatType]) {
                            weakSelf.photoFormatModel.rawPhotoPixelFormatType = supportedRawPhotoPixelFormatTypesForFileType.lastObject;
                        }
                        
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    }];
                    action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                    action.state = [self.photoFormatModel.processedFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
                    [availablePhotoFileTypeActions addObject:action];
                }
                
                UIMenu *processedFileTypesMenu = [UIMenu menuWithTitle:@"Raw Photo Processed File Type"
                                                                 image:nil
                                                            identifier:nil
                                                               options:0
                                                              children:availablePhotoFileTypeActions];
                [availablePhotoFileTypeActions release];
                
                if (AVFileType processedFileType = self.photoFormatModel.processedFileType) {
                    processedFileTypesMenu.subtitle = processedFileType;
                }
                
                [rawMenuElements addObject:processedFileTypesMenu];
            }
        }
        
        UIMenu *rawMenu = [UIMenu menuWithTitle:@""
                                          image:nil
                                     identifier:nil
                                        options:UIMenuOptionsDisplayInline
                                       children:rawMenuElements];
        [rawMenuElements release];
        [children addObject:rawMenu];
        
        //
        
        {
            if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureService.capturePhotoOutput, sel_registerName("isSpatialPhotoCaptureSupported"))) {
                BOOL isSpatialPhotoCaptureEnabled = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(captureService.capturePhotoOutput, sel_registerName("isSpatialPhotoCaptureEnabled"));
                
                UIAction *action = [UIAction actionWithTitle:@"Spatial (Not Working)"
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(captureService.capturePhotoOutput, sel_registerName("setSpatialPhotoCaptureEnabled:"), !isSpatialPhotoCaptureEnabled);
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    });
                }];
                
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = isSpatialPhotoCaptureEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [children addObject:action];
            }
        }
        
        //
        
        {
            if (captureService.capturePhotoOutput.isAutoDeferredPhotoDeliverySupported) {
                BOOL isAutoDeferredPhotoDeliveryEnabled = captureService.capturePhotoOutput.isAutoDeferredPhotoDeliveryEnabled;
                
                UIAction *action = [UIAction actionWithTitle:@"Deferred Photo"
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    dispatch_async(captureService.captureSessionQueue, ^{
                        captureService.capturePhotoOutput.autoDeferredPhotoDeliveryEnabled = !isAutoDeferredPhotoDeliveryEnabled;
                        [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
                    });
                }];
                
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = isAutoDeferredPhotoDeliveryEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [children addObject:action];
            }
        }
        
        //
        
        {
            AVCapturePhotoQualityPrioritization photoQualityPrioritization = self.photoFormatModel.photoQualityPrioritization;
            
            UIAction *speedAction = [UIAction actionWithTitle:@"Speed"
                                                        image:nil
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.photoFormatModel.photoQualityPrioritization = AVCapturePhotoQualityPrioritizationSpeed;
                [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
            }];
            speedAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            speedAction.state = (photoQualityPrioritization == AVCapturePhotoQualityPrioritizationSpeed) ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            UIAction *balancedAction = [UIAction actionWithTitle:@"Balanced"
                                                        image:nil
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.photoFormatModel.photoQualityPrioritization = AVCapturePhotoQualityPrioritizationBalanced;
                [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
            }];
            balancedAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            balancedAction.state = (photoQualityPrioritization == AVCapturePhotoQualityPrioritizationBalanced) ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            UIAction *qualityAction = [UIAction actionWithTitle:@"Quality"
                                                        image:nil
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.photoFormatModel.photoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
                [weakSelf.delegate photoFormatMenuBuilderElementsDidChange:weakSelf];
            }];
            qualityAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            qualityAction.state = (photoQualityPrioritization == AVCapturePhotoQualityPrioritizationQuality) ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Quality Prioritization" children:@[
                speedAction, balancedAction, qualityAction
            ]];
            
            [children addObject:menu];
        }
        
        //
        
        if (completionHandler) completionHandler(children);
        [children release];
    });
}

- (void)didChangeSelectedDeviceNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    if (AVCaptureDevice *oldCaptureDevice = userInfo[CaptureServiceOldCaptureDeviceKey]) {
        [self unregisterCaptureDeviceObservatoins:oldCaptureDevice];
    }
    
    if (AVCaptureDevice *newCaptureDevice = userInfo[CaptureServiceNewCaptureDeviceKey]) {
        [self registerCaptureDeviceObservatoins:newCaptureDevice];
    }
    
    [self.delegate photoFormatMenuBuilderElementsDidChange:self];
}

- (void)registerCaptureDeviceObservatoins:(AVCaptureDevice *)captureDevice {
    [captureDevice addObserver:self forKeyPath:@"activeFormat" options:NSKeyValueObservingOptionNew context:nullptr];
    [captureDevice addObserver:self forKeyPath:@"formats" options:NSKeyValueObservingOptionNew context:nullptr];
}

- (void)unregisterCaptureDeviceObservatoins:(AVCaptureDevice *)captureDevice {
    [captureDevice removeObserver:self forKeyPath:@"activeFormat"];
    [captureDevice removeObserver:self forKeyPath:@"formats"];
}

@end
