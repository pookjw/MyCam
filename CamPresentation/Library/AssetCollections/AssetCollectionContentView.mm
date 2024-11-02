//
//  AssetCollectionContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetCollectionContentView ()
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) UILabel *label;
@property (assign, nonatomic, readonly) CGSize targetSize;
@end

@implementation AssetCollectionContentView
@synthesize stackView = _stackView;
@synthesize imageView = _imageView;
@synthesize label = _label;

+ (Class)_contentViewClass {
    abort();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIStackView *stackView = self.stackView;
        [self addSubview:stackView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_stackView release];
    [_imageView release];
    [_label release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.targetSize, self.model.targetSize)) {
        [self.model cancelRequest];
        [self.model requestImageWithTargetSize:self.targetSize];
    }
}

- (CGSize)targetSize {
    CGSize targetSize = self.bounds.size;
    CGFloat displayScale = self.traitCollection.displayScale;
    targetSize.width *= displayScale;
    targetSize.height *= displayScale;
    
    return targetSize;
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.imageView,
        self.label
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 10.;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 20.;
    imageView.layer.cornerCurve = kCACornerCurveContinuous;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)setModel:(AssetCollectionItemModel *)model {
    [_model cancelRequest];
    [_model release];
    _model = [model retain];
    
    UIImageView *imageView = self.imageView;
    UILabel *label = self.label;
    
    imageView.image = nil;
    label.text = nil;
    
    model.resultHandler = ^(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle) {
        imageView.image = result;
        label.text = localizedTitle;
    };
    
    [model requestImageWithTargetSize:self.targetSize];
}

@end
