//
//  TVSlider.m
//  MyApp
//
//  Created by Jinwoo Kim on 11/21/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_TV

#import <CamPresentation/TVSlider.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface TVSlider ()
@property (retain, readonly, nonatomic) __kindof UIView *_floatingContentView;
@property (retain, nonatomic, readonly) UIView *_minimumTrackView;
@property (retain, nonatomic, readonly) UIView *_maximumTrackView;
@property (retain, nonatomic, readonly) UIView *_tracksContainerview;
@property (retain, nonatomic, readonly) UIView *_thumbView;
@property (retain, nonatomic, nullable) NSLayoutConstraint *_minimumTrackViewWidthConstraint;
@property (retain, nonatomic, readonly) UIPanGestureRecognizer *_panGestureRecognizer;
@property (retain, nonatomic, nullable) NSTimer *_pressTimer;
@property (retain, nonatomic, readonly) UIFocusGuide *_leadingFocusGuide;
@property (retain, nonatomic, readonly) UIFocusGuide *_trailingFocusGuide;
@property (assign, nonatomic) CGPoint _lastTranslation;
@property (assign, nonatomic) NSTimeInterval _lastEnterPressBeganTimestamp;
@property (retain, nonatomic, readonly) NSMutableArray<UIAction *> *_actions;
@end

@implementation TVSlider
@synthesize _floatingContentView = __floatingContentView;
@synthesize _minimumTrackView = __minimumTrackView;
@synthesize _maximumTrackView = __maximumTrackView;
@synthesize _tracksContainerview = __tracksContainerview;
@synthesize _thumbView = __thumbView;
@synthesize _panGestureRecognizer = __panGestureRecognizer;

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit_TVSlider];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit_TVSlider];
    }
    
    return self;
}

- (void)dealloc {
    [__floatingContentView release];
    [__minimumTrackView release];
    [__maximumTrackView release];
    [__tracksContainerview release];
    [__thumbView release];
    [__minimumTrackViewWidthConstraint release];
    [__panGestureRecognizer release];
    [__pressTimer release];
    [__leadingFocusGuide release];
    [__trailingFocusGuide release];
    [__actions release];
    [super dealloc];
}

- (BOOL)canBecomeFocused {
    return YES;
}

- (void)updateConstraints {
    [super updateConstraints];
    [self _updateTrackViewWidthConstraints];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    if (self.window == nil) {
        self._leadingFocusGuide.preferredFocusEnvironments = @[];
        self._trailingFocusGuide.preferredFocusEnvironments = @[];
    } else {
        self._leadingFocusGuide.preferredFocusEnvironments = @[self];
        self._trailingFocusGuide.preferredFocusEnvironments = @[self];
    }
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (UIPress *lastPress = [self _lastPressForPresses:presses]) {
        if ([self _isEnterPress:lastPress]) {
            self.editing = !self.isEditing;
            self._lastEnterPressBeganTimestamp = lastPress.timestamp;
            return;
        } else if ([self _isLeftPress:lastPress]) {
            if (self.isEditing) {
                [self _handlePressBegan:lastPress];
                return;
            }
        } else if ([self _isRightPress:lastPress]) {
            if (self.isEditing) {
                [self _handlePressBegan:lastPress];
                return;
            }
        } else if ([self _isEscapePress:lastPress]) {
            if (self.isEditing) {
                return;
            }
        }
    }
    
    [super pressesBegan:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (UIPress *lastPress = [self _lastPressForPresses:presses]) {
        if ([self _isLeftPress:lastPress] or [self _isRightPress:lastPress]) {
            [self _handlePressEndedOrCancelled:presses];
            return;
        } else if ([self _isEscapePress:lastPress] and self.isEditing) {
            self.editing = NO;
            return;
        } else if ([self _isEnterPress:lastPress]) {
            if (lastPress.timestamp - self._lastEnterPressBeganTimestamp >= 1.0) {
                self.editing = NO;
            }
            return;
        }
    }
    
    [super pressesEnded:presses withEvent:event];
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    if (UIPress *lastPress = [self _lastPressForPresses:presses]) {
        if ([self _isLeftPress:lastPress] or [self _isRightPress:lastPress]) {
            [self _handlePressEndedOrCancelled:presses];
            return;
        } else if ([self _isEscapePress:lastPress] and self.isEditing) {
            self.editing = NO;
            return;
        }
    }
    
    [super pressesCancelled:presses withEvent:event];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    if ([context.nextFocusedView isEqual:self]) {
        if (self.isEditing) {
            reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self._floatingContentView, sel_registerName("setControlState:animated:"), 4, YES);
        } else { reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self._floatingContentView, sel_registerName("setControlState:animated:"), 8, YES);
        }
    } else {
        [self._pressTimer invalidate];
        self._pressTimer = nil;
        self.editing = NO;
    }
}

