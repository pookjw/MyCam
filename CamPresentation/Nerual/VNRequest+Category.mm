//
//  VNRequest+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/20/24.
//

#import <CamPresentation/VNRequest+Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace cp_keys {
static void *flagKey = &flagKey;
static void *completionHandlerKey = &completionHandlerKey;
}

namespace cp_VNCoreMLRequest {
namespace internalPerformRevision_inContext_error_ {
BOOL (*original)(VNCoreMLModel *self, SEL _cmd, NSUInteger revision, id context, NSError * _Nullable __autoreleasing * _Nullable error);
BOOL custom(VNCoreMLModel *self, SEL _cmd, NSUInteger revision, id context, NSError * _Nullable __autoreleasing * _Nullable error) {
    BOOL isAsyncEnabled = static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_keys::flagKey)).boolValue;
    
    if (!isAsyncEnabled) {
        return original(self, _cmd, revision, context, error);
    }
    
    id imageBuffer = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(context, sel_registerName("imageBufferAndReturnError:"), error);
    if (imageBuffer == nil) {
        return NO;
    }
    
    id session = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(context, sel_registerName("session"));
    
    /*
     {
         "VNDetectorInitOption_MemoryPoolId" = 0;
         "VNDetectorInitOption_ModelBackingStore" = 0;
         "VNDetectorOption_ComputeStageDeviceAssignments" =     {
         };
         "VNDetectorOption_EspressoPlanPriority" = 0;
         "VNDetectorOption_OriginatingRequestSpecifier" = VNCoreMLRequestRevision1;
         "VNDetectorOption_PreferBackgroundProcessing" = 0;
         "VNDetectorProcessOption_Session" = "<_VNGlobalSession: 0x302394190>";
     }
     */
    NSMutableDictionary *options = reinterpret_cast<id (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(self, sel_registerName("newDefaultDetectorOptionsForRequestRevision:session:"), revision, session);
    [options autorelease];
    
    NSUInteger imageCropAndScaleOption = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("imageCropAndScaleOption"));
    options[@"VNDetectorProcessOption_ImageCropAndScaleOption"] = @(imageCropAndScaleOption);
    
    VNCoreMLModel *model = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("model"));
    
    id transformer = reinterpret_cast<id (*)(id, SEL, id, id, id *)>(objc_msgSend)([objc_lookUpClass("VNCoreMLTransformer") alloc], sel_registerName("initWithOptions:model:error:"), options, model, error);
    assert(transformer != nil); // TOOD: Error
    
    options[@"VNDetectorProcessOption_InputImageBuffers"] = [NSArray arrayWithObjects:&imageBuffer count:1];
    
    
    if (reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(model, sel_registerName("scenePrintRequestSpecifier")) != nil) {
        abort();
        // TODO: <+336>
    } else if (reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(model, sel_registerName("detectionPrintRequestSpecifier")) != nil) {
        abort();
        // TODO: <+488>
    }
    
    NSUInteger qosClass = reinterpret_cast<NSUInteger (*)(id, SEL)>(objc_msgSend)(context, sel_registerName("qosClass"));
    CGRect regionOfInterest = reinterpret_cast<CGRect (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("regionOfInterest"));
    
    id results = reinterpret_cast<id (*)(id, SEL, NSUInteger, id, CGRect, id, id *, id)>(objc_msgSend)(transformer, sel_registerName("processUsingQualityOfServiceClass:options:regionOfInterest:warningRecorder:error:progressHandler:"), qosClass, options, regionOfInterest, self, error, nil);
    
    if (results == nil) {
        return NO;
    }
    
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("setResults:"), results);
    return YES;
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
    
    return YES;
