//
//  MyCompositionalLayout.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/5/24.
//

#import "MyCompositionalLayout.h"

@implementation MyCompositionalLayout

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
//    NSLog(@"%@ %@", preferredAttributes, originalAttributes);
    BOOL result = [super shouldInvalidateLayoutForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
    NSLog(@"%d", result);
    return result;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
    NSLog(@"%@ %@", preferredAttributes, originalAttributes);
    return [super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    if (context.invalidatedItemIndexPaths.count > 0) {
        pause();
    }
    NSLog(@"%@", [context invalidatedItemIndexPaths]);
    [super invalidateLayoutWithContext:context];
}

@end
