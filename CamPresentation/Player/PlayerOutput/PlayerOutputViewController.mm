//
//  PlayerOutputViewController.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/29/24.
//

#import <CamPresentation/PlayerOutputViewController.h>

@interface PlayerOutputViewController ()
@property (retain, nonatomic, readonly) AVPlayer *player;
@end

@implementation PlayerOutputViewController

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end
