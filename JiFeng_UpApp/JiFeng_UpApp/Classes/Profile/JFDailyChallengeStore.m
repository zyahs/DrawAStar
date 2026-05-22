//
//  JFDailyChallengeStore.m
//  JiFeng_UpApp
//

#import "JFDailyChallengeStore.h"
#import "JFProfileStore.h"

NSNotificationName const JFDailyChallengeDidUpdateNotification = @"JFDailyChallengeDidUpdateNotification";

@interface JFDailyChallenge ()
@property (nonatomic, assign) BOOL completed;
@end

@implementation JFDailyChallenge
@end

#pragma mark -

static NSString * const kJFDailyCompletedDaysKey = @"jf_daily_done_days_v1"; // [dayKey...]

@interface JFDailyChallengeStore ()
@property (nonatomic, strong) NSMutableSet<NSString *> *completedDays;
@property (nonatomic, strong) JFDailyChallenge *cached;
@property (nonatomic, copy)   NSString *cachedDayKey;
@end

@implementation JFDailyChallengeStore

+ (instancetype)shared {
    static JFDailyChallengeStore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        NSArray *days = [[NSUserDefaults standardUserDefaults] arrayForKey:kJFDailyCompletedDaysKey];
        self.completedDays = [NSMutableSet setWithArray:days ?: @[]];
    }
    return self;
}

#pragma mark - 生成

+ (NSString *)dayKeyFromDate:(NSDate *)d {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:d];
    return [NSString stringWithFormat:@"%04ld%02ld%02ld", (long)c.year, (long)c.month, (long)c.day];
}

/// 候选库:游戏种类 + 难度 + 完成阈值 + 文案
+ (NSArray<NSDictionary *> *)pool {
    return @[
        @{@"kind": @(JFGameKindPuzzle),   @"difficulty": @0, @"target": @0,
          @"title": @"3×3 拼图速成",   @"desc": @"完成一次 3×3 拼图"},
        @{@"kind": @(JFGameKindPuzzle),   @"difficulty": @1, @"target": @0,
          @"title": @"4×4 拼图挑战",   @"desc": @"完成一次 4×4 拼图"},
        @{@"kind": @(JFGameKindSnake),    @"difficulty": @0, @"target": @20,
          @"title": @"贪吃蛇 20 分",    @"desc": @"贪吃蛇得分 ≥ 20"},
        @{@"kind": @(JFGameKindSnake),    @"difficulty": @0, @"target": @40,
          @"title": @"贪吃蛇 40 分",    @"desc": @"贪吃蛇得分 ≥ 40"},
        @{@"kind": @(JFGameKind2048),     @"difficulty": @0, @"target": @512,
          @"title": @"2048 · 合到 512",@"desc": @"在 2048 中合出 512"},
        @{@"kind": @(JFGameKindReaction), @"difficulty": @0, @"target": @30,
          @"title": @"反应力 30 击",    @"desc": @"反应力测试 30 秒击中 ≥ 30"},
        @{@"kind": @(JFGameKindMemory),   @"difficulty": @0, @"target": @0,
          @"title": @"记忆翻牌入门",   @"desc": @"完成一次 3×4 记忆翻牌"},
        @{@"kind": @(JFGameKindMemory),   @"difficulty": @1, @"target": @0,
          @"title": @"记忆翻牌进阶",   @"desc": @"完成一次 4×4 记忆翻牌"},
        @{@"kind": @(JFGameKindSudoku),   @"difficulty": @0, @"target": @0,
          @"title": @"数独入门",        @"desc": @"完成一局数独"},
        @{@"kind": @(JFGameKindRhythm),   @"difficulty": @0, @"target": @20,
          @"title": @"节奏 20 连",      @"desc": @"节奏点点中达成连击 ≥ 20"},
        @{@"kind": @(JFGameKindFiveInRow),@"difficulty": @0, @"target": @0,
          @"title": @"五子棋赢一局",   @"desc": @"完成一局五子棋胜利"},
    ];
}

- (JFDailyChallenge *)todayChallenge {
    NSString *today = [JFDailyChallengeStore dayKeyFromDate:[NSDate date]];
    if (self.cached && [self.cachedDayKey isEqualToString:today]) {
        // 但 completed 状态可能在 record 里被刷新过,这里直接同步
        self.cached.completed = [self.completedDays containsObject:today];
        return self.cached;
    }

    NSArray<NSDictionary *> *pool = [JFDailyChallengeStore pool];
    // 用 dayKey 当种子,稳定选取
    NSInteger seed = [today integerValue];
    NSInteger idx = ((seed * 2654435761ll) >> 16) % pool.count;
    if (idx < 0) idx += pool.count;
    NSDictionary *cfg = pool[idx];

    JFDailyChallenge *c = [[JFDailyChallenge alloc] init];
    c.dayKey      = today;
    c.kind        = (JFGameKind)[cfg[@"kind"] integerValue];
    c.difficulty  = [cfg[@"difficulty"] integerValue];
    c.title       = cfg[@"title"];
    c.desc        = cfg[@"desc"];
    c.targetScore = [cfg[@"target"] integerValue];
    c.completed   = [self.completedDays containsObject:today];

    self.cached = c;
    self.cachedDayKey = today;
    return c;
}

#pragma mark - 记录

- (void)recordResultForToday:(JFGameKind)kind difficulty:(NSInteger)difficulty
                       score:(NSInteger)score win:(BOOL)win {
    JFDailyChallenge *c = [self todayChallenge];
    if (c.completed) return;
    if (c.kind != kind) return;
    if (c.difficulty != difficulty) return;

    BOOL ok = NO;
    if (c.targetScore > 0) {
        ok = (score >= c.targetScore);
    } else {
        ok = win;
    }
    if (!ok) return;

    [self.completedDays addObject:c.dayKey];
    [[NSUserDefaults standardUserDefaults] setObject:[self.completedDays allObjects] forKey:kJFDailyCompletedDaysKey];
    c.completed = YES;

    // 完成奖励:50 风之币(走 ProfileStore 的 reportResult 太重,这里直接造一个 result 加上去)
    JFGameResult *bonus = [JFGameResult resultWithKind:kind score:50 win:YES];
    bonus.difficulty = difficulty;
    bonus.extra = @{@"daily": @YES};
    [[JFProfileStore shared] reportResult:bonus];

    [[NSNotificationCenter defaultCenter] postNotificationName:JFDailyChallengeDidUpdateNotification object:self];
}

- (NSInteger)totalCompletedDays { return self.completedDays.count; }

@end
