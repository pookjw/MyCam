//
//  CaptureVideoPreviewView.mm
//  MyCam
//
//  Created by Jinwoo Kim on 9/15/24.
//

#import <CamPresentation/CaptureVideoPreviewView.h>
#import <TargetConditionals.h>

#if !TARGET_OS_VISION

#import <CamPresentation/UIDeferredMenuElement+VideoDevice.h>
#import <CamPresentation/FocusRectLayer.h>
#import <CamPresentation/ExposureRectLayer.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <array>
#include <vector>
#include <ranges>
#import <CamPresentation/DrawingView.h>
#import <CamPresentation/UIMenuElement+CP_NumberOfLines.h>
#import <CamPresentation/NSStringFromAVCaptureCameraLensSmudgeDetectionStatus.h>

#warning 확대할 때 preview 뜨게 하기

namespace CaptureVideoPreview {
enum class GestureMode {
    None, FocusPoint, FocusRect, ExposurePoint, ExposureRect,
    CinematicVideoFixedFocusAtPoint, CinematicVideoTrackingFocusPoint, CinematicVideoTrackingFocusWithDetectedObjectID
};

const std::vector<GestureMode> allGestureModes() {
    std::vector<GestureMode> results {
        GestureMode::None,
        GestureMode::FocusPoint
    };
    
    if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
        results.push_back(GestureMode::FocusRect);
    }
    
    results.push_back(GestureMode::ExposurePoint);
    
    if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
        results.push_back(GestureMode::ExposureRect);
        results.push_back(GestureMode::CinematicVideoFixedFocusAtPoint);
        results.push_back(GestureMode::CinematicVideoTrackingFocusPoint);
        results.push_back(GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID);
    }
    
    return results;
};

NSString *NSStringFromGestureMode(GestureMode gestureMode) {
    switch (gestureMode) {
        case GestureMode::None:
            return @"None";
        case GestureMode::FocusPoint:
            return @"Focus Point";
        case GestureMode::FocusRect:
            return @"Focus Rect";
        case GestureMode::ExposurePoint:
            return @"Exposure Point";
        case GestureMode::ExposureRect:
            return @"Exposure Rect";
        case GestureMode::CinematicVideoFixedFocusAtPoint:
            return @"Cinematic Video Fixed Focus At Point";
        case GestureMode::CinematicVideoTrackingFocusPoint:
            return @"Cinematic Video Tracking Focus Point";
        case GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID:
            return @"Cinematic Video Tracking Focus With Detected ObjectID";
        default:
            abort();
    }
}
}

@interface CaptureVideoPreviewView ()
@property (retain, nonatomic, readonly) UILabel *spatialCaptureDiscomfortReasonLabel;
@property (retain, nonatomic, readonly) UILabel *cinematicVideoCaptureSceneMonitoringStatusesLabel API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0));
@property (retain, nonatomic, readonly) UILabel *cameraLensSmudgeDetectionLabel API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0));
@property (retain, nonatomic, readonly) CaptureService *captureService;
@property (retain, nonatomic, readonly) UIBarButtonItem *menuBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *captureProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *captureProgressBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *reactionProgressActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *reactionProgressBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingFocusActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingFocusBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingExposureActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingExposureBarButtonItem;
@property (retain, nonatomic, readonly) UIActivityIndicatorView *adjustingWhiteBalanceActivityIndicatorView;
@property (retain, nonatomic, readonly) UIBarButtonItem *adjustingWhiteBalanceBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *gestureModeMenuBarButtonItem;
#if TARGET_OS_TV
@property (retain, nonatomic, readonly) __kindof UIView *toolbar;
#else
@property (retain, nonatomic, readonly) UIToolbar *toolbar;
#endif
@property (retain, nonatomic, readonly) UIVisualEffectView *blurView;
@property (retain, nonatomic, readonly) PixelBufferLayer *customPreviewLayer;
@property (retain, nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property (retain, nonatomic, readonly) CALayer *videoThumbnailLayer;
@property (retain, nonatomic, readonly) FocusRectLayer *focusRectLayer;
@property (retain, nonatomic, readonly) ExposureRectLayer *exposureRectLayer;
@property (retain, nonatomic, readonly) NerualAnalyzerLayer *nerualAnalyzerLayer;
@property (assign, nonatomic) CaptureVideoPreview::GestureMode gestureMode;
@property (retain, nonatomic, readonly) DrawingView *drawingView;
@property (nonatomic, readonly) BOOL cinematicVideoCaptureEnabled API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0));
@end

@implementation CaptureVideoPreviewView
@synthesize cinematicVideoCaptureSceneMonitoringStatusesLabel = _cinematicVideoCaptureSceneMonitoringStatusesLabel;
@synthesize spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel;
@synthesize cameraLensSmudgeDetectionLabel = _cameraLensSmudgeDetectionLabel;
@synthesize menuBarButtonItem = _menuBarButtonItem;
@synthesize captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView;
@synthesize captureProgressBarButtonItem = _captureProgressBarButtonItem;
@synthesize reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView;
@synthesize reactionProgressBarButtonItem = _reactionProgressBarButtonItem;
@synthesize adjustingFocusActivityIndicatorView = _adjustingFocusActivityIndicatorView;
@synthesize adjustingFocusBarButtonItem = _adjustingFocusBarButtonItem;
@synthesize adjustingExposureActivityIndicatorView = _adjustingExposureActivityIndicatorView;
@synthesize adjustingExposureBarButtonItem = _adjustingExposureBarButtonItem;
@synthesize adjustingWhiteBalanceActivityIndicatorView = _adjustingWhiteBalanceActivityIndicatorView;
@synthesize adjustingWhiteBalanceBarButtonItem = _adjustingWhiteBalanceBarButtonItem;
@synthesize gestureModeMenuBarButtonItem = _gestureModeMenuBarButtonItem;
@synthesize toolbar = _toolbar;
@synthesize blurView = _blurView;
@synthesize drawingView = _drawingView;

