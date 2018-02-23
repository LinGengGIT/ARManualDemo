//
//  MyARSceneView.m
//  ARManualDemo
//
//  Created by lingeng on 2018/2/7.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#import "MyARSceneView.h"
@import ARVideoKit;
@interface MyARSceneView(){
    SCNVector3 curPos;
    SCNVector3 prevPos;
    RecordAR *recorder;
}
@end
@implementation MyARSceneView

-(instancetype)init{
    self= [super init];
    if (self) {
        [self initRecorder];
    }
    return self;
}

-(void)initRecorder{
//    recorder 
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSSet *allTouches = [event allTouches];
    
    UITouch *touch = [allTouches anyObject];
    CGPoint point = [touch locationInView:self];
    
    SCNVector3 pointIn3D = [self convertToSceneOfPoint:point];
    SCNNode *pointOfView = self.pointOfView;
    SCNMatrix4 transMatrix = pointOfView.transform;
    SCNVector3 dir = SCNVector3Make(-1*transMatrix.m31, -1*transMatrix.m32, -1*transMatrix.m33);
    
    
    prevPos = [self add:pointOfView.position and:[self add:pointIn3D and:[self multiplicate:dir and:0.1]]];
    
    NSLog(@"");

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
    
}

#pragma mark - 划线相关函数

-(SCNGeometry*)lineFrom:(SCNVector3) vector1 to:(SCNVector3)vector2{
    SCNVector3 array[2] = {vector1,vector2};
    
    SCNGeometrySource *source = [SCNGeometrySource  geometrySourceWithVertices:array count:2];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:2 bytesPerIndex:1];
    NSArray *sources = [NSArray arrayWithObject:source];
    NSArray *elements = [NSArray arrayWithObject:element];
    
    return [SCNGeometry geometryWithSources:sources elements:elements];
}


#pragma mark - 一些绘画需要的函数
-(SCNVector3)add:(SCNVector3)v1 and:(SCNVector3)v2{
    return SCNVector3Make(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

-(SCNVector3)multiplicate:(SCNVector3)vector and:(float)scalar{
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar);
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
//    NSLog(@"lg--->convertPoint X: %f,Y:%f，Z:%f", convertPoint.x, convertPoint.y, convertPoint.z);
    return convertPoint;
    
}
@end
