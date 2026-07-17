//
//  JFRhythmAnalyzer.h
//
//  节奏大师 —— 离线 onset 分析。
//  · 4 段一阶 IIR 滤波分频:低 / 中低 / 中高 / 高
//  · 每段半波正差分作为 onset 强度
//  · 自适应阈值 + 局部极大 peak picking
//  · 按各频段能量分布分配到 4 轨,鼓底偏左、镲偏右
//

#import <Foundation/Foundation.h>
#import "JFRhythmSong.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFRhythmAnalyzer : NSObject

/// 给定音频 url(WAV/MP3/AAC 都行),返回一组 JFRhythmBeat;同时输出估算的 BPM
/// duration 是音频长度(秒);失败时返回空数组
+ (NSArray<JFRhythmBeat *> *)analyzeURL:(NSURL *)url
                              duration:(NSTimeInterval)duration
                                outBPM:(double *)outBPM;

@end

NS_ASSUME_NONNULL_END
