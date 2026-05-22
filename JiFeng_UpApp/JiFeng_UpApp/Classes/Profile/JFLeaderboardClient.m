//
//  JFLeaderboardClient.m
//  JiFeng_UpApp
//

#import "JFLeaderboardClient.h"

@implementation JFLeaderboardEntry
@end

#pragma mark - LocalMock 实现

@interface JFLeaderboardLocalMock : NSObject <JFLeaderboardClient>
@end

static NSString * const kJFLBPlayerIdKey   = @"jf_lb_player_id";
static NSString * const kJFLBNameKey       = @"jf_lb_display_name";
static NSString * const kJFLBScoresKey     = @"jf_lb_local_scores"; // {gameKey: bestScore}

@implementation JFLeaderboardLocalMock {
    NSString *_playerId;
    NSString *_name;
}

- (instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _playerId = [ud stringForKey:kJFLBPlayerIdKey];
        if (_playerId.length == 0) {
            _playerId = [[NSUUID UUID] UUIDString];
            [ud setObject:_playerId forKey:kJFLBPlayerIdKey];
        }
        _name = [ud stringForKey:kJFLBNameKey];
        if (_name.length == 0) _name = @"我";
    }
    return self;
}

- (NSString *)playerId    { return _playerId; }
- (NSString *)displayName { return _name; }
- (void)setDisplayName:(NSString *)name {
    if (name.length == 0) return;
    _name = [name copy];
    [[NSUserDefaults standardUserDefaults] setObject:_name forKey:kJFLBNameKey];
}

- (NSString *)keyForGame:(JFGameKind)kind difficulty:(NSInteger)difficulty {
    return [NSString stringWithFormat:@"%ld_%ld", (long)kind, (long)difficulty];
}

- (void)submitScore:(NSInteger)score
            forGame:(JFGameKind)kind
         difficulty:(NSInteger)difficulty
         completion:(JFLeaderboardSubmitCompletion)completion {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *all = [[ud dictionaryForKey:kJFLBScoresKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *key = [self keyForGame:kind difficulty:difficulty];
    NSInteger old = [all[key] integerValue];
    if (score > old) {
        all[key] = @(score);
        [ud setObject:all forKey:kJFLBScoresKey];
    }
    if (completion) completion(YES, nil);
}

- (void)fetchTopScoresForGame:(JFGameKind)kind
                    difficulty:(NSInteger)difficulty
                         limit:(NSInteger)limit
                    completion:(JFLeaderboardFetchCompletion)completion {
    if (!completion) return;

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSDictionary *all = [ud dictionaryForKey:kJFLBScoresKey] ?: @{};
    NSString *key = [self keyForGame:kind difficulty:difficulty];
    NSInteger myScore = [all[key] integerValue];

    JFLeaderboardEntry *me = [[JFLeaderboardEntry alloc] init];
    me.playerId = _playerId;
    me.displayName = _name;
    me.score = myScore;
    me.date = [NSDate date];
    me.isMe = YES;

    // 假榜单:基于我的成绩造几个对照,占位用,后端接入后这一段会被替换。
    NSMutableArray *list = [NSMutableArray array];
    NSArray *fakeNames = @[@"风之子", @"夜枭", @"破晓", @"小江", @"阿水", @"蓝鲸", @"霜叶", @"逆光", @"星轨", @"白鸽"];
    NSInteger top = MAX(myScore + 30, 80);
    for (NSInteger i = 0; i < MIN(limit, (NSInteger)fakeNames.count); i++) {
        JFLeaderboardEntry *e = [[JFLeaderboardEntry alloc] init];
        e.playerId = [NSString stringWithFormat:@"npc_%ld", (long)i];
        e.displayName = fakeNames[i];
        e.score = MAX(0, top - i * 7 - (NSInteger)arc4random_uniform(5));
        e.date = [NSDate date];
        e.isMe = NO;
        [list addObject:e];
    }
    // 把我塞进合适的位置
    BOOL inserted = NO;
    for (NSInteger i = 0; i < list.count; i++) {
        JFLeaderboardEntry *e = list[i];
        if (myScore >= e.score) {
            [list insertObject:me atIndex:i];
            inserted = YES;
            break;
        }
    }
    if (!inserted) [list addObject:me];
    if ((NSInteger)list.count > limit) {
        list = [[list subarrayWithRange:NSMakeRange(0, limit)] mutableCopy];
    }
    for (NSInteger i = 0; i < list.count; i++) {
        ((JFLeaderboardEntry *)list[i]).rank = i + 1;
    }
    completion([list copy], me, nil);
}

@end

#pragma mark - 注册中心

@implementation JFLeaderboardClient

static id<JFLeaderboardClient> _sharedClient;

+ (id<JFLeaderboardClient>)shared {
    @synchronized (self) {
        if (!_sharedClient) {
            _sharedClient = [[JFLeaderboardLocalMock alloc] init];
        }
        return _sharedClient;
    }
}

+ (void)setSharedClient:(id<JFLeaderboardClient>)client {
    @synchronized (self) {
        _sharedClient = client;
    }
}

@end
