//
//  MyARSceneView.h
//  ARManualDemo
//
//  Created by lingeng on 2018/2/7.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#import <ARKit/ARKit.h>

@interface MyARSceneView : ARSCNView

-(instancetype)init;
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
@end
