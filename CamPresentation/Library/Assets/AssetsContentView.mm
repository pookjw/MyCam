//
//  AssetsContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetsContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetsContentView ()
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) UIView *overlayView;
@property (assign, nonatomic, readonly) CGSize targetSize;
@property (nonatomic, readonly) PHImageRequestOptions *imageRequestOptions;
@end

@implementation AssetsContentView
@synthesize imageView = _imageView;
@synthesize overlayView = _overlayView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), imageView);
        
        UIView *overlayView = self.overlayView;
        [self addSubview:overlayView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), overlayView);
        
        [self updateOverlayView];
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_imageView release];
    [_overlayView release];
    [super dealloc];
}

- (void)setModel:(AssetsItemModel *)model {
//    if ([_model.asset isEqual:model.asset]) {
//        [_model requestImageWithTargetSize:self.targetSize resultHandler:[self resultHandler]];
//        return;
//    }
    
    [_model cancelRequest];
    [_model release];
    _model = [model retain];
    
    UIImageView *imageView = self.imageView;
    imageView.image = nil;
    imageView.alpha = 0.;
    
    [model requestImageWithTargetSize:self.targetSize options:self.imageRequestOptions resultHandler:[self resultHandler]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.model requestImageWithTargetSize:self.targetSize options:self.imageRequestOptions resultHandler:[self resultHandler]];
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    [self updateOverlayView];
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    [self updateOverlayView];
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.backgroundColor = UIColor.clearColor;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

- (CGSize)targetSize {
    CGSize targetSize = self.bounds.size;
    CGFloat displayScale = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_currentScreenScale"));
    targetSize.width *= displayScale;
    targetSize.height *= displayScale;
    
    return targetSize;
}

- (UIView *)overlayView {
    if (auto overlayView = _overlayView) return overlayView;
    
    UIView *overlayView = [UIView new];
    
    _overlayView = overlayView;
    return overlayView;
}

- (PHImageRequestOptions *)imageRequestOptions {
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    return [options autorelease];
}

- (void (^)(UIImage * _Nullable, NSDictionary * _Nullable))resultHandler {
    UIImageView *imageView = self.imageView;
    
    return [[^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_assert_queue(dispatch_get_main_queue());
        
        if (NSNumber *cancelledNumber = info[PHImageCancelledKey]) {
            if (cancelledNumber.boolValue) {
                NSLog(@"Cancelled");
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

- (void)updateOverlayView {
    if (self.selected) {
//        self.overlayView.hidden = NO;
//        self.overlayView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.75];
        self.overlayView.backgroundColor = [UIColor.blackColor colorWithProminence:UIColorProminenceSecondary];
    } else if (self.highlighted) {
//        self.overlayView.hidden = NO;
        
//        self.overlayView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
        self.overlayView.backgroundColor = [UIColor.blackColor colorWithProminence:UIColorProminenceQuaternary];
    } else {
//        self.overlayView.hidden = YES;
        self.overlayView.backgroundColor = UIColor.clearColor;
    }
}

@end
