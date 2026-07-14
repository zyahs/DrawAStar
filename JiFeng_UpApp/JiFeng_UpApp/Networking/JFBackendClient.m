//
//  JFBackendClient.m
//  JiFeng_UpApp
//

#import "JFBackendClient.h"
#import "JFAnalyticsTracker.h"
#import <UIKit/UIKit.h>
#import <math.h>

NSNotificationName const JFBackendAuthDidChangeNotification = @"JFBackendAuthDidChangeNotification";

static NSString * const kJFBackendBaseURL = @"https://zy-fbdy.com/jifeng-api";
static NSString * const kJFBackendAccessTokenKey = @"jf_backend_access_token";
static NSString * const kJFBackendRefreshTokenKey = @"jf_backend_refresh_token";
static NSString * const kJFBackendUserIdKey = @"jf_backend_user_id";
static NSString * const kJFBackendGuestDeviceIdKey = @"jf_backend_guest_device_id";

@interface JFBackendClient ()
@property (nonatomic, copy, nullable) NSString *accessToken;
@property (nonatomic, copy, nullable) NSString *refreshToken;
@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, assign) BOOL signingIn;
@property (nonatomic, strong) NSMutableArray<void (^)(BOOL, NSError * _Nullable)> *pendingSignInCompletions;
@end

@implementation JFBackendClient

+ (instancetype)shared {
    static JFBackendClient *client;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        client = [[self alloc] init];
    });
    return client;
}

- (instancetype)init {
    if (self = [super init]) {
        _baseURLString = kJFBackendBaseURL;
        _pendingSignInCompletions = [NSMutableArray array];
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _accessToken = [ud stringForKey:kJFBackendAccessTokenKey];
        _refreshToken = [ud stringForKey:kJFBackendRefreshTokenKey];
        _userId = [ud stringForKey:kJFBackendUserIdKey];
    }
    return self;
}

- (void)configureDefault {
    self.baseURLString = kJFBackendBaseURL;
}

- (BOOL)signedIn {
    return self.accessToken.length > 0 && self.userId.length > 0;
}

#pragma mark - Auth

- (void)ensureSignedInWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.signedIn) {
        if (completion) completion(YES, nil);
        return;
    }

    @synchronized (self) {
        if (completion) [self.pendingSignInCompletions addObject:[completion copy]];
        if (self.signingIn) return;
        self.signingIn = YES;
    }

    if (self.refreshToken.length > 0) {
        [self refreshAccessTokenWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self finishSignIn:YES error:nil];
            } else {
                [self guestLoginWithCompletion:^(BOOL guestSuccess, NSError * _Nullable guestError) {
                    [self finishSignIn:guestSuccess error:guestError ?: error];
                }];
            }
        }];
    } else {
        [self guestLoginWithCompletion:^(BOOL success, NSError * _Nullable error) {
            [self finishSignIn:success error:error];
        }];
    }
}

- (void)finishSignIn:(BOOL)success error:(NSError *)error {
    NSArray<void (^)(BOOL, NSError * _Nullable)> *completions = nil;
    @synchronized (self) {
        self.signingIn = NO;
        completions = [self.pendingSignInCompletions copy];
        [self.pendingSignInCompletions removeAllObjects];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:JFBackendAuthDidChangeNotification object:self];
        }
        for (void (^block)(BOOL, NSError * _Nullable) in completions) {
            block(success, error);
        }
    });
}

- (void)guestLoginWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSDictionary *body = @{
        @"deviceId": [self guestDeviceId],
        @"deviceName": [[UIDevice currentDevice] name] ?: @"iPhone",
    };
    [self rawRequestPath:@"/auth/guest" method:@"POST" body:body auth:NO completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable error) {
        if (error || status < 200 || status >= 300 || ![obj isKindOfClass:[NSDictionary class]]) {
            if (completion) completion(NO, error ?: [self errorWithCode:status message:@"guest login failed"]);
            return;
        }
        [self persistAuthResponse:(NSDictionary *)obj];
        if (completion) completion(self.signedIn, nil);
    }];
}

- (void)refreshAccessTokenWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.refreshToken.length == 0) {
        if (completion) completion(NO, [self errorWithCode:401 message:@"missing refresh token"]);
        return;
    }
    [self rawRequestPath:@"/auth/refresh" method:@"POST" body:@{@"refreshToken": self.refreshToken} auth:NO completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable error) {
        if (error || status < 200 || status >= 300 || ![obj isKindOfClass:[NSDictionary class]]) {
            if (completion) completion(NO, error ?: [self errorWithCode:status message:@"refresh failed"]);
            return;
        }
        NSDictionary *dict = (NSDictionary *)obj;
        NSString *token = [dict[@"accessToken"] isKindOfClass:[NSString class]] ? dict[@"accessToken"] : nil;
        if (token.length > 0) {
            self.accessToken = token;
            [[NSUserDefaults standardUserDefaults] setObject:token forKey:kJFBackendAccessTokenKey];
        }
        NSDictionary *user = [dict[@"user"] isKindOfClass:[NSDictionary class]] ? dict[@"user"] : nil;
        NSString *uid = [user[@"id"] isKindOfClass:[NSString class]] ? user[@"id"] : nil;
        if (uid.length > 0) {
            self.userId = uid;
            [[NSUserDefaults standardUserDefaults] setObject:uid forKey:kJFBackendUserIdKey];
        }
        if (completion) completion(self.accessToken.length > 0, nil);
    }];
}

