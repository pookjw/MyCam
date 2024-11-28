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
@property (assign, nonatomic, readonly) CGSize targetSize;
@end

@implementation AssetsContentView
@synthesize imageView = _imageView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), imageView);
    }
    
    return self;
}

- (void)dealloc {
    [_model release];
    [_imageView release];
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
    
    [model requestImageWithTargetSize:self.targetSize resultHandler:[self resultHandler]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.model requestImageWithTargetSize:self.targetSize resultHandler:[self resultHandler]];
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

@end
