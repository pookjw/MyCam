//
//  AssetCollectionsHeaderView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionsHeaderView.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetCollectionsHeaderView ()
@property (retain, nonatomic, readonly) UIVisualEffectView *blurView;
@property (retain, nonatomic, readonly) UILabel *label;
@end

@implementation AssetCollectionsHeaderView
@synthesize blurView = _blurView;
@synthesize label = _label;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIVisualEffectView *blurView = self.blurView;
        [self addSubview:blurView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), blurView);
        
        UILabel *label = self.label;
        [self addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:20.],
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20.],
            [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20.],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-20.]
        ]];
    }
    
    return self;
}

- (void)dealloc {
    [_blurView release];
    [_label release];
    [super dealloc];
}

- (UIVisualEffectView *)blurView {
    if (auto blurView = _blurView) return blurView;
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    
    _blurView = [blurView retain];
    return [blurView autorelease];
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    label.textAlignment = NSTextAlignmentNatural;
    label.numberOfLines = 1;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)setTitle:(NSString *)title {
    self.label.text = title;
}

- (NSString *)title {
    return self.label.text;
}

@end
