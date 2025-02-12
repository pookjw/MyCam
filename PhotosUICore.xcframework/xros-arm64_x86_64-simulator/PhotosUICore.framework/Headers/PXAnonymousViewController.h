#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PXAnonymousViewController <NSObject>
@property (readonly, nonatomic) UIEdgeInsets px_safeAreaInsets;
@property (readonly, nonatomic) UIEdgeInsets px_layoutMargins;
@property (readonly, nonatomic) CGSize px_referenceSize;
@property (readonly, nonatomic) CGSize px_windowReferenceSize;
@property (readonly, nonatomic) BOOL px_isVisible;
@end

@interface UIViewController (PhotosUICore) <PXAnonymousViewController>
@end

NS_ASSUME_NONNULL_END