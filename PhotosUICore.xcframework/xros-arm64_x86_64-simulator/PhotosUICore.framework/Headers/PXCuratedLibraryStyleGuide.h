#import <PhotosUIFoundation/PXObservable.h>
#import <PhotosUICore/PXExtendedTraitCollection.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryStyleGuide : PXObservable
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithExtendedTraitCollection:(PXExtendedTraitCollection *)extendedTraitCollection;
- (instancetype)initWithExtendedTraitCollection:(PXExtendedTraitCollection *)extendedTraitCollection secondaryToolbarStyle:(NSUInteger)secondaryToolbarStyle;
@end

NS_ASSUME_NONNULL_END