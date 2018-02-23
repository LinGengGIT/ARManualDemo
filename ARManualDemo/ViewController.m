//
//  ViewController.m
//  ARManualDemo
//
//  Created by lingeng on 2017/10/27.
//  Copyright © 2017年 Lingeng. All rights reserved.
//

#import "ViewController.h"
#import "ARSCNViewController.h"
#import "SecondARViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startArBtn;
- (IBAction)goArView:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)goArView:(id)sender {
    
//    ARSCNViewController *vc = [[ARSCNViewController alloc]init];
//    vc.open3DARview = YES;
    
    SecondARViewController *vc = [[SecondARViewController alloc]init];
    vc.is3D = YES;
    [self presentViewController:vc animated:YES completion:nil];
    }
@end
