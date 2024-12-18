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

@interface AssetContentView () <UserTransformViewDelegate>
@property (retain, nonatomic, readonly) UIImageView *imageView;
@property (retain, nonatomic, readonly) UserTransformView *userTransformView;
@property (nonatomic, readonly) void (^resultHandler)(UIImage * _Nullable result, NSDictionary * _Nullable info);
@end

@implementation AssetContentView
@synthesize imageView = _imageView;
@synthesize userTransformView = _userTransformView;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = self.imageView;
        [self addSubview:imageView];
        
        UserTransformView *userTransformView = self.userTransformView;
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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (!CGSizeEqualToSize(self.imageView.image.size, CGSizeZero)) {
        CGRect frame = AVMakeRectWithAspectRatioInsideRect(self.imageView.image.size, self.userTransformView.frame);
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = frame;
        self.userTransformView.untransformedContentFrame = frame;
    }
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
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeNone;
    options.networkAccessAllowed = YES;
    options.allowSecondaryDegradedImage = YES;
    
    [model requestImageWithTargetSize:PHImageManagerMaximumSize options:options resultHandler:self.resultHandler];
    
    [options release];
}

- (void)didChangeIsDisplaying:(BOOL)isDisplaying {
    [self.userTransformView zoomOut:NO];
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

- (UserTransformView *)userTransformView {
    if (auto userTransformView = _userTransformView) return userTransformView;
    
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
    UIImageView *imageView = self.imageView;
    UserTransformView *userTransformView = self.userTransformView;
    
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
        
        if (result) {
            CGRect frame = AVMakeRectWithAspectRatioInsideRect(result.size, userTransformView.frame);
            imageView.frame = frame;
            
            userTransformView.contentPixelSize = result.size;
            userTransformView.untransformedContentFrame = frame;
        }
    } copy] autorelease];
}


- (void)userTransformView:(UserTransformView *)userTransformView didChangeUserAffineTransform:(CGAffineTransform)userAffineTransform isUserInteracting:(BOOL)isUserInteracting {
    self.imageView.transform = userAffineTransform;
}

- (void)didTriggerTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    BOOL hasUserZoomedIn = self.userTransformView.hasUserZoomedIn;
    
    if (hasUserZoomedIn) {
        [self.userTransformView zoomOut:YES];
    } else {
        [self.userTransformView zoomInOnLocationFromProvider:sender animated:YES];
    }
}

@end
