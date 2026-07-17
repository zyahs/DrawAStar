//
//  JFRhythmDrumSynth.h
//
//  节奏大师 —— 极简鼓机合成器(给"预设节奏"用)。
//  · 启动一次 AVAudioEngine,3 个 PlayerNode 各驻一个 buffer:
//    kick(底鼓,60Hz 衰减正弦)、snare(军鼓,带通白噪声)、hat(高帽,高通白噪声)
//  · 单击即触发,延迟在毫秒级,够节奏游戏跟拍。
//  · 不依赖外部音频资源,全部运行时合成。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFRhythmDrumSynth : NSObject

+ (instancetype)shared;

/// 启动引擎(空闲时可调用 stop 释放)。播放前若未启动,内部会自动启动。
- (void)start;
- (void)stop;

/// 触发不同的鼓点;`gain` 0~1 控制音量
- (void)playKickWithGain:(float)gain;
- (void)playSnareWithGain:(float)gain;
- (void)playHatWithGain:(float)gain;

/// 按 lane 自动选鼓:0=kick,1=hat,2=hat,3=snare
- (void)playForLane:(NSInteger)lane gain:(float)gain;

@end

NS_ASSUME_NONNULL_END
