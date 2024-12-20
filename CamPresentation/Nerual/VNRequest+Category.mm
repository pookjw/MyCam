//
//  VNRequest+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/20/24.
//

#import <CamPresentation/VNRequest+Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

/*
 1. [VNDetector processUsingQualityOfServiceClass:options:regionOfInterest:warningRecorder:error:progressHandler:]와 -[VNDetector internalProcessUsingQualityOfServiceClass:options:regionOfInterest:warningRecorder:error:progressHandler:]를 재작성 해야함
 2. -[VNDetector internalProcessUsingQualityOfServiceClass:options:regionOfInterest:warningRecorder:error:progressHandler:]에서 block 0이 resize, block 3가 실제 처리 blraa가 두번 불리는거 보임 <+624>
 3. -[VNRequest performInContext:error:]을 재작성 해야함 위 API로 
 */

namespace cp_keys {
static void *flagKey = &flagKey;
}

namespace cp_VNCoreMLRequest {
namespace internalPerformRevision_inContext_error_ {
BOOL (*original)(VNCoreMLModel *self, SEL _cmd, NSUInteger revision, id context, NSError * _Nullable __autoreleasing * _Nullable error);
BOOL custom(VNCoreMLModel *self, SEL _cmd, NSUInteger revision, id context, NSError * _Nullable __autoreleasing * _Nullable error) {
    return original(self, _cmd, revision, context, error);
}
void swizzle() {
    Method method = class_getInstanceMethod([VNCoreMLRequest class], sel_registerName("internalPerformRevision:inContext:error:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

namespace cp_VNRequest {
namespace performInContext_error_ {
BOOL (*original)(__kindof VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable error);
BOOL custom(__kindof VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable error) {
    BOOL isAsyncEnabled = static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_keys::flagKey)).boolValue;
    
    if (!isAsyncEnabled) {
        return original(self, _cmd, context, error);
    }
    
//    return original(self, _cmd, context, error);
    
    assert([self class] == [VNCoreMLRequest class]);
    
    NSUInteger serialNumber = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(context, sel_registerName("serialNumber"));
    NSUInteger resolvedRevision = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("resolvedRevision"));
    Class frameworkClass = reinterpret_cast<Class (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("frameworkClass"));
    NSUInteger VNClassCode = reinterpret_cast<NSUInteger (*)(Class, SEL)>(objc_msgSend)(frameworkClass, sel_registerName("VNClassCode"));
    
    BOOL cancellationTriggered = reinterpret_cast<BOOL (*)(id, SEL, id *)>(objc_msgSend)(self, sel_registerName("cancellationTriggeredAndReturnError:"), error);
    
    if (cancellationTriggered) {
        self.completionHandler(self, *error);
        return NO;
    }
    
    if (!reinterpret_cast<BOOL (*)(Class, SEL, NSUInteger)>(objc_msgSend)(frameworkClass, sel_registerName("supportsAnyRevision:"), resolvedRevision)) {
        __kindof NSError *vnError = reinterpret_cast<id (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(objc_lookUpClass("VNError"), sel_registerName("errorForUnsupportedRevision:ofRequest:"), resolvedRevision, self);
        self.completionHandler(self, vnError);
        return NO;
    }
    
    id cachedObservations = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)(context, sel_registerName("cachedObservationsAcceptedByRequest:"), self);
    
    if (cachedObservations) {
        reinterpret_cast<void (*)(id, SEL, id, BOOL)>(objc_msgSend)(self, sel_registerName("setResults:assignedWithOriginatingSpecifier:"), cachedObservations, NO);
        self.completionHandler(self, nil);
        return YES;
    }
    
    if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("hasCancellationHook"))) {
        // TODO
        abort();
    }
    
    BOOL result = reinterpret_cast<BOOL (*)(id, SEL, NSUInteger, id, id *)>(objc_msgSend)(self, sel_registerName("internalPerformRevision:inContext:error:"), resolvedRevision, context, error);
    
    if (!result) {
        self.completionHandler(self, *error);
        return NO;
    }
    
    BOOL setsTimeRangeOnResults = reinterpret_cast<BOOL (*)(Class, SEL)>(objc_msgSend)(frameworkClass, sel_registerName("setsTimeRangeOnResults"));
    
    if (setsTimeRangeOnResults) {
        abort();
        // TODO: <+1036>
    }
    
    // VNImageBuffer *
    id imageBuffer = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(context, sel_registerName("imageBufferAndReturnError:"), error);
    
    if (imageBuffer == nil) {
        abort();
        // TODO: <+724>
    }
    
    CMTime timingInfo = reinterpret_cast<CMTime (*)(id, SEL)>(objc_msgSend)(imageBuffer, sel_registerName("timingInfo"));
    
    NSArray<VNObservation *> *results = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("results"));
    
    // TODO: Loop results and -setTimeRange:
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(context, sel_registerName("recordSequencedObservationsOfRequest:"), self);
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(context, sel_registerName("cacheObservationsOfRequest:"), self);
    
    self.completionHandler(self, nil);
    
    return YES;
}
void swizzle() {
    Method method = class_getInstanceMethod([VNRequest class], sel_registerName("performInContext:error:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

namespace cp_VNDetector {

}


@implementation VNRequest (Category)

+ (void)load {
    cp_VNCoreMLRequest::internalPerformRevision_inContext_error_::swizzle();
    cp_VNRequest::performInContext_error_::swizzle();
}

- (void)cp_setProcessAsynchronously:(BOOL)cp_processAsynchronously {
    objc_setAssociatedObject(self, cp_keys::flagKey, @(cp_processAsynchronously), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cp_processAsynchronously {
    return static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_keys::flagKey)).boolValue;
}

@end
