//
//  JFAnalyticsTracker.m
//  JiFeng_UpApp
//

#import "JFAnalyticsTracker.h"
#import "JFBackendClient.h"
#import "JFProfileStore.h"
#import <math.h>

static NSString * const kJFAnalyticsQueueKey = @"jf_analytics_queue_v1";
static NSUInteger const kJFAnalyticsQueueLimit = 500;
static NSUInteger const kJFAnalyticsBatchSize = 50;

@interface JFAnalyticsTracker ()

@property (nonatomic, strong) dispatch_queue_t storageQueue;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingEvents;
@property (nonatomic, assign) BOOL flushing;
@property (nonatomic, assign) BOOL flushScheduled;

@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *appSessionId;
@property (nonatomic, strong, nullable) NSDate *appSessionStartedAt;
@property (nonatomic, assign) BOOL appActive;

@property (nonatomic, copy, nullable) NSString *gameSessionId;
@property (nonatomic, assign) JFGameKind currentGameKind;
@property (nonatomic, copy, nullable) NSString *currentGameSource;
@property (nonatomic, strong, nullable) NSDate *gameActiveSegmentStartedAt;
@property (nonatomic, assign) NSTimeInterval gameActiveSeconds;
@property (nonatomic, assign) BOOL currentGameCompleted;

@end

@implementation JFAnalyticsTracker

+ (instancetype)shared {
    static JFAnalyticsTracker *tracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [[self alloc] init];
    });
    return tracker;
}

- (instancetype)init {
    if (self = [super init]) {
        _storageQueue = dispatch_queue_create("com.jifeng.analytics.storage", DISPATCH_QUEUE_SERIAL);
        NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:kJFAnalyticsQueueKey];
        _pendingEvents = [saved isKindOfClass:[NSArray class]] ? [saved mutableCopy] : [NSMutableArray array];

        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0";
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"0";
        _appVersion = [[NSString stringWithFormat:@"%@(%@)", version, build] substringToIndex:MIN((NSUInteger)32, version.length + build.length + 2)];
    }
    return self;
}

#pragma mark - Lifecycle

- (void)sceneDidBecomeActive {
    NSString *sessionId = nil;
    @synchronized (self) {
        if (self.appActive) return;
        self.appActive = YES;
        self.appSessionId = [[NSUUID UUID] UUIDString];
        self.appSessionStartedAt = [NSDate date];
        sessionId = self.appSessionId;
        if (self.gameSessionId.length > 0) {
            self.gameActiveSegmentStartedAt = [NSDate date];
        }
    }
    [self enqueueEvent:@"app_session_start"
                  kind:nil
          appSessionId:sessionId
         gameSessionId:nil
            properties:nil
                  date:[NSDate date]];
    [self flush];
}

- (void)sceneWillResignActive {
    NSString *sessionId = nil;
    NSTimeInterval duration = 0;
    @synchronized (self) {
        if (!self.appActive || self.appSessionId.length == 0) return;
        NSDate *now = [NSDate date];
        sessionId = self.appSessionId;
        duration = MAX(0, [now timeIntervalSinceDate:self.appSessionStartedAt ?: now]);
        if (self.gameActiveSegmentStartedAt) {
            self.gameActiveSeconds += MAX(0, [now timeIntervalSinceDate:self.gameActiveSegmentStartedAt]);
            self.gameActiveSegmentStartedAt = nil;
        }
        self.appActive = NO;
        self.appSessionId = nil;
        self.appSessionStartedAt = nil;
    }
    [self enqueueEvent:@"app_session_end"
                  kind:nil
          appSessionId:sessionId
         gameSessionId:nil
            properties:@{ @"durationMs": @((NSInteger)llround(duration * 1000.0)) }
                  date:[NSDate date]];
    [self flush];
}

#pragma mark - Games

- (void)trackGameCardClick:(JFGameKind)kind source:(NSString *)source {
    [self trackEvent:@"game_card_click"
            gameKind:kind
          properties:@{ @"source": [self cleanText:source fallback:@"home" maxLength:32] }];
}

- (void)beginGameSession:(JFGameKind)kind source:(NSString *)source {
    [self endCurrentGameSessionWithReason:@"replaced"];

    NSString *gameSessionId = [[NSUUID UUID] UUIDString];
    NSString *cleanSource = [self cleanText:source fallback:@"home" maxLength:32];
    @synchronized (self) {
        self.gameSessionId = gameSessionId;
        self.currentGameKind = kind;
        self.currentGameSource = cleanSource;
        self.gameActiveSeconds = 0;
        self.currentGameCompleted = NO;
        self.gameActiveSegmentStartedAt = self.appActive ? [NSDate date] : nil;
    }

    NSDictionary *properties = @{ @"source": cleanSource };
    [self enqueueGameEvent:@"game_enter" kind:kind properties:properties];
    [self enqueueGameEvent:@"game_start" kind:kind properties:properties];
}

