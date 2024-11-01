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
@property (retain, nonatomic, readonly) dispatch_queue_t queue;
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
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, QOS_MIN_RELATIVE_PRIORITY);
        dispatch_queue_t queue = dispatch_queue_create("Asset Collection Content View Queue", attr);
        _queue = queue;
        
        UIStackView *stackView = self.stackView;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), stackView);
    }
    
    return self;
}

- (void)dealloc {
    dispatch_release(_queue);
    [_collection release];
    [_stackView release];
    [_imageView release];
    [_label release];
    [super dealloc];
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
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

- (UILabel *)label {
    if (auto label = _label) return label;
    
    UILabel *label = [UILabel new];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    
    _label = [label retain];
    return [label autorelease];
}

- (void)setCollection:(PHAssetCollection *)collection {
    [_collection release];
    _collection = [collection retain];
    
    UIImageView *imageView = self.imageView;
    UILabel *label = self.label;
    
    imageView.image = nil;
    label.text = nil;
    
    dispatch_async(self.queue, ^{
        NSString *localizedTitle = collection.localizedTitle;
        
        PHFetchOptions *options = [PHFetchOptions new];
        options.wantsIncrementalChangeDetails = NO;
        options.fetchLimit = 1;
        
        PHFetchResult<PHAsset *> * assetFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        [options release];
        
        PHAsset * _Nullable asset = assetFetchResult.firstObject;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.collection isEqual:collection]) return;
            
            label.text = localizedTitle;
        });
    });
}

@end
