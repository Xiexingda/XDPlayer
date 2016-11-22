//
//  XDPlayerSetView.m
//  XDPlayer
//
//  Created by 谢兴达 on 2016/11/7.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import "XDPlayerSetView.h"

#define KHEIGHT [[UIScreen mainScreen] bounds].size.height
#define KWIDTH  [[UIScreen mainScreen] bounds].size.width

#define KTOTOP        64  //控制框距屏幕顶端的高度
#define KSTOPWIDTH    60  //暂停按钮的宽
#define KCURRENTWIDTH 60  //当前播放时间的宽度
#define KTOTALWIDTH   60  //总时间的宽度
#define KFULLSIZE     40  //全屏按钮大小

@implementation XDPlayerSetView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self creatUI];
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

//配置主UI
- (void)creatUI {
    NSLog(@"宽，%f,高，%f",KWIDTH,KHEIGHT);
    
    //控制条框
    _contentView = [[UIView alloc]init];
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.alpha = 0.7;
    
    
    //暂停按钮
    _stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_stopButton setTitle:@"暂停" forState:UIControlStateNormal];
    [_contentView addSubview:_stopButton];
    
    //缓冲进度条
    _progress = [[UIProgressView alloc]init];
    _progress.trackTintColor = [UIColor lightGrayColor];
    _progress.progressTintColor = [UIColor blueColor];
    _progress.userInteractionEnabled = YES;
    [_contentView addSubview:_progress];
    
    //快进与播放进度条
    _slider = [[UISlider alloc]init];
    _slider.tintColor = [UIColor clearColor];
    _slider.maximumTrackTintColor = [UIColor clearColor];
    _slider.minimumTrackTintColor = [UIColor greenColor];
    [_contentView addSubview:_slider];
    
    //播放时长
    _currentTime = [[UILabel alloc]init];
    _currentTime.font = [UIFont systemFontOfSize:10.0];
    _currentTime.text = @"00:00:00";
    _currentTime.textAlignment = NSTextAlignmentRight;
    [_contentView addSubview:_currentTime];
    
    //总时长
    _totalTime = [[UILabel alloc]init];
    _totalTime.font = [UIFont systemFontOfSize:10.0];
    _totalTime.text = @"/00:00:00";
    [_contentView addSubview:_totalTime];
    
    //全屏按钮
    _fullScreen = [[SelectImageView alloc]init];
    _fullScreen.backgroundColor = [UIColor redColor];
    [_contentView addSubview:_fullScreen];
    
    [self frameForControlLine:KWIDTH toTopSpace:KTOTOP];
    
    [self addSubview:_contentView];
}

// 配置控件的Frame
- (void)frameForControlLine:(CGFloat)length toTopSpace:(CGFloat)topSpace{
    
    //容器frame
    _contentView.frame = CGRectMake(0, topSpace, length, 40);
    
    //暂停按钮frame
    _stopButton.frame = CGRectMake(0, 0, KSTOPWIDTH, 40);
    
    //缓冲进度frame
    _progress.frame = CGRectMake(CGRectGetMaxX(_stopButton.frame) + 5,
                                 20,
                                 length - KSTOPWIDTH - KCURRENTWIDTH - KTOTALWIDTH - KFULLSIZE - 5,
                                 0);
    
    //播放进度frame
    _slider.frame = CGRectMake(CGRectGetMaxX(_stopButton.frame),
                               6,
                               length - KSTOPWIDTH - KCURRENTWIDTH - KTOTALWIDTH - KFULLSIZE,
                               30);
    
    //当前播放时间frame
    _currentTime.frame = CGRectMake(CGRectGetMaxX(_slider.frame), 10, KCURRENTWIDTH, 20);
    
    //总时间frame
    _totalTime.frame = CGRectMake(CGRectGetMaxX(_currentTime.frame), 10, KTOTALWIDTH, 20);
    
    //全屏按钮frame
    _fullScreen.frame = CGRectMake(CGRectGetMaxX(_totalTime.frame), 0, KFULLSIZE, KFULLSIZE);
}

@end