- (void)persistAuthResponse:(NSDictionary *)dict {
    NSString *access = [dict[@"accessToken"] isKindOfClass:[NSString class]] ? dict[@"accessToken"] : nil;
    NSString *refresh = [dict[@"refreshToken"] isKindOfClass:[NSString class]] ? dict[@"refreshToken"] : nil;
    NSDictionary *user = [dict[@"user"] isKindOfClass:[NSDictionary class]] ? dict[@"user"] : nil;
    NSString *uid = [user[@"id"] isKindOfClass:[NSString class]] ? user[@"id"] : nil;

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (access.length > 0) {
        self.accessToken = access;
        [ud setObject:access forKey:kJFBackendAccessTokenKey];
    }
    if (refresh.length > 0) {
        self.refreshToken = refresh;
        [ud setObject:refresh forKey:kJFBackendRefreshTokenKey];
    }
    if (uid.length > 0) {
        self.userId = uid;
        [ud setObject:uid forKey:kJFBackendUserIdKey];
    }
}

- (NSString *)guestDeviceId {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *saved = [ud stringForKey:kJFBackendGuestDeviceIdKey];
    if (saved.length > 0) return saved;

    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *deviceId = identifier.length > 0 ? identifier : [[NSUUID UUID] UUIDString];
    [ud setObject:deviceId forKey:kJFBackendGuestDeviceIdKey];
    return deviceId;
}

#pragma mark - Profile

- (void)fetchProfileWithCompletion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [self requestPath:@"/me" method:@"GET" body:nil retry:YES completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable error) {
        if (completion) completion([obj isKindOfClass:[NSDictionary class]] ? obj : nil, error ?: (status >= 400 ? [self errorWithCode:status message:@"fetch profile failed"] : nil));
    }];
}

- (void)updateProfile:(NSDictionary *)profile completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self requestPath:@"/me" method:@"PATCH" body:profile retry:YES completion:^(__unused id obj, NSInteger status, NSError * _Nullable error) {
        if (completion) completion(!error && status >= 200 && status < 300, error);
    }];
}

#pragma mark - Chat

- (void)fetchChatMessagesInRoom:(NSString *)room
                            take:(NSInteger)take
                      completion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    NSString *cleanRoom = [self urlEncoded:room.length > 0 ? room : @"global"];
    NSString *path = [NSString stringWithFormat:@"/chat/messages?room=%@&take=%ld", cleanRoom, (long)MAX(1, take)];
    [self requestPath:path method:@"GET" body:nil retry:YES completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable error) {
        if (error || status < 200 || status >= 300 || ![obj isKindOfClass:[NSArray class]]) {
            if (completion) completion(nil, error ?: [self errorWithCode:status message:@"fetch chat failed"]);
            return;
        }
        if (completion) completion((NSArray<NSDictionary *> *)obj, nil);
    }];
}

- (void)sendChatMessage:(NSString *)content
                 inRoom:(NSString *)room
             completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSString *text = [content ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        if (completion) completion(NO, [self errorWithCode:0 message:@"empty message"]);
        return;
    }
    NSDictionary *body = @{@"room": room.length > 0 ? room : @"global", @"content": text};
    [self requestPath:@"/chat/messages" method:@"POST" body:body retry:YES completion:^(__unused id obj, NSInteger status, NSError * _Nullable error) {
        BOOL ok = !error && status >= 200 && status < 300;
        if (ok) [[JFAnalyticsTracker shared] trackEvent:@"chat_send" properties:nil];
        if (completion) completion(ok, ok ? nil : error ?: [self errorWithCode:status message:@"send chat failed"]);
    }];
}

#pragma mark - Analytics

- (void)submitAnalyticsEvents:(NSArray<NSDictionary *> *)events
                    completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (events.count == 0) {
        if (completion) completion(YES, nil);
        return;
    }
    [self requestPath:@"/analytics/events/batch"
               method:@"POST"
                 body:@{ @"events": events }
                retry:YES
           completion:^(__unused id obj, NSInteger status, NSError * _Nullable error) {
        BOOL ok = !error && status >= 200 && status < 300;
        if (completion) completion(ok, ok ? nil : error ?: [self errorWithCode:status message:@"analytics upload failed"]);
    }];
}

#pragma mark - Leaderboard

