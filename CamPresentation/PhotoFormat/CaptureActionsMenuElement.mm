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

@interface _CaptureActionsMenuElementStorage : NSObject
@property (class, nonatomic, readonly) void *key;
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (copy, nonatomic, readonly) PhotoFormatModel *photoFormatModel;
@property (copy, nonatomic, readonly, nullable) void (^reloadHandler)(PhotoFormatModel * _Nonnull);
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCaptureService:(CaptureService *)captureService photoFormatModel:(PhotoFormatModel *)photoFormatModel reloadHandler:(void (^ _Nullable)(PhotoFormatModel *photoFormatModel))reloadHandler;
@end

@implementation _CaptureActionsMenuElementStorage

+ (void *)key {
    static void *key = &key;
    return key;
}

- (instancetype)initWithCaptureService:(CaptureService *)captureService photoFormatModel:(PhotoFormatModel *)photoFormatModel reloadHandler:(void (^)(PhotoFormatModel * _Nonnull))reloadHandler {
    if (self = [super init]) {
        _captureService = [captureService retain];
        _photoFormatModel = [photoFormatModel copy];
        _reloadHandler = [reloadHandler copy];
    }
    
    return self;
}

- (void)dealloc {
    [_captureService release];
    [_photoFormatModel release];
    [_reloadHandler release];
    [super dealloc];
}

@end


@interface CaptureActionsMenuElement ()
@property (retain, nonatomic, readonly) _CaptureActionsMenuElementStorage *storage;
@end

@implementation CaptureActionsMenuElement

+ (instancetype)elementWithCaptureService:(CaptureService *)captureService photoFormatModel:(PhotoFormatModel *)photoFormatModel reloadHandler:(void (^)(PhotoFormatModel * _Nonnull))reloadHandler {
    __block CaptureActionsMenuElement *result = static_cast<CaptureActionsMenuElement *>([UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        assert(object_getClass(result) == CaptureActionsMenuElement.class);
        [result menuElementsWithcompletionHandler:completion];
    }]);
    
    assert(object_setClass(result, CaptureActionsMenuElement.class) != NULL);
    
    //
    
    _CaptureActionsMenuElementStorage *storage = [[_CaptureActionsMenuElementStorage alloc] initWithCaptureService:captureService photoFormatModel:photoFormatModel reloadHandler:reloadHandler];
    
    objc_setAssociatedObject(result, _CaptureActionsMenuElementStorage.key, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [storage release];
    
    //
    
    
    
    //
    
    return result;
}

- (void)dealloc {
    [super dealloc];
}

- (_CaptureActionsMenuElementStorage *)storage {
    return objc_getAssociatedObject(self, _CaptureActionsMenuElementStorage.key);
}

- (void)menuElementsWithcompletionHandler:(void (^)(NSArray<__kindof UIMenuElement *> *))completionHandler {
    UIAction *action = [UIAction actionWithTitle:@"Test" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
    }];
    
    completionHandler(@[action]);
}

@end
