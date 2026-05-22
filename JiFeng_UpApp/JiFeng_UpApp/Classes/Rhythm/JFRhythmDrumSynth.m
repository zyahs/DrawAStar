//
//  JFRhythmDrumSynth.m
//

#import "JFRhythmDrumSynth.h"
#import <AVFoundation/AVFoundation.h>

@interface JFRhythmDrumSynth ()
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioMixerNode *mixer;
@property (nonatomic, strong) AVAudioPlayerNode *kickNode;
@property (nonatomic, strong) AVAudioPlayerNode *snareNode;
@property (nonatomic, strong) AVAudioPlayerNode *hatNode;
@property (nonatomic, strong) AVAudioPCMBuffer *kickBuffer;
@property (nonatomic, strong) AVAudioPCMBuffer *snareBuffer;
@property (nonatomic, strong) AVAudioPCMBuffer *hatBuffer;
@property (nonatomic, strong) AVAudioFormat *format;
@property (nonatomic, assign) BOOL ready;
@end

@implementation JFRhythmDrumSynth

+ (instancetype)shared {
    static JFRhythmDrumSynth *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)start {
    if (self.ready && self.engine.isRunning) return;
    if (!self.engine) [self setupEngine];
    NSError *err = nil;
    // 与 AVAudioPlayer 共存:让我们的引擎服从 ambient/playback 类型,不打断系统音乐
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [session setActive:YES error:nil];
    if (![self.engine startAndReturnError:&err]) {
        NSLog(@"[JFRhythmDrumSynth] start failed: %@", err);
        return;
    }
    if (!self.kickNode.isPlaying)  [self.kickNode play];
    if (!self.snareNode.isPlaying) [self.snareNode play];
    if (!self.hatNode.isPlaying)   [self.hatNode play];
    self.ready = YES;
}

- (void)stop {
    [self.kickNode stop];
    [self.snareNode stop];
    [self.hatNode stop];
    [self.engine stop];
    self.ready = NO;
}

- (void)setupEngine {
    self.engine = [[AVAudioEngine alloc] init];
    self.mixer = self.engine.mainMixerNode;
    self.format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];

    self.kickNode  = [[AVAudioPlayerNode alloc] init];
    self.snareNode = [[AVAudioPlayerNode alloc] init];
    self.hatNode   = [[AVAudioPlayerNode alloc] init];
    [self.engine attachNode:self.kickNode];
    [self.engine attachNode:self.snareNode];
    [self.engine attachNode:self.hatNode];
    [self.engine connect:self.kickNode  to:self.mixer format:self.format];
    [self.engine connect:self.snareNode to:self.mixer format:self.format];
    [self.engine connect:self.hatNode   to:self.mixer format:self.format];

    self.kickBuffer  = [self synthKick];
    self.snareBuffer = [self synthSnare];
    self.hatBuffer   = [self synthHat];
}

#pragma mark - 合成 buffer

- (AVAudioPCMBuffer *)bufferOfDuration:(double)seconds {
    AVAudioFrameCount frames = (AVAudioFrameCount)(self.format.sampleRate * seconds);
    AVAudioPCMBuffer *buf = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.format frameCapacity:frames];
    buf.frameLength = frames;
    return buf;
}

/// 60Hz 正弦,频率从 90Hz 衰减到 50Hz,幅度指数衰减,模拟底鼓"咚"
- (AVAudioPCMBuffer *)synthKick {
    double dur = 0.32;
    AVAudioPCMBuffer *buf = [self bufferOfDuration:dur];
    float **ch = buf.floatChannelData;
    double sr = self.format.sampleRate;
    double phase = 0;
    for (AVAudioFrameCount i = 0; i < buf.frameLength; i++) {
        double t = (double)i / sr;
        double freq = 50.0 + 60.0 * exp(-t * 24.0);     // 110 -> 50
        phase += 2.0 * M_PI * freq / sr;
        double env = exp(-t * 7.0);
        double attack = MIN(1.0, t * 200.0);            // 5ms attack 防爆音
        double sample = sin(phase) * env * attack * 0.95;
        ch[0][i] = (float)sample;
        ch[1][i] = (float)sample;
    }
    return buf;
}

/// 噪声 + 200Hz 正弦混合,模拟军鼓"啪"
- (AVAudioPCMBuffer *)synthSnare {
    double dur = 0.22;
    AVAudioPCMBuffer *buf = [self bufferOfDuration:dur];
    float **ch = buf.floatChannelData;
    double sr = self.format.sampleRate;
    double phase = 0;
    double prev = 0;
    for (AVAudioFrameCount i = 0; i < buf.frameLength; i++) {
        double t = (double)i / sr;
        double tone = sin(phase) * 0.3;
        phase += 2.0 * M_PI * 200.0 / sr;
        double n = ((double)arc4random_uniform(20000) / 10000.0) - 1.0;
        // 简单 1 阶高通(去低频)
        double hp = n - prev * 0.85;
        prev = n;
        double env = exp(-t * 18.0);
        double attack = MIN(1.0, t * 400.0);
        double sample = (tone + hp * 0.65) * env * attack * 0.7;
        ch[0][i] = (float)sample;
        ch[1][i] = (float)sample;
    }
    return buf;
}

/// 高通白噪声,模拟 hi-hat "嚓"
- (AVAudioPCMBuffer *)synthHat {
    double dur = 0.12;
    AVAudioPCMBuffer *buf = [self bufferOfDuration:dur];
    float **ch = buf.floatChannelData;
    double sr = self.format.sampleRate;
    double prev = 0;
    for (AVAudioFrameCount i = 0; i < buf.frameLength; i++) {
        double t = (double)i / sr;
        double n = ((double)arc4random_uniform(20000) / 10000.0) - 1.0;
        // 双重高通,让噪声更尖
        double hp1 = n - prev * 0.92;
        prev = n;
        double env = exp(-t * 38.0);
        double attack = MIN(1.0, t * 800.0);
        double sample = hp1 * env * attack * 0.45;
        ch[0][i] = (float)sample;
        ch[1][i] = (float)sample;
    }
    return buf;
}

#pragma mark - 播放

- (void)scheduleNode:(AVAudioPlayerNode *)node buffer:(AVAudioPCMBuffer *)buf gain:(float)gain {
    if (!self.ready) [self start];
    if (!self.ready) return;
    // 每次都新建一个 buffer 引用走 schedule —— interrupts 当前同 node 的播放,达到"再触发"效果
    node.volume = MAX(0.0f, MIN(1.0f, gain));
    [node scheduleBuffer:buf atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    if (!node.isPlaying) [node play];
}

- (void)playKickWithGain:(float)gain  { [self scheduleNode:self.kickNode  buffer:self.kickBuffer  gain:gain]; }
- (void)playSnareWithGain:(float)gain { [self scheduleNode:self.snareNode buffer:self.snareBuffer gain:gain]; }
- (void)playHatWithGain:(float)gain   { [self scheduleNode:self.hatNode   buffer:self.hatBuffer   gain:gain]; }

- (void)playForLane:(NSInteger)lane gain:(float)gain {
    switch (lane) {
        case 0: [self playKickWithGain:gain]; break;
        case 1: [self playHatWithGain:gain * 0.85]; break;
        case 2: [self playHatWithGain:gain * 0.85]; break;
        case 3: [self playSnareWithGain:gain]; break;
        default: [self playHatWithGain:gain]; break;
    }
}

@end