- (instancetype)initWithCaptureService:(CaptureService *)captureService captureDevice:(AVCaptureDevice *)captureDevice previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer customPreviewLayer:(PixelBufferLayer *)customPreviewLayer sampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer videoThumbnailLayer:(CALayer *)videoThumbnailLayer depthMapLayer:(CALayer *)depthMapLayer visionLayer:(CALayer *)visionLayer metadataObjectsLayer:(CALayer *)metadataObjectsLayer nerualAnalyzerLayer:(NerualAnalyzerLayer *)nerualAnalyzerLayer {
    assert(previewLayer != nil);
    
    if (self = [super init]) {
        _captureService = [captureService retain];
        _captureDevice = [captureDevice retain];
        _previewLayer = [previewLayer retain];
        _customPreviewLayer = [customPreviewLayer retain];
        _sampleBufferDisplayLayer = [sampleBufferDisplayLayer retain];
        _videoThumbnailLayer = [videoThumbnailLayer retain];
        _depthMapLayer = [depthMapLayer retain];
        _visionLayer = [visionLayer retain];
        _nerualAnalyzerLayer = [nerualAnalyzerLayer retain];
        _metadataObjectsLayer = [metadataObjectsLayer retain];
        
        CALayer *layer = self.layer;
#if !TARGET_OS_TV
        if (@available(iOS 26.0, *)) {
            layer.preferredDynamicRange = CADynamicRangeHigh;
        } else {
            layer.wantsExtendedDynamicRangeContent = YES;
        }
#endif
        
        CGRect bounds = layer.bounds;
        
        previewLayer.frame = bounds;
        [layer addSublayer:previewLayer];
        
        customPreviewLayer.frame = bounds;
        [layer addSublayer:customPreviewLayer];
        
        sampleBufferDisplayLayer.frame = bounds;
        [layer addSublayer:sampleBufferDisplayLayer];
        
        videoThumbnailLayer.frame = bounds;
        [layer addSublayer:videoThumbnailLayer];
        
        if (depthMapLayer != nil) {
            depthMapLayer.frame = bounds;
            [layer addSublayer:depthMapLayer];
        }
        
        if (visionLayer != nil) {
            visionLayer.frame = bounds;
            [layer addSublayer:visionLayer];
        }
        
        if (metadataObjectsLayer != nil) {
            metadataObjectsLayer.frame = bounds;
            [layer addSublayer:metadataObjectsLayer];
        }
        
        nerualAnalyzerLayer.frame = bounds;
        [layer addSublayer:nerualAnalyzerLayer];
        
        FocusRectLayer *focusRectLayer = [[FocusRectLayer alloc] initWithCaptureDevice:captureDevice videoPreviewLayer:previewLayer];
        [layer addSublayer:focusRectLayer];
        _focusRectLayer = focusRectLayer;
        
        ExposureRectLayer *exposureRectLayer = [[ExposureRectLayer alloc] initWithCaptureDevice:captureDevice videoPreviewLayer:previewLayer];
        [layer addSublayer:exposureRectLayer];
        _exposureRectLayer = exposureRectLayer;
        
        DrawingView *drawingView = self.drawingView;
        drawingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        drawingView.frame = self.bounds;
        [self addSubview:drawingView];
        
        //
        
        UILabel *spatialCaptureDiscomfortReasonLabel = self.spatialCaptureDiscomfortReasonLabel;
        spatialCaptureDiscomfortReasonLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:spatialCaptureDiscomfortReasonLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [spatialCaptureDiscomfortReasonLabel.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor],
            [spatialCaptureDiscomfortReasonLabel.centerYAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerYAnchor],
            [spatialCaptureDiscomfortReasonLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.topAnchor],
            [spatialCaptureDiscomfortReasonLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [spatialCaptureDiscomfortReasonLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
            [spatialCaptureDiscomfortReasonLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor]
        ]];
        
        //
        
        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
            UILabel *cinematicVideoCaptureSceneMonitoringStatusesLabel = self.cinematicVideoCaptureSceneMonitoringStatusesLabel;
            cinematicVideoCaptureSceneMonitoringStatusesLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:cinematicVideoCaptureSceneMonitoringStatusesLabel];
            
            [NSLayoutConstraint activateConstraints:@[
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor],
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.centerYAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerYAnchor],
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.topAnchor],
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
                [cinematicVideoCaptureSceneMonitoringStatusesLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor]
            ]];
            
            
            UILabel *cameraLensSmudgeDetectionLabel = self.cameraLensSmudgeDetectionLabel;
            cameraLensSmudgeDetectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:cameraLensSmudgeDetectionLabel];
            
            [NSLayoutConstraint activateConstraints:@[
                [cameraLensSmudgeDetectionLabel.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor],
                [cameraLensSmudgeDetectionLabel.centerYAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerYAnchor],
                [cameraLensSmudgeDetectionLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.topAnchor],
                [cameraLensSmudgeDetectionLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
                [cameraLensSmudgeDetectionLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
                [cameraLensSmudgeDetectionLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor]
            ]];
        }
        
        //
        
#if TARGET_OS_TV
        __kindof UIView *toolbar = self.toolbar;
#else
        UIToolbar *toolbar = self.toolbar;
#endif
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:toolbar];
        [NSLayoutConstraint activateConstraints:@[
            [toolbar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [toolbar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [toolbar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        toolbar.layer.zPosition = customPreviewLayer.zPosition + 1.f;
        
        //
        
        UITapGestureRecognizer *tapGestureRecogninzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewTapGestureRecognizer:)];
        [self addGestureRecognizer:tapGestureRecogninzer];
        _tapGestureRecogninzer = tapGestureRecogninzer;
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerCaptureVideoPreviewViewLongPressGestureRecognizer:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
        _longPressGestureRecognizer = longPressGestureRecognizer;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerPanGestureRecognizer:)];
        [self addGestureRecognizer:panGestureRecognizer];
        _panGestureRecognizer = panGestureRecognizer;
        
        //
        
        [captureDevice addObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons" options:NSKeyValueObservingOptionNew context:nullptr];
        [self updateSpatialCaptureDiscomfortReasonLabelWithReasons:captureDevice.spatialCaptureDiscomfortReasons];
        
        [self updateContentsScale];
        
        self.gestureMode = CaptureVideoPreview::GestureMode::None;
        
        //
        
        UIVisualEffectView *blurView = self.blurView;
        [self addSubview:blurView];
        blurView.frame = self.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.hidden = YES;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willBeginSnapshotSessionNotification:)
                                                   name:@"_UIApplicationWillBeginSnapshotSessionNotification"
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didEndSnapshotSessionNotification:)
                                                   name:@"_UIApplicationDidEndSnapshotSessionNotification"
                                                 object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didChangeCaptureReadinessNotification:)
                                                   name:CaptureServiceDidChangeCaptureReadinessNotificationName
                                                 object:captureService];
        
        [captureDevice addObserver:self forKeyPath:@"reactionEffectsInProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        [captureDevice addObserver:self forKeyPath:@"adjustingWhiteBalance" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        
        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
            [captureDevice addObserver:self forKeyPath:@"cinematicVideoCaptureSceneMonitoringStatuses" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
            [captureDevice addObserver:self forKeyPath:@"cameraLensSmudgeDetectionStatus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
            [captureDevice addObserver:self forKeyPath:@"cameraLensSmudgeDetectionEnabled" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nullptr];
        }
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_captureService release];
    [_captureDevice removeObserver:self forKeyPath:@"spatialCaptureDiscomfortReasons"];
    [_captureDevice removeObserver:self forKeyPath:@"reactionEffectsInProgress"];
    [_captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    [_captureDevice removeObserver:self forKeyPath:@"adjustingExposure"];
    [_captureDevice removeObserver:self forKeyPath:@"adjustingWhiteBalance"];
    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
        [_captureDevice removeObserver:self forKeyPath:@"cinematicVideoCaptureSceneMonitoringStatuses"];
        [_captureDevice removeObserver:self forKeyPath:@"cameraLensSmudgeDetectionStatus"];
        [_captureDevice removeObserver:self forKeyPath:@"cameraLensSmudgeDetectionEnabled"];
    }
    [_captureDevice release];
    [_previewLayer release];
    [_customPreviewLayer release];
    [_sampleBufferDisplayLayer release];
    [_videoThumbnailLayer release];
    [_depthMapLayer release];
    [_visionLayer release];
    [_metadataObjectsLayer release];
    [_focusRectLayer release];
    [_exposureRectLayer release];
    [_nerualAnalyzerLayer release];
    [_spatialCaptureDiscomfortReasonLabel release];
    [_cinematicVideoCaptureSceneMonitoringStatusesLabel release];
    [_cameraLensSmudgeDetectionLabel release];
    [_menuBarButtonItem release];
    [_captureProgressActivityIndicatorView release];
    [_captureProgressBarButtonItem release];
    [_reactionProgressActivityIndicatorView release];
    [_reactionProgressBarButtonItem release];
    [_adjustingFocusActivityIndicatorView release];
    [_adjustingFocusBarButtonItem release];
    [_adjustingExposureActivityIndicatorView release];
    [_adjustingExposureBarButtonItem release];
    [_adjustingWhiteBalanceActivityIndicatorView release];
    [_adjustingWhiteBalanceBarButtonItem release];
    [_gestureModeMenuBarButtonItem release];
    [_toolbar release];
    [_blurView release];
    [_tapGestureRecogninzer release];
    [_longPressGestureRecognizer release];
    [_panGestureRecognizer release];
    [_drawingView release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([_captureDevice isEqual:object]) {
        if ([keyPath isEqualToString:@"spatialCaptureDiscomfortReasons"]) {
            auto captureDevice = static_cast<AVCaptureDevice *>(object);
            
            dispatch_async(self.captureService.captureSessionQueue, ^{
                NSSet<AVSpatialCaptureDiscomfortReason> *spatialCaptureDiscomfortReasons = captureDevice.spatialCaptureDiscomfortReasons;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateSpatialCaptureDiscomfortReasonLabelWithReasons:spatialCaptureDiscomfortReasons];
                });
            });
            return;
        } else if ([keyPath isEqualToString:@"reactionEffectsInProgress"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeReactionEffectsInProgress];
            });
            return;
        } else if ([keyPath isEqualToString:@"adjustingFocus"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeAdjustingFocus];
            });
            return;
        } else if ([keyPath isEqualToString:@"adjustingExposure"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeAdjustingExposure];
            });
            return;
        } else if ([keyPath isEqualToString:@"adjustingWhiteBalance"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didChangeAdjustingWhiteBalance];
            });
            return;
        } else if ([keyPath isEqualToString:@"cinematicVideoCaptureSceneMonitoringStatuses"]) {
            auto captureDevice = static_cast<AVCaptureDevice *>(object);
            
            if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                dispatch_async(self.captureService.captureSessionQueue, ^{
                    NSSet<AVCaptureSceneMonitoringStatus> *cinematicVideoCaptureSceneMonitoringStatuses = captureDevice.cinematicVideoCaptureSceneMonitoringStatuses;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                            [self updateCinematicVideoCaptureSceneMonitoringStatusesLabel:cinematicVideoCaptureSceneMonitoringStatuses];
                        } else {
                            abort();
                        }
                    });
                });
            } else {
                abort();
            }
            return;
        } else if ([keyPath isEqualToString:@"cameraLensSmudgeDetectionStatus"] or [keyPath isEqualToString:@"cameraLensSmudgeDetectionEnabled"]) {
            auto captureDevice = static_cast<AVCaptureDevice *>(object);
            
            if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                dispatch_async(self.captureService.captureSessionQueue, ^{
                    AVCaptureCameraLensSmudgeDetectionStatus cameraLensSmudgeDetectionStatus = captureDevice.cameraLensSmudgeDetectionStatus;
                    BOOL cameraLensSmudgeDetectionEnabled = captureDevice.cameraLensSmudgeDetectionEnabled;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                            [self updateCameraLensSmudgeDetectionStatusLabel:cameraLensSmudgeDetectionStatus cameraLensSmudgeDetectionEnabled:cameraLensSmudgeDetectionEnabled];
                        } else {
                            abort();
                        }
                    });
                });
            } else {
                abort();
            }
            
            return;
        }
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateContentsScale];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CGRect bounds = self.layer.bounds;
    self.previewLayer.frame = bounds;
    self.customPreviewLayer.frame = bounds;
    self.sampleBufferDisplayLayer.frame = bounds;
    self.videoThumbnailLayer.frame = bounds;
    self.depthMapLayer.frame = bounds;
    self.visionLayer.frame = bounds;
    self.metadataObjectsLayer.frame = bounds;
    self.focusRectLayer.frame = bounds;
    self.exposureRectLayer.frame = bounds;
    self.nerualAnalyzerLayer.frame = bounds;
    [pool release];
}

