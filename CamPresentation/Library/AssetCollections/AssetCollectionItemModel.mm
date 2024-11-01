//
//  AssetCollectionItemModel.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/2/24.
//

#import <CamPresentation/AssetCollectionItemModel.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AssetCollectionItemModel ()

@end

@implementation AssetCollectionItemModel

- (instancetype)initWithCollection:(PHAssetCollection *)collection {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)dealloc {
    [_collection release];
    [super dealloc];
}

@end
