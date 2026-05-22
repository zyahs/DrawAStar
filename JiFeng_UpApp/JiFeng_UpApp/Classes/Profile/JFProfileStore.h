//
//  JFProfileStore.h
//  JiFeng_UpApp
//
//  玩家档案 —— 全局累计、连续天数、各游戏最佳成绩。
//  落盘:NSUserDefaults(单 key,JSON 字符串)。
//  预留 syncToServer 接口,后续接后端只需要换 LeaderboardClient 实现 + 把
//  reportResult 内的 syncRemote 接通即可,业务侧零改动。
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

/// 单局结果。所有游戏完成时统一上报。
@interface JFGameResult : NSObject
@property (nonatomic, assign) JFGameKind kind;
/// 主分数(贪吃蛇得分、拼图剩余时间等)。越大越好。
/// 拼图这种"步数 / 用时越少越好"的项目,sub 字段用对应原值,score 自己换算成正向(例:10000 - moves)。
@property (nonatomic, assign) NSInteger score;
/// 难度等级 0/1/2(没有的游戏传 0)
@property (nonatomic, assign) NSInteger difficulty;
/// 用时秒数(没有的传 0)
@property (nonatomic, assign) NSTimeInterval duration;
/// 是否胜利(单机普遍传 YES,失败传 NO,无胜负概念也传 YES)
@property (nonatomic, assign) BOOL win;
/// 给业务自由扩展的额外字段
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *extra;

+ (instancetype)resultWithKind:(JFGameKind)kind score:(NSInteger)score win:(BOOL)win;

@end

#pragma mark -

extern NSNotificationName const JFProfileDidChangeNotification;

/// 玩家档案中心。线程不安全,默认主线程使用。
@interface JFProfileStore : NSObject

+ (instancetype)shared;

#pragma mark - 全局累计

@property (nonatomic, readonly) NSInteger totalGamesPlayed;     // 总局数
@property (nonatomic, readonly) NSInteger totalScore;            // 总积分
@property (nonatomic, readonly) NSInteger coins;                 // 风之币
@property (nonatomic, readonly) NSInteger level;                 // 等级,1 起
@property (nonatomic, readonly) NSInteger currentStreakDays;     // 连续天数
@property (nonatomic, readonly) NSInteger longestStreakDays;     // 历史最长连续
@property (nonatomic, readonly) NSDate * _Nullable lastActiveDate;

/// 进度:当前等级到下一级的 [0,1]
- (CGFloat)progressToNextLevel;
/// 升到下一级还需要多少币
- (NSInteger)coinsToNextLevel;

#pragma mark - 单游戏成绩

- (NSInteger)playCountForGame:(JFGameKind)kind;
- (NSInteger)bestScoreForGame:(JFGameKind)kind;
- (NSDate * _Nullable)lastPlayedForGame:(JFGameKind)kind;

#pragma mark - 上报

/// 调一次 = 玩了一局。统一在这里:
///  1. 更新次数/最佳成绩/连续天数
///  2. 加风之币 / 总分
///  3. 触发成就判定
///  4. 调 LeaderboardClient 上传(本地 mock,后端接入后换实现)
///  5. 发 JFProfileDidChangeNotification
- (void)reportResult:(JFGameResult *)result;

/// 进入主页时调一次。仅用于刷新连续天数(进入也算"今日已活跃")。
- (void)markAppActive;

/// 扣除金币;若余额不足返回 NO 且不扣款。成功后会发广播。
- (BOOL)spendCoins:(NSInteger)amount;

#pragma mark - 同步占位(后端接入再实现)

/// 拉远端档案(预留,当前空实现)。后端接入后在这里覆盖本地或合并。
- (void)pullRemoteProfileWithCompletion:(void (^ _Nullable)(BOOL success))completion;

/// 推本地档案到远端(预留)
- (void)pushLocalProfileWithCompletion:(void (^ _Nullable)(BOOL success))completion;

#pragma mark - 调试

/// 仅用于开发自查 / 后端打通后做 reset
- (void)resetAll;

@end

NS_ASSUME_NONNULL_END
