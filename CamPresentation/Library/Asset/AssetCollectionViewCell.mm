//
//  AssetCollectionViewCell.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/AssetCollectionViewCell.h>
#import <CamPresentation/AssetContentView.h>

@implementation AssetCollectionViewCell

+ (Class)_contentViewClass {
    return AssetContentView.class;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

- (void)setModel:(AssetsItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetContentView *>(self.contentView).model = model;
}

@end
