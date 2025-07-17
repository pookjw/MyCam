//
//  CompositionTracksViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/17/25.
//

#import <CamPresentation/CompositionTracksViewController.h>

@interface CompositionTracksViewController ()
@property (retain, nonatomic, readonly, getter=_compositionService) CompositionService *compositionService;
@end

@implementation CompositionTracksViewController

- (instancetype)initWithCompositionService:(CompositionService *)compositionService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _compositionService = [compositionService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_compositionService release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



@end
