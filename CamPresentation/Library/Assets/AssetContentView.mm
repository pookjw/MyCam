//
//  AssetContentView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/1/24.
//

#import <CamPresentation/AssetContentView.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetContentView ()
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (assign, nonatomic, readonly) CGSize targetSize;
@property (nonatomic, readonly) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info);
@end

@implementation AssetContentView
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

- (void)setModel:(AssetItemModel *)model {
    if (CGSizeEqualToSize(_model.targetSize, model.targetSize) && [_model.asset isEqual:model.asset]) return;
    
    [_model cancelRequest];
    [_model release];
    _model = [model retain];
    
    UIImageView *imageView = self.imageView;
    imageView.image = nil;
    imageView.alpha = 0.;
    
    if (model.prefetchingModel) {
        if (CGSizeEqualToSize(self.targetSize, model.targetSize)) {
            model.resultHandler = self.resultHandler;
        } else {
            [model cancelRequest];
            model.resultHandler = self.resultHandler;
            [model requestImageWithTargetSize:self.targetSize];
        }
    } else {
        model.resultHandler = self.resultHandler;
        [model requestImageWithTargetSize:self.targetSize];;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.targetSize, self.model.targetSize)) {
        [self.model cancelRequest];
        [self.model requestImageWithTargetSize:self.targetSize];
    }
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
    CGFloat displayScale = self.traitCollection.displayScale;
    targetSize.width *= displayScale;
    targetSize.height *= displayScale;
    
    return targetSize;
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

@end
