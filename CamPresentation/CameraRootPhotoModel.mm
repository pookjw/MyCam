//
//  CameraRootPhotoModel.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 9/16/24.
//

#import <CamPresentation/CameraRootPhotoModel.h>
#import <CamPresentation/CaptureService.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation CameraRootPhotoModel

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
        _quality = 1.f;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _photoPixelFormatType = [[coder decodeObjectOfClass:NSNumber.class forKey:@"photoPixelFormatType"] copy];
        _codecType = [[coder decodeObjectOfClass:NSString.class forKey:@"codecType"] copy];
        _quality = [coder decodeFloatForKey:@"quality"];
        _isRAWEnabled = [coder decodeBoolForKey:@"isRAWEnabled"];
        _rawPhotoPixelFormatType = [[coder decodeObjectOfClass:NSNumber.class forKey:@"rawPhotoPixelFormatType"] copy];
        _rawFileType = [[coder decodeObjectOfClass:NSString.class forKey:@"rawFileType"] copy];
        _processedFileType = [[coder decodeObjectOfClass:NSString.class forKey:@"processedFileType"] copy];
    }
    
    return self;
}

- (void)dealloc {
    if (auto captureService = _captureService) {
        AVCapturePhotoOutput *capturePhotoOutput = captureService.capturePhotoOutput;
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoPixelFormatTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoCodecTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoFileTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoFileTypes"];
        
        [captureService release];
    }
    
    [_photoPixelFormatType release];
    [_codecType release];
    [_rawPhotoPixelFormatType release];
    [_rawFileType release];
    [_processedFileType release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:AVCapturePhotoOutput.class]) {
        auto capturePhotoOutput = static_cast<AVCapturePhotoOutput *>(object);
        
        if ([keyPath isEqualToString:@"availablePhotoPixelFormatTypes"]) {
            NSArray<NSNumber *> *photoPixelFormatTypes;
            if (self.processedFileType == nil) {
                photoPixelFormatTypes = capturePhotoOutput.availablePhotoPixelFormatTypes;
            } else {
                photoPixelFormatTypes = [capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:self.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.photoPixelFormatType == nil) {
                if (self.codecType == nil) {
                    shouldUpdate = YES;
                } else {
                    shouldUpdate = NO;
                }
            } else if (![photoPixelFormatTypes containsObject:self.photoPixelFormatType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.photoPixelFormatType = photoPixelFormatTypes.lastObject;
            }
        } else if ([keyPath isEqualToString:@"availablePhotoCodecTypes"]) {
            NSArray<AVVideoCodecType> *photoCodecTypes;
            if (self.processedFileType == nil) {
                photoCodecTypes = capturePhotoOutput.availablePhotoCodecTypes;
            } else {
                photoCodecTypes = [capturePhotoOutput supportedPhotoCodecTypesForFileType:self.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.codecType == nil) {
                if (self.photoPixelFormatType == nil) {
                    shouldUpdate = YES;
                } else {
                    shouldUpdate = NO;
                }
            } else if (![photoCodecTypes containsObject:self.codecType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.codecType = photoCodecTypes.lastObject;
            }
        } else if ([keyPath isEqualToString:@"availableRawPhotoPixelFormatTypes"]) {
            NSArray<NSNumber *> *rawPhotoPixelFormatTypes;
            if (self.processedFileType == nil) {
                rawPhotoPixelFormatTypes = capturePhotoOutput.availableRawPhotoPixelFormatTypes;
            } else {
                rawPhotoPixelFormatTypes = [capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:self.processedFileType];
            }
            
            BOOL shouldUpdate;
            if (self.rawPhotoPixelFormatType == nil) {
                shouldUpdate = YES;
            } else if (![rawPhotoPixelFormatTypes containsObject:self.rawPhotoPixelFormatType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.rawPhotoPixelFormatType = rawPhotoPixelFormatTypes.lastObject;
            }
        } else if ([keyPath isEqualToString:@"availableRawPhotoFileTypes"]) {
            NSArray<AVFileType> *availableRawPhotoFileTypes = capturePhotoOutput.availableRawPhotoFileTypes;
            
            BOOL shouldUpdate;
            if (self.rawFileType == nil) {
                shouldUpdate = YES;
            } else if (![availableRawPhotoFileTypes containsObject:self.rawFileType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.rawFileType = availableRawPhotoFileTypes.lastObject;
            }
        } else if ([keyPath isEqualToString:@"availablePhotoFileTypes"]) {
            NSArray<AVFileType> *availablePhotoFileTypes = capturePhotoOutput.availablePhotoFileTypes;
            
            BOOL shouldUpdate;
            if (self.processedFileType == nil) {
                shouldUpdate = YES;
            } else if (![availablePhotoFileTypes containsObject:self.processedFileType]) {
                shouldUpdate = YES;
            } else {
                shouldUpdate = NO;
            }
            
            if (shouldUpdate) {
                self.processedFileType = nil;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (id)copyWithZone:(struct _NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        auto casted = static_cast<CameraRootPhotoModel *>(copy);
        casted->_captureService = [_captureService retain];
        casted->_photoPixelFormatType = [_photoPixelFormatType copyWithZone:zone];
        casted->_codecType = [_codecType copyWithZone:zone];
        casted->_quality = _quality;
        casted->_isRAWEnabled = _isRAWEnabled;
        casted->_rawPhotoPixelFormatType = [_rawPhotoPixelFormatType copyWithZone:zone];
        casted->_rawFileType = [_rawFileType copyWithZone:zone];
        casted->_processedFileType = [_processedFileType copyWithZone:zone];
    }
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_photoPixelFormatType forKey:@"photoPixelFormatType"];
    [coder encodeObject:_codecType forKey:@"codecType"];
    [coder encodeFloat:_quality forKey:@"quality"];
    [coder encodeBool:_isRAWEnabled forKey:@"isRAWEnabled"];
    [coder encodeObject:_rawPhotoPixelFormatType forKey:@"rawPhotoPixelFormatType"];
    [coder encodeObject:_rawFileType forKey:@"rawFileType"];
    [coder encodeObject:_processedFileType forKey:@"processedFileType"];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else {
        auto casted = static_cast<CameraRootPhotoModel *>(other);
        return [_photoPixelFormatType isEqualToNumber:casted->_photoPixelFormatType] &&
        [_codecType isEqualToString:casted->_codecType] &&
        (_quality == casted->_quality) &&
        (_isRAWEnabled == casted->_isRAWEnabled) &&
        [_rawPhotoPixelFormatType isEqualToNumber:casted->_rawPhotoPixelFormatType] &&
        [_rawFileType isEqualToString:casted->_rawFileType] &&
        [_processedFileType isEqualToString:casted->_processedFileType];
    }
}

- (NSUInteger)hash {
    return _photoPixelFormatType.hash ^
    _codecType.hash ^
    static_cast<NSUInteger>(_quality) ^
    _isRAWEnabled ^
    _rawPhotoPixelFormatType.hash ^
    _rawFileType.hash ^
    _processedFileType.hash;
}

- (void)setCaptureService:(CaptureService *)captureService {
    if (auto oldCaptureService = _captureService) {
        AVCapturePhotoOutput *capturePhotoOutput = oldCaptureService.capturePhotoOutput;
        
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoPixelFormatTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoCodecTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availableRawPhotoFileTypes"];
        [capturePhotoOutput removeObserver:self forKeyPath:@"availablePhotoFileTypes"];
        
        [oldCaptureService release];
    }
    
    _captureService = [captureService retain];
    
    AVCapturePhotoOutput *capturePhotoOutput = captureService.capturePhotoOutput;
    [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoCodecTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoPixelFormatTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    [capturePhotoOutput addObserver:self forKeyPath:@"availableRawPhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
    [capturePhotoOutput addObserver:self forKeyPath:@"availablePhotoFileTypes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
}

- (NSArray<UIMenuElement *> *)configurationMenuElementsWithSelectionHandler:(void (^ _Nullable)())selectionHandler {
    __weak auto weakSelf = self;
    CaptureService *captureService = self.captureService;
    
    NSMutableArray<UIMenuElement *> *children = [NSMutableArray new];
    
    //
    
    {
        NSArray<NSNumber *> *photoPixelFormatTypes;
        if (self.processedFileType == nil) {
            photoPixelFormatTypes = captureService.capturePhotoOutput.availablePhotoPixelFormatTypes;
        } else {
            photoPixelFormatTypes = [captureService.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:self.processedFileType];
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
                weakSelf.photoPixelFormatType = formatNumber;
                weakSelf.codecType = nil;
                if (selectionHandler) selectionHandler();
            }];
            
            [string release];
            
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            action.state = [self.photoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
            
            [photoPixelFormatTypeActions addObject:action];
        }
        
        UIMenu *photoPixelFormatTypesMenu = [UIMenu menuWithTitle:@"Pixel Format"
                                                            image:[UIImage systemImageNamed:@"dot.square"]
                                                       identifier:nil
                                                          options:0
                                                         children:photoPixelFormatTypeActions];
        [photoPixelFormatTypeActions release];
        
        if (NSNumber *photoPixelFormatType = self.photoPixelFormatType) {
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
        if (self.processedFileType == nil) {
            availablePhotoCodecTypes = captureService.capturePhotoOutput.availablePhotoCodecTypes;
        } else {
            availablePhotoCodecTypes = [captureService.capturePhotoOutput supportedPhotoCodecTypesForFileType:self.processedFileType];
        }
        
        NSMutableArray<UIAction *> *photoCodecTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoCodecTypes.count];
        
        for (AVVideoCodecType photoCodecType in availablePhotoCodecTypes) {
            UIAction *action = [UIAction actionWithTitle:photoCodecType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.photoPixelFormatType = nil;
                weakSelf.codecType = photoCodecType;
                if (selectionHandler) selectionHandler();
            }];
            
            action.state = [self.codecType isEqualToString:photoCodecType] ? UIMenuElementStateOn : UIMenuElementStateOff;
            action.attributes = UIMenuElementAttributesKeepsMenuPresented;
            
            [photoCodecTypeActions addObject:action];
        }
        
        UIMenu *photoCodecTypesMenu = [UIMenu menuWithTitle:@"Codec"
                                                      image:[UIImage systemImageNamed:@"rectangle.on.rectangle.badge.gearshape"]
                                                 identifier:nil
                                                    options:0
                                                   children:photoCodecTypeActions];
        [photoCodecTypeActions release];
        photoCodecTypesMenu.subtitle = self.codecType;
        [children addObject:photoCodecTypesMenu];
    }
    
    //
    
    {
        if (self.photoPixelFormatType == nil) {
            NSMutableArray<UIAction *> *qualityActions = [[NSMutableArray alloc] initWithCapacity:10];
            
            for (NSUInteger count = 1; count <= 10; count++) {
                float quality = static_cast<float>(count) / 10.f;
                
                UIAction *action = [UIAction actionWithTitle:@(quality).stringValue image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    weakSelf.quality = quality;
                    if (selectionHandler) selectionHandler();
                }];
                
                action.state = (self.quality == quality) ? UIMenuElementStateOn : UIMenuElementStateOff;
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                [qualityActions addObject:action];
            }
            
            UIMenu *qualityMenu = [UIMenu menuWithTitle:@"Quality"
                                                  image:[UIImage systemImageNamed:@"slider.horizontal.below.sun.max"]
                                             identifier:nil
                                                options:0
                                               children:qualityActions];
            [qualityActions release];
            qualityMenu.subtitle = @(self.quality).stringValue;
            
            [children addObject:qualityMenu];
        }
    }
    
    //
    
    
    NSMutableArray<UIMenuElement *> *rawMenuElements = [[NSMutableArray alloc] initWithCapacity:self.isRAWEnabled ? 4 : 1];
    
    {
        UIAction *rawEnabledAction = [UIAction actionWithTitle:@"Enable RAW"
                                                         image:[UIImage systemImageNamed:@"compass.drawing"]
                                                    identifier:nil
                                                       handler:^(__kindof UIAction * _Nonnull action) {
            weakSelf.isRAWEnabled = !weakSelf.isRAWEnabled;
            if (weakSelf.isRAWEnabled) {
                weakSelf.rawPhotoPixelFormatType = captureService.capturePhotoOutput.availableRawPhotoPixelFormatTypes.lastObject;
                weakSelf.rawFileType = captureService.capturePhotoOutput.availableRawPhotoFileTypes.lastObject;
                weakSelf.processedFileType = nil;
            } else {
                weakSelf.rawPhotoPixelFormatType = nil;
                weakSelf.rawFileType = nil;
                weakSelf.processedFileType = nil;
            }
            if (selectionHandler) selectionHandler();
        }];
        
        rawEnabledAction.state = self.isRAWEnabled ? UIMenuElementStateOn : UIMenuElementStateOff;
        rawEnabledAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
        
        [rawMenuElements addObject:rawEnabledAction];
    }
    
    if (self.isRAWEnabled) {
        {
            NSArray<NSNumber *> *availableRawPhotoPixelFormatTypes;
            if (self.processedFileType == nil) {
                availableRawPhotoPixelFormatTypes = captureService.capturePhotoOutput.availableRawPhotoPixelFormatTypes;
            } else {
                availableRawPhotoPixelFormatTypes = [captureService.capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:self.processedFileType];
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
                    weakSelf.rawPhotoPixelFormatType = formatNumber;
                    if (selectionHandler) selectionHandler();
                }];
                
                [string release];
                
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = [self.rawPhotoPixelFormatType isEqualToNumber:formatNumber] ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [rawPhotoPixelFormatTypeActions addObject:action];
            }
            
            UIMenu *rawPhotoPixelFormatTypesMenu = [UIMenu menuWithTitle:@"Raw Photo Pixel Format"
                                                                   image:[UIImage systemImageNamed:@"squareshape.dotted.squareshape"]
                                                              identifier:nil
                                                                 options:0
                                                                children:rawPhotoPixelFormatTypeActions];
            
            if (NSNumber *rawPhotoPixelFormatType = self.rawPhotoPixelFormatType) {
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
                    weakSelf.rawFileType = fileType;
                    if (selectionHandler) selectionHandler();
                }];
                
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = [self.rawFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                [rawFileTypeActions addObject:action];
            }
            
            UIMenu *rawFileTypesMenu = [UIMenu menuWithTitle:@"Raw Photo File Type"
                                                       image:nil
                                                  identifier:nil
                                                     options:0
                                                    children:rawFileTypeActions];
            [rawFileTypeActions release];
            
            if (AVFileType rawFileType = self.rawFileType) {
                rawFileTypesMenu.subtitle = rawFileType;
            }
            
            [rawMenuElements addObject:rawFileTypesMenu];
            
            //
            
            NSArray<AVFileType> *availablePhotoFileTypes = captureService.capturePhotoOutput.availablePhotoFileTypes;
            NSMutableArray<UIAction *> *availablePhotoFileTypeActions = [[NSMutableArray alloc] initWithCapacity:availablePhotoFileTypes.count + 1];
            
            UIAction *nullAction = [UIAction actionWithTitle:@"(null)" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                weakSelf.processedFileType = nil;
                if (selectionHandler) selectionHandler();
            }];
            nullAction.attributes = UIMenuElementAttributesKeepsMenuPresented;
            nullAction.state = (self.processedFileType == nil) ? UIMenuElementStateOn : UIMenuElementStateOff;
            [availablePhotoFileTypeActions addObject:nullAction];
            
            for (AVFileType fileType in availablePhotoFileTypes) {
                UIAction *action = [UIAction actionWithTitle:fileType image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    weakSelf.processedFileType = fileType;
                    
                    NSArray<NSNumber *> *supportedPhotoPixelFormatTypes = [captureService.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:fileType];
                    if (![supportedPhotoPixelFormatTypes containsObject:weakSelf.photoPixelFormatType]) {
                        weakSelf.photoPixelFormatType = supportedPhotoPixelFormatTypes.lastObject;
                    }
                    
                    NSArray<AVFileType> *supportedPhotoCodecTypesForFileType = [captureService.capturePhotoOutput supportedPhotoCodecTypesForFileType:fileType];
                    if (![supportedPhotoCodecTypesForFileType containsObject:weakSelf.codecType]) {
                        weakSelf.codecType = supportedPhotoCodecTypesForFileType.lastObject;
                    }
                    
                    NSArray<NSNumber *> *supportedRawPhotoPixelFormatTypesForFileType = [captureService.capturePhotoOutput supportedRawPhotoPixelFormatTypesForFileType:fileType];
                    if (![supportedRawPhotoPixelFormatTypesForFileType containsObject:weakSelf.rawPhotoPixelFormatType]) {
                        weakSelf.rawPhotoPixelFormatType = supportedRawPhotoPixelFormatTypesForFileType.lastObject;
                    }
                    
                    if (selectionHandler) selectionHandler();
                }];
                action.attributes = UIMenuElementAttributesKeepsMenuPresented;
                action.state = [self.processedFileType isEqualToString:fileType] ? UIMenuElementStateOn : UIMenuElementStateOff;
                [availablePhotoFileTypeActions addObject:action];
            }
            
            UIMenu *processedFileTypesMenu = [UIMenu menuWithTitle:@"Raw Photo Processed File Type"
                                                             image:nil
                                                        identifier:nil
                                                           options:0
                                                          children:availablePhotoFileTypeActions];
            [availablePhotoFileTypeActions release];
            
            if (AVFileType processedFileType = self.processedFileType) {
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
    
    return [children autorelease];
}

@end
