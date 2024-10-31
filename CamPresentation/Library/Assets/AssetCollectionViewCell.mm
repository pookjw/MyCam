//
//  AssetCollectionViewCell.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionViewCell.h>
#import <CamPresentation/AssetContentView.h>

@interface AssetCollectionViewCell ()
@end

@implementation AssetCollectionViewCell

+ (Class)_contentViewClass {
    return AssetContentView.class;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

- (void)setModel:(AssetItemModel *)model {
    [_model release];
    _model = [model retain];
    
    static_cast<AssetContentView *>(self.contentView).model = model;
}

@end
