//
//  AssetCollectionContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionContentView.h>

@implementation AssetCollectionContentView

+ (Class)_contentViewClass {
    abort();
}

- (void)dealloc {
    [_collection release];
    [super dealloc];
}

- (void)setCollection:(PHAssetCollection *)collection {
    [_collection release];
    _collection = [collection retain];
    
    // TODO
}

@end