- (void)finishGameWithResult:(JFGameResult *)result {
    if (!result || [result.extra[@"daily"] boolValue]) return;

    NSString *gameSessionId = nil;
    NSString *source = nil;
    NSTimeInterval duration = 0;
    @synchronized (self) {
        if (self.gameSessionId.length == 0 || self.currentGameKind != result.kind) return;
        gameSessionId = self.gameSessionId;
        source = self.currentGameSource ?: @"home";
        duration = [self currentGameDurationLocked];
        self.currentGameCompleted = YES;
    }

    NSMutableDictionary *properties = [@{
        @"source": source,
        @"durationMs": @((NSInteger)llround(duration * 1000.0)),
        @"score": @(MAX(0, result.score)),
        @"difficulty": @(MAX(0, result.difficulty)),
        @"win": @(result.win),
    } mutableCopy];
    if ([self isValidJSONObject:result.extra]) properties[@"extra"] = result.extra;

    [self enqueueEvent:@"game_finish"
                  kind:@(result.kind)
          appSessionId:[self currentAppSessionId]
         gameSessionId:gameSessionId
            properties:properties
                  date:[NSDate date]];
}

- (void)endCurrentGameSessionWithReason:(NSString *)reason {
    NSString *gameSessionId = nil;
    NSString *source = nil;
    JFGameKind kind = JFGameKindDrawBoard;
    NSTimeInterval duration = 0;
    BOOL completed = NO;

    @synchronized (self) {
        if (self.gameSessionId.length == 0) return;
        gameSessionId = self.gameSessionId;
        kind = self.currentGameKind;
        source = self.currentGameSource ?: @"home";
        duration = [self currentGameDurationLocked];
        completed = self.currentGameCompleted;

        self.gameSessionId = nil;
        self.currentGameSource = nil;
        self.gameActiveSegmentStartedAt = nil;
        self.gameActiveSeconds = 0;
        self.currentGameCompleted = NO;
    }

    [self enqueueEvent:@"game_exit"
                  kind:@(kind)
          appSessionId:[self currentAppSessionId]
         gameSessionId:gameSessionId
            properties:@{
                @"source": source,
                @"reason": [self cleanText:reason fallback:@"unknown" maxLength:40],
                @"completed": @(completed),
                @"durationMs": @((NSInteger)llround(duration * 1000.0)),
            }
                  date:[NSDate date]];
    [self flush];
}

- (NSTimeInterval)currentGameDurationLocked {
    NSTimeInterval duration = self.gameActiveSeconds;
    if (self.gameActiveSegmentStartedAt) {
        duration += MAX(0, [[NSDate date] timeIntervalSinceDate:self.gameActiveSegmentStartedAt]);
    }
    return duration;
}

#pragma mark - Generic events

- (void)trackEvent:(NSString *)name properties:(NSDictionary<NSString *,id> *)properties {
    [self enqueueEvent:name
                  kind:nil
          appSessionId:[self currentAppSessionId]
         gameSessionId:nil
            properties:properties
                  date:[NSDate date]];
}

- (void)trackEvent:(NSString *)name
          gameKind:(JFGameKind)kind
        properties:(NSDictionary<NSString *,id> *)properties {
    NSString *gameSessionId = nil;
    @synchronized (self) {
        if (self.gameSessionId.length > 0 && self.currentGameKind == kind) {
            gameSessionId = self.gameSessionId;
        }
    }
    [self enqueueEvent:name
                  kind:@(kind)
          appSessionId:[self currentAppSessionId]
         gameSessionId:gameSessionId
            properties:properties
                  date:[NSDate date]];
}

- (void)enqueueGameEvent:(NSString *)name
                    kind:(JFGameKind)kind
              properties:(NSDictionary *)properties {
    NSString *gameSessionId = nil;
    @synchronized (self) {
        gameSessionId = self.gameSessionId;
    }
    [self enqueueEvent:name
                  kind:@(kind)
          appSessionId:[self currentAppSessionId]
         gameSessionId:gameSessionId
            properties:properties
                  date:[NSDate date]];
}

- (NSString *)currentAppSessionId {
    @synchronized (self) {
        if (self.appSessionId.length == 0) {
            self.appSessionId = [[NSUUID UUID] UUIDString];
        }
        return self.appSessionId;
    }
}

#pragma mark - Queue

