//
//  CinematicSnapshot.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <CamPresentation/CinematicSnapshot.h>

@implementation CinematicSnapshot

- (instancetype)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition assetData:(CinematicAssetData *)assetData {
    if (self = [super init]) {
        _composition = [composition copy];
        _videoComposition = [videoComposition copy];
        _assetData = [assetData retain];
    }
    
    return self;
}

- (void)dealloc {
    [_composition release];
    [_videoComposition release];
    [_assetData release];
    [super dealloc];
}

@end
