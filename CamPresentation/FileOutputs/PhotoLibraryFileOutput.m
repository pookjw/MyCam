//
//  PhotoLibraryFileOutput.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/BaseFileOutput+Private.h>

@implementation PhotoLibraryFileOutput

+ (instancetype)output {
    return [[[self alloc] initPrivate] autorelease];
}

@end
