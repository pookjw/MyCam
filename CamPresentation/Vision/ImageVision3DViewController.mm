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

@interface ImageVision3DViewController ()
@property (retain, nonatomic, readonly) SCNView *_scnView;
@property (retain, nonatomic, readonly) UIBarButtonItem *_doneBarButtonItem;
@end

@implementation ImageVision3DViewController
@synthesize _scnView = __scnView;
@synthesize _doneBarButtonItem = __doneBarButtonItem;

- (void)dealloc {
    [_descriptor release];
    [__scnView release];
    [__doneBarButtonItem release];
    [super dealloc];
}

- (void)loadView {
    self.view = self._scnView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.rightBarButtonItem = self._doneBarButtonItem;
}

- (void)setDescriptor:(ImageVision3DDescriptor *)descriptor {
    [_descriptor release];
    _descriptor = [descriptor retain];
    
    self._scnView.scene = [self _sceneFromDescriptor:descriptor];
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

- (void)_didTriggerDoneBarButtonItem:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (SCNScene *)_sceneFromDescriptor:(ImageVision3DDescriptor *)descriptor {
    SCNScene *scene = [SCNScene new];
    
    UIImage *image = descriptor.image;
    assert(image != nil);
    VNHumanBodyPose3DObservation *observation = descriptor.humanBodyPose3DObservations.firstObject;
    assert(observation != nil);
    
    //
    
    CGFloat aspectRatioW = image.size.width / image.size.height;
    SCNPlane *imagePlane = [SCNPlane planeWithWidth:1.8 * aspectRatioW height:1.8];
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
    
    
    
    [nodesByJointName release];
    
    //
    
    return [scene autorelease];
}

@end
