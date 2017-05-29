//
//  XDPlayerContorller.m
//  XDPlayer
//
//  Created by 谢兴达 on 2016/11/7.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import "XDPlayerContorller.h"
#import "XDPlayerSetView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#define KHEIGHT [[UIScreen mainScreen] bounds].size.height
#define KWIDTH  [[UIScreen mainScreen] bounds].size.width

#define KHTOTOP        0    //横屏时控制框距屏幕顶端的高度
#define KYTOTOP        64   //竖屏时控制框距屏幕顶端的高度
#define MINSCREENH     KWIDTH * KWIDTH / (KHEIGHT - 88) //小屏时横屏视频的高度

@interface XDPlayerContorller () {
    //播放器
    AVPlayer * player;
    //播放层
    AVPlayerLayer * playerLayer;
    //视频时长
    CGFloat _viewLength;
    //视频当前播放时间
    float currenttime;
    //
    NSURL * videlurl;
}

@property(nonatomic, retain) XDPlayerSetView * setview; //视频控制view
@property(nonatomic, retain) AVPlayerItem * playItem;   //视频播放对象
@property(nonatomic, strong) UIImage *thumbnailImage;   //视频画面

@property(nonatomic, assign) BOOL isFull;   //是否全屏
@property(nonatomic, assign) BOOL isShow;   //是否显示控制条
@property(nonatomic, assign) BOOL ispause;  //是否暂停


@end

@implementation XDPlayerContorller

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // 退出界面时 将视频停止 并移除观察者
    [self removeVideokvo];
    [player pause];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    //初始化标志符号
    [self markManiger];
    
    //创建主UI
    [self creatMainUI];
    
    //是否可以横屏检测，应用重力感应横屏放大或缩小
    [self lisenDeviceRotated];
}

//标志符号初始化
- (void)markManiger {
    _isFull = NO;  // 进入播放器时默认为非全屏
    _ispause = NO; // 进入播放器时立即播放
    _isShow = YES; // 进入播放器是默认显示控制条
}

//创建主UI
-(void)creatMainUI {
    
    videlurl = [NSURL URLWithString:_urlStr];
    //加载控制view
    if (!_setview) {
        _setview = [[XDPlayerSetView alloc]init];
    }
    
    [self.setview.slider addTarget:self action:@selector(changeprogress:) forControlEvents:UIControlEventValueChanged];
    [self.setview.stopButton addTarget:self action:@selector(pausevideo:) forControlEvents:UIControlEventTouchUpInside];
    
    //全屏按钮点击事件
    [_setview.fullScreen tapGestureBlock:^(id obj) {
        [self screenStatus];
    }];
    
    //视频资源
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videlurl options:nil];
    NSParameterAssert(asset);
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    NSError *thumbnailImageGenerationError = nil;
    CGImageRef thumbnailImageRef = NULL;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(2*15, 15) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef) {
      NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    
    //视频画面
    _thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    NSLog(@"___高____%f ___宽____%f",_thumbnailImage.size.height,_thumbnailImage.size.width);
    
    //确定视频资源 一个视频用一个item
    self.playItem=[AVPlayerItem playerItemWithAsset:asset];
    
    //确定视频视频框架
    player = [AVPlayer playerWithPlayerItem: self.playItem];
    player.externalPlaybackVideoGravity=AVLayerVideoGravityResizeAspectFill;
    [self addObserver];
    
    //将视频放到playerlayer上播放
    playerLayer=[AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.videoGravity=AVLayerVideoGravityResize;
    
    // 配置不全屏时playerlayer 和 setview 的frame
    [self unFullScreenFrameForPlayerLayeerAndSetView];
    
    [self.view.layer addSublayer:playerLayer];
    [self.view addSubview:_setview];
    
    //添加屏幕双击手势（ 全屏/退出全屏 ）
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [_setview addGestureRecognizer:doubleTap];
    
    //添加屏幕单机手势（ 隐藏/显示控制条 ）
    UITapGestureRecognizer *onceTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onceTap)];
    onceTap.numberOfTapsRequired = 1;
    onceTap.delaysTouchesBegan = YES;
    [_setview addGestureRecognizer:onceTap];
    [onceTap requireGestureRecognizerToFail:doubleTap];
}

// 双击屏幕
- (void)doubleTap {
    NSLog(@"双击");
    [self screenStatus];
}

