//
//  JFRhythmSongStore.h
//
//  节奏点点 —— 歌单管理。
//  · 用户导入的歌:音频拷到 Documents/RhythmSongs/<uuid>.<ext>,
//    谱面与元数据一起持久化在 Library/jf_rhythm_library.archive。
//  · 内置预设:在内存里维护,不写盘。
//  · UI 通过 [allSongs] 拿到「我的导入 + 内置预设」混合列表。
//

#import <Foundation/Foundation.h>
#import "JFRhythmSong.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFRhythmSongStore : NSObject

+ (instancetype)shared;

/// 内置预设 + 用户导入,先预设后导入(预设固定排在前面),已按拥有顺序返回
- (NSArray<JFRhythmSong *> *)allSongs;

/// 仅用户导入的歌,按导入时间倒序
- (NSArray<JFRhythmSong *> *)userSongs;

/// 仅内置预设
- (NSArray<JFRhythmSong *> *)presetSongs;

/// 把外部 url 拷贝到 Documents/RhythmSongs,返回拷贝后的本地 url + 唯一文件名
/// 失败时返回 nil。`kindHint` 仅用于命名,不影响存储。
- (nullable NSURL *)copyImportedAudioFromURL:(NSURL *)src outFileName:(NSString **)outName error:(NSError **)error;

/// 把一首已分析好的歌入库(立即写盘)
- (void)addUserSong:(JFRhythmSong *)song;

/// 删除某首用户导入歌(同时删除音频文件)
- (void)removeUserSong:(JFRhythmSong *)song;

@end

NS_ASSUME_NONNULL_END