- (BOOL)isEnabled {
    abort();
}

- (void)setEnabled:(BOOL)enabled {
    abort();
}

- (BOOL)isEditing {
    return self._panGestureRecognizer.isEnabled;
}

- (void)setEditing:(BOOL)editing {
    [self willChangeValueForKey:@"editing"];
    
    self._leadingFocusGuide.enabled = editing;
    self._trailingFocusGuide.enabled = editing;
    self._panGestureRecognizer.enabled = editing;
    
    if (editing and self.isFocused) {
        reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self._floatingContentView, sel_registerName("setControlState:animated:"), 4, YES);
    } else {
        if (self.isFocused) {
            reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self._floatingContentView, sel_registerName("setControlState:animated:"), 8, YES);
        } else {
            reinterpret_cast<void (*)(id, SEL, NSUInteger, BOOL)>(objc_msgSend)(self._floatingContentView, sel_registerName("setControlState:animated:"), 0, YES);
        }
    }
    
    [self didChangeValueForKey:@"editing"];
}

- (void)_commonInit_TVSlider {
    __kindof UIView *floatingContentView = self._floatingContentView;
    [self addSubview:floatingContentView];
    
    UIView *contentView = ((id (*)(id, SEL))objc_msgSend)(floatingContentView, sel_registerName("contentView"));
    
    UIView *tracksContainerview = self._tracksContainerview;
    [contentView addSubview:tracksContainerview];
    
    UIView *minimumTrackView = self._minimumTrackView;
    [tracksContainerview addSubview:minimumTrackView];
    
    UIView *maximumTrackView = self._maximumTrackView;
    [tracksContainerview addSubview:maximumTrackView];
    
    UIView *thumbView = self._thumbView;
    [contentView addSubview:thumbView];
    
    self.minimumTrackTintColor = UIColor.tintColor;
    self.maximumTrackTintColor = UIColor.separatorColor;
    self.thumbTintColor = UIColor.whiteColor;
    
    _minimumValue = 0.f;
    _maximumValue = 100.f;
    _value = 50.f;
    _stepValue = 10.f;
    
    reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(self, sel_registerName("_addBoundsMatchingConstraintsForView:"), floatingContentView);
    
    UIFocusGuide *leadingFocusGuide = [UIFocusGuide new];
    UIFocusGuide *trailingFocusGuide = [UIFocusGuide new];
    
    [self addLayoutGuide:leadingFocusGuide];
    [self addLayoutGuide:trailingFocusGuide];
    
    [NSLayoutConstraint activateConstraints:@[
        [tracksContainerview.centerYAnchor constraintEqualToAnchor:floatingContentView.centerYAnchor],
        [tracksContainerview.leadingAnchor constraintEqualToAnchor:floatingContentView.leadingAnchor constant:30.],
        [tracksContainerview.trailingAnchor constraintEqualToAnchor:floatingContentView.trailingAnchor constant:-30.],
        [tracksContainerview.heightAnchor constraintEqualToConstant:8.],
        
        [minimumTrackView.topAnchor constraintEqualToAnchor:tracksContainerview.topAnchor],
        [minimumTrackView.leadingAnchor constraintEqualToAnchor:tracksContainerview.leadingAnchor],
        [minimumTrackView.bottomAnchor constraintEqualToAnchor:tracksContainerview.bottomAnchor],
        
        [maximumTrackView.topAnchor constraintEqualToAnchor:tracksContainerview.topAnchor],
        [maximumTrackView.trailingAnchor constraintEqualToAnchor:tracksContainerview.trailingAnchor],
        [maximumTrackView.bottomAnchor constraintEqualToAnchor:tracksContainerview.bottomAnchor],
        
        [minimumTrackView.trailingAnchor constraintEqualToAnchor:maximumTrackView.leadingAnchor],
        
        [thumbView.centerYAnchor constraintEqualToAnchor:minimumTrackView.centerYAnchor],
        [thumbView.centerXAnchor constraintEqualToAnchor:minimumTrackView.trailingAnchor],
        [thumbView.topAnchor constraintGreaterThanOrEqualToAnchor:floatingContentView.topAnchor constant:20.],
        [thumbView.bottomAnchor constraintGreaterThanOrEqualToAnchor:floatingContentView.bottomAnchor constant:-20.],
        [thumbView.widthAnchor constraintEqualToConstant:30.],
        [thumbView.heightAnchor constraintEqualToConstant:30.],
        
        [leadingFocusGuide.topAnchor constraintEqualToAnchor:self.topAnchor],
        [leadingFocusGuide.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-1.],
        [leadingFocusGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [leadingFocusGuide.widthAnchor constraintEqualToConstant:1.],
        
        [trailingFocusGuide.topAnchor constraintEqualToAnchor:self.topAnchor],
        [trailingFocusGuide.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:1.],
        [trailingFocusGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [trailingFocusGuide.widthAnchor constraintEqualToConstant:1.],
    ]];
    
    __leadingFocusGuide = leadingFocusGuide;
    __trailingFocusGuide = trailingFocusGuide;
    
    __actions = [NSMutableArray new];
    
    //
    
    [self addGestureRecognizer:self._panGestureRecognizer];
    
    //
    
    [self _updateTrackViewWidthConstraints];
    self.editing = NO;
}

- (void)setValue:(float)value {
    [self setValue:value animated:NO];
}

- (void)setMinimumValue:(float)minimumValue {
    [self willChangeValueForKey:@"minimumValue"];
    _minimumValue = minimumValue;
    [self didChangeValueForKey:@"minimumValue"];
    [self setNeedsUpdateConstraints];
}

- (void)setMaximumValue:(float)maximumValue {
    [self willChangeValueForKey:@"maximumValue"];
    _maximumValue = maximumValue;
    [self didChangeValueForKey:@"maximumValue"];
    [self setNeedsUpdateConstraints];
}

- (void)setValue:(float)value animated:(BOOL)animated {
    [self willChangeValueForKey:@"value"];
    _value = value;
    [self didChangeValueForKey:@"value"];
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self setNeedsUpdateConstraints];
            [self setNeedsLayout];
            [self layoutIfNeeded];
        }];
    } else {
        [self setNeedsUpdateConstraints];
    }
}