- (void)setGestureMode:(CaptureVideoPreview::GestureMode)gestureMode {
    _gestureMode = gestureMode;
    
    switch (gestureMode) {
        case CaptureVideoPreview::GestureMode::None:
            self.tapGestureRecogninzer.enabled = NO;
            self.longPressGestureRecognizer.enabled = NO;
            self.panGestureRecognizer.enabled = NO;
            break;
        case CaptureVideoPreview::GestureMode::FocusPoint:
            assert(self.captureDevice.focusPointOfInterestSupported);
            self.tapGestureRecogninzer.enabled = YES;
            self.longPressGestureRecognizer.enabled = YES;
            self.panGestureRecognizer.enabled = NO;
            break;
        case CaptureVideoPreview::GestureMode::FocusRect:
            if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                assert(self.captureDevice.focusRectOfInterestSupported);
                self.tapGestureRecogninzer.enabled = NO;
                self.longPressGestureRecognizer.enabled = YES;
                self.panGestureRecognizer.enabled = YES;
            } else {
                abort();
            }
            break;
        case CaptureVideoPreview::GestureMode::ExposurePoint:
            assert(self.captureDevice.exposurePointOfInterestSupported);
            self.tapGestureRecogninzer.enabled = YES;
            self.longPressGestureRecognizer.enabled = YES;
            self.panGestureRecognizer.enabled = NO;
            break;
        case CaptureVideoPreview::GestureMode::ExposureRect:
            if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                assert(self.captureDevice.exposureRectOfInterestSupported);
                self.tapGestureRecogninzer.enabled = NO;
                self.longPressGestureRecognizer.enabled = YES;
                self.panGestureRecognizer.enabled = YES;
            } else {
                abort();
            }
            break;
        case CaptureVideoPreview::GestureMode::CinematicVideoFixedFocusAtPoint:
        case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusPoint:
        case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID:
            if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                self.tapGestureRecogninzer.enabled = YES;
                self.longPressGestureRecognizer.enabled = YES;
                self.panGestureRecognizer.enabled = NO;
            } else {
                abort();
            }
            break;
        default:
            abort();
    }
}