- (void)submitScore:(NSInteger)score
            forGame:(JFGameKind)kind
         difficulty:(NSInteger)difficulty
            duration:(NSTimeInterval)duration
                 win:(BOOL)win
               extra:(NSDictionary<NSString *,id> *)extra
         completion:(JFLeaderboardSubmitCompletion)completion {
    NSMutableDictionary *body = [@{
        @"kind": [self backendKindForGame:kind],
        @"score": @(MAX(0, score)),
        @"difficulty": @(MAX(0, difficulty)),
        @"durationMs": @((NSInteger)llround(MAX(0, duration) * 1000.0)),
        @"win": @(win),
    } mutableCopy];
    if (extra && [NSJSONSerialization isValidJSONObject:extra]) body[@"extra"] = extra;
    [self requestPath:@"/games/records" method:@"POST" body:body retry:YES completion:^(__unused id obj, NSInteger status, NSError * _Nullable error) {
        BOOL ok = !error && status >= 200 && status < 300;
        if (completion) completion(ok, ok ? nil : error ?: [self errorWithCode:status message:@"submit score failed"]);
    }];
}

- (void)fetchTopScoresForGame:(JFGameKind)kind
                    difficulty:(NSInteger)difficulty
                         limit:(NSInteger)limit
                    completion:(JFLeaderboardFetchCompletion)completion {
    NSString *path = [NSString stringWithFormat:@"/games/leaderboard?kind=%@&take=%ld", [self backendKindForGame:kind], (long)MAX(1, limit)];
    [self requestPath:path method:@"GET" body:nil retry:YES completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable error) {
        if (error || status < 200 || status >= 300 || ![obj isKindOfClass:[NSArray class]]) {
            if (completion) completion(nil, nil, error ?: [self errorWithCode:status message:@"fetch leaderboard failed"]);
            return;
        }

        NSMutableArray<JFLeaderboardEntry *> *entries = [NSMutableArray array];
        JFLeaderboardEntry *myEntry = nil;
        NSArray *raw = (NSArray *)obj;
        NSInteger rank = 1;
        for (NSDictionary *item in raw) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *user = [item[@"user"] isKindOfClass:[NSDictionary class]] ? item[@"user"] : @{};
            JFLeaderboardEntry *entry = [[JFLeaderboardEntry alloc] init];
            entry.playerId = [user[@"id"] isKindOfClass:[NSString class]] ? user[@"id"] : @"";
            entry.displayName = [user[@"displayName"] isKindOfClass:[NSString class]] ? user[@"displayName"] : @"继风玩家";
            entry.score = [item[@"score"] integerValue];
            entry.rank = rank++;
            entry.date = [NSDate date];
            entry.isMe = self.userId.length > 0 && [entry.playerId isEqualToString:self.userId];
            if (entry.isMe) myEntry = entry;
            [entries addObject:entry];
        }
        if (completion) completion(entries, myEntry, nil);
    }];
}

- (NSString *)playerId {
    return self.userId ?: [self guestDeviceId];
}

- (NSString *)displayName {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"jf_backend_display_name"] ?: @"我";
}

- (void)setDisplayName:(NSString *)name {
    if (name.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"jf_backend_display_name"];
    [self updateProfile:@{@"displayName": name} completion:nil];
}

#pragma mark - HTTP

- (void)requestPath:(NSString *)path
             method:(NSString *)method
               body:(NSDictionary * _Nullable)body
              retry:(BOOL)retry
         completion:(void (^)(id _Nullable obj, NSInteger status, NSError * _Nullable error))completion {
    [self ensureSignedInWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            if (completion) completion(nil, 0, error);
            return;
        }
        [self rawRequestPath:path method:method body:body auth:YES completion:^(id  _Nullable obj, NSInteger status, NSError * _Nullable requestError) {
            if (status == 401 && retry && self.refreshToken.length > 0) {
                [self refreshAccessTokenWithCompletion:^(BOOL refreshed, NSError * _Nullable refreshError) {
                    if (!refreshed) {
                        if (completion) completion(nil, 401, refreshError ?: requestError);
                        return;
                    }
                    [self requestPath:path method:method body:body retry:NO completion:completion];
                }];
                return;
            }
            if (completion) completion(obj, status, requestError);
        }];
    }];
}

- (void)rawRequestPath:(NSString *)path
                method:(NSString *)method
                  body:(NSDictionary * _Nullable)body
                  auth:(BOOL)auth
            completion:(void (^)(id _Nullable obj, NSInteger status, NSError * _Nullable error))completion {
    NSString *base = [self.baseURLString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSString *full = [base stringByAppendingString:path ?: @""];
    NSURL *url = [NSURL URLWithString:full];
    if (!url) {
        if (completion) completion(nil, 0, [self errorWithCode:0 message:@"bad url"]);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method ?: @"GET";
    request.timeoutInterval = 15;
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    if (auth && self.accessToken.length > 0) {
        [request setValue:[@"Bearer " stringByAppendingString:self.accessToken] forHTTPHeaderField:@"authorization"];
    }
    if (body) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        id obj = nil;
        if (data.length > 0) {
            obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }
        if (completion) completion(obj, status, error);
    }];
    [task resume];
}

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"JFBackendClient"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"backend error"}];
}

- (NSString *)urlEncoded:(NSString *)value {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

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
    }
}

@end