- (UIColor *)minimumTrackTintColor {
    return self._minimumTrackView.backgroundColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    self._minimumTrackView.backgroundColor = minimumTrackTintColor;
}

- (UIColor *)maximumTrackTintColor {
    return self._maximumTrackView.backgroundColor;
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    self._maximumTrackView.backgroundColor = maximumTrackTintColor;
}

- (UIColor *)thumbTintColor {
    return self._thumbView.backgroundColor;
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    self._thumbView.backgroundColor = thumbTintColor;
}

- (void)addAction:(UIAction *)action {
    assert(![self._actions containsObject:action]);
    [self._actions addObject:action];
}

- (void)removeAction:(UIAction *)action {
    assert([self._actions containsObject:action]);
    [self._actions addObject:action];
}

- (__kindof UIView *)_floatingContentView {
    if (auto floatingContentView = __floatingContentView) return floatingContentView;
    
    __kindof UIView *floatingContentView = reinterpret_cast<id (*)(id, SEL, CGRect)>(objc_msgSend)([objc_lookUpClass("_UIFloatingContentView") alloc], @selector(initWithFrame:), self.bounds);
    
    reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(floatingContentView, sel_registerName("setFocusScaleAnchorPoint:"), CGPointMake(0.5, 1.));
    
    __floatingContentView = [floatingContentView retain];
    return [floatingContentView autorelease];
}

