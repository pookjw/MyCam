//
//  AssetContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/AssetContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetContentView () <UIScrollViewDelegate>
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) UIScrollView *scrollView;
@property (retain, nonatomic, readonly) UIView *hostedView;
@property (nonatomic, readonly) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info);
@end

@implementation AssetContentView
@synthesize imageView = _imageView;
@synthesize scrollView = _scrollView;
@synthesize hostedView = _hostedView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), imageView);
        
        UIScrollView *scrollView = self.scrollView;
        [self addSubview:scrollView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), scrollView);
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_scrollView release];
    [_imageView release];
    [_hostedView release];
    [super dealloc];
}

- (void)setModel:(AssetsItemModel *)model {
    if ([_model.asset isEqual:model.asset]) return;
    
    [_model cancelRequest];
    [_model release];
    _model = [model retain];
    
    UIImageView *imageView = self.imageView;
    imageView.image = nil;
    imageView.alpha = 0.;
    
    if (CGSizeEqualToSize(PHImageManagerMaximumSize, model.targetSize)) {
        model.resultHandler = self.resultHandler;
    } else {
        [model cancelRequest];
        model.resultHandler = self.resultHandler;
        [model requestImageWithTargetSize:PHImageManagerMaximumSize];
    }
}

- (void)didChangeIsDisplaying:(BOOL)isDisplaying {
    self.scrollView.zoomScale = 1.;
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.backgroundColor = UIColor.clearColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

- (UIScrollView *)scrollView {
    if (auto scrollView = _scrollView) return scrollView;
    
    UIScrollView *scrollView = [UIScrollView new];
    UIView *hostedView = self.hostedView;
    UIImageView *imageView = self.imageView;
    
    [scrollView addSubview:hostedView];
    hostedView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.centerXAnchor constraintEqualToAnchor:hostedView.centerXAnchor],
        [scrollView.centerYAnchor constraintEqualToAnchor:hostedView.centerYAnchor],
        [scrollView.widthAnchor constraintEqualToAnchor:hostedView.widthAnchor],
        [scrollView.heightAnchor constraintEqualToAnchor:hostedView.heightAnchor],
    ]];
    
    scrollView.maximumZoomScale = 5.;
    scrollView.delegate = self;
    
    _scrollView = [scrollView retain];
    return [scrollView autorelease];
}

- (UIView *)hostedView {
    if (auto hostedView = _hostedView) return hostedView;
    
    UIView *hostedView = [UIView new];
    hostedView.backgroundColor = [UIColor.systemOrangeColor colorWithAlphaComponent:0.3];
    
    _hostedView = [hostedView retain];
    return [hostedView autorelease];
}

- (void (^)(UIImage * _Nullable, NSDictionary * _Nullable))resultHandler {
    __weak auto weakSelf = self;
    UIImageView *imageView = self.imageView;
    
    return [[^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
        
        if (result == nil) {
            NSLog(@"image is nil.");
            return;
        }
        
        imageView.image = result;
        
        [UIView animateWithDuration:0.2 animations:^{
            imageView.alpha = 1.;
        }];
    } copy] autorelease];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.hostedView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    NSLog(@"%lf", scrollView.zoomScale);
}

@end
