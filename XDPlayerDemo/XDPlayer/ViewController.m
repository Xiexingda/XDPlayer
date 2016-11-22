//
//  ViewController.m
//  XDPlayer
//
//  Created by 谢兴达 on 2016/11/21.
//  Copyright © 2016年 谢兴达. All rights reserved.
//

#import "ViewController.h"
#import "XDPlayerContorller.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *playbt = [UIButton buttonWithType:UIButtonTypeCustom];
    playbt.backgroundColor = [UIColor redColor];
    [playbt setTitle:@"播放" forState:UIControlStateNormal];
    [playbt setFrame:CGRectMake(0, 150, self.view.frame.size.width, 60)];
    [playbt addTarget:self action:@selector(playXDPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playbt];
   
}

- (void)playXDPlay {
    /*
     不要忘了iOS10 的info适配
     
     */
    //http://xddfile.jiejiegao.com/2/ali/v/67a592258f61491cb779dac41b15873f.mp4 竖屏
    //http://v.jxvdy.com/sendfile/w5bgP3A8JgiQQo5l0hvoNGE2H16WbN09X-ONHPq3P3C1BISgf7C-qVs6_c8oaw3zKScO78I--b0BGFBRxlpw13sf2e54QA  横屏
    
    XDPlayerContorller *root = [[XDPlayerContorller alloc]init];
    //测试网址 （使用时把该网址换成 自己的）
    root.urlStr = @"http://xddfile.jiejiegao.com/2/ali/v/67a592258f61491cb779dac41b15873f.mp4";
    [self.navigationController pushViewController:root animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
