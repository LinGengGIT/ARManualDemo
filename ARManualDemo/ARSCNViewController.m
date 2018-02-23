//
//  ARSCNViewController.m
//  ARManualDemo
//
//  Created by lingeng on 2017/10/27.
//  Copyright © 2017年 Lingeng. All rights reserved.
//
//3D游戏框架
//#import <SceneKit/SceneKit.h>
//ARKit框架
//#import <ARKit/ARKit.h>
//#import <ARKit/ARConfiguration.h>

#import "ARSCNViewController.h"
#import "BTSceneView.h"
#import <ARKit/ARKit.h>

@import ARVideoKit;

@interface ARSCNViewController ()<ARSessionDelegate,ArViewDelegate>{
    CIContext *ctx;
    CGImageRef* cgImage;
}

@property (strong, nonatomic) IBOutlet UIButton *btnBack;
@property (strong, nonatomic) IBOutlet UIButton *btnDraw;
@property (strong, nonatomic) IBOutlet UIButton *btnRecord;
@property (strong, nonatomic) IBOutlet UIButton *btnStop;

@property (strong, nonatomic) IBOutlet UIView *arContainer;
@property(nonatomic,strong) BTSceneView *arScnView;
@property(nonatomic,strong) ARSession *arSession;
@property(nonatomic,strong) ARConfiguration *arConfiguration;
@property(nonatomic,strong) SCNNode *planeNode;
//test
@property(nonatomic,strong) CIFilter* filter;

@end

@implementation ARSCNViewController

#pragma  mark - vc生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self initARView:self.open3DARview];
    
}



-(void)viewWillDisappear:(BOOL)animated{
//    [self.arScnView resetRecorder];
}


/**
 初始化arview
 @param open3Dview yes:打开sceneView no:打开spiritView
 */
-(void)initARView:(BOOL)open3Dview{
    if (open3Dview) {
        self.arScnView = [[BTSceneView alloc]initARWithFrame:self.arContainer.bounds];
        self.arScnView.arViewDelegate = self;
        [self.arContainer addSubview:self.arScnView];
    }
}

#pragma mark- 点击屏幕添加节点
- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnDrawClicked:(id)sender {
    self.arScnView.isDrawing = !self.arScnView.isDrawing;

}

- (IBAction)btnRecordClicked:(id)sender {
    
    [self.arScnView startRecordARVideo];
    
}

- (IBAction)btnStopClicked:(id)sender {
    [self.arScnView stopRecordARVideo];
}

#pragma mark - 设置按钮显示
-(void)setBtnsShow:(BOOL)show{
    self.btnDraw.hidden = !show;
    self.btnStop.hidden = !show;
    self.btnRecord.hidden = !show;
    self.btnBack.hidden = !show;
}

#pragma mark - arViewDelegate接口实现
-(void)onStartDrawing{
    [self setBtnsShow:NO];
}
-(void)onStopDrawing{
    [self setBtnsShow:YES];
}

@end
