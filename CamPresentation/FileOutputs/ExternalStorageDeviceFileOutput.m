//
//  ExternalStorageDeviceFileOutput.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <CamPresentation/BaseFileOutput+Private.h>

@implementation ExternalStorageDeviceFileOutput

- (instancetype)initWithExternalStorageDevice:(AVExternalStorageDevice *)externalStorageDevice {
    if (self = [super initPrivate]) {
        _externalStorageDevice = [externalStorageDevice retain];
    }
    
    return self;
}

- (void)dealloc {
    [_externalStorageDevice release];
    [super dealloc];
}

@end
