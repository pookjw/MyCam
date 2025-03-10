//
//  CinematicEditTimelineView.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicEditTimelineView.h>

@interface CinematicEditTimelineView ()
@property (retain, nonatomic, readonly, getter=_viewModel) CinematicViewModel *viewModel;
@end

@implementation CinematicEditTimelineView

- (instancetype)initWithViewModel:(CinematicViewModel *)viewModel {
    if (self = [super init]) {
        _viewModel = [viewModel retain];
        [viewModel addObserver:self forKeyPath:@"isolated_snapshot" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [_viewModel removeObserver:self forKeyPath:@"isolated_snapshot"];
    [_viewModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.viewModel]) {
        if ([keyPath isEqualToString:@"isolated_snapshot"]) {
            [self _didChangeSnapshot];
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)_didChangeSnapshot {
    dispatch_async(self.viewModel.queue, ^{
        NSLog(@"%@", self.viewModel.isolated_snapshot.assetData.cnScript);
    });
}

@end
