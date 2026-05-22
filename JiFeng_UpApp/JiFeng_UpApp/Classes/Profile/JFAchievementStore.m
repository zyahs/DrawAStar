//
//  JFAchievementStore.m
//  JiFeng_UpApp
//

#import "JFAchievementStore.h"
#import "JFProfileStore.h"

NSNotificationName const JFAchievementUnlockedNotification = @"JFAchievementUnlockedNotification";

#pragma mark - JFAchievement

@interface JFAchievement ()
@property (nonatomic, assign) BOOL unlocked;
@property (nonatomic, strong, nullable) NSDate *unlockedDate;
@end

@implementation JFAchievement
@end

#pragma mark - Store

static NSString * const kJFAchUnlockedKey = @"jf_ach_unlocked_v1"; // {id: ts}

@interface JFAchievementStore ()
@property (nonatomic, strong) NSArray<JFAchievement *> *achievements;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *unlockedMap;
@end

@implementation JFAchievementStore

+ (instancetype)shared {
    static JFAchievementStore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *map = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kJFAchUnlockedKey];
        self.unlockedMap = [(map ?: @{}) mutableCopy];
        [self buildDefinitions];
        [self syncUnlockedStateIntoDefs];
    }
    return self;
}

- (void)syncUnlockedStateIntoDefs {
    for (JFAchievement *a in self.achievements) {
        NSNumber *ts = self.unlockedMap[a.identifier];
        if (ts) {
            a.unlocked = YES;
            a.unlockedDate = [NSDate dateWithTimeIntervalSince1970:ts.doubleValue];
        }
    }
}

#pragma mark - 定义

- (JFAchievement *)defWithId:(NSString *)i title:(NSString *)t desc:(NSString *)d
                      symbol:(NSString *)sym reward:(NSInteger)r
                   evaluator:(BOOL (^)(JFGameResult *, JFProfileStore *))ev {
    JFAchievement *a = [[JFAchievement alloc] init];
    a.identifier = i;
    a.title = t;
    a.desc = d;
    a.symbolName = sym;
    a.coinReward = r;
    a.evaluator = ev;
    return a;
}

