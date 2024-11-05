//
//  AssetCollectionContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetCollectionContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>

@interface AssetCollectionContentView ()
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) UIImageView *symbolImageView;
@property (retain, nonatomic, readonly) UILabel *label;
@property (assign, nonatomic, readonly) CGSize targetSize;
@end

@implementation AssetCollectionContentView
@synthesize stackView = _stackView;
@synthesize imageView = _imageView;
@synthesize symbolImageView = _symbolImageView;
@synthesize label = _label;

+ (void)load {
    assert(dlopen("/System/Library/PrivateFrameworks/PhotosUICore.framework/PhotosUICore", RTLD_NOW) != NULL);
}

+ (Class)_contentViewClass {
    abort();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIStackView *stackView = self.stackView;
        [self addSubview:stackView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
        
        UIImageView *imageView = self.imageView;
        NSLayoutConstraint *squareConstraint = [imageView.widthAnchor constraintEqualToAnchor:imageView.heightAnchor];
//        squareConstraint.priority = UILayoutPriorityRequired;
        squareConstraint.priority = UILayoutPriorityDefaultHigh;
        [NSLayoutConstraint activateConstraints:@[
            [imageView.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
            squareConstraint
        ]];
        
        UIImageView *symbolImageView = self.symbolImageView;
        [self addSubview:symbolImageView];
        symbolImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [symbolImageView.trailingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:-20.],
            [symbolImageView.bottomAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:-20.],
            [symbolImageView.widthAnchor constraintEqualToConstant:40.],
            [symbolImageView.heightAnchor constraintEqualToConstant:40.]
        ]];
        
        UILabel *label = self.label;
        [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_stackView release];
    [_imageView release];
    [_symbolImageView release];
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
    CGFloat displayScale = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_currentScreenScale"));
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

- (UIImageView *)symbolImageView {
    if (auto symbolImageView = _symbolImageView) return symbolImageView;
    
    UIImageView *symbolImageView = [UIImageView new];
    symbolImageView.contentMode = UIViewContentModeScaleAspectFit;
    symbolImageView.tintColor = UIColor.whiteColor;
    
    CGColorRef blackColor = CGColorCreateGenericGray(0., 1.);
    symbolImageView.layer.shadowColor = blackColor;
    CGColorRelease(blackColor);
    symbolImageView.layer.shadowOpacity = 1.f;
    symbolImageView.layer.shadowRadius = 10.f;
    
    _symbolImageView = [symbolImageView retain];
    return [symbolImageView autorelease];
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
    if (CGSizeEqualToSize(_model.targetSize, model.targetSize) && [_model.collection isEqual:model.collection]) return;
    
    [_model cancelRequest];
    [_model release];
    _model = [model retain];
    
    NSString *px_symbolImageName = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(model.collection, sel_registerName("px_symbolImageName"));
    self.symbolImageView.image = [UIImage systemImageNamed:px_symbolImageName];
    
    UIImageView *imageView = self.imageView;
    UILabel *label = self.label;
    
    imageView.image = nil;
    label.text = nil;
    
    imageView.alpha = 0.;
    label.alpha = 0.;
    
    __weak auto weakSelf = self;
    
    model.resultHandler = ^(UIImage * _Nullable result, NSDictionary * _Nullable info, NSString * _Nullable localizedTitle, NSUInteger assetsCount) {
        dispatch_assert_queue(dispatch_get_main_queue());
        
        if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
            if (cancelledNumber.boolValue) {
                NSLog(@"Cancelled");
                return;
            }
        }
        
        auto unretained = weakSelf;
        if (unretained == nil) return;
        
        if (NSNumber *requestIDNumber = info[PHImageResultRequestIDKey]) {
            if (unretained.model.requestID != requestIDNumber.integerValue) {
                NSLog(@"Request ID does not equal.");
                return;
            }
        }
        
        if (NSError *error = info[PHImageErrorKey]) {
            NSLog(@"%@", error);
            return;
        }
        
        //
        
        label.text = [NSString stringWithFormat:@"%@ (%ld)", localizedTitle, assetsCount];
        imageView.image = result;
        
        [UIView animateWithDuration:0.2 animations:^{
            if (imageView.image != nil) {
                imageView.alpha = 1.;
            }
            
            if (label.text != nil) {
                label.alpha = 1.;
            }
        }];
        
        [self invalidateIntrinsicContentSize];
    };
    
    [model requestImageWithTargetSize:self.targetSize];
}

@end