- (UILabel *)spatialCaptureDiscomfortReasonLabel {
    if (auto spatialCaptureDiscomfortReasonLabel = _spatialCaptureDiscomfortReasonLabel) return spatialCaptureDiscomfortReasonLabel;
    
    UILabel *spatialCaptureDiscomfortReasonLabel = [UILabel new];
    spatialCaptureDiscomfortReasonLabel.textAlignment = NSTextAlignmentCenter;
    spatialCaptureDiscomfortReasonLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    spatialCaptureDiscomfortReasonLabel.numberOfLines = 0;
    
    spatialCaptureDiscomfortReasonLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    spatialCaptureDiscomfortReasonLabel.textColor = UIColor.whiteColor;
    
    _spatialCaptureDiscomfortReasonLabel = [spatialCaptureDiscomfortReasonLabel retain];
    return [spatialCaptureDiscomfortReasonLabel autorelease];
}

- (UILabel *)cinematicVideoCaptureSceneMonitoringStatusesLabel {
    if (auto cinematicVideoCaptureSceneMonitoringStatusesLabel = _cinematicVideoCaptureSceneMonitoringStatusesLabel) return cinematicVideoCaptureSceneMonitoringStatusesLabel;
    
    UILabel *cinematicVideoCaptureSceneMonitoringStatusesLabel = [UILabel new];
    cinematicVideoCaptureSceneMonitoringStatusesLabel.textAlignment = NSTextAlignmentCenter;
    cinematicVideoCaptureSceneMonitoringStatusesLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cinematicVideoCaptureSceneMonitoringStatusesLabel.numberOfLines = 0;
    
    cinematicVideoCaptureSceneMonitoringStatusesLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    cinematicVideoCaptureSceneMonitoringStatusesLabel.textColor = UIColor.whiteColor;
    
    _cinematicVideoCaptureSceneMonitoringStatusesLabel = cinematicVideoCaptureSceneMonitoringStatusesLabel;
    return cinematicVideoCaptureSceneMonitoringStatusesLabel;
}

- (UILabel *)cameraLensSmudgeDetectionLabel {
    if (auto cameraLensSmudgeDetectionLabel = _cameraLensSmudgeDetectionLabel) return cameraLensSmudgeDetectionLabel;
    
    UILabel *cameraLensSmudgeDetectionLabel = [UILabel new];
    cameraLensSmudgeDetectionLabel.textAlignment = NSTextAlignmentCenter;
    cameraLensSmudgeDetectionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cameraLensSmudgeDetectionLabel.numberOfLines = 0;
    
    cameraLensSmudgeDetectionLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    cameraLensSmudgeDetectionLabel.textColor = UIColor.whiteColor;
    
    _cameraLensSmudgeDetectionLabel = cameraLensSmudgeDetectionLabel;
    return cameraLensSmudgeDetectionLabel;
}