//单机屏幕
- (void)onceTap {
    
    //取 非 ，用来实现交替点击
    _isShow = !_isShow;

    /*
     如果视频画面 高>宽 且视频转角一律为0，高>宽 又说明视频是纵向的，此时全屏不需要改变状态条长度
     */
    CGFloat length = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                KWIDTH
                                                                              :
                                                                                KHEIGHT;
    //全屏和非全屏时的 控制条隐藏和出现的位置
    _isFull ?
                _isShow ? [UIView animateWithDuration:0.3 animations:^{
                    [_setview frameForControlLine:length toTopSpace:KHTOTOP];
                }] : [UIView animateWithDuration:0.3 animations:^{
                    [_setview frameForControlLine:length toTopSpace:-40];
                }]
        
            :
                _isShow ? [UIView animateWithDuration:0.3 animations:^{
                    [_setview frameForControlLine:KWIDTH toTopSpace:KYTOTOP];
                }] : [UIView animateWithDuration:0.3 animations:^{
                    [_setview frameForControlLine:KWIDTH toTopSpace:-40];
                }] ;
}

// 旋转配置
- (void)rotationConfigureDegress:(CGFloat)rotaDegress {
    
    /*
     如果视频画面 高>宽 且视频转角一律为0，高>宽 说明视频是纵放置的 所以此时全屏不需要旋转视频
     */
    CGFloat  degress1 = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                    0
                                                                                 :
                                                                                     rotaDegress;
     playerLayer.transform = CATransform3DMakeRotation(degress1, 0, 0, 1);
    
    /*
     如果视频画面 高>宽 且视频转角一律为0，则视频被纵向压缩，此时全屏不需要旋转状态条
     */
    CGFloat degress2 = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                  0
                                                                                :
                                                                                   rotaDegress;
    _setview.layer.transform = CATransform3DMakeRotation(degress2, 0, 0, 1);
}

//小屏时playeerlayer 和 setview的frame
- (void)unFullScreenFrameForPlayerLayeerAndSetView {
    
    /*
     如果视频画面 高>宽 且视频转角一律为0，则视频被纵向压缩，此时视频画面的frame应该按照高大于宽进行设置
     */
    playerLayer.frame = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                  CGRectMake((KWIDTH - MINSCREENH)/2.0, (KHEIGHT + 44 - KWIDTH)/2.0, MINSCREENH, KWIDTH)
                                                                                 :
                                                                                    CGRectMake(0, (KHEIGHT + 44 - MINSCREENH)/2, KWIDTH, MINSCREENH);
    
    _setview.frame = self.view.bounds;
}

//全屏时playeerlayer 和 setview的frame
- (void)fullScreenFrameForPlayerLayeerAndSetView {
    playerLayer.frame = self.view.bounds;
    _setview.frame = self.view.bounds;
}

//屏幕状态
- (void)screenStatus {
    _isFull = !_isFull;
    if (_isFull) {
        self.navigationController.navigationBar.hidden = YES;
        
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
            [self rotationConfigureDegress:M_PI_2];
            [self fullScreenFrameForPlayerLayeerAndSetView];
            
            /*
             如果视频画面 高>宽 视频是纵向的，此时全屏不需要改变状态条长度
             */
            CGFloat length = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                        KWIDTH
                                                                                      :
                                                                                        KHEIGHT;
            [weakSelf.setview frameForControlLine:length toTopSpace:KHTOTOP];
        }];
        
    } else {
        self.navigationController.navigationBar.hidden = NO;
        
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
            [self rotationConfigureDegress:-0];
            [self unFullScreenFrameForPlayerLayeerAndSetView];
            [weakSelf.setview frameForControlLine:KWIDTH toTopSpace:KYTOTOP];
        }];
    }
}

-(void)addObserver{
    //获取视频信息，要用item添加kvo,编程的时候最好使用item 的status，会准确点。
    [ self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)removeVideokvo{
    [self.playItem removeObserver:self forKeyPath:@"status"];
    [self.playItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.playItem.status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                //视频总长度
                _viewLength=self.playItem.duration.value*1/ self.playItem.duration.timescale;
                // 设置播放进度UI
                [self showPlayeritemInformation:self.playItem];
                NSLog(@"时长：%f",_viewLength);
                [player play];
            }
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"播放失败");
                break;
            default:
                
                break;
        }
        
    }
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        if (videlurl) {
            NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
            NSLog(@"Time Interval:%f",timeInterval);
            CMTime duration = self.playItem.duration;
            CGFloat totalDuration = CMTimeGetSeconds(duration);
            self.setview.progress.progress=timeInterval/totalDuration;
        }
    }
}

