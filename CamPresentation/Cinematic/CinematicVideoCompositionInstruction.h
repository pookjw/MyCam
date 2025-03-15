//
//  CinematicVideoCompositionInstruction.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 3/9/25.
//

#import <AVFoundation/AVFoundation.h>
#import <Cinematic/Cinematic.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface CinematicVideoCompositionInstruction : NSObject <AVVideoCompositionInstruction>
@property (retain, nonatomic, readonly) CNRenderingSession *renderingSession;
@property (retain, nonatomic, readonly) CNCompositionInfo *compositionInfo;
@property (retain, nonatomic, readonly) CNScript *script;
@property (assign, nonatomic, readonly) BOOL editMode;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRenderingSession:(CNRenderingSession *)renderingSession compositionInfo:(CNCompositionInfo *)compositionInfo script:(CNScript *)script editMode:(BOOL)editMode;
@end

NS_ASSUME_NONNULL_END
