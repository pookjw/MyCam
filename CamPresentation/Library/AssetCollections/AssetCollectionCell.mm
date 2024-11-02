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
    [_model release];
    [super dealloc];
}

- (void)setModel:(AssetCollectionItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetCollectionContentView *>(self.contentView).model = model;
}

@end