- (UIBarButtonItem *)menuBarButtonItem {
    if (auto menuBarButtonItem = _menuBarButtonItem) return menuBarButtonItem;
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement cp_videoDeviceElementWithCaptureService:self.captureService videoDevice:self.captureDevice didChangeHandler:nil]
    ]];
    
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"list.bullet"] menu:menu];
    menuBarButtonItem.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _menuBarButtonItem = [menuBarButtonItem retain];
    return [menuBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)captureProgressActivityIndicatorView {
    if (auto captureProgressActivityIndicatorView = _captureProgressActivityIndicatorView) return captureProgressActivityIndicatorView;
    
    UIActivityIndicatorView *captureProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    captureProgressActivityIndicatorView.hidesWhenStopped = YES;
    captureProgressActivityIndicatorView.color = UIColor.systemRedColor;
    
    _captureProgressActivityIndicatorView = [captureProgressActivityIndicatorView retain];
    return [captureProgressActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)captureProgressBarButtonItem {
    if (auto captureProgressBarButtonItem = _captureProgressBarButtonItem) return captureProgressBarButtonItem;
    
    UIActivityIndicatorView *captureProgressActivityIndicatorView = self.captureProgressActivityIndicatorView;
    UIBarButtonItem *captureProgressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:captureProgressActivityIndicatorView];
#if !TARGET_OS_TV
    captureProgressBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    captureProgressBarButtonItem.enabled = NO;
    
    _captureProgressBarButtonItem = [captureProgressBarButtonItem retain];
    return [captureProgressBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)reactionProgressActivityIndicatorView {
    if (auto reactionProgressActivityIndicatorView = _reactionProgressActivityIndicatorView) return reactionProgressActivityIndicatorView;
    
    UIActivityIndicatorView *reactionProgressActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    reactionProgressActivityIndicatorView.hidesWhenStopped = YES;
    reactionProgressActivityIndicatorView.color = UIColor.systemOrangeColor;
    
    _reactionProgressActivityIndicatorView = [reactionProgressActivityIndicatorView retain];
    return [reactionProgressActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)reactionProgressBarButtonItem {
    if (auto reactionProgressBarButtonItem = _reactionProgressBarButtonItem) return reactionProgressBarButtonItem;
    
    UIActivityIndicatorView *reactionProgressActivityIndicatorView = self.reactionProgressActivityIndicatorView;
    UIBarButtonItem *reactionProgressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reactionProgressActivityIndicatorView];
#if !TARGET_OS_TV
    reactionProgressBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    reactionProgressBarButtonItem.enabled = NO;
    
    _reactionProgressBarButtonItem = [reactionProgressBarButtonItem retain];
    return [reactionProgressBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)adjustingFocusActivityIndicatorView {
    if (auto adjustingFocusActivityIndicatorView = _adjustingFocusActivityIndicatorView) return adjustingFocusActivityIndicatorView;
    
    UIActivityIndicatorView *adjustingFocusActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    adjustingFocusActivityIndicatorView.hidesWhenStopped = YES;
    adjustingFocusActivityIndicatorView.color = UIColor.systemYellowColor;
    
    _adjustingFocusActivityIndicatorView = [adjustingFocusActivityIndicatorView retain];
    return [adjustingFocusActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)adjustingFocusBarButtonItem {
    if (auto adjustingFocusBarButtonItem = _adjustingFocusBarButtonItem) return adjustingFocusBarButtonItem;
    
    UIActivityIndicatorView *adjustingFocusActivityIndicatorView = self.adjustingFocusActivityIndicatorView;
    UIBarButtonItem *adjustingFocusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:adjustingFocusActivityIndicatorView];
#if !TARGET_OS_TV
    adjustingFocusBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    adjustingFocusBarButtonItem.enabled = NO;
    
    _adjustingFocusBarButtonItem = [adjustingFocusBarButtonItem retain];
    return [adjustingFocusBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)adjustingExposureActivityIndicatorView {
    if (auto adjustingExposureActivityIndicatorView = _adjustingExposureActivityIndicatorView) return adjustingExposureActivityIndicatorView;
    
    UIActivityIndicatorView *adjustingExposureActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    adjustingExposureActivityIndicatorView.hidesWhenStopped = YES;
    adjustingExposureActivityIndicatorView.color = UIColor.systemGreenColor;
    
    _adjustingExposureActivityIndicatorView = [adjustingExposureActivityIndicatorView retain];
    return [adjustingExposureActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)adjustingExposureBarButtonItem {
    if (auto adjustingExposureBarButtonItem = _adjustingExposureBarButtonItem) return adjustingExposureBarButtonItem;
    
    UIActivityIndicatorView *adjustingExposureActivityIndicatorView = self.adjustingExposureActivityIndicatorView;
    UIBarButtonItem *adjustingExposureBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:adjustingExposureActivityIndicatorView];
#if !TARGET_OS_TV
    adjustingExposureBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    adjustingExposureBarButtonItem.enabled = NO;
    
    _adjustingExposureBarButtonItem = [adjustingExposureBarButtonItem retain];
    return [adjustingExposureBarButtonItem autorelease];
}

- (UIActivityIndicatorView *)adjustingWhiteBalanceActivityIndicatorView {
    if (auto adjustingWhiteBalanceActivityIndicatorView = _adjustingWhiteBalanceActivityIndicatorView) return adjustingWhiteBalanceActivityIndicatorView;
    
    UIActivityIndicatorView *adjustingWhiteBalanceActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    adjustingWhiteBalanceActivityIndicatorView.hidesWhenStopped = YES;
    adjustingWhiteBalanceActivityIndicatorView.color = UIColor.systemBlueColor;
    
    _adjustingWhiteBalanceActivityIndicatorView = [adjustingWhiteBalanceActivityIndicatorView retain];
    return [adjustingWhiteBalanceActivityIndicatorView autorelease];
}

- (UIBarButtonItem *)adjustingWhiteBalanceBarButtonItem {
    if (auto adjustingWhiteBalanceBarButtonItem = _adjustingWhiteBalanceBarButtonItem) return adjustingWhiteBalanceBarButtonItem;
    
    UIActivityIndicatorView *adjustingWhiteBalanceActivityIndicatorView = self.adjustingWhiteBalanceActivityIndicatorView;
    UIBarButtonItem *adjustingWhiteBalanceBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:adjustingWhiteBalanceActivityIndicatorView];
#if !TARGET_OS_TV
    adjustingWhiteBalanceBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    adjustingWhiteBalanceBarButtonItem.enabled = NO;
    
    _adjustingWhiteBalanceBarButtonItem = [adjustingWhiteBalanceBarButtonItem retain];
    return [adjustingWhiteBalanceBarButtonItem autorelease];
}

- (UIBarButtonItem *)gestureModeMenuBarButtonItem {
    if (auto gestureModeMenuBarButtonItem = _gestureModeMenuBarButtonItem) return gestureModeMenuBarButtonItem;
    
    __block auto unreaintedSelf = self;
    
    UIDeferredMenuElement *element = [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        CaptureVideoPreview::GestureMode currentGestureMode = unreaintedSelf.gestureMode;
        
        dispatch_async(unreaintedSelf.captureService.captureSessionQueue, ^{
            auto _unreaintedSelf = unreaintedSelf;
            
            const std::vector<CaptureVideoPreview::GestureMode> allModes = CaptureVideoPreview::allGestureModes();
            
            auto actionsVec = allModes
            | std::views::transform([currentGestureMode, _unreaintedSelf](CaptureVideoPreview::GestureMode gestureMode) -> UIAction * {
                UIAction *action = [UIAction actionWithTitle:CaptureVideoPreview::NSStringFromGestureMode(gestureMode) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    _unreaintedSelf.gestureMode = gestureMode;
                }];
                
                action.state = (currentGestureMode == gestureMode) ? UIMenuElementStateOn : UIMenuElementStateOff;
                
                BOOL isSupported;
                switch (gestureMode) {
                    case CaptureVideoPreview::GestureMode::None:
                        isSupported = YES;
                        break;
                    case CaptureVideoPreview::GestureMode::FocusPoint:
                        isSupported = _unreaintedSelf.captureDevice.focusPointOfInterestSupported;
                        break;
                    case CaptureVideoPreview::GestureMode::FocusRect:
                        if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                            isSupported = _unreaintedSelf.captureDevice.focusRectOfInterestSupported;
                        } else {
                            abort();
                        }
                        break;
                    case CaptureVideoPreview::GestureMode::ExposurePoint:
                        isSupported = _unreaintedSelf.captureDevice.isExposurePointOfInterestSupported;
                        break;
                    case CaptureVideoPreview::GestureMode::ExposureRect:
                        if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                            isSupported = _unreaintedSelf.captureDevice.exposureRectOfInterestSupported;
                        } else {
                            abort();
                        }
                        break;
                    case CaptureVideoPreview::GestureMode::CinematicVideoFixedFocusAtPoint:
                    case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusPoint:
                    case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID:
                        if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                            isSupported = _unreaintedSelf.cinematicVideoCaptureEnabled;
                        } else {
                            abort();
                        }
                        break;
                    default:
                        NSLog(@"%@", CaptureVideoPreview::NSStringFromGestureMode(gestureMode));
                        abort();
                }
                
                action.attributes = isSupported ? 0 : UIMenuElementAttributesDisabled;
                action.cp_overrideNumberOfTitleLines = 0;
                
                return action;
            })
            | std::ranges::to<std::vector<UIAction *>>();
            
            NSArray<UIAction *> *actions = [[NSArray alloc] initWithObjects:actionsVec.data() count:actionsVec.size()];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(actions);
            });
            [actions release];
        });
    }];
    
    UIMenu *menu = [UIMenu menuWithChildren:@[
        element
    ]];
    
    UIBarButtonItem *gestureModeMenuBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"hand.rays"] menu:menu];
    gestureModeMenuBarButtonItem.preferredMenuElementOrder = UIContextMenuConfigurationElementOrderFixed;
    
    _gestureModeMenuBarButtonItem = [gestureModeMenuBarButtonItem retain];
    return [gestureModeMenuBarButtonItem autorelease];
}