- (void)buildDefinitions {
    NSMutableArray *list = [NSMutableArray array];

    // 全局
    [list addObject:[self defWithId:@"first_play" title:@"初识继风" desc:@"完成第一局游戏"
                              symbol:@"sparkles" reward:20
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.totalGamesPlayed >= 1;
    }]];
    [list addObject:[self defWithId:@"play_50" title:@"百炼成钢·初" desc:@"累计游玩 50 局"
                              symbol:@"flame.fill" reward:50
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.totalGamesPlayed >= 50;
    }]];
    [list addObject:[self defWithId:@"play_200" title:@"百炼成钢·终" desc:@"累计游玩 200 局"
                              symbol:@"flame.circle.fill" reward:200
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.totalGamesPlayed >= 200;
    }]];
    [list addObject:[self defWithId:@"streak_3" title:@"日常打卡" desc:@"连续 3 天打开 App"
                              symbol:@"calendar.badge.checkmark" reward:30
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.currentStreakDays >= 3;
    }]];
    [list addObject:[self defWithId:@"streak_7" title:@"七日有约" desc:@"连续 7 天打开 App"
                              symbol:@"calendar.circle.fill" reward:80
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.currentStreakDays >= 7;
    }]];
    [list addObject:[self defWithId:@"streak_30" title:@"月度风雷" desc:@"连续 30 天打开 App"
                              symbol:@"crown.fill" reward:300
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.currentStreakDays >= 30;
    }]];
    [list addObject:[self defWithId:@"level_5" title:@"小有名气" desc:@"达到等级 5"
                              symbol:@"star.fill" reward:50
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.level >= 5;
    }]];
    [list addObject:[self defWithId:@"level_10" title:@"远近闻名" desc:@"达到等级 10"
                              symbol:@"star.circle.fill" reward:150
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return p.level >= 10;
    }]];

    // 单游戏
    [list addObject:[self defWithId:@"snake_30" title:@"蛇道初成" desc:@"贪吃蛇得分 30"
                              symbol:@"scribble.variable" reward:30
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return [p bestScoreForGame:JFGameKindSnake] >= 30;
    }]];
    [list addObject:[self defWithId:@"snake_80" title:@"蛇道大成" desc:@"贪吃蛇得分 80"
                              symbol:@"scribble" reward:120
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return [p bestScoreForGame:JFGameKindSnake] >= 80;
    }]];
    [list addObject:[self defWithId:@"puzzle_easy_clear" title:@"完璧归赵·初" desc:@"完成一次 3×3 拼图"
                              symbol:@"square.grid.3x3" reward:25
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return r && r.kind == JFGameKindPuzzle && r.win && r.difficulty == 0;
    }]];
    [list addObject:[self defWithId:@"puzzle_hard_clear" title:@"完璧归赵·终" desc:@"完成一次 5×5 拼图"
                              symbol:@"square.grid.4x3.fill" reward:120
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return r && r.kind == JFGameKindPuzzle && r.win && r.difficulty == 2;
    }]];
    [list addObject:[self defWithId:@"five_first_win" title:@"初尝胜果" desc:@"五子棋赢一局"
                              symbol:@"square.grid.4x3.fill" reward:30
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return r && r.kind == JFGameKindFiveInRow && r.win;
    }]];
    [list addObject:[self defWithId:@"reaction_50" title:@"眼疾手快" desc:@"反应力测试 30s 击中 50 次"
                              symbol:@"hand.tap.fill" reward:50
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return [p bestScoreForGame:JFGameKindReaction] >= 50;
    }]];
    [list addObject:[self defWithId:@"twenty48_2048" title:@"达成 2048" desc:@"在 2048 中合出 2048 方块"
                              symbol:@"square.fill.on.square.fill" reward:200
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        if (!r || r.kind != JFGameKind2048) return NO;
        NSInteger maxTile = [r.extra[@"maxTile"] integerValue];
        return maxTile >= 2048;
    }]];
    [list addObject:[self defWithId:@"sudoku_clear" title:@"九宫初解" desc:@"完成一局数独"
                              symbol:@"square.grid.3x3.square" reward:60
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return r && r.kind == JFGameKindSudoku && r.win;
    }]];
    [list addObject:[self defWithId:@"memory_clear" title:@"过目不忘" desc:@"完成一局记忆翻牌"
                              symbol:@"rectangle.on.rectangle" reward:40
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        return r && r.kind == JFGameKindMemory && r.win;
    }]];
    [list addObject:[self defWithId:@"rhythm_perfect" title:@"心律相通" desc:@"节奏点点中达成 50 连击"
                              symbol:@"music.note" reward:80
                          evaluator:^BOOL(JFGameResult *r, JFProfileStore *p) {
        if (!r || r.kind != JFGameKindRhythm) return NO;
        NSInteger maxCombo = [r.extra[@"maxCombo"] integerValue];
        return maxCombo >= 50;
    }]];
    self.achievements = [list copy];
}

#pragma mark - 状态

- (NSInteger)totalCount    { return self.achievements.count; }
- (NSInteger)unlockedCount { return self.unlockedMap.count; }

- (NSArray<JFAchievement *> *)allAchievements { return self.achievements; }

#pragma mark - 判定

- (void)persist {
    [[NSUserDefaults standardUserDefaults] setObject:self.unlockedMap forKey:kJFAchUnlockedKey];
}

- (void)tryUnlock:(JFAchievement *)a result:(JFGameResult *)r profile:(JFProfileStore *)p {
    if (a.unlocked) return;
    if (!a.evaluator) return;
    BOOL ok = NO;
    @try { ok = a.evaluator(r, p); }
    @catch (__unused NSException *e) { ok = NO; }
    if (!ok) return;

    a.unlocked = YES;
    a.unlockedDate = [NSDate date];
    self.unlockedMap[a.identifier] = @(a.unlockedDate.timeIntervalSince1970);
    [self persist];

    [[NSNotificationCenter defaultCenter] postNotificationName:JFAchievementUnlockedNotification
                                                        object:self
                                                      userInfo:@{@"achievement": a}];
}

- (void)evaluateOnResult:(JFGameResult *)result profile:(JFProfileStore *)profile {
    for (JFAchievement *a in self.achievements) {
        [self tryUnlock:a result:result profile:profile];
    }
}

- (void)evaluateProfileOnly:(JFProfileStore *)profile {
    for (JFAchievement *a in self.achievements) {
        [self tryUnlock:a result:nil profile:profile];
    }
}

@end
