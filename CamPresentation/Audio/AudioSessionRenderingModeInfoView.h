//
//  AudioSessionRenderingModeInfoView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 10/15/24.
//

#import <UIKit/UIKit.h>
#import <AVFAudio/AVFAudio.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSessionRenderingModeInfoView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithAudioSession:(AVAudioSession *)audioSession NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
