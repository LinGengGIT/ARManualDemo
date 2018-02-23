//
//  BTSceneView.m
//  ARManualDemo
//
//  Created by lingeng on 2018/2/2.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#import "BTSceneView.h"

#import <OpenGLES/EAGL.h>




@interface BTSceneView(){
    SCNVector3 curPos;
    SCNVector3 prevPos;
    NSMutableDictionary *options;
}
@property (nonatomic,strong)    CIContext *ctx;
@property (nonatomic,strong)    EAGLContext *myEAGLContext;
//视频录制相关
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic, strong) SCNRenderer *renderer;
@property (nonatomic, assign) WZRecordStatus status;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, copy) NSString *outputPath;
@property (nonatomic, assign) CGSize outputSize;
@property (nonatomic, assign) int count;



@end


@implementation BTSceneView



-(instancetype)initARWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    //todo --builder模式自定义构造arview
    self.delegate = self;
    self.session.delegate = self;
    self.scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    
    //初始化视频录制的变量
    self.renderer = [SCNRenderer rendererWithDevice:nil options:nil];
    self.renderer.scene = self.scene;
    
    self.videoQueue = dispatch_queue_create("com.worthy.video.queue", NULL);
    self.outputSize = CGSizeMake(720, 1280);
    return self;
}

-(void)layoutSubviews{
    ARWorldTrackingConfiguration *config = [[ARWorldTrackingConfiguration alloc]init];
 
    config.planeDetection = ARPlaneDetectionHorizontal;
    [self.session runWithConfiguration:config];

    //视频录制
//    recorder = [[RecordAR alloc]initWithARSceneKit:self];
//    [recorder prepare:config];

}



#pragma mark - 视频录制
-(void)captureARPhoto{
}

-(void)startRecordARVideo{
    //方式1：集成录制framework
//    if (recorder.status == RecordARStatusReadyToRecord) {
//        [recorder record];
//    }
    
    
    //方式2：自己实现
    [self startRecording];
}

-(void)pauseRecordARVideo{
//    if (recorder.status == RecordARStatusRecording) {
//        [recorder pause];
//    }
}

-(void)continueRecordARVideo{
//    if (recorder.status == RecordARStatusPaused) {
//        [recorder record];
//    }
}

-(void)stopRecordARVideo{
//    if (recorder.status == RecordARStatusRecording) {
//        [recorder stopAndExport:NULL];
//    }
    
    [self finishRecording];
}


/**
 VC的viewWillDisappear中调用 重置录制
 */
//-(void) resetRecorder{
//    [recorder rest];
//}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSSet *allTouches = [event allTouches];
    
    UITouch *touch = [allTouches anyObject];
    CGPoint point = [touch locationInView:self];
    
    
    SCNVector3 pointIn3D = [self convertToSceneOfPoint:point];
    SCNNode *pointOfView = self.pointOfView;
    SCNMatrix4 transMatrix = pointOfView.transform;
    SCNVector3 dir = SCNVector3Make(-1*transMatrix.m31, -1*transMatrix.m32, -1*transMatrix.m33);
    
    prevPos = [self add:pointOfView.position and:[self add:pointIn3D and:[self multiplicate:dir and:0.1]]];
    
    if (self.arViewDelegate && [self.arViewDelegate respondsToSelector:@selector(onStartDrawing)]) {
        [self.arViewDelegate onStartDrawing];
    }
}



-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSSet *allTouches = [event allTouches];
    
    UITouch *touch = [allTouches anyObject];
    CGPoint point = [touch locationInView:self];
    
    SCNVector3 pointIn3D = [self convertToSceneOfPoint:point];
    SCNNode *pointOfView = self.pointOfView;
    SCNMatrix4 transMatrix = pointOfView.transform;
    SCNVector3 dir = SCNVector3Make(-1*transMatrix.m31, -1*transMatrix.m32, -1*transMatrix.m33);

    curPos =  [self add:pointOfView.position and:[self add:pointIn3D and:[self multiplicate:dir and:0.1]]];
    
    SCNGeometry *line = [self lineFrom:prevPos to:curPos];
    SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
    lineNode.geometry.firstMaterial.diffuse.contents = [UIColor whiteColor];
    [self.scene.rootNode addChildNode:lineNode];
    
    prevPos = curPos;
    
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(self.arViewDelegate && [self.arViewDelegate respondsToSelector:@selector(onStopDrawing)]){
        [self.arViewDelegate onStopDrawing];
    }
    
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(self.arViewDelegate && [self.arViewDelegate respondsToSelector:@selector(onStopDrawing)]){
        [self.arViewDelegate onStopDrawing];
    }
}

