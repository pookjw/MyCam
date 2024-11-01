//
//  AssetCollectionCell.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionCell.h>
#import <CamPresentation/AssetCollectionContentView.h>

@implementation AssetCollectionCell

+ (Class)_contentViewClass {
    return AssetCollectionContentView.class;
}

- (void)dealloc {
    [_collection release];
    [super dealloc];
}

- (void)setCollection:(PHAssetCollection *)collection {
    [_collection release];
    _collection = [collection retain];
    
    static_cast<AssetCollectionContentView *>(self.contentView).collection = collection;
}

@end
