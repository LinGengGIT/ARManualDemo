//
//  SecondARViewController.m
//  ARManualDemo
//
//  Created by lingeng on 2018/2/5.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#import "SecondARViewController.h"
#import <ARKit/ARKit.h>
#import "math.h"
#import "MyARSceneView.h"
@import ARVideoKit;
@interface SecondARViewController ()<ARSessionDelegate,ARSCNViewDelegate,ARSKViewDelegate>{
    RecordAR *recorder;
    
}
@property (strong, nonatomic) IBOutlet UIView *arContainer;
@property (strong, nonatomic) IBOutlet UIButton *btnRecord;
@property (strong, nonatomic) IBOutlet UIButton *btnBack;
@property (strong, nonatomic) IBOutlet UIButton *btnPause;
@property (strong, nonatomic) IBOutlet UIButton *btnStop;
@property (nonatomic,assign) BOOL isDrawing;
@property(nonatomic,strong) MyARSceneView *arScnView;//三维
@property(nonatomic,strong) ARSKView *arSkView;//二维
@property(nonatomic,strong) CIFilter *filter;
@property(nonatomic,strong) CIContext *ctx;
@property(nonatomic,strong) EAGLContext* myEAGLContext;

@end

@implementation SecondARViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.is3D) {
        [self initScnView];
    }else{
        [self initSkView];
    }
    
   
}

-(void)initScnView{
    self.arScnView = [[MyARSceneView alloc]init];
    self.arScnView.frame = self.arContainer.bounds;
    self.arScnView.delegate = self;
    self.arScnView.session.delegate = self;
    self.arScnView.scene = [SCNScene sceneNamed:@"art.scnassets/world.scn"];
    self.arScnView.showsStatistics = YES;
    [self.arContainer addSubview:self.arScnView];
    
    recorder = [[RecordAR alloc]initWithARSceneKit:self.arScnView];
}

-(void)initSkView{
    self.arSkView = [[ARSKView alloc]init];
    self.arSkView.frame = self.arContainer.bounds;
    self.arSkView.delegate = self;
    self.arSkView.session.delegate = self;
    
    self.arSkView.showsFPS = YES;
    [self.arContainer addSubview:self.arSkView];
    recorder = [[RecordAR alloc]initWithARSpriteKit:self.arSkView];
}


-(void)viewDidAppear:(BOOL)animated{
   
}

-(void)viewWillAppear:(BOOL)animated{
    ARWorldTrackingConfiguration *config = [[ARWorldTrackingConfiguration alloc]init];
    
    if (self.is3D) {
        [self.arScnView.session runWithConfiguration:config];
        self.arScnView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    }else{
        [self.arSkView.session runWithConfiguration:config ];
    }
    [recorder prepare:config];
    
}


-(void)viewWillDisappear:(BOOL)animated{
    [self.arScnView.session pause];
    [self.arSkView.session pause];
    [recorder rest];
}


-(void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time{
    
}



#pragma mark - ARSessionDelegate 加滤镜
-(void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame{
    //展示锚点
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (frame.rawFeaturePoints&& frame.rawFeaturePoints.count>0) {
//            for( int i = 0;i<frame.rawFeaturePoints.count;i++) {
//          vector_float3 point = frame.rawFeaturePoints.points[i] ;
//              SCNVector3 startPoint = self.arScnView.pointOfView.position;
//                float r = sqrtf(pow(point.x-startPoint.x,2)+pow(point.y-startPoint.y, 2)+pow(point.z-startPoint.z, 2) );
//                NSLog(@"lg--->锚点间距离：%f",r);
//            }
//        }
//    });
    
    //滤镜
    CIImage *image = [CIImage imageWithCVPixelBuffer:frame.capturedImage];
    if (!self.ctx) {
        NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null]};
        self.myEAGLContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.ctx = [CIContext contextWithEAGLContext:self.myEAGLContext options:options];
    }
    
    if (!self.filter) {
        self.filter = [CIFilter filterWithName:@"CIColorInvert"];
    }
    
    [self.filter setValue:image forKey:kCIInputImageKey];
    
    CIImage *result = self.filter.outputImage;
    CGImageRef cgImage = [self.ctx createCGImage:result fromRect:result.extent];
    if (cgImage) {
        self.arScnView.scene.background.contents = cgImage;
        self.arScnView.scene.background.contentsTransform = [self currentScreenTransform];
    }
    
    CFRelease(cgImage);
    
    
    
    
}


/**
 屏幕方向检测
 */
-(SCNMatrix4)currentScreenTransform{
    switch (UIDevice.currentDevice.orientation) {
        case UIDeviceOrientationLandscapeLeft:
            return SCNMatrix4Identity;
            break;
        case UIDeviceOrientationLandscapeRight:
            return SCNMatrix4MakeRotation(M_PI, 0, 0,  1);
            break;
        case UIDeviceOrientationPortrait:
            return SCNMatrix4MakeRotation(M_PI/2, 0, 0, 1);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            return SCNMatrix4MakeRotation(-M_PI/2, 0, 0, 1);
        default:
            return SCNMatrix4Identity;
            
    }
    
    
}





#pragma mark - 手势监听
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self setBtnsShow:NO];

    
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSSet *allTouches = [event allTouches];
    if([allTouches count] == 1){
        UITouch *touch = [allTouches anyObject];
        CGPoint point = [touch locationInView:self.arContainer];
        NSLog(@"lg--->VC中 2d: x = %f, y = %f ",point.x,point.y);
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self setBtnsShow:YES];
}

-(void)setBtnsShow:(BOOL)show{
    self.btnPause.hidden = !show;
    self.btnStop.hidden = !show;
    self.btnRecord.hidden = !show;
    self.btnBack.hidden = !show;
}


#pragma mark - 录制视频
- (IBAction)stopRecord:(id)sender {
    if (recorder.status == RecordARStatusRecording) {
        [recorder stopAndExport:NULL];
    }
}
- (IBAction)pauseRecord:(id)sender {
    if (recorder.status == RecordARStatusRecording) {
        [recorder pause];
        [self.btnPause setTitle:@"resume" forState:UIControlStateNormal];
    }
    if (recorder.status == RecordARStatusPaused) {
        [recorder record];
        [self.btnPause setTitle:@"pause" forState:UIControlStateNormal];
    }
    
}

- (IBAction)startRecord:(id)sender {
    if (recorder.status == RecordARStatusReadyToRecord) {
        [recorder record];
    }
}

- (IBAction)backClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"lg--->memory warning!!!");
    
}
@end
