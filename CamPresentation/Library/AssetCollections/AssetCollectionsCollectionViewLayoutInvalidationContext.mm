//
//  AssetCollectionsCollectionViewLayoutInvalidationContext.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/5/24.
//

#import <CamPresentation/AssetCollectionsCollectionViewLayoutInvalidationContext.h>

@implementation AssetCollectionsCollectionViewLayoutInvalidationContext

- (instancetype)init {
    if (self = [super init]) {
        _newBounds = CGRectNull;
    }
    
    return self;
}

- (void)dealloc {
    [_preferredAttributes release];
    [_originalAttributes release];
    [super dealloc];
}

@end
