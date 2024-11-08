//
//  UserTransformView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/7/24.
//

#import <CamPresentation/UserTransformView.h>
#import <objc/message.h>
#import <objc/runtime.h>

OBJC_EXPORT id objc_msgSendSuper2(void); /* objc_super superInfo = { self, [self class] }; */

@interface UserTransformView () <UIScrollViewDelegate> {
    BOOL _zoomingOut;
}
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

- (void)zoomOut:(BOOL)animated {
    _zoomingOut = YES;
    [self.scrollView setZoomScale:1. animated:animated];
    _zoomingOut = NO;
}

- (BOOL)hasUserZoomedIn {
    return self.scrollView.zoomScale != 1.;
}

- (UIScrollView *)scrollView {
    if (auto scrollView = _scrollView) return scrollView;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [scrollView addSubview:self.hostedView];
    
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1.;
    scrollView.maximumZoomScale = 13.636;
    scrollView.contentInsetAdjustmentBehavior = static_cast<UIScrollViewContentInsetAdjustmentBehavior>(101);
    scrollView.scrollsToTop = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(scrollView, sel_registerName("setPreservesCenterDuringRotation:"), YES);
    scrollView.transfersHorizontalScrollingToParent = YES;
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(scrollView, sel_registerName("_setAllowsParentToBeginHorizontally:"), YES);
    
    _scrollView = [scrollView retain];
    return [scrollView autorelease];
}

- (UIView *)hostedView {
    if (auto hostedView = _hostedView) return hostedView;
    
    UIView *hostedView = [UIView new];
//    hostedView.backgroundColor = [UIColor.systemOrangeColor colorWithAlphaComponent:0.3];
    
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
    
    CGRect fitBounds = _untransformedContentFrame;
    
    CGAffineTransform userAffineTransform;
    if (CGRectGetWidth(fitBounds) == 0. or CGRectGetHeight(fitBounds) == 0.) {
        userAffineTransform = CGAffineTransformIdentity;
    } else {
        CGSize scale = CGSizeMake(CGRectGetWidth(frame) / CGRectGetWidth(fitBounds),
                                  CGRectGetHeight(frame) / CGRectGetHeight(fitBounds));
        
        CGPoint offset = CGPointMake(CGRectGetMidX(frame) - CGRectGetMidX(fitBounds),
                                     CGRectGetMidY(frame) - CGRectGetMidY(fitBounds));
        
        userAffineTransform = CGAffineTransformMake(scale.width, 0., 0., scale.height, offset.x, offset.y);
    }

    [self.delegate userTransformView:self didChangeUserAffineTransform:userAffineTransform isUserInteracting:self.scrollView.isTracking];
}

- (void)zoomInOnLocationFromProvider:(__kindof UIGestureRecognizer *)provider animated:(BOOL)animated {
    if (!CGRectContainsPoint(self.hostedView.frame, [provider locationInView:self])) return;
    
    UIScrollView *scrollView = self.scrollView;
    CGPoint location = [provider locationInView:self.hostedView];
    
    CGRect untransformedContentFrame = _untransformedContentFrame;
    
    CGSize scaledSize = [UserTransformView rectWithAspectFit:YES rect:untransformedContentFrame size:scrollView.bounds.size].size;
    
    CGFloat ratio_1 = CGRectGetWidth(untransformedContentFrame) / CGRectGetHeight(untransformedContentFrame);
    CGFloat ratio_2 = scaledSize.width / scaledSize.height;
    CGPoint origin;
    if (ratio_1 < ratio_2) {
        origin.x = CGRectGetMinX(untransformedContentFrame);
        
        origin.y = location.y - scaledSize.height * 0.5;
        
        if (origin.y < 0.) {
            origin.y = 0.;
        }
        if ((CGRectGetHeight(untransformedContentFrame) - scaledSize.height) < origin.y) {
            origin.y = CGRectGetHeight(untransformedContentFrame) - scaledSize.height;
        }
    } else {
        origin.x = location.x - scaledSize.width * 0.5;
        
        if (origin.x < 0.) {
            origin.x = 0.;
        }
        if ((CGRectGetWidth(untransformedContentFrame) - scaledSize.width) < origin.x) {
            origin.x = CGRectGetWidth(untransformedContentFrame) - scaledSize.width;
        } 
        
        origin.y = CGRectGetMinY(untransformedContentFrame);
    }
    
    CGRect rect = CGRectMake(origin.x,
                             origin.y,
                             scaledSize.width,
                             scaledSize.height);
    
    [scrollView zoomToRect:rect animated:animated];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.hostedView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self notifyUserAffineTransform];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_zoomingOut) {
        [self notifyUserAffineTransform];
    }
}

@end
