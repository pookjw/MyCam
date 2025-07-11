//
//  AudioInputPickerView.h
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(26.0))
API_UNAVAILABLE(visionos)
API_UNAVAILABLE(tvos)
@interface AudioInputPickerView : UIView
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithAudioSession:(AVAudioSession *)audioSession NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
