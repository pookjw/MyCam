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
@property (retain, nonatomic, readonly) PHImageManager *imageManager;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic, readonly) CGSize targetSize;
@property (assign, nonatomic) CGSize requestedTargetSize;
@end

@implementation AssetContentView
@synthesize imageView = _imageView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageManager = [PHImageManager.defaultManager retain];
        
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), imageView);
    }
    
    return self;
}

- (void)dealloc {
    [_asset release];
    [_imageView release];
    [_imageManager release];
    [super dealloc];
}

- (void)setAsset:(PHAsset *)asset {
    [_asset release];
    _asset = [asset retain];
    [self requestImage];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.targetSize, self.requestedTargetSize)) {
        [self requestID];
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

- (void)requestImage {
    PHAsset * _Nullable asset = self.asset;
    if (asset == nil) return;
    
    PHImageManager *imageManager = self.imageManager;
    [imageManager cancelImageRequest:self.requestID];
    
    UIImageView *imageView = self.imageView;
    imageView.image = nil;
    imageView.alpha = 0.;
    
    CGSize targetSize = self.targetSize;
    self.requestedTargetSize = targetSize;
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        
    };
    
    __weak auto weakSelf = self;
    
    self.requestID = [imageManager requestImageForAsset:asset
                                             targetSize:targetSize
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
            if (unretained.requestID != requestIDNumber.integerValue) {
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
    }];
    
    [options release];
}

@end