//    BOOL setsTimeRangeOnResults = reinterpret_cast<BOOL (*)(Class, SEL)>(objc_msgSend)(frameworkClass, sel_registerName("setsTimeRangeOnResults"));
//    
//    if (setsTimeRangeOnResults) {
//        abort();
//        // TODO: <+1036>
//    }
//    
//    // VNImageBuffer *
//    id imageBuffer = reinterpret_cast<id (*)(id, SEL, id *)>(objc_msgSend)(context, sel_registerName("imageBufferAndReturnError:"), error);
//    
//    if (imageBuffer == nil) {
//        abort();
//        // TODO: <+724>
//    }
//    
//    CMTime timingInfo = reinterpret_cast<CMTime (*)(id, SEL)>(objc_msgSend)(imageBuffer, sel_registerName("timingInfo"));
//    
//    NSArray<VNObservation *> *results = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("results"));
//    
//    // TODO: Loop results and -setTimeRange:
//    
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(context, sel_registerName("recordSequencedObservationsOfRequest:"), self);
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(context, sel_registerName("cacheObservationsOfRequest:"), self);
//    
//    self.completionHandler(self, nil);
//    
//    return YES;
}
void swizzle() {
    Method method = class_getInstanceMethod([VNRequest class], sel_registerName("performInContext:error:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}


namespace cp_VNDetector {
namespace internalProcessUsingQualityOfServiceClass_options_regionOfInterest_warningRecorder_error_progressHandler_ {
id (*original)(id self, SEL _cmd, NSUInteger qosClass, NSDictionary *options, CGRect regionOfInterest, id warningRecorder, NSError * _Nullable __autoreleasing * _Nullable error);
id custom(id self, SEL _cmd, NSUInteger qosClass, NSDictionary *options, CGRect regionOfInterest, id warningRecorder, NSError * _Nullable __autoreleasing * _Nullable error) {
    auto request = static_cast<__kindof VNRequest *>(warningRecorder);
    
    BOOL isAsyncEnabled = static_cast<NSNumber *>(objc_getAssociatedObject(request, cp_keys::flagKey)).boolValue;
    if (!isAsyncEnabled) {
        return original(self, _cmd, qosClass, options, regionOfInterest, request, error);
    }
    
    CVPixelBufferRef croppedPixelBuffer;
    BOOL result_1 = reinterpret_cast<BOOL (*)(id, SEL, CGRect, id, NSUInteger, id, CVPixelBufferRef *, id *, id)>(objc_msgSend)(self, sel_registerName("createRegionOfInterestCrop:options:qosClass:warningRecorder:pixelBuffer:error:progressHandler:"), regionOfInterest, options, qosClass, warningRecorder, &croppedPixelBuffer, error, nil);
    
    if (!result_1) {
        return nil;
    }
    
    id nsObj = (id)croppedPixelBuffer;
    
//    id result_2 = reinterpret_cast<id (*)(id, SEL, CGRect, CVPixelBufferRef, id, NSUInteger, id, id *, id)>(objc_msgSend)(self, sel_registerName("processRegionOfInterest:croppedPixelBuffer:options:qosClass:warningRecorder:error:progressHandler:"), regionOfInterest, croppedPixelBuffer, options, qosClass, warningRecorder, error, nil);
//    
//    return result_2;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        id result_2 = reinterpret_cast<id (*)(id, SEL, CGRect, CVPixelBufferRef, id, NSUInteger, id, id *, id)>(objc_msgSend)(self, sel_registerName("processRegionOfInterest:croppedPixelBuffer:options:qosClass:warningRecorder:error:progressHandler:"), regionOfInterest, (CVPixelBufferRef)nsObj, options, qosClass, warningRecorder, error, nil);
        
        if (result_2 == nil) {
            request.completionHandler(request, *error);
            return;
        }
        
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(request, sel_registerName("setResults:"), result_2);
        request.completionHandler(request, nil);
    });
    
    CVPixelBufferRelease(croppedPixelBuffer);
    
    return @[];
    
    // block_invoke -> block_invoke_2
    // block_invoke_2 -> -[VNCoreMLTransformer createRegionOfInterestCrop:options:qosClass:warningRecorder:pixelBuffer:error:progressHandler:] (objc_method)
    // Back to current frame
    // block_invoke_3 -> block_invoke_4
    // block_invoke_4 -> block_invoke_5
    // block_invoke_5 -> -[VNCoreMLTransformer processRegionOfInterest:croppedPixelBuffer:options:qosClass:warningRecorder:error:progressHandler:]
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("VNDetector"), sel_registerName("internalProcessUsingQualityOfServiceClass:options:regionOfInterest:warningRecorder:error:progressHandler:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}


@implementation VNRequest (Category)

+ (void)load {
//    cp_VNCoreMLRequest::internalPerformRevision_inContext_error_::swizzle();
//    cp_VNRequest::performInContext_error_::swizzle();
//    cp_VNDetector::internalProcessUsingQualityOfServiceClass_options_regionOfInterest_warningRecorder_error_progressHandler_::swizzle();
}

- (void)cp_setProcessAsynchronously:(BOOL)cp_processAsynchronously {
    objc_setAssociatedObject(self, cp_keys::flagKey, @(cp_processAsynchronously), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cp_processAsynchronously {
    return static_cast<NSNumber *>(objc_getAssociatedObject(self, cp_keys::flagKey)).boolValue;
}

@end
