//
//  CameraOperationDelegate.h
//  ARManualDemo
//
//  Created by lingeng on 2018/2/2.
//  Copyright © 2018年 Lingeng. All rights reserved.
//

#ifndef CameraOperationDelegate_h
#define CameraOperationDelegate_h


#endif /* CameraOperationDelegate_h */

@protocol CameraOperationDelegate <NSObject>

@optional
-(void)captureARPhoto;
-(void)startRecordARVideo;
-(void)pauseRecordARVideo;
-(void)continueRecordARVideo;
-(void)stopRecordARVideo;

@end
