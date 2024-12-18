//
//  AssetCollectionViewCell.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/AssetCollectionViewCell.h>
#import <CamPresentation/AssetContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@implementation AssetCollectionViewCell

+ (Class)_contentViewClass {
    return AssetContentView.class;
}

- (AssetContentView *)ownContentView {
    return static_cast<AssetContentView *>(self.contentView);
}

- (void)_notifyIsDisplaying:(BOOL)isDisplaying {
    objc_super superInfo = { self, [self class] };
    reinterpret_cast<void (*)(objc_super *, SEL, BOOL)>(objc_msgSendSuper2)(&superInfo, _cmd, isDisplaying);
    
    [self.ownContentView didChangeIsDisplaying:isDisplaying];
}

@end
