#import <PhotosUICore/PXGSplitLayout.h>
#import <PhotosUICore/PXCuratedLibraryViewModel.h>
#import <PhotosUICore/PXCuratedLibraryViewModelPresenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface PXCuratedLibraryLayout : PXGSplitLayout <PXCuratedLibraryViewModelPresenter>
- (instancetype)initWithViewModel:(PXCuratedLibraryViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END