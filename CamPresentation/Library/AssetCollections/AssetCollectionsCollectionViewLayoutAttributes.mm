//
//  AssetCollectionsCollectionViewLayoutAttributes.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/5/24.
//

#import <CamPresentation/AssetCollectionsCollectionViewLayoutAttributes.h>

@implementation AssetCollectionsCollectionViewLayoutAttributes

- (id)copyWithZone:(struct _NSZone *)zone {
    auto copy = static_cast<AssetCollectionsCollectionViewLayoutAttributes *>([super copyWithZone:zone]);
    
    assert([copy isKindOfClass:AssetCollectionsCollectionViewLayoutAttributes.class]);
    copy->_originalY = _originalY;
    
    return copy;
}

@end
