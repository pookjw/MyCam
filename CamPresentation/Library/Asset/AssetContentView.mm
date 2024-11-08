//
//  AssetContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/6/24.
//

#import <CamPresentation/AssetContentView.h>
#import <CamPresentation/UserTransformView.h>
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>

namespace cp_PUUserTransformView {
namespace doubleTapZoomScaleForContentSize {
CGFloat (*original)(Class, SEL, CGSize, CGSize, CGFloat, BOOL);
CGFloat custom(Class self, SEL _cmd, CGSize contentSize, CGSize boundsSize, CGFloat defaultScale, BOOL preferToFillOnDoubleTap) {
    return original(self, _cmd, contentSize, boundsSize, defaultScale, preferToFillOnDoubleTap);
}
void swizzle() {
    Method method = class_getClassMethod(objc_lookUpClass("PUUserTransformView"), sel_registerName("doubleTapZoomScaleForContentSize:inBoundsSize:defaultScale:preferToFillOnDoubleTap:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

@interface AssetContentView () <UserTransformViewDelegate>
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) __kindof UIView *userTransformView;
@property (nonatomic, readonly) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info);
@end

@implementation AssetContentView
@synthesize imageView = _imageView;
@synthesize userTransformView = _userTransformView;

+ (void)load {
    assert(dlopen("/System/Library/PrivateFrameworks/PhotosUIPrivate.framework/PhotosUIPrivate", RTLD_NOW) != NULL);
    
    Protocol * _Nullable PUUserTransformViewDelegate = NSProtocolFromString(@"PUUserTransformViewDelegate");
    if (PUUserTransformViewDelegate) {
        assert(class_addProtocol(self, PUUserTransformViewDelegate));
    }
    
    cp_PUUserTransformView::doubleTapZoomScaleForContentSize::swizzle();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        
        __kindof UIView *userTransformView = self.userTransformView;
        [self addSubview:userTransformView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), userTransformView);
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_imageView release];
    [_userTransformView release];
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
    imageView.frame = CGRectZero;
    
    if (CGSizeEqualToSize(PHImageManagerMaximumSize, model.targetSize)) {
        model.resultHandler = self.resultHandler;
    } else {
        [model cancelRequest];
        model.resultHandler = self.resultHandler;
        [model requestImageWithTargetSize:PHImageManagerMaximumSize];
    }
}

- (void)didChangeIsDisplaying:(BOOL)isDisplaying {
    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.userTransformView, sel_registerName("zoomOut:"), NO);
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

- (__kindof UIView *)userTransformView {
    if (auto userTransformView = _userTransformView) return userTransformView;
    
//    __kindof UIView *userTransformView = [objc_lookUpClass("PUUserTransformView") new];
//    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(userTransformView, sel_registerName("setDelegate:"), self);
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(userTransformView, sel_registerName("setPreferToFillOnDoubleTap:"), YES);
//    reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(userTransformView, sel_registerName("setEnabledInteractions:"), 7);
//    reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(userTransformView, sel_registerName("setNeedsUpdateEnabledInteractions:"), YES);
    
    UserTransformView *userTransformView = [UserTransformView new];
    userTransformView.delegate = self;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerTapGestureRecognizer:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    _userTransformView = [userTransformView retain];
    return [userTransformView autorelease];
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
        
        if (result) {
            CGRect frame = AVMakeRectWithAspectRatioInsideRect(result.size, self.userTransformView.frame);
            imageView.frame = frame;
            
            reinterpret_cast<void (*)(id, SEL, CGSize)>(objc_msgSend)(self.userTransformView, sel_registerName("setContentPixelSize:"), result.size);
            reinterpret_cast<void (*)(id, SEL, CGRect)>(objc_msgSend)(self.userTransformView, sel_registerName("setUntransformedContentFrame:"), frame);
        }
    } copy] autorelease];
}


- (void)userTransformView:(id)arg1 didChangeUserAffineTransform:(struct CGAffineTransform)arg2 isUserInteracting:(_Bool)arg3 {
    self.imageView.transform = arg2;
}

- (void)userTransformView:(id)arg1 didChangeIsUserInteracting:(_Bool)arg2 {
    
}

- (void)userTransformViewDidChangeIsZoomedIn:(id)arg1 {
    
}

- (void)didTriggerTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    BOOL hasUserZoomedIn = reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.userTransformView, sel_registerName("hasUserZoomedIn"));
    
//    if (hasUserZoomedIn) {
//        reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(self.userTransformView, sel_registerName("zoomOut:"), NO);
//    } else {
        reinterpret_cast<void (*)(id, SEL, id, BOOL)>(objc_msgSend)(self.userTransformView, sel_registerName("zoomInOnLocationFromProvider:animated:"), sender, YES);
//    }
}

@end
