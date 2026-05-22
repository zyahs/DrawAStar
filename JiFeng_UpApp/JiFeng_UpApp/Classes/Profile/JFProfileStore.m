//
//  JFProfileStore.m
//  JiFeng_UpApp
//

#import "JFProfileStore.h"
#import "JFAchievementStore.h"
#import "JFLeaderboardClient.h"

NSNotificationName const JFProfileDidChangeNotification = @"JFProfileDidChangeNotification";

#pragma mark - JFGameResult

@implementation JFGameResult

+ (instancetype)resultWithKind:(JFGameKind)kind score:(NSInteger)score win:(BOOL)win {
    JFGameResult *r = [[self alloc] init];
    r.kind = kind;
    r.score = score;
    r.win = win;
    r.difficulty = 0;
    r.duration = 0;
    return r;
}

@end

#pragma mark - JFProfileStore

static NSString * const kJFProfileKey = @"jf_profile_v1";

// JSON keys
static NSString * const kK_TotalGames     = @"totalGames";
static NSString * const kK_TotalScore     = @"totalScore";
static NSString * const kK_Coins          = @"coins";
static NSString * const kK_Level          = @"level";
static NSString * const kK_CurStreak      = @"curStreak";
static NSString * const kK_LongestStreak  = @"longestStreak";
static NSString * const kK_LastActive     = @"lastActiveTs";
static NSString * const kK_Games          = @"games";       // {kind: {count, best, lastPlayedTs}}

@interface JFProfileStore ()
@property (nonatomic, strong) NSMutableDictionary *root;
@end

@implementation JFProfileStore

+ (instancetype)shared {
    static JFProfileStore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        [self load];
    }
    return self;
}

#pragma mark - 持久化

- (void)load {
    NSString *json = [[NSUserDefaults standardUserDefaults] stringForKey:kJFProfileKey];
    NSMutableDictionary *root = nil;
    if (json.length > 0) {
        NSData *d = [json dataUsingEncoding:NSUTF8StringEncoding];
        id obj = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingMutableContainers error:nil];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            root = obj;
        }
    }
    if (!root) {
        root = [NSMutableDictionary dictionary];
        root[kK_TotalGames]    = @0;
        root[kK_TotalScore]    = @0;
        root[kK_Coins]         = @0;
        root[kK_Level]         = @1;
        root[kK_CurStreak]     = @0;
        root[kK_LongestStreak] = @0;
        root[kK_Games]         = [NSMutableDictionary dictionary];
    }
    if (![root[kK_Games] isKindOfClass:[NSMutableDictionary class]]) {
        root[kK_Games] = [NSMutableDictionary dictionaryWithDictionary:root[kK_Games] ?: @{}];
    }
    self.root = root;
}

- (void)save {
    NSError *err = nil;
    NSData *d = [NSJSONSerialization dataWithJSONObject:self.root options:0 error:&err];
    if (!d) return;
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kJFProfileKey];
}

- (void)broadcast {
    [[NSNotificationCenter defaultCenter] postNotificationName:JFProfileDidChangeNotification object:self];
}

#pragma mark - 全局累计 getter

- (NSInteger)totalGamesPlayed { return [self.root[kK_TotalGames] integerValue]; }
- (NSInteger)totalScore       { return [self.root[kK_TotalScore] integerValue]; }
- (NSInteger)coins            { return [self.root[kK_Coins] integerValue]; }
- (NSInteger)level            { NSInteger l = [self.root[kK_Level] integerValue]; return l < 1 ? 1 : l; }
- (NSInteger)currentStreakDays { return [self.root[kK_CurStreak] integerValue]; }
- (NSInteger)longestStreakDays { return [self.root[kK_LongestStreak] integerValue]; }
- (NSDate *)lastActiveDate {
    NSNumber *ts = self.root[kK_LastActive];
    if (!ts) return nil;
    return [NSDate dateWithTimeIntervalSince1970:ts.doubleValue];
}

#pragma mark - 等级 / 经验曲线

/// 升到第 N 级所需累计币数。简单二次,既不太陡也不太平。
+ (NSInteger)coinsRequiredForLevel:(NSInteger)level {
    if (level <= 1) return 0;
    NSInteger n = level - 1;
    return n * n * 50 + n * 50;  // 1->2: 100, 2->3: 250, 3->4: 450, 4->5: 700 ...
}

- (CGFloat)progressToNextLevel {
    NSInteger lo = [JFProfileStore coinsRequiredForLevel:self.level];
    NSInteger hi = [JFProfileStore coinsRequiredForLevel:self.level + 1];
    if (hi <= lo) return 1.0;
    CGFloat p = (CGFloat)(self.coins - lo) / (CGFloat)(hi - lo);
    return MAX(0, MIN(1.0, p));
}

- (NSInteger)coinsToNextLevel {
    NSInteger hi = [JFProfileStore coinsRequiredForLevel:self.level + 1];
    return MAX(0, hi - self.coins);
}

