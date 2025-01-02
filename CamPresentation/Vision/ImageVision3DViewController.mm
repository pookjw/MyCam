//
//  ImageVision3DViewController.mm
//  CamPresentation
//
//  Created by Jinwoo Kim on 1/2/25.
//

#import <CamPresentation/ImageVision3DViewController.h>
#import <SceneKit/SceneKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <numbers>
#import <CamPresentation/NSStringFromVNHumanBodyPose3DObservationHeightEstimation.h>

@interface ImageVision3DViewController ()
@property (retain, nonatomic, readonly) SCNView *_scnView;
@property (retain, nonatomic, readonly, nullable) SCNView *_scnViewIfLoaded;
@property (retain, nonatomic, readonly) UIBarButtonItem *_doneBarButtonItem;
@property (retain, nonatomic, readonly) UIBarButtonItem *_showCameraBarButtonItem;
@property (assign, nonatomic, setter=_setShowCamera:) BOOL _showCamera;
@end

@implementation ImageVision3DViewController
@synthesize _scnView = __scnView;
@synthesize _doneBarButtonItem = __doneBarButtonItem;
@synthesize _showCameraBarButtonItem = __showCameraBarButtonItem;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self _commonInit];
    }
    
    return self;
}

- (void)dealloc {
    [_descriptor release];
    [__scnView release];
    [__doneBarButtonItem release];
    [__showCameraBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self._scnView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItem = self._doneBarButtonItem;
    navigationItem.leftBarButtonItem = self._showCameraBarButtonItem;
    
    [self _updateShowCameraBarButtonItem];
    
    if (ImageVision3DDescriptor *descriptor = self.descriptor) {
        self._scnView.scene = [self _sceneFromDescriptor:descriptor showCamera:self._showCamera];
    }
}

- (void)setDescriptor:(ImageVision3DDescriptor *)descriptor {
    [_descriptor release];
    _descriptor = [descriptor retain];
    
    if (SCNView *scnView = self._scnViewIfLoaded) {
        if (descriptor == nil) {
            scnView.scene = nil;
        } else {
            scnView.scene = [self _sceneFromDescriptor:descriptor showCamera:self._showCamera];
        }
    }
    
    if (VNHumanBodyPose3DObservation *observation = descriptor.humanBodyPose3DObservations.firstObject) {
        NSString *heightEstimationString = NSStringFromVNHumanBodyPose3DObservationHeightEstimation(observation.heightEstimation);
        
        NSMeasurement *bodyHeight = [[NSMeasurement alloc] initWithDoubleValue:observation.bodyHeight unit:[NSUnitLength meters]];
        NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
        formatter.unitOptions = NSMeasurementFormatterUnitOptionsProvidedUnit;
        formatter.unitStyle = NSFormattingUnitStyleLong;
        NSString *bodyHeightString = [formatter stringFromMeasurement:bodyHeight];
        [bodyHeight release];
        [formatter release];
        
        self.navigationItem.title = [NSString stringWithFormat:@"heightEstimation: %@ | bodyHeight: %@", heightEstimationString, bodyHeightString];
    } else {
        self.navigationItem.title = nil;
    }
}

- (void)_commonInit {
    __showCamera = NO;
}

- (void)_setShowCamera:(BOOL)showCamera {
    __showCamera = showCamera;
    [self _updateShowCameraBarButtonItem];
    
    if (SCNView *scnView = self._scnViewIfLoaded) {
        if (ImageVision3DDescriptor *descriptor = self.descriptor) {
            scnView.scene = [self _sceneFromDescriptor:descriptor showCamera:showCamera];
        }
    }
}

- (SCNView *)_scnViewIfLoaded {
    return __scnView;
}

- (SCNView *)_scnView {
    if (auto scnView = __scnView) return scnView;
    
    SCNView *scnView = [[SCNView alloc] initWithFrame:CGRectNull options:@{
        SCNPreferredDeviceKey: @(YES),
        SCNPreferredRenderingAPIKey: @(SCNRenderingAPIMetal)
    }];
    
    scnView.showsStatistics = YES;
    scnView.autoenablesDefaultLighting = YES;
    scnView.allowsCameraControl = YES;
    
    __scnView = [scnView retain];
    return [scnView autorelease];
}

- (UIBarButtonItem *)_doneBarButtonItem {
    if (auto doneBarButtonItem = __doneBarButtonItem) return doneBarButtonItem;
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_didTriggerDoneBarButtonItem:)];
    
    __doneBarButtonItem = [doneBarButtonItem retain];
    return [doneBarButtonItem autorelease];
}

