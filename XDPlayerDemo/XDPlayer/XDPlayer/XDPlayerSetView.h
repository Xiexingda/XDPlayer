//
//  XDPlayerSetView.h
//  XDPlayer
//
//  Created by 谢兴达 on 2016/11/7.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectImageView.h"

@interface XDPlayerSetView : UIView

@property (nonatomic, strong) UIView *contentView;         //控制条容器
@property (nonatomic, strong) UIProgressView *progress;    //缓冲进度条
@property (nonatomic, strong) UISlider * slider;           //进度条
@property (nonatomic, strong) UIButton * stopButton;       //暂停按钮
@property (nonatomic, strong) UILabel * totalTime;         //总时间
@property (nonatomic, strong) UILabel * currentTime;       //当前播放时间
@property (nonatomic, strong) SelectImageView *fullScreen; //全屏按钮

//配置控制条frame 及位置
- (void)frameForControlLine:(CGFloat)length toTopSpace:(CGFloat)topSpace;

@end
