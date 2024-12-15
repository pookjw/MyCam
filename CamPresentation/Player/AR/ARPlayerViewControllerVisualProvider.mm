//
//  ARPlayerViewControllerVisualProvider.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#import <TargetConditionals.h>

#if !TARGET_OS_TV

#import <CamPresentation/ARPlayerViewControllerVisualProvider.h>

@implementation ARPlayerViewControllerVisualProvider
@dynamic player;

- (instancetype)initWithPlayerViewController:(ARPlayerViewController *)playerViewController {
    if (self = [super init]) {
        _playerViewController = playerViewController;
    }
    
    return self;
}

- (void)viewDidLoad {
    
}

@end

#endif