#if TARGET_OS_TV
- (__kindof UIView *)toolbar {
    if (auto toolbar = _toolbar) return toolbar;
    
    __kindof UIView *toolbar = [objc_lookUpClass("UIToolbar") new];
    
    reinterpret_cast<void (*)(id, SEL, id, BOOL)>(objc_msgSend)(toolbar, sel_registerName("setItems:animated:"), @[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem,
        self.adjustingExposureBarButtonItem,
        self.adjustingWhiteBalanceBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.gestureModeMenuBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.menuBarButtonItem
    ], NO);
    
    _toolbar = [toolbar retain];
    return [toolbar autorelease];
}
#else
- (UIToolbar *)toolbar {
    if (auto toolbar = _toolbar) return toolbar;
    
    UIToolbar *toolbar = [UIToolbar new];
    
    [toolbar setItems:@[
        self.captureProgressBarButtonItem,
        self.reactionProgressBarButtonItem,
        self.adjustingFocusBarButtonItem,
        self.adjustingExposureBarButtonItem,
        self.adjustingWhiteBalanceBarButtonItem,
        [UIBarButtonItem flexibleSpaceItem],
        self.gestureModeMenuBarButtonItem,
        self.menuBarButtonItem
    ]
             animated:NO];
    
    _toolbar = [toolbar retain];
    return [toolbar autorelease];
}
#endif

- (UIVisualEffectView *)blurView {
    if (auto blurView = _blurView) return blurView;
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    
    _blurView = [blurView retain];
    return [blurView autorelease];
}

- (DrawingView *)drawingView {
    if (auto drawingView = _drawingView) return drawingView;
    
    DrawingView *drawingView = [DrawingView new];
    drawingView.userInteractionEnabled = NO;
    
    _drawingView = drawingView;
    return drawingView;
}

- (BOOL)cinematicVideoCaptureEnabled API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0)) {
    NSSet<AVCaptureDeviceInput *> *addedDeviceInputs = [self.captureService queue_addedDeviceInputsFromCaptureDevice:self.captureDevice];
    assert(addedDeviceInputs.count == 1);
    AVCaptureDeviceInput *input = addedDeviceInputs.allObjects[0];
    return input.cinematicVideoCaptureEnabled;
}

- (void)updateSpatialCaptureDiscomfortReasonLabelWithReasons:(NSSet<AVSpatialCaptureDiscomfortReason> *)reasons {
    NSString *text = [reasons.allObjects componentsJoinedByString:@"\n"];
    self.spatialCaptureDiscomfortReasonLabel.text = text;
}

- (void)reloadMenu __attribute__((deprecated)) {
    UIMenu *menu = [self.menuBarButtonItem.menu copy];
    self.menuBarButtonItem.menu = menu;
    [menu release];
}

- (void)didTriggerCaptureVideoPreviewViewTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    auto previewView = static_cast<CaptureVideoPreviewView *>(sender.view);
    AVCaptureVideoPreviewLayer *previewLayer = previewView.previewLayer;
    CGPoint viewPoint = [sender locationInView:previewView];
    CGPoint pointOfInterest = [previewLayer captureDevicePointOfInterestForPoint:viewPoint];
    CaptureVideoPreview::GestureMode gestureMode = self.gestureMode;
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDevice *captureDevice = [self.captureService queue_captureDeviceFromPreviewLayer:previewLayer];
        
        switch (gestureMode) {
            case CaptureVideoPreview::GestureMode::FocusPoint:
            {
                if (!captureDevice.isFocusPointOfInterestSupported) return;
                
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                
                captureDevice.focusPointOfInterest = pointOfInterest;
                
                if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                } else if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                    captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
                }
                
                [captureDevice unlockForConfiguration];
            }
                break;
            case CaptureVideoPreview::GestureMode::FocusRect:
                // Pan Gesture만 가능해야함
                abort();
            case CaptureVideoPreview::GestureMode::ExposurePoint:
            {
                if (!captureDevice.isExposurePointOfInterestSupported) return;
                
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                
                captureDevice.exposurePointOfInterest = pointOfInterest;
                
                if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                    captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
                } else if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                    captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
                }
                
                [captureDevice unlockForConfiguration];
            }
                break;
            case CaptureVideoPreview::GestureMode::ExposureRect:
                // Pan Gesture만 가능해야함
                abort();
            case CaptureVideoPreview::GestureMode::CinematicVideoFixedFocusAtPoint:
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    [captureDevice setCinematicVideoFixedFocusAtPoint:pointOfInterest focusMode:AVCaptureCinematicVideoFocusModeWeak];
                    [captureDevice unlockForConfiguration];
                } else {
                    abort();
                }
                break;
            case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusPoint:
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    [captureDevice setCinematicVideoTrackingFocusAtPoint:pointOfInterest focusMode:AVCaptureCinematicVideoFocusModeWeak];
                    [captureDevice unlockForConfiguration];
                } else {
                    abort();
                }
                break;
            case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID: {
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    AVMetadataObject * _Nullable metadata = [self queue_metadataObjectLayerPoint:viewPoint];
                    if (metadata != nil) {
                        NSError * _Nullable error = nil;
                        [captureDevice lockForConfiguration:&error];
                        assert(error == nil);
                        [self.captureDevice setCinematicVideoTrackingFocusWithDetectedObjectID:metadata.objectID focusMode:AVCaptureCinematicVideoFocusModeWeak];
                        [captureDevice unlockForConfiguration];
                    }
                } else {
                    abort();
                }
                break;
            }
            default:
                abort();
        }
    });
}

