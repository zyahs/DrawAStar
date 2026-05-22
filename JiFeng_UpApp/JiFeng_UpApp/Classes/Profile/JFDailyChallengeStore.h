//
//  JFDailyChallengeStore.h
//  JiFeng_UpApp
//
//  每日挑战。
//  - 一天一个,基于日期种子轮换游戏 + 难度
//  - 完成情况落本地;首次完成 +50 风之币
//  - 业务侧只需要在每日挑战 VC 里跳合适游戏 + 完成时调 markCompleted
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFDailyChallenge : NSObject
@property (nonatomic, copy)   NSString  *dayKey;     // YYYYMMDD
@property (nonatomic, assign) JFGameKind kind;
@property (nonatomic, assign) NSInteger  difficulty; // 0/1/2
@property (nonatomic, copy)   NSString  *title;      // "今日挑战 · 拼图 4×4"
@property (nonatomic, copy)   NSString  *desc;       // 完成条件描述
@property (nonatomic, assign) NSInteger  targetScore; // 至少多少分算完成,0=只要赢
@property (nonatomic, readonly) BOOL completed;
@end

#pragma mark -

extern NSNotificationName const JFDailyChallengeDidUpdateNotification;

@interface JFDailyChallengeStore : NSObject

+ (instancetype)shared;

/// 今天的挑战
- (JFDailyChallenge *)todayChallenge;

/// 业务侧每局结束后,如果当前关心的游戏是今日挑战项目,调一次。
/// 内部判断是否符合标的并落 completion。
- (void)recordResultForToday:(JFGameKind)kind
                  difficulty:(NSInteger)difficulty
                       score:(NSInteger)score
                         win:(BOOL)win;

/// 总累计完成天数
- (NSInteger)totalCompletedDays;

@end

NS_ASSUME_NONNULL_END
