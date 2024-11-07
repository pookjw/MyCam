//
//  UserTransformView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/7/24.
//

#import <CamPresentation/UserTransformView.h>
#import <objc/message.h>
#import <objc/runtime.h>

// reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_currentScreenScale"));

@interface UserTransformView () <UIScrollViewDelegate>
@property (retain, nonatomic, readonly) UIScrollView *scrollView;
@property (retain, nonatomic, readonly) UIView *hostedView;
@end

@implementation UserTransformView
@synthesize scrollView = _scrollView;
@synthesize hostedView = _hostedView;

+ (CGRect)rectWithAspectFit:(BOOL)aspectFit rect:(CGRect)rect size:(CGSize)size {
    CGFloat ratio_1 = CGRectGetWidth(rect) / CGRectGetHeight(rect);
    CGFloat ratio_2 = size.width / size.height;
    
    if (((ratio_1 < ratio_2) and aspectFit) or ((ratio_2 < ratio_1) and !aspectFit)) {
        CGFloat width = CGRectGetWidth(rect);
        CGFloat ratio = width / size.width;
        CGFloat height = size.height * ratio;
        CGFloat x = CGRectGetMinX(rect);
        CGFloat y = CGRectGetMinY(rect) + (CGRectGetHeight(rect) - height) * 0.5;
        return CGRectMake(x, y, width, height);
    } else {
        CGFloat height = CGRectGetHeight(rect);
        CGFloat ratio = height / size.height;
        CGFloat width = size.width * ratio;
        CGFloat x = CGRectGetMinX(rect) + (CGRectGetWidth(rect) - width) * 0.5;
        CGFloat y = CGRectGetMinY(rect);
        return CGRectMake(x, y, width, height);
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIScrollView *scrollView = self.scrollView;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.frame = self.bounds;
        [self addSubview:scrollView];
    }
    
    return self;
}

- (void)dealloc {
    [_scrollView release];
    [_hostedView release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateScrollViewContentSize];
}

- (UIScrollView *)scrollView {
    if (auto scrollView = _scrollView) return scrollView;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [scrollView addSubview:self.hostedView];
    
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1.;
#warning Dynamic
    scrollView.maximumZoomScale = 13.636;
//    scrollView.contentAlignmentPoint = CGPointMake(0.5, 0.5);
    
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

- (void)setContentPixelSize:(CGSize)contentPixelSize {
    _contentPixelSize = contentPixelSize;
    [self updateScrollViewContentSize];
}

- (void)setUntransformedContentFrame:(struct CGRect)untransformedContentFrame {
    _untransformedContentFrame = untransformedContentFrame;
}

- (void)updateScrollViewContentSize {
    UIScrollView *scrollView = self.scrollView;
    CGSize contentPixelSize = _contentPixelSize;
    
    if (CGSizeEqualToSize(contentPixelSize, CGSizeZero)) {
        scrollView.contentSize = CGSizeZero;
        return;
    }
    
    CGRect zeroOriginBounds = scrollView.bounds;
    zeroOriginBounds.origin = CGPointZero;
    
    CGRect fitBounds = [UserTransformView rectWithAspectFit:YES rect:zeroOriginBounds size:contentPixelSize];
    
    scrollView.contentSize = fitBounds.size;
    self.hostedView.frame = fitBounds;
}

- (void)notifyUserAffineTransform {
    UIView *hostedView = self.hostedView;
    CGRect frame = [hostedView convertRect:hostedView.bounds toView:self];
    
    CGRect zeroOriginBounds = self.scrollView.bounds;
    zeroOriginBounds.origin = CGPointZero;
    CGRect fitBounds = [UserTransformView rectWithAspectFit:YES rect:zeroOriginBounds size:_contentPixelSize];
    
    CGSize scale = CGSizeMake(CGRectGetWidth(frame) / CGRectGetWidth(fitBounds),
                              CGRectGetHeight(frame) / CGRectGetHeight(fitBounds));
    
    CGPoint offset = CGPointMake(CGRectGetMidX(frame) - CGRectGetMidX(fitBounds),
                                 CGRectGetMidY(frame) - CGRectGetMidY(fitBounds));
    
    CGAffineTransform userAffineTransform = CGAffineTransformMake(scale.width, 0., 0., scale.height, offset.x, offset.y);

    [self.delegate userTransformView:self didChangeUserAffineTransform:userAffineTransform isUserInteracting:NO];
}

- (void)zoomInOnLocationFromProvider:(__kindof UIGestureRecognizer *)provider animated:(BOOL)animated {
//    UIScrollView *scrollView = self.scrollView;
//    
//    CGRect untransformedContentFrame = _untransformedContentFrame;
//    CGPoint location = [provider locationInView:scrollView];
//    
//    CGFloat width = CGRectGetWidth(untransformedContentFrame);
//    CGFloat height = CGRectGetHeight(untransformedContentFrame);
//    
//    CGRect rect = CGRectMake(width * 0.5,
//                             height * 0.5,
//                             width * 0.3,
//                             height * 0.3);
//    
//    [scrollView zoomToRect:rect animated:YES];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.hostedView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self notifyUserAffineTransform];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self notifyUserAffineTransform];
}

@end
