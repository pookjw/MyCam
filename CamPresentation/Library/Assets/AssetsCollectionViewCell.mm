//
//  AssetsCollectionViewCell.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsCollectionViewCell.h>
#import <CamPresentation/AssetsContentView.h>

@implementation AssetsCollectionViewCell

+ (Class)_contentViewClass {
    return AssetsContentView.class;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    static_cast<AssetsContentView *>(self.contentView).selected = selected;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    static_cast<AssetsContentView *>(self.contentView).highlighted = highlighted;
}

- (void)setModel:(AssetsItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetsContentView *>(self.contentView).model = model;
}

@end
