//
//  ExternalStorageDeviceFileOutput.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/8/24.
//

#import <CamPresentation/ExternalStorageDeviceFileOutput.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

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

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        auto output = static_cast<ExternalStorageDeviceFileOutput *>(other);
        return [_externalStorageDevice isEqual:output->_externalStorageDevice];
    }
}

@end

#endif
