//
//  AssetCollectionsCollectionViewLayoutInvalidationContext.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/5/24.
//

#import <CamPresentation/AssetCollectionsCollectionViewLayoutInvalidationContext.h>

@implementation AssetCollectionsCollectionViewLayoutInvalidationContext

- (void)dealloc {
    [_preferredAttributes release];
    [_originalAttributes release];
    [super dealloc];
}

@end