#pragma mark - AR视图刷新
-(void)renderer:(id<SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time{
    if (!self.isDrawing||!self.pointOfView) {
        return;
    }
    SCNMatrix4 mat = self.pointOfView.transform ;
    SCNVector3 dir = SCNVector3Make(-1*mat.m31,  -1 * mat.m32, -1 * mat.m33);
    curPos = [self add:self.pointOfView.position and:[self multiplicate:dir and:0.1]];
    

    SCNGeometry *line = [self lineFrom:prevPos to:curPos];

    SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
    lineNode.geometry.firstMaterial.diffuse.contents = [UIColor whiteColor];
    [self.scene.rootNode addChildNode:lineNode];
    prevPos = curPos;
    
}


#pragma mark -ARSessionDelegate
-(void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame{
    //必须在主线程中执行以下代码
    dispatch_async(dispatch_get_main_queue(), ^{
        //滤镜处理
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
        CIImage *result = [self.filter outputImage];
        
        CGImageRef cgImage = [self.ctx createCGImage:result fromRect:[result extent]];
        
        if (cgImage) {
            self.scene.background.contents = cgImage;
            self.scene.background.contentsTransform = [self currentScreenTransform];
        }
        //创建cgImage后必须要释放掉
        CGImageRelease(cgImage);
    });
    
    
    //----视频录制----
    if (self.status == WZRecordStatusRecording) {
        dispatch_async(self.videoQueue, ^{
            @autoreleasepool {
                if (self.count % 2 == 0) {
                    CVPixelBufferRef pixelBuffer = [self capturePixelBuffer];
                    if (pixelBuffer) {
                        @try {
                            [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(self.count/2*1000, 30*1000)];
                        }@catch (NSException *exception) {
                            NSLog(@"%@",exception.reason);
                        }@finally {
                            CFRelease(pixelBuffer);
                        }
                    }
                }
                self.count++;
            }
        });
    }else if (self.status == WZRecordStatusFinish) {
        self.status = WZRecordStatusIdle;
        self.count = 0;
        [self.videoInput markAsFinished];
        [self.writer finishWritingWithCompletionHandler:^{
            UISaveVideoAtPathToSavedPhotosAlbum(self.outputPath, nil, nil, nil);
            NSLog(@"record finish, saved to alblum.");
        }];
    }
    
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




#pragma mark - 一些绘画需要的函数
-(SCNVector3)add:(SCNVector3)v1 and:(SCNVector3)v2{
    return SCNVector3Make(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

-(SCNVector3)multiplicate:(SCNVector3)vector and:(float)scalar{
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar);
}



-(SCNGeometry*)lineFrom:(SCNVector3) vector1 to:(SCNVector3)vector2{
    SCNVector3 array[2] = {vector1,vector2};
    
    SCNGeometrySource *source = [SCNGeometrySource  geometrySourceWithVertices:array count:2];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:2 bytesPerIndex:1];
    NSArray *sources = [NSArray arrayWithObject:source];
    NSArray *elements = [NSArray arrayWithObject:element];
    
    return [SCNGeometry geometryWithSources:sources elements:elements];
}

#pragma mark - 2D坐标转3D坐标
-(SCNVector3) convertToSceneOfPoint:(CGPoint) point{
    CGFloat Z_Far = 0.1;
    CGFloat Screen_Aspect = [UIScreen mainScreen].bounds.size.width>400?0.3:0.0;
    double Y = tan((double)(self.pointOfView.camera.fieldOfView/180/2)*M_PI) * (double)(Z_Far-Screen_Aspect);
    
    double X = tan((double)(self.pointOfView.camera.fieldOfView/2/180)*M_PI) * (double)(Z_Far-Screen_Aspect) * (double)(self.bounds.size.width/self.bounds.size.height);
    CGFloat alphaX = 2 *  X / self.bounds.size.width;
    CGFloat alphaY = 2 *  Y / self.bounds.size.height;
    float x = -(CGFloat)X + point.x * alphaX;
    float y = (CGFloat)Y - point.y * alphaY;
    SCNVector3 target = SCNVector3Make((float)(x), (float)(y),(float)(-Z_Far));
    SCNVector3 convertPoint = [self.pointOfView convertVector:target toNode:self.scene.rootNode];
    
    return convertPoint;
    
}




#pragma mark - 视频录制

- (void)setupWriter {
    self.outputPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"out.mp4"];
    [[NSFileManager defaultManager] removeItemAtPath:self.outputPath error:nil];
    self.writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.outputPath] fileType:AVFileTypeQuickTimeMovie error:nil];
    self.videoInput = [[AVAssetWriterInput alloc]
                       initWithMediaType:AVMediaTypeVideo outputSettings:
                       @{AVVideoCodecKey:AVVideoCodecTypeH264,
                         AVVideoWidthKey: @(self.outputSize.width),
                         AVVideoHeightKey: @(self.outputSize.height)}];
    [self.writer addInput:self.videoInput];
    self.pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:
                               @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
                                 (id)kCVPixelBufferWidthKey:@(self.outputSize.width),
                                 (id)kCVPixelBufferHeightKey:@(self.outputSize.height)}];
}

- (void)startRecording {
    [self setupWriter];
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    self.status = WZRecordStatusRecording;
}

- (void)finishRecording {
    self.status = WZRecordStatusFinish;
}



-(CVPixelBufferRef)capturePixelBuffer {
    UIImage *image = [self.renderer snapshotAtTime:1 withSize:CGSizeMake(self.outputSize.width, self.outputSize.height) antialiasingMode:SCNAntialiasingModeMultisampling4X];
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer(NULL, [self.pixelBufferAdaptor pixelBufferPool], &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data  = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGContextRef context = CGBitmapContextCreate(data, self.outputSize.width, self.outputSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), CGColorSpaceCreateDeviceRGB(),  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, self.outputSize.width, self.outputSize.height), image.CGImage);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CGContextRelease(context);
    return pixelBuffer;
}

@end
