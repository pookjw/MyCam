//
//  AudioInputPickerView.m
//  CamPresentation
//
//  Created by Jinwoo Kim on 7/11/25.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import <CamPresentation/AudioInputPickerView.h>
#import <AVKit/AVKit.h>
#include <objc/message.h>
#include <objc/runtime.h>

@interface AudioInputPickerView () <AVInputPickerInteractionDelegate>
@property (retain, nonatomic, readonly) AVAudioSession *audioSession;
@property (retain, nonatomic, readonly) AVInputPickerInteraction *inputPickerInteraction;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *presentButton;
@property (retain, nonatomic, readonly) UIButton *internalPresentButton;
@property (retain, nonatomic, readonly) UIButton *dismissWithDelayButton;
@end

@implementation AudioInputPickerView
@synthesize inputPickerInteraction = _inputPickerInteraction;
@synthesize stackView = _stackView;
@synthesize presentButton = _presentButton;
@synthesize internalPresentButton = _internalPresentButton;
@synthesize dismissWithDelayButton = _dismissWithDelayButton;

- (instancetype)initWithAudioSession:(AVAudioSession *)audioSession {
    if (self = [super initWithFrame:CGRectNull]) {
        _audioSession = [audioSession retain];
        [self addInteraction:self.inputPickerInteraction];
        
        [self addSubview:self.stackView];
        self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    
    return self;
}

- (void)dealloc {
    [_audioSession release];
    [_inputPickerInteraction release];
    [_stackView release];
    [_presentButton release];
    [_internalPresentButton release];
    [_dismissWithDelayButton release];
    [super dealloc];
}

- (AVInputPickerInteraction *)inputPickerInteraction {
    if (auto inputPickerInteraction = _inputPickerInteraction) return inputPickerInteraction;
    
    AVInputPickerInteraction *inputPickerInteraction = [[AVInputPickerInteraction alloc] initWithAudioSession:self.audioSession];
    inputPickerInteraction.delegate = self;
    
    _inputPickerInteraction = inputPickerInteraction;
    return inputPickerInteraction;
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.presentButton, self.internalPresentButton, self.dismissWithDelayButton]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    
    _stackView = stackView;
    return stackView;
}

- (UIButton *)presentButton {
    if (auto presentButton = _presentButton) return presentButton;
    
    UIButton *presentButton = [UIButton new];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = @"Present";
    presentButton.configuration = configuration;
    
    [presentButton addTarget:self action:@selector(presentButtonDidTrigger:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _presentButton = presentButton;
    return presentButton;
}

- (UIButton *)internalPresentButton {
    if (auto internalPresentButton = _internalPresentButton) return internalPresentButton;
    
    UIButton *internalPresentButton = [UIButton new];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = @"Present (Internal)";
    internalPresentButton.configuration = configuration;
    
    [internalPresentButton addTarget:self action:@selector(internalPresentButtonDidTrigger:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _internalPresentButton = internalPresentButton;
    return internalPresentButton;
}

- (UIButton *)dismissWithDelayButton {
    if (auto dismissWithDelayButton = _dismissWithDelayButton) return dismissWithDelayButton;
    
    UIButton *dismissWithDelayButton = [UIButton new];
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = @"Dismiss with delay";
    dismissWithDelayButton.configuration = configuration;
    
    [dismissWithDelayButton addTarget:self action:@selector(dismissWithDelayButtonDidTrigger:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _dismissWithDelayButton = dismissWithDelayButton;
    return dismissWithDelayButton;
}

- (void)presentButtonDidTrigger:(UIButton *)sender {
    [self.inputPickerInteraction present];
}

- (void)internalPresentButtonDidTrigger:(UIButton *)sender {
    __kindof UIViewController *viewController = [objc_lookUpClass("AVInputPickerPresenterViewController") new];
    __block auto unretained = viewController;
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(viewController, sel_registerName("setDismissalBlock:"), ^{
        [unretained dismissViewControllerAnimated:YES completion:nil];
    });
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    UIViewController *presentedViewController = self.window.rootViewController;
    while (presentedViewController.presentedViewController != nil) {
        presentedViewController = presentedViewController.presentedViewController;
    }
    
    [presentedViewController presentViewController:viewController animated:NO completion:^{
        reinterpret_cast<void (*)(id, SEL, BOOL, BOOL, id)>(objc_msgSend)(viewController, sel_registerName("transitionToVisible:animated:completion:"), YES, YES, ^{
            
        });
    }];
    [viewController release];
}

- (void)dismissWithDelayButtonDidTrigger:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.inputPickerInteraction dismiss];
    });
}

@end

#endif
