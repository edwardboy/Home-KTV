//
//  ViewController.m
//  Home-KTV
//
//  Created by dfc on 2017/11/21.
//  Copyright © 2017年 dfc. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

//#import <MediaPlayer/MediaPlayer.h> // 废弃

@interface ViewController ()<AVAudioPlayerDelegate>

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

/**
 设置界面
 */
- (void)setupView{
    
    self.navigationItem.title = @"Home-KTV";
    
    [self setupPlayer];
    
    [self setupRecorder];
}

- (void)setupPlayer{
    NSString *resourceName = @"荀彧.mp3";
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    _audioPlayer.numberOfLoops = 0;
    _audioPlayer.delegate = self;
    BOOL prepareResult = [_audioPlayer prepareToPlay];
    if (!prepareResult) {
        NSLog(@"buffer failed");
    }
    if (error) {
        NSLog(@"an error occured during initializing audio player, error:%@",error.localizedDescription);
    }
    
    // play in background
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL playBackMode = [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    BOOL activeMode = [audioSession setActive:YES error:nil];
    NSLog(@"playBackMode--%d,activeMode--%d",playBackMode,activeMode);
    
    // route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)setupRecorder{
    AVAudioRecorder *audioRecorder = [AVAudioRecorder ];
}

- (void)routeChange:(NSNotification *)notification{
    NSLog(@"%s",__func__);
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}

- (IBAction)play{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
    
    // 开始录音
    
}

- (IBAction)pause{
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer pause];
    }
    
    // 停止录音，合成
}


#pragma mark - AVAudioPlayerDelegate
/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"%s",__func__);
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"%s",__func__);
}

/* AVAudioPlayer INTERRUPTION NOTIFICATIONS ARE DEPRECATED - Use AVAudioSession instead. */

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    NSLog(@"%s",__func__);
}

/* audioPlayerEndInterruption:withOptions: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags{
    NSLog(@"%s",__func__);
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags{
    NSLog(@"%s",__func__);
}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player{
    NSLog(@"%s",__func__);
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
