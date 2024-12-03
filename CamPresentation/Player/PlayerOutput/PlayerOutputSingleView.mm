//
//  PlayerOutputSingleView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/3/24.
//

#import <CamPresentation/PlayerOutputSingleView.h>

@implementation PlayerOutputSingleView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)_commonInit {
    self.backgroundColor = UIColor.systemCyanColor;
}

@end
