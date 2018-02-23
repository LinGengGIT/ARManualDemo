//
//  BTSceneView.h
//  ARManualDemo
//
//  Created by lingeng on 2018/2/2.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#import <ARKit/ARKit.h>
#import "CameraOperationDelegate.h"
#import <SceneKit/SceneKit.h>
#import <ARKit/ARConfiguration.h>
#import "ArViewDelegate.h"
//@import ARVideoKit;

typedef NS_ENUM(NSInteger, WZRecordStatus)  {
    WZRecordStatusIdle,
    WZRecordStatusRecording,
    WZRecordStatusFinish,
    
};

@interface BTSceneView : ARSCNView <CameraOperationDelegate,ARSCNViewDelegate,ARSessionDelegate>
{
//    RecordAR *recorder;
}
@property (nonatomic,strong) id <ArViewDelegate> arViewDelegate;
@property (nonatomic, retain)   CIContext         *ciContext;
@property (nonatomic,assign)   CGColorSpaceRef   colorSpace;
@property (nonatomic, retain) CIFilter     *filter;
@property (nonatomic,assign) BOOL isDrawing;
-(instancetype)initARWithFrame:(CGRect)frame;
-(ARWorldTrackingConfiguration*)getConfiguration;
-(void)resetRecorder;
@end