- (void)didTriggerCaptureVideoPreviewViewLongPressGestureRecognizer:(UILongPressGestureRecognizer *)sender {
    auto previewView = static_cast<CaptureVideoPreviewView *>(sender.view);
    AVCaptureVideoPreviewLayer *previewLayer = previewView.previewLayer;
    CGPoint viewPoint = [sender locationInView:previewView];
    CGPoint pointOfInterest = [previewLayer captureDevicePointOfInterestForPoint:viewPoint];
    CaptureVideoPreview::GestureMode gestureMode = self.gestureMode;
    
    dispatch_async(self.captureService.captureSessionQueue, ^{
        AVCaptureDevice *captureDevice = [self.captureService queue_captureDeviceFromPreviewLayer:previewLayer];
        
        switch (gestureMode) {
            case CaptureVideoPreview::GestureMode::FocusPoint:
            {
                if (!captureDevice.isFocusPointOfInterestSupported) abort();
                if (![captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) return;
                
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.focusPointOfInterest = pointOfInterest;
                captureDevice.focusMode = AVCaptureFocusModeLocked;
                [captureDevice unlockForConfiguration];
                break;
            }
            case CaptureVideoPreview::GestureMode::FocusRect:
            {
                if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                    if (!captureDevice.isFocusRectOfInterestSupported) abort();
                    if (![captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) return;
                    
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    captureDevice.focusMode = AVCaptureFocusModeLocked;
                    [captureDevice unlockForConfiguration];
                    break;
                } else {
                    abort();
                }
            }
            case CaptureVideoPreview::GestureMode::ExposurePoint:
            {
                if (!captureDevice.isExposurePointOfInterestSupported) abort();
                if (![captureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) return;
                
                NSError * _Nullable error = nil;
                [captureDevice lockForConfiguration:&error];
                assert(error == nil);
                captureDevice.exposurePointOfInterest = pointOfInterest;
                captureDevice.exposureMode = AVCaptureExposureModeLocked;
                [captureDevice unlockForConfiguration];
                break;
            }
            case CaptureVideoPreview::GestureMode::ExposureRect:
            {
                if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                    if (!captureDevice.isExposureRectOfInterestSupported) abort();
                    if (![captureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) return;
                    
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    captureDevice.exposureMode = AVCaptureExposureModeLocked;
                    [captureDevice unlockForConfiguration];
                    break;
                } else {
                    abort();
                }
            }
            case CaptureVideoPreview::GestureMode::CinematicVideoFixedFocusAtPoint:
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    [captureDevice setCinematicVideoFixedFocusAtPoint:pointOfInterest focusMode:AVCaptureCinematicVideoFocusModeStrong];
                    [captureDevice unlockForConfiguration];
                } else {
                    abort();
                }
                break;
            case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusPoint:
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    NSError * _Nullable error = nil;
                    [captureDevice lockForConfiguration:&error];
                    assert(error == nil);
                    [captureDevice setCinematicVideoTrackingFocusAtPoint:pointOfInterest focusMode:AVCaptureCinematicVideoFocusModeStrong];
                    [captureDevice unlockForConfiguration];
                } else {
                    abort();
                }
            case CaptureVideoPreview::GestureMode::CinematicVideoTrackingFocusWithDetectedObjectID:
                if (@available(macOS 26.0, iOS 26.0, macCatalyst 26.0, tvOS 26.0, visionOS 26.0, *)) {
                    assert(self.cinematicVideoCaptureEnabled);
                    AVMetadataObject * _Nullable metadata = [self queue_metadataObjectLayerPoint:viewPoint];
                    if (metadata != nil) {
                        NSError * _Nullable error = nil;
                        [captureDevice lockForConfiguration:&error];
                        assert(error == nil);
                        [self.captureDevice setCinematicVideoTrackingFocusWithDetectedObjectID:metadata.objectID focusMode:AVCaptureCinematicVideoFocusModeStrong];
                        [captureDevice unlockForConfiguration];
                    }
                } else {
                    abort();
                }
                break;
            default:
                abort();
        }
    });
}

- (void)didTriggerPanGestureRecognizer:(UIPanGestureRecognizer *)sender {
    DrawingView *drawingView = self.drawingView;
    
    CGPoint location = [sender locationInView:drawingView];
    CGRect bounds = drawingView.bounds;
    location.x /= CGRectGetWidth(bounds);
    location.y /= CGRectGetHeight(bounds);
    
    DrawingLayer *drawingLayer = drawingView.drawingLayer;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [drawingLayer clearPoints];
            [drawingLayer addLineToNormalizedPoint:location begin:YES];
            break;
        case UIGestureRecognizerStateChanged:
            [drawingLayer addLineToNormalizedPoint:location begin:NO];
            break;
        case UIGestureRecognizerStateEnded: {
            [drawingLayer addLineToNormalizedPoint:location begin:NO];
            
            CGRect boundingBox = drawingLayer.normalizedBoundingBox;
            if (CGRectIsNull(boundingBox)) return;
            
            boundingBox.origin.x *= CGRectGetWidth(bounds);
            boundingBox.origin.y *= CGRectGetHeight(bounds);
            boundingBox.size.width *= CGRectGetWidth(bounds);
            boundingBox.size.height *= CGRectGetHeight(bounds);
            
            AVCaptureVideoPreviewLayer *previewLayer = self.previewLayer;
            CGPoint pointOfInterest1 = [previewLayer captureDevicePointOfInterestForPoint:CGPointMake(CGRectGetMinX(boundingBox),
                                                                                                      CGRectGetMinY(boundingBox))];
            CGPoint pointOfInterest2 = [previewLayer captureDevicePointOfInterestForPoint:CGPointMake(CGRectGetMaxX(boundingBox),
                                                                                                      CGRectGetMaxY(boundingBox))];
            
            CGRect rectOfInterest = CGRectUnion(CGRectMake(pointOfInterest1.x, pointOfInterest1.y, 0., 0.),
                                                CGRectMake(pointOfInterest2.x, pointOfInterest2.y, 0., 0.));
            
            AVCaptureDevice *captureDevice = self.captureDevice;
            
            switch (self.gestureMode) {
                case CaptureVideoPreview::GestureMode::FocusRect: {
                    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                        CGSize minFocusRectOfInterestSize = captureDevice.minFocusRectOfInterestSize;
                        if (CGRectGetWidth(rectOfInterest) < minFocusRectOfInterestSize.width) {
                            rectOfInterest = CGRectInset(rectOfInterest,
                                                         (minFocusRectOfInterestSize.width - CGRectGetWidth(rectOfInterest)) * -0.5,
                                                         0.);
                        }
                        if (CGRectGetHeight(rectOfInterest) < minFocusRectOfInterestSize.height) {
                            rectOfInterest = CGRectInset(rectOfInterest,
                                                         0.,
                                                         (minFocusRectOfInterestSize.height - CGRectGetHeight(rectOfInterest)) * -0.5);
                        }
                    } else {
                        abort();
                    }
                    break;
                }
                case CaptureVideoPreview::GestureMode::ExposureRect: {
                    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                        CGSize minExposureRectOfInterestSize = captureDevice.minExposureRectOfInterestSize;
                        if (CGRectGetWidth(rectOfInterest) < minExposureRectOfInterestSize.width) {
                            rectOfInterest = CGRectInset(rectOfInterest,
                                                         (minExposureRectOfInterestSize.width - CGRectGetWidth(rectOfInterest)) * -0.5,
                                                         0.);
                        }
                        if (CGRectGetHeight(rectOfInterest) < minExposureRectOfInterestSize.height) {
                            rectOfInterest = CGRectInset(rectOfInterest,
                                                         0.,
                                                         (minExposureRectOfInterestSize.height - CGRectGetHeight(rectOfInterest)) * -0.5);
                        }
                    } else {
                        abort();
                    }
                    break;
                }
                default:
                    abort();
            }
            
            if (CGRectIsNull(rectOfInterest)) return;
            
            //
            
            NSError * _Nullable error = nil;
            [captureDevice lockForConfiguration:&error];
            assert(error == nil);
            
            switch (self.gestureMode) {
                case CaptureVideoPreview::GestureMode::FocusRect: {
                    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                        captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                    } else if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
                    }
                    
                    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                        captureDevice.focusRectOfInterest = rectOfInterest;
                    } else {
                        abort();
                    }
                    break;
                }
                case CaptureVideoPreview::GestureMode::ExposureRect: {
                    captureDevice.exposureMode = AVCaptureExposureModeLocked;
                    if (@available(iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, macOS 26.0, *)) {
                        captureDevice.exposureRectOfInterest = rectOfInterest;
                    } else {
                        abort();
                    }
                    break;
                }
                default:
                    abort();
            }
            
            [captureDevice unlockForConfiguration];
            break;
        }
        default:
            [self.drawingView.drawingLayer addLineToNormalizedPoint:location begin:NO];
            break;
    }
}

