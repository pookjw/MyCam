//
//  PhotoLibraryFileOutput.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/PhotoLibraryFileOutput.h>
#import <CamPresentation/BaseFileOutput+Private.h>

@implementation PhotoLibraryFileOutput

- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary {
    if (self = [super initPrivate]) {
        _photoLibrary = [photoLibrary retain];
    }
    
    return self;
}

- (void)dealloc {
    [_photoLibrary release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        auto output = static_cast<PhotoLibraryFileOutput *>(other);
        return [_photoLibrary isEqual:output->_photoLibrary];
    }
}

@end
