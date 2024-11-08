//
//  AssetCollectionViewLayout.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/8/24.
//

#import <CamPresentation/AssetCollectionViewLayout.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@implementation AssetCollectionViewLayout

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)contentOffset withScrollingVelocity:(CGPoint)velocity {
    CGRect bounds = self.collectionView.bounds;
    bounds.origin = contentOffset;
    
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributes = [self layoutAttributesForElementsInRect:bounds];
    NSUInteger count = layoutAttributes.count;
    
    if (count == 0 or count > 2) {
        objc_super superInfo = { self, [self class] };
        return reinterpret_cast<CGPoint (*)(objc_super *, SEL, CGPoint, CGPoint)>(objc_msgSendSuper2)(&superInfo, _cmd, contentOffset, velocity);
    } else if (count == 1) {
        return layoutAttributes[0].frame.origin;
    } else {
        CGFloat x;
        if (velocity.x > 0) {
            x = MAX(layoutAttributes[0].frame.origin.x, layoutAttributes[1].frame.origin.x);
        } else if (velocity.x < 0) {
            x = MIN(layoutAttributes[0].frame.origin.x, layoutAttributes[1].frame.origin.x);
        } else {
            if (abs(contentOffset.x - layoutAttributes[0].frame.origin.x) < abs(contentOffset.x - layoutAttributes[1].frame.origin.x)) {
                x = layoutAttributes[0].frame.origin.x; 
            } else {
                x = layoutAttributes[1].frame.origin.x;
            }
        }
        
        return CGPointMake(x, 0.);
    }
}

@end
