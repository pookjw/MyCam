//
//  AssetsCollectionViewCell.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsCollectionViewCell.h>
#import <CamPresentation/AssetsContentView.h>

@interface AssetsCollectionViewCell ()
@end

@implementation AssetsCollectionViewCell

+ (Class)_contentViewClass {
    return AssetsContentView.class;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

- (void)setModel:(AssetsItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetsContentView *>(self.contentView).model = model;
}

@end