- (void)updateContentsScale {
    CGFloat displayScale = reinterpret_cast<CGFloat (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_currentScreenScale"));
    
    self.customPreviewLayer.contentsScale = displayScale;
    self.sampleBufferDisplayLayer.contentsScale = displayScale;
    self.videoThumbnailLayer.contentsScale = displayScale;
    self.depthMapLayer.contentsScale = displayScale;
    self.visionLayer.contentsScale = displayScale;
    self.metadataObjectsLayer.contentsScale = displayScale;
    self.focusRectLayer.contentsScale = displayScale;
    self.exposureRectLayer.contentsScale = displayScale;
    self.nerualAnalyzerLayer.contentsScale = displayScale;
}

- (__kindof AVMetadataObject * _Nullable)queue_metadataObjectLayerPoint:(CGPoint)layerPoint {
    AVCaptureMetadataOutput *metadataOutput = [self.captureService queue_outputWithClass:[AVCaptureMetadataOutput class] fromCaptureDevice:self.captureDevice];
    assert(metadataOutput != nil);
    
    NSArray<__kindof AVMetadataObject *> *metadataObjects = [self.captureService.queue_metadataObjectsByMetadataOutputCopiedMapTable objectForKey:metadataOutput];
    assert(metadataObjects != nil);
    
    for (__kindof AVMetadataObject *metadataObject in metadataObjects) {
        __kindof AVMetadataObject *transformed = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        if (transformed != nil) {
            if (CGRectContainsPoint(transformed.bounds, layerPoint)) {
                return transformed;
            }
        }
    }
    
    return nil;
}

- (void)willBeginSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = NO;
        }
    }
}

- (void)didEndSnapshotSessionNotification:(NSNotification *)notification {
    if (UIWindowScene *windowScene = self.window.windowScene) {
        if (windowScene.activationState == UISceneActivationStateBackground) {
            self.blurView.hidden = YES;
        }
    }
}

- (void)didChangeCaptureReadinessNotification:(NSNotification *)notification {
    CaptureService *captureService = self.captureService;
    dispatch_assert_queue(captureService.captureSessionQueue);
    
    auto captureDevice = static_cast<AVCaptureDevice *>(notification.userInfo[CaptureServiceCaptureDeviceKey]);
    
    if (![self.captureDevice isEqual:captureDevice]) {
        return;
    }
    
    AVCapturePhotoOutputReadinessCoordinator *readinessCoordinator = [captureService queue_readinessCoordinatorFromCaptureDevice:captureDevice];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (readinessCoordinator.captureReadiness == AVCapturePhotoOutputCaptureReadinessReady) {
            [self.captureProgressActivityIndicatorView stopAnimating];
            
#if !TARGET_OS_TV
            self.captureProgressBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
        } else {
            [self.captureProgressActivityIndicatorView startAnimating];
#if !TARGET_OS_TV
            self.captureProgressBarButtonItem.hidden = NO;
#else
#warning TODO
#endif
        }
        
        reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self.menuBarButtonItem, sel_registerName("_updateMenuInPlace"));
    });
}

- (void)didChangeReactionEffectsInProgress {
    NSUInteger reactionEffectsInProgressCount = self.captureDevice.reactionEffectsInProgress.count;
    
    if (reactionEffectsInProgressCount > 0) {
        [self.reactionProgressActivityIndicatorView startAnimating];
#if !TARGET_OS_TV
        self.reactionProgressBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    } else {
        [self.reactionProgressActivityIndicatorView stopAnimating];
#if !TARGET_OS_TV
        self.reactionProgressBarButtonItem.hidden = NO;
#else
#warning TODO
#endif
    }
}

- (void)didChangeAdjustingFocus {
    BOOL adjustingFocus = self.captureDevice.adjustingFocus;
    
    if (adjustingFocus) {
        [self.adjustingFocusActivityIndicatorView startAnimating];
#if !TARGET_OS_TV
        self.adjustingFocusBarButtonItem.hidden = NO;
#else
#warning TODO
#endif
    } else {
        [self.adjustingFocusActivityIndicatorView stopAnimating];
#if !TARGET_OS_TV
        self.adjustingFocusBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    }
}

- (void)didChangeAdjustingExposure {
    BOOL adjustingExposure = self.captureDevice.adjustingExposure;
    
    if (adjustingExposure) {
        [self.adjustingExposureActivityIndicatorView startAnimating];
#if !TARGET_OS_TV
        self.adjustingExposureBarButtonItem.hidden = NO;
#else
#warning TODO
#endif
    } else {
        [self.adjustingExposureActivityIndicatorView stopAnimating];
#if !TARGET_OS_TV
        self.adjustingExposureBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    }
}

- (void)didChangeAdjustingWhiteBalance {
    BOOL adjustingWhiteBalance = self.captureDevice.adjustingWhiteBalance;
    
    if (adjustingWhiteBalance) {
        [self.adjustingWhiteBalanceActivityIndicatorView startAnimating];
#if !TARGET_OS_TV
        self.adjustingWhiteBalanceBarButtonItem.hidden = NO;
#else
#warning TODO
#endif
    } else {
        [self.adjustingWhiteBalanceActivityIndicatorView stopAnimating];
#if !TARGET_OS_TV
        self.adjustingWhiteBalanceBarButtonItem.hidden = YES;
#else
#warning TODO
#endif
    }
}

- (void)updateCinematicVideoCaptureSceneMonitoringStatusesLabel:(NSSet<NSString *> *)cinematicVideoCaptureSceneMonitoringStatuses API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0)) {
    NSString *text = [cinematicVideoCaptureSceneMonitoringStatuses.allObjects componentsJoinedByString:@"\n"];
    self.cinematicVideoCaptureSceneMonitoringStatusesLabel.text = text;
}

- (void)updateCameraLensSmudgeDetectionStatusLabel:(AVCaptureCameraLensSmudgeDetectionStatus)status cameraLensSmudgeDetectionEnabled:(BOOL)cameraLensSmudgeDetectionEnabled API_AVAILABLE(ios(26.0), watchos(26.0), tvos(26.0), visionos(26.0), macos(26.0)) {
    self.cameraLensSmudgeDetectionLabel.text = NSStringFromAVCaptureCameraLensSmudgeDetectionStatus(status);
    self.cameraLensSmudgeDetectionLabel.hidden = !cameraLensSmudgeDetectionEnabled;
}

@end

#endif
