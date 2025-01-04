//
//  AVPlayerItemVideoOutput+Category.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/4/25.
//

#import <CamPresentation/AVPlayerItemVideoOutput+Category.h>
#import <objc/message.h>
#import <objc/runtime.h>

@implementation AVPlayerItemVideoOutput (Category)

- (AVPlayerItem *)cp_playerItem {
    id _videoOutputInternal;
    assert(object_getInstanceVariable(self, "_videoOutputInternal", reinterpret_cast<void **>(&_videoOutputInternal)));
    id playerItemWeakReference;
    assert(object_getInstanceVariable(_videoOutputInternal, "playerItemWeakReference", reinterpret_cast<void **>(&playerItemWeakReference)));
    AVPlayerItem *playerItem = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(playerItemWeakReference, sel_registerName("referencedObject"));
    
    return playerItem;
}

@end
