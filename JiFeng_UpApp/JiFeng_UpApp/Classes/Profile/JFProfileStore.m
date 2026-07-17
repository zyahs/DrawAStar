//
//  JFProfileStore.m
//  JiFeng_UpApp
//

#import "JFProfileStore.h"
#import "JFAchievementStore.h"
#import "JFLeaderboardClient.h"
#import "JFBackendClient.h"
#import "JFAnalyticsTracker.h"

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
static NSString * const kK_DisplayName    = @"displayName";
static NSString * const kK_AvatarSymbol   = @"avatarSymbol";
static NSString * const kK_Background     = @"backgroundStyle";
static NSString * const kK_Signature      = @"signature";

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
        root[kK_DisplayName]   = @"新玩家";
        root[kK_AvatarSymbol]  = @"person.crop.circle.fill";
        root[kK_Background]    = @"aurora";
        root[kK_Signature]     = @"今晚也要赢一局";
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
- (NSString *)displayName {
    NSString *name = self.root[kK_DisplayName];
    return name.length > 0 ? name : @"新玩家";
}
- (NSString *)avatarSymbolName {
    NSString *name = self.root[kK_AvatarSymbol];
    return name.length > 0 ? name : @"person.crop.circle.fill";
}
- (NSString *)backgroundStyle {
    NSString *style = self.root[kK_Background];
    return style.length > 0 ? style : @"aurora";
}
- (NSString *)signature {
    NSString *text = self.root[kK_Signature];
    return text.length > 0 ? text : @"今晚也要赢一局";
}
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

#pragma mark - 个人资料

- (NSString *)trimmedText:(NSString *)text maxLength:(NSUInteger)maxLength fallback:(NSString *)fallback {
    NSString *trimmed = [[text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (trimmed.length == 0) return fallback;
    if (trimmed.length > maxLength) {
        trimmed = [trimmed substringToIndex:maxLength];
    }
    return trimmed;
}

- (void)updateDisplayName:(NSString *)displayName {
    self.root[kK_DisplayName] = [self trimmedText:displayName maxLength:16 fallback:@"新玩家"];
    [self save];
    [self broadcast];
    [[JFLeaderboardClient shared] setDisplayName:self.displayName];
}

- (void)updateAvatarSymbolName:(NSString *)avatarSymbolName {
    self.root[kK_AvatarSymbol] = [self trimmedText:avatarSymbolName maxLength:48 fallback:@"person.crop.circle.fill"];
    [self save];
    [self broadcast];
    [self pushLocalProfileWithCompletion:nil];
}

- (void)updateBackgroundStyle:(NSString *)backgroundStyle {
    self.root[kK_Background] = [self trimmedText:backgroundStyle maxLength:24 fallback:@"aurora"];
    [self save];
    [self broadcast];
    [self pushLocalProfileWithCompletion:nil];
}

- (void)updateSignature:(NSString *)signature {
    self.root[kK_Signature] = [self trimmedText:signature maxLength:36 fallback:@"今晚也要赢一局"];
    [self save];
    [self broadcast];
    [self pushLocalProfileWithCompletion:nil];
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

    [[JFAnalyticsTracker shared] finishGameWithResult:result];

    // 单局成绩与排行榜共用一条上报，完整保留胜负、用时和玩法细节。
    [[JFLeaderboardClient shared] submitScore:result.score
                                      forGame:result.kind
                                   difficulty:result.difficulty
                                      duration:result.duration
                                           win:result.win
                                         extra:result.extra
                                   completion:nil];

    [self broadcast];
}

#pragma mark - 同步占位

- (void)pullRemoteProfileWithCompletion:(void (^)(BOOL))completion {
    [[JFBackendClient shared] fetchProfileWithCompletion:^(NSDictionary * _Nullable profile, NSError * _Nullable error) {
        if (!profile || error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self mergeRemoteProfile:profile];
            [self save];
            [self broadcast];
            if (completion) completion(YES);
        });
    }];
}

- (void)pushLocalProfileWithCompletion:(void (^)(BOOL))completion {
    NSDictionary *payload = [self remoteProfilePayload];
    [[JFBackendClient shared] updateProfile:payload completion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(success && !error);
        });
    }];
}

- (NSDictionary *)remoteProfilePayload {
    return @{
        @"displayName": self.displayName,
        @"avatarSymbol": self.avatarSymbolName,
        @"background": self.backgroundStyle,
        @"signature": self.signature,
    };
}

- (void)mergeRemoteProfile:(NSDictionary *)profile {
    NSString *name = [profile[@"displayName"] isKindOfClass:[NSString class]] ? profile[@"displayName"] : nil;
    NSString *avatar = [profile[@"avatarSymbol"] isKindOfClass:[NSString class]] ? profile[@"avatarSymbol"] : nil;
    NSString *background = [profile[@"background"] isKindOfClass:[NSString class]] ? profile[@"background"] : nil;
    NSString *signature = [profile[@"signature"] isKindOfClass:[NSString class]] ? profile[@"signature"] : nil;

    if (name.length > 0) self.root[kK_DisplayName] = name;
    if (avatar.length > 0) self.root[kK_AvatarSymbol] = avatar;
    if (background.length > 0) self.root[kK_Background] = background;
    if (signature.length > 0) self.root[kK_Signature] = signature;

    NSInteger remoteGames = [profile[@"totalGames"] integerValue];
    if (remoteGames > self.totalGamesPlayed) {
        self.root[kK_TotalGames] = @(remoteGames);
        self.root[kK_TotalScore] = @([profile[@"totalScore"] integerValue]);
        self.root[kK_Coins] = @([profile[@"coins"] integerValue]);
        self.root[kK_Level] = @([profile[@"level"] integerValue]);
    }
}

- (void)resetAll {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kJFProfileKey];
    [self load];
    [self broadcast];
}

@end
