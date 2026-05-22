//
//  JFRhythmSong.h
//
//  节奏点点 —— 一首"歌"的数据模型(可能是用户导入的音频,也可能是内置的纯节拍预设)。
//  · 用户导入:audioFileName 指向 Documents/RhythmSongs 下的音频文件
//  · 内置预设:audioFileName 为空,只有 chart + bpm,运行时用 haptic 节拍提示
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFRhythmSongKind) {
    JFRhythmSongKindUserImport = 0,   // 用户导入的本地音频
    JFRhythmSongKindPreset,           // 预设节奏,无音频
};

typedef NS_ENUM(NSInteger, JFRhythmDifficulty) {
    JFRhythmDifficultyEasy = 0,
    JFRhythmDifficultyMedium,
    JFRhythmDifficultyHard,
};

@class JFRhythmBeat;

/// 把全量谱面按难度抽稀
/// · easy:最少音符,最低 0.36s 间隔,粘连点直接合并
/// · medium:平衡密度
/// · hard:最密集,最低 0.16s 间隔
@interface JFRhythmChart : NSObject
+ (NSArray<JFRhythmBeat *> *)chartFromFull:(NSArray<JFRhythmBeat *> *)full
                                difficulty:(JFRhythmDifficulty)diff;
+ (NSString *)nameOfDifficulty:(JFRhythmDifficulty)diff;
+ (NSString *)keyOfDifficulty:(JFRhythmDifficulty)diff;
@end

/// 谱面单个拍点
@interface JFRhythmBeat : NSObject <NSSecureCoding>
@property (nonatomic, assign) NSTimeInterval time;     // 该音符到达判定线的"歌曲时间"(秒)
@property (nonatomic, assign) NSInteger lane;          // 0..3
@property (nonatomic, assign) double strength;         // 该 onset 的能量(0..1),用于动效
+ (instancetype)beatAt:(NSTimeInterval)t lane:(NSInteger)lane strength:(double)s;
@end

@interface JFRhythmSong : NSObject <NSSecureCoding>

@property (nonatomic, assign) JFRhythmSongKind kind;
@property (nonatomic, copy)   NSString *songId;             // 唯一标识(UUID 或预设 key)
@property (nonatomic, copy)   NSString *title;              // 显示用标题
@property (nonatomic, copy, nullable) NSString *artist;     // 副标题/简介
@property (nonatomic, copy, nullable) NSString *audioFileName;  // 仅本地音频用,Documents/RhythmSongs/<x>
@property (nonatomic, copy, nullable) NSString *bundleAudioName; // 仅预设用,bundle 中 Music/<x>
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) double bpm;
@property (nonatomic, strong) NSArray<JFRhythmBeat *> *chart;        // 当前难度下的谱面
@property (nonatomic, strong, nullable) NSArray<JFRhythmBeat *> *fullChart;  // 完整 onset 列表;用于按难度重抽
@property (nonatomic, strong, nullable) NSDate *importedAt;

/// 仅当 kind == UserImport 时返回真实文件路径
- (nullable NSURL *)audioURLInDocuments;

/// 当前歌曲对应的可播放 url(自动区分 UserImport / Preset);找不到返回 nil
- (nullable NSURL *)playableAudioURL;

@end

NS_ASSUME_NONNULL_END
