//
//  CALayer+CP_UIKit.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/6/25.
//

#import <CamPresentation/CALayer+CP_UIKit.h>

@implementation CALayer (CP_UIKit)

- (UIView *)cp_associatedView {
    __kindof CALayer * _Nullable targetLayer = self;
    
    while (targetLayer != nil) {
        id<CALayerDelegate> delegate = targetLayer.delegate;
        
        if ([delegate isKindOfClass:[UIView class]]) {
            return static_cast<UIView *>(delegate);
        }
        
        targetLayer = targetLayer.superlayer;
    }
    
    return nil;
}

@end