- (UIBarButtonItem *)_showCameraBarButtonItem {
    if (auto showCameraBarButtonItem = __showCameraBarButtonItem) return showCameraBarButtonItem;
    
    UIBarButtonItem *showCameraBarButtonItem = [[UIBarButtonItem alloc] initWithImage:nil style:UIBarButtonItemStylePlain target:self action:@selector(_didTriggerShowCameraBarButtonItem:)];
    
    __showCameraBarButtonItem = [showCameraBarButtonItem retain];
    return [showCameraBarButtonItem autorelease];
}

- (void)_didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_didTriggerShowCameraBarButtonItem:(UIBarButtonItem *)sender {
    self._showCamera = !self._showCamera;
}

- (void)_updateShowCameraBarButtonItem {
    UIImage *image = [UIImage systemImageNamed:self._showCamera ? @"camera.fill" : @"camera"];
    self._showCameraBarButtonItem.image = image;
}

- (SCNScene *)_sceneFromDescriptor:(ImageVision3DDescriptor *)descriptor showCamera:(BOOL)showCamera {
    SCNScene *scene = [SCNScene new];
    
    UIImage *image = descriptor.image;
    assert(image != nil);
    VNHumanBodyPose3DObservation *observation = descriptor.humanBodyPose3DObservations.firstObject;
    assert(observation != nil);
    
    //
    
    NSMutableDictionary<VNHumanBodyPose3DObservationJointName, SCNNode *> *nodesByJointName = [NSMutableDictionary new];
    
    for (VNHumanBodyPose3DObservationJointName jointName in observation.availableJointNames) {
        NSError * _Nullable error = nil;
        VNHumanBodyRecognizedPoint3D *point = [observation recognizedPointForJointName:jointName error:&error];
        assert(error == nil);
        
        simd::float3 pointFloat3 = simd::make_float3(point.position.columns[3][0], point.position.columns[3][1], point.position.columns[3][2]);
        
        SCNGeometry *geometry = [SCNBox boxWithWidth:0.05 height:0.05 length:0.05 chamferRadius:0.05];
        SCNNode *jointNode = [SCNNode nodeWithGeometry:geometry];
        jointNode.simdPosition = pointFloat3;
        
        nodesByJointName[jointName] = jointNode;
    }
    
    //
    
    /*
     Joint의 좌표계와 Image의 좌표계가 다르다. Image 좌표계를 Joint에 맞게 Scale하기 위해
     1. 무작위 2개 Joint를 선별한다.
     2. Joint 좌표계에서 두 Joint의 거리를 구한다.
     3. Image 좌표계에서 두 Joint의 거리를 구한다.
     4. Scale = Joint / Image를 통해 Image 좌표계에 곱해준다.
     
     5. Root Joint의 위치로 Image를 이동
     */
    float imageScaleFromJoint;
    {
        NSArray<VNHumanBodyPose3DObservationJointName> *jointNames = nodesByJointName.allKeys;
        assert(jointNames.count >= 2);
        VNHumanBodyPose3DObservationJointName firstJointName = jointNames[0];
        assert(firstJointName != nil);
        VNHumanBodyPose3DObservationJointName secondJointName = jointNames[1];
        assert(secondJointName != nil);
        SCNNode *firstJointNode = nodesByJointName[firstJointName];
        assert(firstJointNode != nil);
        SCNNode *secondJointNode = nodesByJointName[secondJointName];
        assert(secondJointNode != nil);
        
        float distanceInJoint = simd::distance(firstJointNode.simdPosition, secondJointNode.simdPosition);
        
        NSError * _Nullable error = nil;
        VNPoint *pointInImageForFirstJoint = [observation pointInImageForJointName:firstJointName error:&error];
        assert(error == nil);
        VNPoint *pointInImageForSecondJoint = [observation pointInImageForJointName:secondJointName error:&error];
        assert(error == nil);
        
        float distanceInImage = simd::distance(simd::make_float2(pointInImageForFirstJoint.x, pointInImageForFirstJoint.y),
                                               simd::make_float2(pointInImageForSecondJoint.x, pointInImageForSecondJoint.y));
        
        imageScaleFromJoint = distanceInJoint / distanceInImage;
    }
    
    //
    
    CGFloat aspectRatioW = image.size.width / image.size.height;
    SCNPlane *imagePlane = [SCNPlane planeWithWidth:imageScaleFromJoint * aspectRatioW height:imageScaleFromJoint];
    SCNNode *imageNode = [SCNNode nodeWithGeometry:imagePlane];
    imageNode.position = SCNVector3Zero;
    
    UIImage *orientedImage = reinterpret_cast<id (*)(Class, SEL, id, UIImageOrientation)>(objc_msgSend)([UIImage class], sel_registerName("vk_orientedImageFromImage:fromOrientation:"), image, image.imageOrientation);
    imagePlane.firstMaterial.diffuse.contents = orientedImage;
    imagePlane.firstMaterial.doubleSided = YES;
    
    imageNode.opacity = 0.85;
    
    simd::float4x4 cameraOriginMatrix = observation.cameraOriginMatrix;
    cameraOriginMatrix.columns[3] = simd::make_float4(0.f, 0.f, 0.f, 1.f);
    imageNode.simdTransform = simd::inverse(cameraOriginMatrix);
    
    [scene.rootNode addChildNode:imageNode];
    
    //
    
    {
        NSError * _Nullable error = nil;
        VNPoint *point = [observation pointInImageForJointName:VNHumanBodyPose3DObservationJointNameRoot error:&error];
        assert(error == nil);
        
        /*
         point는 좌측 하단을 원점으로 가지고 0.0 부터 1.0 사이의 Image 좌표계다. 따라서 width를 곱해주고, 원점을 중심으로 이동시켜주면 imagePlan 상에서 좌표계가 된다.
         */
        CGFloat x = (point.x * imagePlane.width) - imagePlane.width * 0.5;
        CGFloat y = (point.y * imagePlane.height) - imagePlane.height * 0.5;
        
        simd::float3 simdPosition = imageNode.simdPosition;
        simdPosition.x -= x;
        simdPosition.y -= y;
        
        imageNode.simdPosition = simdPosition;
    }
    
    //
    
    if (showCamera) {
        SCNCamera *camera = [SCNCamera new];
        SCNNode *cameraNode = [SCNNode new];
        cameraNode.camera = camera;
        [camera release];
        cameraNode.simdPivot = observation.cameraOriginMatrix;
        
        [scene.rootNode addChildNode:cameraNode];
        [cameraNode release];
    } else {
        SCNPyramid *cameraPyramidGeometry = [SCNPyramid pyramidWithWidth:0.25 height:0.25 length:0.25];
        SCNNode *originCameraNode = [SCNNode nodeWithGeometry:cameraPyramidGeometry];
        originCameraNode.simdPosition = simd::make_float3(0.f, 0.f, 0.f);
        originCameraNode.opacity = 0.6;
        originCameraNode.geometry.firstMaterial.diffuse.contents = UIColor.cyanColor;
        
        constexpr float degree = -std::numbers::pi * 0.5f;
        simd::float4x4 rotX90 = simd::float4x4(simd::make_float4(1.f, 0.f, 0.f, 0.f),
                                               simd::make_float4(0.f, std::cos(degree), std::sin(degree), 0.f),
                                               simd::make_float4(0.f, -std::sin(degree), std::cos(degree), 0.f),
                                               simd::make_float4(0.f, 0.f, 0.f, 1.f));
        
        originCameraNode.simdPivot = simd_mul(rotX90, observation.cameraOriginMatrix);
        [scene.rootNode addChildNode:originCameraNode];
    }
    
    //
    
    {
        SCNNode *bodyAnchorNode = [SCNNode new];
        bodyAnchorNode.position = SCNVector3Zero;
        [scene.rootNode addChildNode:bodyAnchorNode];
        
        for (SCNNode *jointNode in nodesByJointName.allValues) {
            [bodyAnchorNode addChildNode:jointNode];
        }
        
        [bodyAnchorNode release];
    }
    
    //
    
    {
        SCNNode *topHeadNode = nodesByJointName[VNHumanBodyPose3DObservationJointNameTopHead];
        SCNNode *centerHeadNode = nodesByJointName[VNHumanBodyPose3DObservationJointNameCenterHead];
        SCNNode *centerShoulderNode = nodesByJointName[VNHumanBodyPose3DObservationJointNameCenterShoulder];
        
        if (topHeadNode != nil and centerHeadNode != nil and centerShoulderNode != nil) {
            CGFloat headHeight = topHeadNode.position.y - centerShoulderNode.position.y;
            
            centerHeadNode.geometry = [SCNBox boxWithWidth:0.2
                                                    height:headHeight
                                                    length:0.2
                                             chamferRadius:0.4];
            
            centerHeadNode.geometry.firstMaterial.diffuse.contents = UIColor.greenColor;
            topHeadNode.hidden = YES;
        }
    }
    
    //
    
    {
        NSArray<VNHumanBodyPose3DObservationJointName> *jointOrderArray = @[
            VNHumanBodyPose3DObservationJointNameLeftWrist,
            VNHumanBodyPose3DObservationJointNameLeftElbow,
            VNHumanBodyPose3DObservationJointNameLeftShoulder,
            VNHumanBodyPose3DObservationJointNameRightWrist,
            VNHumanBodyPose3DObservationJointNameRightElbow,
            VNHumanBodyPose3DObservationJointNameRightShoulder,
            VNHumanBodyPose3DObservationJointNameCenterShoulder,
            VNHumanBodyPose3DObservationJointNameSpine,
            VNHumanBodyPose3DObservationJointNameRightAnkle,
            VNHumanBodyPose3DObservationJointNameRightKnee,
            VNHumanBodyPose3DObservationJointNameRightHip,
            VNHumanBodyPose3DObservationJointNameLeftAnkle,
            VNHumanBodyPose3DObservationJointNameLeftKnee,
            VNHumanBodyPose3DObservationJointNameLeftHip
        ];
        
        for (VNHumanBodyPose3DObservationJointName jointName in jointOrderArray) {
            SCNNode *jointNode = nodesByJointName[jointName];
            if (jointName == nil) continue;
            VNHumanBodyPose3DObservationJointName parentJointName = [observation parentJointNameForJointName:jointName];
            if (parentJointName == nil) continue;
            SCNNode *parentJointNode = nodesByJointName[parentJointName];
            if (parentJointNode == nil) continue;
            
            float length = std::fmaxf(simd_length(parentJointNode.simdPosition - jointNode.simdPosition), 1E-5f);
            
            SCNBox *boxGeometry = [SCNBox boxWithWidth:0.05
                                                height:length
                                                length:0.05
                                         chamferRadius:0.05];
            
            jointNode.geometry = boxGeometry;
            jointNode.geometry.firstMaterial.diffuse.contents = UIColor.greenColor;
            jointNode.simdPosition = (parentJointNode.simdPosition + jointNode.simdPosition) * 0.5f;
            
            //
            
            NSError * _Nullable error = nil;
            VNHumanBodyRecognizedPoint3D *recognizedPoint = [observation recognizedPointForJointName:jointName error:&error];
            assert(error == nil);
            simd::float4x4 localPotision = recognizedPoint.localPosition;
            simd::float3 translationC = simd::make_float3(localPotision.columns[3][0], localPotision.columns[3][1], localPotision.columns[3][2]);
            float pitch = std::numbers::pi * 0.5f;
            float yaw = std::acos(translationC.z / simd::length(translationC));
            float roll = std::atan2(translationC.y, translationC.x);
            jointNode.simdEulerAngles = simd::make_float3(pitch, yaw, roll);
        }
    }
    
    //
    
    [nodesByJointName release];
    return [scene autorelease];
}

@end
