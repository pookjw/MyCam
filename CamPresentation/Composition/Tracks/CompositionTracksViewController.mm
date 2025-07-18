//
//  CompositionTracksViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <CamPresentation/CompositionTracksViewController.h>
#import <CamPresentation/CompositionTracksCollectionViewLayout.h>

@interface CompositionTracksViewController ()
@property (retain, nonatomic, readonly, getter=_compositionService) CompositionService *compositionService;
@property (retain, nonatomic, readonly, getter=_collectionView) UICollectionView *collectionView;
@property (retain, nonatomic, readonly, getter=_collectionViewLayout) CompositionTracksCollectionViewLayout *collectionViewLayout;
@end

@implementation CompositionTracksViewController
@synthesize collectionView = _collectionView;
@synthesize collectionViewLayout = _collectionViewLayout;

- (instancetype)initWithCompositionService:(CompositionService *)compositionService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _compositionService = [compositionService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_compositionService release];
    [_collectionView release];
    [_collectionViewLayout release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionView *collectionView = self.collectionView;
    collectionView.frame = self.view.bounds;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:collectionView];
}

- (UICollectionView *)_collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:self.collectionViewLayout];
    
    _collectionView = collectionView;
    return collectionView;
}

- (CompositionTracksCollectionViewLayout *)_collectionViewLayout {
    if (auto collectionViewLayout = _collectionViewLayout) return collectionViewLayout;
    
    CompositionTracksCollectionViewLayout *collectionViewLayout = [[CompositionTracksCollectionViewLayout alloc] init];
    
    _collectionViewLayout = collectionViewLayout;
    return collectionViewLayout;
}

@end