-(void)showPlayeritemInformation:(AVPlayerItem *)item{
    __weak typeof(self) weakSelf = self;
    //设置检查频率，1s更新一次这个block
    CMTime time = CMTimeMake(1.0, 1.0);
    [player addPeriodicTimeObserverForInterval:time queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //当前播放时间
        currenttime =item.currentTime.value/item.currentTime.timescale;
        weakSelf.setview.slider.value=currenttime/_viewLength;
        //显示时间的俩label
        weakSelf.setview.totalTime.text=[NSString stringWithFormat:@"/%@",[weakSelf getVideoLengthFromTimeLength:item.duration.value*1/ item.duration.timescale]];
        weakSelf.setview.currentTime.text=[NSString stringWithFormat:@"%@",[weakSelf getVideoLengthFromTimeLength:item.currentTime.value/item.currentTime.timescale]];
    }];
}

-(void)changeprogress:(UISlider *)sender{
    CGFloat currt= sender.value * _viewLength;
    [player seekToTime:CMTimeMake(currt, 1)];
}

//点击按钮暂停播放，再点击继续播放
-(void)pausevideo:(UIButton *)sender{
    _ispause=!_ispause;
    if (_ispause) {
        [player pause];
    }else{
        [player play];
    }
}

#pragma mark 工具方法
//计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

//将时长转换成时分秒
- (NSString *)getVideoLengthFromTimeLength:(float)timeLength
{
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:timeLength];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
    NSDateComponents *components = [calendar components:unitFlags fromDate:date];
    
    if (timeLength >= 3600 ) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)components.hour,(long)components.minute,(long)components.second];
        
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld",(long)components.minute,(long)components.second];
    }
}

#pragma mark  重力感应选择
//判断设备是否打开了重力感应旋转
-(void)lisenDeviceRotated{
    [[UIDevice currentDevice]beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

//重力感应选择监听事件
- (void)onDeviceOrientationChange {
    UIDeviceOrientation oriention = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOriention = (UIInterfaceOrientation)oriention;
    
    //
    switch (interfaceOriention) {
            
        case UIInterfaceOrientationUnknown:
            NSLog(@"位置方向");break;
            
            
        case UIInterfaceOrientationPortrait:
            NSLog(@"竖屏");
            [self backOrientationPortrait];break;
            
            
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"倒立");
            [self backOrientationPortrait];break;
            
            
        case UIInterfaceOrientationLandscapeLeft:
            [self setDeviceOrientationLandscapeLeft];
            NSLog(@"右横屏");break;
            
            
        case UIInterfaceOrientationLandscapeRight:
            [self setDeviceOrientationLandscapeRight];
            NSLog(@"左横屏");break;
            
        default:
            break;
    }
}

//竖屏 或 屏幕向下 时 返回小屏
-(void)backOrientationPortrait{
    self.navigationController.navigationBar.hidden = NO;
    
    //是否全屏
    _isFull = NO;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        [self rotationConfigureDegress:-0];
        [self unFullScreenFrameForPlayerLayeerAndSetView];
        [weakSelf.setview frameForControlLine:KWIDTH toTopSpace:KYTOTOP];
    }];
}

//右横屏
-(void)setDeviceOrientationLandscapeRight{
    
    //全屏(横屏frame计算)
    self.navigationController.navigationBar.hidden = YES;
    
    //是否全屏
    _isFull = YES;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        [self rotationConfigureDegress:M_PI_2];
        [self fullScreenFrameForPlayerLayeerAndSetView];
        
        /*
         如果视频画面 高>宽 说明视频是纵向的，此时全屏不需要改变状态条长度 否则改变为高的长度
         */
        CGFloat length = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                    KWIDTH
                                                                                  :
                                                                                    KHEIGHT;
        [weakSelf.setview frameForControlLine:length toTopSpace:KHTOTOP];
    }];
}

//左横屏
- (void)setDeviceOrientationLandscapeLeft {
    
    //全屏(横屏frame计算)
    self.navigationController.navigationBar.hidden = YES;
    
    //是否全屏
    _isFull = YES;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        /*
         如果视频画面 高>宽 说明视频是纵向的，此时全屏不需要旋转 否则逆向旋转90
         */
        CGFloat degress3 = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                     0
                                                                                    :
                                                                                     -M_PI_2;
        [self rotationConfigureDegress:degress3];
        [self fullScreenFrameForPlayerLayeerAndSetView];
        
        /*
         如果视频画面 高>宽 说明视频是纵向的，此时全屏不需要改变状态条长度 否则改变为高的长度
         */
        CGFloat length = _thumbnailImage.size.height > _thumbnailImage.size.width ?
                                                                                    KWIDTH
                                                                                  :
                                                                                    KHEIGHT;
        [weakSelf.setview frameForControlLine:length toTopSpace:KHTOTOP];
    }];
}


//隐藏navigation tabbar 电池栏
- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