- (UIView *)_minimumTrackView {
    if (auto minimumTrackView = __minimumTrackView) return minimumTrackView;
    
    UIView *minimumTrackView = [UIView new];
    minimumTrackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    __minimumTrackView = [minimumTrackView retain];
    return [minimumTrackView autorelease];
}

- (UIView *)_maximumTrackView {
    if (auto maximumTrackView = __maximumTrackView) return maximumTrackView;
    
    UIView *maximumTrackView = [UIView new];
    maximumTrackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    __maximumTrackView = [maximumTrackView retain];
    return [maximumTrackView autorelease];
}

- (UIView *)_tracksContainerview {
    if (auto tracksContainerview = __tracksContainerview) return tracksContainerview;
    
    UIView *tracksContainerview = [UIView new];
    tracksContainerview.translatesAutoresizingMaskIntoConstraints = NO;
    
    __tracksContainerview = [tracksContainerview retain];
    return [tracksContainerview autorelease];
}

- (UIView *)_thumbView {
    if (auto thumbView = __thumbView) return thumbView;
    
    UIView *thumbView = [UIView new];
    thumbView.translatesAutoresizingMaskIntoConstraints = NO;
    thumbView.layer.cornerRadius = 15.;
    
    __thumbView = [thumbView retain];
    return [thumbView autorelease];
}

- (UIPanGestureRecognizer *)_panGestureRecognizer {
    if (auto panGestureRecognizer = __panGestureRecognizer) return panGestureRecognizer;
    
    UIPanGestureRecognizer *panGestureRecognizer = [[objc_lookUpClass("_UIPanOrFlickGestureRecognizer") alloc] initWithTarget:self action:@selector(_didTriggerPanGestureRecognizer:)];
    panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    
    __panGestureRecognizer = [panGestureRecognizer retain];
    return [panGestureRecognizer autorelease];
}

- (void)_didTriggerPanGestureRecognizer:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            CGPoint translation = [sender translationInView:self._thumbView];
            CGPoint lastTranslation = self._lastTranslation;
            
            CGPoint offset = CGPointMake(translation.x - lastTranslation.x, translation.y - lastTranslation.y);
            self._lastTranslation = translation;
            
            float minimumValue = self.minimumValue;
            float maximumValue = self.maximumValue;
            float value = self.value;
            
            value += offset.x / 70.f;
            value = MIN(maximumValue, MAX(minimumValue, value));
            
            [self setValue:value animated:NO];
            
            if (self.isContinuous or sender.state != UIGestureRecognizerStateChanged) {
                for (UIAction *action in self._actions) {
                    [action performWithSender:self target:nil];
                }
            }
            
            break;
        }
        default:
            break;
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            self._lastTranslation = CGPointZero;
            break;
        }
        default:
            break;
    }
}

- (UIPress * _Nullable)_lastPressForPresses:(NSSet<UIPress *> *)presses {
    UIPress * _Nullable lastPress = nil;
    for (UIPress *press in presses) {
        if (lastPress == nil) {
            lastPress = press;
            continue;
        }
        
        if (lastPress.timestamp < press.timestamp) {
            lastPress = press;
        }
    }
    
    return lastPress;
}

