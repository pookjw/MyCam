//
//  UIImage+CP_Category.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/11/25.
//

#import <CamPresentation/UIImage+CP_Category.h>

@implementation UIImage (CP_Category)

- (UIImage *)cp_imageByPreparingForDisplay {
    dispatch_assert_queue_not(dispatch_get_main_queue());
    
    UIImage * _Nullable imageByPreparingForDisplay = self.imageByPreparingForDisplay;
    
    if (imageByPreparingForDisplay == nil) {
        return self;
    }
    
    return imageByPreparingForDisplay;
}

@end
