//
//  AssetCollectionsCell.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionsCell.h>
#import <CamPresentation/AssetCollectionsContentView.h>

@implementation AssetCollectionsCell

+ (Class)_contentViewClass {
    return AssetCollectionsContentView.class;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

- (void)setModel:(AssetCollectionsItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetCollectionsContentView *>(self.contentView).model = model;
}

@end