- (void)recomputeLevel {
    NSInteger coins = self.coins;
    NSInteger lv = 1;
    while ([JFProfileStore coinsRequiredForLevel:lv + 1] <= coins) {
        lv++;
        if (lv > 999) break;
    }
    self.root[kK_Level] = @(lv);
}

#pragma mark - 单游戏

- (NSMutableDictionary *)gameDictForKind:(JFGameKind)kind ensure:(BOOL)ensure {
    NSMutableDictionary *games = self.root[kK_Games];
    NSString *key = [NSString stringWithFormat:@"%ld", (long)kind];
    NSMutableDictionary *g = games[key];
    if (!g) {
        if (!ensure) return nil;
        g = [NSMutableDictionary dictionary];
        g[@"count"] = @0;
        g[@"best"]  = @0;
        games[key]  = g;
    } else if (![g isKindOfClass:[NSMutableDictionary class]]) {
        g = [NSMutableDictionary dictionaryWithDictionary:g];
        games[key] = g;
    }
    return g;
}

- (NSInteger)playCountForGame:(JFGameKind)kind {
    return [[self gameDictForKind:kind ensure:NO][@"count"] integerValue];
}

- (NSInteger)bestScoreForGame:(JFGameKind)kind {
    return [[self gameDictForKind:kind ensure:NO][@"best"] integerValue];
}

- (NSDate *)lastPlayedForGame:(JFGameKind)kind {
    NSNumber *ts = [self gameDictForKind:kind ensure:NO][@"lastPlayedTs"];
    if (!ts) return nil;
    return [NSDate dateWithTimeIntervalSince1970:ts.doubleValue];
}

#pragma mark - 连续天数

+ (NSInteger)dayIndexFromDate:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    return c.year * 10000 + c.month * 100 + c.day;
}

- (void)bumpStreakIfNeeded {
    NSInteger today = [JFProfileStore dayIndexFromDate:[NSDate date]];
    NSDate *last = self.lastActiveDate;
    NSInteger lastDay = last ? [JFProfileStore dayIndexFromDate:last] : 0;

    if (lastDay == today) {
        // 同一天已记过,不变
    } else {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *yest = [cal dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:[NSDate date] options:0];
        NSInteger yestIdx = [JFProfileStore dayIndexFromDate:yest];

        if (lastDay == yestIdx) {
            self.root[kK_CurStreak] = @(self.currentStreakDays + 1);
        } else {
            // 断签或首次
            self.root[kK_CurStreak] = @1;
        }
        if (self.currentStreakDays > self.longestStreakDays) {
            self.root[kK_LongestStreak] = @(self.currentStreakDays);
        }
    }
    self.root[kK_LastActive] = @([[NSDate date] timeIntervalSince1970]);
}

- (void)markAppActive {
    [self bumpStreakIfNeeded];
    [self save];
    [self broadcast];
}

- (BOOL)spendCoins:(NSInteger)amount {
    if (amount <= 0) return YES;
    if (self.coins < amount) return NO;
    self.root[kK_Coins] = @(self.coins - amount);
    [self save];
    [self broadcast];
    return YES;
}

#pragma mark - 上报

- (void)reportResult:(JFGameResult *)result {
    if (!result) return;

    [self bumpStreakIfNeeded];

    // 累计
    self.root[kK_TotalGames] = @(self.totalGamesPlayed + 1);
    NSInteger addScore = MAX(0, result.score);
    self.root[kK_TotalScore] = @(self.totalScore + addScore);

    // 风之币:基础 5 + 胜利 +5 + 分数 / 10
    NSInteger coinsGain = 5 + (result.win ? 5 : 0) + addScore / 10;
    if (result.difficulty > 0) coinsGain += result.difficulty * 3;
    self.root[kK_Coins] = @(self.coins + coinsGain);
    [self recomputeLevel];

    // 单游戏数据
    NSMutableDictionary *g = [self gameDictForKind:result.kind ensure:YES];
    g[@"count"] = @([g[@"count"] integerValue] + 1);
    if (result.score > [g[@"best"] integerValue]) {
        g[@"best"] = @(result.score);
    }
    g[@"lastPlayedTs"] = @([[NSDate date] timeIntervalSince1970]);

    [self save];

    // 成就判定
    [[JFAchievementStore shared] evaluateOnResult:result profile:self];

    // 排行榜上传(本地 mock,后端接入后只换实现)
    [[JFLeaderboardClient shared] submitScore:result.score
                                      forGame:result.kind
                                   difficulty:result.difficulty
                                   completion:nil];

    [self broadcast];
}

#pragma mark - 同步占位

- (void)pullRemoteProfileWithCompletion:(void (^)(BOOL))completion {
    // TODO: 后端接入后实现。当前直接回调成功。
    if (completion) completion(YES);
}

- (void)pushLocalProfileWithCompletion:(void (^)(BOOL))completion {
    // TODO: 后端接入后实现。当前直接回调成功。
    if (completion) completion(YES);
}

- (void)resetAll {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kJFProfileKey];
    [self load];
    [self broadcast];
}

@end