- (void)_handlePressBegan:(UIPress *)press {
    if (NSTimer *pressTimer = self._pressTimer) {
        UIPress *oldPress = pressTimer.userInfo[@"press"];
        assert(oldPress != nil);
        assert(oldPress.timestamp < press.timestamp);
        
        [pressTimer invalidate];
        self._pressTimer = nil;
    }
    
    BOOL isLeftPress = [self _isLeftPress:press];
    [self _stepToLeft:isLeftPress];
    
    NSTimer *pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self selector:@selector(_didTriggerPressTimer:)
                                                    userInfo:@{
        @"press": press,
        @"isLeftPress": @(isLeftPress)
    }
                                                     repeats:YES];
    
    self._pressTimer = pressTimer;
}

- (void)_didTriggerPressTimer:(NSTimer *)sender {
    NSNumber *isLeftPressNumber = sender.userInfo[@"isLeftPress"];
    assert(isLeftPressNumber != nil);
    assert([isLeftPressNumber isKindOfClass:NSNumber.class]);
    
    BOOL isLeftPress = isLeftPressNumber.boolValue;
    [self _stepToLeft:isLeftPress];
}

- (void)_stepToLeft:(BOOL)left {
    float stepValue = self.stepValue;
    float value = self.value;
    float newValue;
    if (left) {
        newValue = MAX(value - stepValue, self.minimumValue);
    } else {
        newValue = MIN(value + stepValue, self.maximumValue);
    }
    
    [self setValue:newValue animated:YES];
    
    if (self.isContinuous) {
        for (UIAction *action in self._actions) {
            [action performWithSender:self target:nil];
        }
    }
}

- (void)_handlePressEndedOrCancelled:(NSSet<UIPress *> *)presses {
    NSTimer *pressTimer = self._pressTimer;
    if (pressTimer == nil) return;
    
    UIPress *press = pressTimer.userInfo[@"press"];
    assert(press != nil);
    
    if (![presses containsObject:press]) return;
    
    [pressTimer invalidate];
    self._pressTimer = nil;
    
    if (!self.isContinuous) {
        for (UIAction *action in self._actions) {
            [action performWithSender:self target:nil];
        }
    }
}

- (BOOL)_isEscapePress:(UIPress *)press {
    if (UIKey *key = press.key) {
        if (key.keyCode == UIKeyboardHIDUsageKeyboardEscape) {
            return YES;
        } else {
            return NO;
        }
    } else {
        if (press.type == UIPressTypeMenu) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (BOOL)_isEnterPress:(UIPress *)press {
    if (UIKey *key = press.key) {
        if (key.keyCode == UIKeyboardHIDUsageKeyboardReturnOrEnter) {
            return YES;
        } else {
            return NO;
        }
    } else {
        if (press.type == UIPressTypeSelect) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (BOOL)_isLeftPress:(UIPress *)press {
    if (UIKey *key = press.key) {
        switch (key.keyCode) {
            case UIKeyboardHIDUsageKeyboardLeftArrow:
                return YES;
            default:
                return NO;
        }
    } else {
        switch (press.type) {
            case UIPressTypeLeftArrow:
                return YES;
            default:
                return NO;
        }
    }
}

- (BOOL)_isRightPress:(UIPress *)press {
    if (UIKey *key = press.key) {
        switch (key.keyCode) {
            case UIKeyboardHIDUsageKeyboardRightArrow:
                return YES;
            default:
                return NO;
        }
    } else {
        switch (press.type) {
            case UIPressTypeRightArrow:
                return YES;
            default:
                return NO;
        }
    }
}

- (void)_updateTrackViewWidthConstraints {
    float minimumValue = self.minimumValue;
    float maximumValue = self.maximumValue;
    float size = maximumValue - minimumValue;
    float value = self.value;
    
    NSLayoutConstraint *minimumTrackViewWidthConstraint = [self._minimumTrackView.widthAnchor constraintEqualToAnchor:self._tracksContainerview.widthAnchor multiplier:(value - minimumValue) / size];
    
    self._minimumTrackViewWidthConstraint.active = NO;
    minimumTrackViewWidthConstraint.active = YES;
    
    self._minimumTrackViewWidthConstraint = minimumTrackViewWidthConstraint;
}

@end

#endif
