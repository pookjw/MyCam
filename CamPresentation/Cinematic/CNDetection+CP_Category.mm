//
//  CNDetection+CP_Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/13/25.
//

// -[PTCinematographyCustomTrack _initWithCustomTrack:]

#import <CamPresentation/CNDetection+CP_Category.h>

#if !TARGET_OS_SIMULATOR && !TARGET_OS_VISION

#import <objc/message.h>
#import <objc/runtime.h>

namespace cp_PTCinematographyCustomTrack {
    namespace _initWithCustomTrack_ {
        id (*original)(id self, SEL _cmd, id customTrack);
        id custom(id self, SEL _cmd, id customTrack) {
            self = original(self, _cmd, customTrack);
            
            if (self) {
                CNDetectionID trackIdentifier = reinterpret_cast<CNDetectionID (*)(id, SEL)>(objc_msgSend)(customTrack, sel_registerName("trackIdentifier"));
                reinterpret_cast<void (*)(id, SEL, CNDetectionID)>(objc_msgSend)(self, sel_registerName("setTrackIdentifier:"), trackIdentifier);
            }
            
            return self;
        }
        void swizzle() {
            Method method = class_getInstanceMethod(objc_lookUpClass("PTCinematographyCustomTrack"), sel_registerName("_initWithCustomTrack:"));
            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
}

@implementation CNDetection (CP_Category)

+ (void)load {
    if (@available(macOS 26.0, iOS 26.0, tvOS 26.0, *)) {
        // nop
    } else {
        cp_PTCinematographyCustomTrack::_initWithCustomTrack_::swizzle();
    }
}

@end

#endif