- (void)enqueueEvent:(NSString *)name
                 kind:(nullable NSNumber *)kind
         appSessionId:(NSString *)appSessionId
        gameSessionId:(nullable NSString *)gameSessionId
           properties:(nullable NSDictionary *)properties
                 date:(NSDate *)date {
    if (name.length == 0 || appSessionId.length == 0) return;

    NSMutableDictionary *event = [@{
        @"eventId": [[NSUUID UUID] UUIDString],
        @"appSessionId": appSessionId,
        @"name": name,
        @"platform": @"ios",
        @"appVersion": self.appVersion,
        @"occurredAt": [self isoStringFromDate:date],
    } mutableCopy];
    if (kind) event[@"kind"] = [self backendKindForGame:kind.integerValue];
    if (gameSessionId.length > 0) event[@"gameSessionId"] = gameSessionId;
    if ([self isValidJSONObject:properties]) event[@"properties"] = properties;

    dispatch_async(self.storageQueue, ^{
        [self.pendingEvents addObject:event];
        if (self.pendingEvents.count > kJFAnalyticsQueueLimit) {
            NSUInteger overflow = self.pendingEvents.count - kJFAnalyticsQueueLimit;
            [self.pendingEvents removeObjectsInRange:NSMakeRange(0, overflow)];
        }
        [self persistQueueLocked];
        [self scheduleFlushLocked];
    });
}

- (void)flush {
    dispatch_async(self.storageQueue, ^{
        [self flushLocked];
    });
}

- (void)scheduleFlushLocked {
    [self scheduleFlushLockedAfter:3.0];
}

- (void)scheduleFlushLockedAfter:(NSTimeInterval)delay {
    if (self.flushScheduled || self.flushing) return;
    self.flushScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.storageQueue, ^{
        self.flushScheduled = NO;
        [self flushLocked];
    });
}

- (void)flushLocked {
    if (self.flushing || self.pendingEvents.count == 0) return;
    self.flushing = YES;
    NSUInteger count = MIN(kJFAnalyticsBatchSize, self.pendingEvents.count);
    NSArray<NSDictionary *> *batch = [self.pendingEvents subarrayWithRange:NSMakeRange(0, count)];
    NSSet<NSString *> *eventIds = [NSSet setWithArray:[batch valueForKey:@"eventId"]];

    [[JFBackendClient shared] submitAnalyticsEvents:batch completion:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(self.storageQueue, ^{
            if (success) {
                NSIndexSet *sent = [self.pendingEvents indexesOfObjectsPassingTest:^BOOL(NSDictionary *event, NSUInteger idx, BOOL *stop) {
                    return [eventIds containsObject:event[@"eventId"]];
                }];
                [self.pendingEvents removeObjectsAtIndexes:sent];
                [self persistQueueLocked];
            }
            self.flushing = NO;
            if (success && self.pendingEvents.count > 0) {
                [self flushLocked];
            } else if (!success && self.pendingEvents.count > 0) {
                [self scheduleFlushLockedAfter:30.0];
            }
        });
    }];
}

- (void)persistQueueLocked {
    [[NSUserDefaults standardUserDefaults] setObject:self.pendingEvents forKey:kJFAnalyticsQueueKey];
}

#pragma mark - Helpers

- (NSString *)backendKindForGame:(JFGameKind)kind {
    switch (kind) {
        case JFGameKindDrawBoard: return @"DRAW_BOARD";
        case JFGameKindTruthOrDare: return @"TRUTH_OR_DARE";
        case JFGameKindDice: return @"DICE";
        case JFGameKindFiveInRow: return @"FIVE_IN_ROW";
        case JFGameKindUndercover: return @"UNDERCOVER";
        case JFGameKindKing: return @"KING";
        case JFGameKindCard: return @"CARD";
        case JFGameKindGesture: return @"GESTURE";
        case JFGameKindPuzzle: return @"PUZZLE";
        case JFGameKindSnake: return @"SNAKE";
        case JFGameKind2048: return @"GAME_2048";
        case JFGameKindSudoku: return @"SUDOKU";
        case JFGameKindMemory: return @"MEMORY";
        case JFGameKindReaction: return @"REACTION";
        case JFGameKindRhythm: return @"RHYTHM";
        case JFGameKindSokoban: return @"SOKOBAN";
        case JFGameKindPacman: return @"PACMAN";
        case JFGameKindRecommendedSocial: return @"RECOMMENDED_SOCIAL";
        case JFGameKindNeverHaveIEver: return @"NEVER_HAVE_I_EVER";
        case JFGameKindDrawGuess: return @"DRAW_GUESS";
    }
    return @"DRAW_BOARD";
}

- (NSString *)isoStringFromDate:(NSDate *)date {
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    return [formatter stringFromDate:date ?: [NSDate date]];
}

- (BOOL)isValidJSONObject:(id)object {
    return object && [NSJSONSerialization isValidJSONObject:object];
}

- (NSString *)cleanText:(NSString *)text fallback:(NSString *)fallback maxLength:(NSUInteger)maxLength {
    NSString *clean = [text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) clean = fallback;
    if (clean.length > maxLength) clean = [clean substringToIndex:maxLength];
    return clean;
}

@end
