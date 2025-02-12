#import <PhotosUIFoundation/PXObservable.h>
#import <PhotosUICore/PXAnonymousViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXExtendedTraitCollection : PXObservable
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithViewController:(NSObject<PXAnonymousViewController> *)viewController;
@end

NS_ASSUME_NONNULL_END