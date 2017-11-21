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

#define kRecordAudioFile @"myRecord.caf"

@interface ViewController ()<AVAudioPlayerDelegate,AVAudioRecorderDelegate>

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@property (nonatomic,strong) AVAudioRecorder *audioRecorder;

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
    
    [self setupAudioPlayer];
    
    [self setupAudioRecorder];
}

- (NSURL *)getSourceFileUrl{
    NSString *resourceName = @"荀彧.mp3";
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    return fileUrl;
}

- (NSURL *)getRecordFileUrl{
    // create path to save recorded file if not exist
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr = [urlStr stringByAppendingPathComponent:kRecordAudioFile];
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

- (NSURL *)getDestFileUrl{
    // create path to save recorded file if not exist
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr = [urlStr stringByAppendingPathComponent:@"荀彧_合成.m4a"];
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

/**
 initialize audio player
 */
- (void)setupAudioPlayer{
//    NSString *resourceName = @"荀彧.mp3";
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil];
//    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self getSourceFileUrl] error:&error];
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

/**
 initialize audio recorder
 */
- (void)setupAudioRecorder{
    AVAudioRecorder *audioRecorder = [[AVAudioRecorder alloc] initWithURL:[self getRecordFileUrl] settings:[self getAudioRecorderSetting] error:nil];
    _audioRecorder = audioRecorder;
    audioRecorder.delegate = self;
    [audioRecorder prepareToRecord];
}

- (NSDictionary *)getAudioRecorderSetting{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    return dicM;
}

#pragma mark - AVAudioRecorderDelegate
/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"%s",__func__);
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    NSLog(@"%s",__func__);
}
/* AVAudioRecorder INTERRUPTION NOTIFICATIONS ARE DEPRECATED - Use AVAudioSession instead. */

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    NSLog(@"%s",__func__);
}

/* audioRecorderEndInterruption:withOptions: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    NSLog(@"%s",__func__);
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags{
    NSLog(@"%s",__func__);
}

/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder{
    NSLog(@"%s",__func__);
}

#pragma mark - Notification
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
    if (![self.audioRecorder isRecording]) {
        [self.audioRecorder record];
    }
}

- (IBAction)pause{
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer pause];
    }
    
    // 停止录音
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
    }
    
    // 合成
    NSURL *resourceFileUrl = [self getSourceFileUrl];
    NSURL *recordFileUrl = [self getRecordFileUrl];
    
    [self audioMerge:@[resourceFileUrl,recordFileUrl] destUrl:[self getDestFileUrl]];
}

- (void)audioMerge:(NSArray *)dataSource destUrl:(NSURL *)destUrl{
    AVURLAsset *videoAsset1 = [[AVURLAsset alloc] initWithURL:dataSource[0] options:nil];
    AVURLAsset *videoAsset2 = [[AVURLAsset alloc] initWithURL:dataSource[1] options:nil];
    
    //音频轨迹(一般视频至少有2个轨道,一个播放声音,一个播放画面.音频有一个)
    AVAssetTrack *assetTrack1 = [[videoAsset1 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetTrack *assetTrack2 = [[videoAsset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    // 开始时间
//    CMTime beginTime = kCMTimeZero;
    // 设置音频合并音轨
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset2.duration) ofTrack:assetTrack1 atTime:kCMTimeZero error:nil];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset2.duration) ofTrack:assetTrack2 atTime:kCMTimeZero error:nil];
    
//    NSError *error = nil;
//    for (NSURL *sourceURL in dataSource) {
//        //音频文件资源
//        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:sourceURL options:nil];
//        //需要合并的音频文件的区间
//        CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
//        // ofTrack 音频文件内容
//        BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:beginTime error:&error];
//
//        if (!success) {
//            NSLog(@"Error: %@",error);
//        }
//        beginTime = CMTimeAdd(beginTime, audioAsset.duration);
//    }
    // presetName 与 outputFileType 要对应  导出合并的音频
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
    assetExportSession.outputURL = destUrl;
    assetExportSession.outputFileType = @"com.apple.m4a-audio";
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (assetExportSession.error) {
                NSLog(@"export failed --- %@",assetExportSession.error);
            }else {
                NSLog(@"export successfully");
            }
        });
    }];
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
