//
//  JFAchievementStore.h
//  JiFeng_UpApp
//
//  成就系统。
//  - 成就定义在代码里(简单 + 编译期检查 + 国际化方便)
//  - 进度落 UserDefaults
//  - 每局结束 Profile 触发 evaluateOnResult: 统一过一遍
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

@class JFGameResult, JFProfileStore;

/// 单条成就定义
@interface JFAchievement : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *symbolName;        // SF Symbol
@property (nonatomic, assign) NSInteger coinReward;      // 达成奖励币
/// 判定逻辑。返回 YES 即代表本次达成。
/// 实现里面可以读 result 也可以读 profile。
@property (nonatomic, copy) BOOL (^evaluator)(JFGameResult * _Nullable result, JFProfileStore *profile);

@property (nonatomic, readonly) BOOL unlocked;
@property (nonatomic, readonly, nullable) NSDate *unlockedDate;
@end

#pragma mark -

extern NSNotificationName const JFAchievementUnlockedNotification;
/// userInfo: { @"achievement": JFAchievement }

@interface JFAchievementStore : NSObject

+ (instancetype)shared;

/// 全部成就(按定义顺序)
- (NSArray<JFAchievement *> *)allAchievements;

- (NSInteger)unlockedCount;
- (NSInteger)totalCount;

/// 由 ProfileStore 在 reportResult 末尾调用
- (void)evaluateOnResult:(JFGameResult * _Nullable)result profile:(JFProfileStore *)profile;

/// 仅"档案变化"类成就(连续天数、累计局数)的判定。markAppActive 时调一次。
- (void)evaluateProfileOnly:(JFProfileStore *)profile;

@end

NS_ASSUME_NONNULL_END
