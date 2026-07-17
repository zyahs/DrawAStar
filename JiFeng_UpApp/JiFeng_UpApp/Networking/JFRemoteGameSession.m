//
//  JFRemoteGameSession.m
//
//  线上联机骨架,默认走 Mock(自连自,事件本地回放)便于业务先跑通。
//  正式接入步骤详见 JFRemoteGameSession.h 顶部注释。
//

#import "JFRemoteGameSession.h"
#import "JFRemoteEndpoint.h"
#import "JFBackendClient.h"
#import "JFProfileStore.h"
#import "JFAnalyticsTracker.h"

static NSString * const kMockHostPeerId = @"mock-host";
static NSString * const kMockClientPeerId = @"mock-client";

@interface JFRemoteGameSession () <NSURLSessionWebSocketDelegate>

@property (nonatomic, copy, readwrite)   NSString *serviceType;
@property (nonatomic, assign, readwrite) JFSessionRole role;
@property (nonatomic, strong, readwrite) JFGamePeer *localPeer;

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong, nullable) NSURLSessionWebSocketTask *socketTask;
@property (nonatomic, strong) NSMutableArray<JFGamePeer *> *internalConnectedPeers;
@property (nonatomic, copy, nullable) NSString *roomId;
@property (nonatomic, assign) NSInteger latestSeq;
@property (nonatomic, strong, nullable) NSTimer *pollTimer;

@end

@implementation JFRemoteGameSession

@synthesize delegate = _delegate;

- (instancetype)initWithServiceType:(NSString *)serviceType {
    if (self = [super init]) {
        _serviceType = [serviceType copy];
        _role = JFSessionRoleNone;
        _internalConnectedPeers = [NSMutableArray array];

        _localPeer = [[JFGamePeer alloc] init];
        _localPeer.displayName = [JFProfileStore shared].displayName;
        _localPeer.peerId = [[NSUUID UUID] UUIDString];

        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest = 15;
        _urlSession = [NSURLSession sessionWithConfiguration:cfg
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

#pragma mark - JFGameSession

- (NSArray<JFGamePeer *> *)connectedPeers { return [self.internalConnectedPeers copy]; }
- (NSString *)roomCode { return self.roomId; }

- (void)refreshLocalIdentity {
    NSString *name = [JFProfileStore shared].displayName;
    self.localPeer.displayName = name.length > 0 ? name : @"新玩家";
}

- (void)startAsHost {
    [self refreshLocalIdentity];
    self.role = JFSessionRoleHost;
    if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint apiBaseURLString].length > 0) {
        [self createRemoteRoom];
    } else if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint webSocketURLString].length > 0) {
        [self connectWebSocketAsHost:YES];
    } else {
        // Mock:立刻当作"已连接到一个虚拟客户端",方便业务先跑
        [self mockConnectAsHost];
    }
}

- (void)startAsClient {
    [self refreshLocalIdentity];
    self.role = JFSessionRoleClient;
    if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint apiBaseURLString].length > 0) {
        [self joinLatestRemoteRoom];
    } else if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint webSocketURLString].length > 0) {
        [self connectWebSocketAsHost:NO];
    } else {
        [self mockConnectAsClient];
    }
}

- (void)startAsClientWithRoomCode:(NSString *)roomCode {
    NSString *normalized = [[roomCode ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if (normalized.length == 0 || ![JFRemoteEndpoint remoteEnabled] || [JFRemoteEndpoint apiBaseURLString].length == 0) {
        [self startAsClient];
        return;
    }

    [self refreshLocalIdentity];
    self.role = JFSessionRoleClient;
    [[JFBackendClient shared] ensureSignedInWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            [self emitError:error ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:401 userInfo:@{NSLocalizedDescriptionKey: @"sign in failed"}]];
            return;
        }
        [self joinRemoteRoom:normalized];
    }];
}

- (void)stop {
    [self.pollTimer invalidate];
    self.pollTimer = nil;
    [self.socketTask cancel];
    self.socketTask = nil;
    [self.internalConnectedPeers removeAllObjects];
    self.role = JFSessionRoleNone;
    self.roomId = nil;
    self.latestSeq = 0;
}

- (BOOL)sendMessage:(JFGameMessage *)message toPeer:(nullable JFGamePeer *)peer {
    if (!message.from.length) message.from = self.localPeer.peerId;
    NSData *data = [message dataRepresentation];
    if (!data) return NO;

    if (self.roomId.length > 0) {
        NSDictionary *body = @{
            @"type": message.type ?: @"",
            @"from": message.from ?: self.localPeer.peerId ?: @"",
            @"to": message.to ?: peer.peerId ?: @"",
            @"payload": message.payload ?: @{},
        };
        [self requestPath:[NSString stringWithFormat:@"/multiplayer/rooms/%@/messages", self.roomId]
                   method:@"POST"
                     body:body
               completion:nil];
        return YES;
    } else if (self.socketTask) {
        NSURLSessionWebSocketMessage *m = [[NSURLSessionWebSocketMessage alloc] initWithData:data];
        [self.socketTask sendMessage:m completionHandler:^(NSError * _Nullable error) {
            if (error) NSLog(@"[JFRemoteGameSession] send error: %@", error);
        }];
        return YES;
    }

    // Mock:本地直接回放给 delegate(模拟收到)
    JFGamePeer *fakeFrom = self.localPeer;
    JFGamePeer *fakeTo   = self.internalConnectedPeers.firstObject;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:didReceiveMessage:fromPeer:)]) {
            // 把消息当作"自己收到一份"——开发期可视化用
            [self.delegate gameSession:self didReceiveMessage:message fromPeer:fakeTo ?: fakeFrom];
        }
    });
    return YES;
}

#pragma mark - REST Rooms

- (void)createRemoteRoom {
    [[JFBackendClient shared] ensureSignedInWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            [self emitError:error ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:401 userInfo:@{NSLocalizedDescriptionKey: @"sign in failed"}]];
            return;
        }
        NSDictionary *body = @{
            @"kind": [self backendKind],
            @"displayName": self.localPeer.displayName ?: @"iPhone",
            @"serviceType": self.serviceType ?: @"",
        };
        [self requestPath:@"/multiplayer/rooms" method:@"POST" body:body completion:^(id obj, NSError *requestError) {
            if (![obj isKindOfClass:[NSDictionary class]]) {
                [self emitError:requestError ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:500 userInfo:@{NSLocalizedDescriptionKey: @"create room failed"}]];
                return;
            }
            [self handleRoomSnapshot:(NSDictionary *)obj];
            [[JFAnalyticsTracker shared] trackEvent:@"room_create"
                                           gameKind:[self analyticsGameKind]
                                         properties:@{ @"mode": self.serviceType ?: @"remote" }];
            [self startPolling];
        }];
    }];
}

- (void)joinLatestRemoteRoom {
    [[JFBackendClient shared] ensureSignedInWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            [self emitError:error ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:401 userInfo:@{NSLocalizedDescriptionKey: @"sign in failed"}]];
            return;
        }
        NSString *encodedType = [self.serviceType stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: @"";
        NSString *path = [NSString stringWithFormat:@"/multiplayer/rooms?kind=%@&serviceType=%@", [self backendKind], encodedType];
        [self requestPath:path method:@"GET" body:nil completion:^(id obj, NSError *requestError) {
            NSArray *rooms = [obj isKindOfClass:[NSArray class]] ? (NSArray *)obj : nil;
            NSDictionary *first = rooms.firstObject;
            NSString *room = [first[@"roomId"] isKindOfClass:[NSString class]] ? first[@"roomId"] : nil;
            if (room.length == 0) {
                [self emitError:requestError ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:404 userInfo:@{NSLocalizedDescriptionKey: @"no remote room"}]];
                return;
            }
            [self joinRemoteRoom:room];
        }];
    }];
}

- (void)joinRemoteRoom:(NSString *)room {
    NSDictionary *body = @{
        @"displayName": self.localPeer.displayName ?: @"iPhone",
        @"serviceType": self.serviceType ?: @"",
    };
    NSString *path = [NSString stringWithFormat:@"/multiplayer/rooms/%@/join", room];
    [self requestPath:path method:@"POST" body:body completion:^(id obj, NSError *requestError) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            [self emitError:requestError ?: [NSError errorWithDomain:@"JFRemoteGameSession" code:500 userInfo:@{NSLocalizedDescriptionKey: @"join room failed"}]];
            return;
        }
        [self handleRoomSnapshot:(NSDictionary *)obj];
        [[JFAnalyticsTracker shared] trackEvent:@"room_join"
                                       gameKind:[self analyticsGameKind]
                                     properties:@{ @"mode": self.serviceType ?: @"remote" }];
        [self startPolling];
    }];
}

- (void)startPolling {
    [self.pollTimer invalidate];
    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(pollRemoteRoom) userInfo:nil repeats:YES];
    [self pollRemoteRoom];
}

- (void)pollRemoteRoom {
    if (self.roomId.length == 0) return;
    NSString *path = [NSString stringWithFormat:@"/multiplayer/rooms/%@?since=%ld", self.roomId, (long)self.latestSeq];
    [self requestPath:path method:@"GET" body:nil completion:^(id obj, NSError *error) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [self handleRoomSnapshot:(NSDictionary *)obj];
        }
    }];
}

- (void)handleRoomSnapshot:(NSDictionary *)snapshot {
    NSString *room = [snapshot[@"roomId"] isKindOfClass:[NSString class]] ? snapshot[@"roomId"] : nil;
    if (room.length > 0) self.roomId = room;
    NSString *selfPeerId = [snapshot[@"selfPeerId"] isKindOfClass:[NSString class]] ? snapshot[@"selfPeerId"] : nil;
    if (selfPeerId.length > 0) self.localPeer.peerId = selfPeerId;

    NSArray *peers = [snapshot[@"peers"] isKindOfClass:[NSArray class]] ? snapshot[@"peers"] : @[];
    [self syncPeers:peers];

    NSArray *messages = [snapshot[@"messages"] isKindOfClass:[NSArray class]] ? snapshot[@"messages"] : @[];
    for (NSDictionary *dict in messages) {
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        NSInteger seq = [dict[@"seq"] integerValue];
        self.latestSeq = MAX(self.latestSeq, seq);
        NSString *from = [dict[@"from"] isKindOfClass:[NSString class]] ? dict[@"from"] : nil;
        NSString *to = [dict[@"to"] isKindOfClass:[NSString class]] ? dict[@"to"] : nil;
        if ([from isEqualToString:self.localPeer.peerId]) continue;
        if (to.length > 0 && ![to isEqualToString:self.localPeer.peerId]) continue;

        JFGameMessage *message = [JFGameMessage messageWithType:dict[@"type"] payload:dict[@"payload"]];
        message.from = from;
        message.to = to;
        message.timestamp = [dict[@"ts"] doubleValue];

        JFGamePeer *peer = [self peerForId:from] ?: self.localPeer;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(gameSession:didReceiveMessage:fromPeer:)]) {
                [self.delegate gameSession:self didReceiveMessage:message fromPeer:peer];
            }
        });
    }
    self.latestSeq = MAX(self.latestSeq, [snapshot[@"latestSeq"] integerValue]);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSessionDidUpdateRoom:)]) {
            [self.delegate gameSessionDidUpdateRoom:self];
        }
    });
}

- (void)syncPeers:(NSArray *)peerDicts {
    NSMutableArray<JFGamePeer *> *next = [NSMutableArray array];
    for (NSDictionary *dict in peerDicts) {
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        NSString *peerId = [dict[@"peerId"] isKindOfClass:[NSString class]] ? dict[@"peerId"] : nil;
        if (peerId.length == 0 || [peerId isEqualToString:self.localPeer.peerId]) continue;
        JFGamePeer *peer = [self peerForId:peerId] ?: [[JFGamePeer alloc] init];
        peer.peerId = peerId;
        peer.displayName = [dict[@"displayName"] isKindOfClass:[NSString class]] ? dict[@"displayName"] : peerId;
        [next addObject:peer];
        if (![self.internalConnectedPeers containsObject:peer]) {
            [self emitState:JFSessionPeerStateConnected forPeer:peer];
        }
    }
    self.internalConnectedPeers = next;
}

- (JFGamePeer *)peerForId:(NSString *)peerId {
    if (peerId.length == 0) return nil;
    for (JFGamePeer *peer in self.internalConnectedPeers) {
        if ([peer.peerId isEqualToString:peerId]) return peer;
    }
    return nil;
}

- (NSString *)backendKind {
    if ([self.serviceType isEqualToString:@"undercover"]) return @"UNDERCOVER";
    if ([self.serviceType isEqualToString:@"kinggame"]) return @"KING";
    // Room routing also includes serviceType, so use the long-supported drawing
    // enum during rolling backend deploys. Older servers reject DRAW_GUESS at DTO validation.
    if ([self.serviceType isEqualToString:@"drawguess"]) return @"DRAW_BOARD";
    if ([self.serviceType isEqualToString:@"haveyounot"]) return @"NEVER_HAVE_I_EVER";
    if ([self.serviceType hasPrefix:@"card-"]) return @"CARD";
    if ([self.serviceType hasPrefix:@"dice-"]) return @"DICE";
    return [self.serviceType uppercaseString];
}

- (JFGameKind)analyticsGameKind {
    if ([self.serviceType isEqualToString:@"undercover"]) return JFGameKindUndercover;
    if ([self.serviceType isEqualToString:@"kinggame"]) return JFGameKindKing;
    if ([self.serviceType isEqualToString:@"drawguess"]) return JFGameKindDrawGuess;
    if ([self.serviceType isEqualToString:@"haveyounot"]) return JFGameKindNeverHaveIEver;
    if ([self.serviceType hasPrefix:@"card-"]) return JFGameKindCard;
    if ([self.serviceType hasPrefix:@"dice-"]) return JFGameKindDice;
    return JFGameKindCard;
}

- (void)requestPath:(NSString *)path
             method:(NSString *)method
               body:(NSDictionary *)body
         completion:(void (^)(id obj, NSError *error))completion {
    NSString *base = [JFRemoteEndpoint apiBaseURLString];
    NSURL *url = [NSURL URLWithString:[base stringByAppendingString:path]];
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"JFRemoteGameSession" code:400 userInfo:@{NSLocalizedDescriptionKey: @"bad url"}]);
        return;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = method;
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"jf_backend_access_token"];
    if (token.length > 0) [req setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    if (body) {
        req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        id obj = nil;
        if (data.length > 0) obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        if (status < 200 || status >= 300) {
            NSString *message = [obj isKindOfClass:NSDictionary.class] && [obj[@"message"] isKindOfClass:NSString.class]
                ? obj[@"message"]
                : [NSHTTPURLResponse localizedStringForStatusCode:status];
            NSError *statusError = [NSError errorWithDomain:@"JFRemoteGameSession"
                                                       code:status
                                                   userInfo:@{NSLocalizedDescriptionKey: message ?: @"request failed"}];
            if (completion) completion(nil, statusError);
            return;
        }
        if (completion) completion(obj, nil);
    }];
    [task resume];
}

- (void)emitError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:didFailWithError:)]) {
            [self.delegate gameSession:self didFailWithError:error];
        }
    });
}

#pragma mark - Mock

- (void)mockConnectAsHost {
    JFGamePeer *fake = [[JFGamePeer alloc] init];
    fake.peerId = kMockClientPeerId;
    fake.displayName = @"Mock 玩家";
    [self.internalConnectedPeers addObject:fake];
    [self emitState:JFSessionPeerStateConnected forPeer:fake];
}
- (void)mockConnectAsClient {
    JFGamePeer *fake = [[JFGamePeer alloc] init];
    fake.peerId = kMockHostPeerId;
    fake.displayName = @"Mock 房主";
    [self.internalConnectedPeers addObject:fake];
    [self emitState:JFSessionPeerStateConnected forPeer:fake];
}

- (void)emitState:(JFSessionPeerState)state forPeer:(JFGamePeer *)peer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:peer:didChangeState:)]) {
            [self.delegate gameSession:self peer:peer didChangeState:state];
        }
    });
}

#pragma mark - WebSocket(骨架)

- (void)connectWebSocketAsHost:(BOOL)asHost {
    NSString *urlStr = [JFRemoteEndpoint webSocketURLString];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) return;

    // TODO:在 query / header 中带上服务类型、客户端版本、token 等
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:[JFRemoteEndpoint clientVersion] forHTTPHeaderField:@"X-Client-Version"];
    [req setValue:self.serviceType forHTTPHeaderField:@"X-Service-Type"];
    [req setValue:asHost ? @"host" : @"client" forHTTPHeaderField:@"X-Role"];

    self.socketTask = [self.urlSession webSocketTaskWithRequest:req];
    [self.socketTask resume];
    [self listenForServerMessages];
}

- (void)listenForServerMessages {
    __weak typeof(self) wself = self;
    [self.socketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        if (error) {
            NSLog(@"[JFRemoteGameSession] recv error: %@", error);
            return;
        }
        NSData *data = message.type == NSURLSessionWebSocketMessageTypeData
                        ? message.data
                        : [message.string dataUsingEncoding:NSUTF8StringEncoding];
        JFGameMessage *m = [JFGameMessage messageFromData:data];
        if (m) {
            JFGamePeer *from = [[JFGamePeer alloc] init];
            from.peerId = m.from ?: @"server";
            from.displayName = m.from ?: @"server";
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sself.delegate respondsToSelector:@selector(gameSession:didReceiveMessage:fromPeer:)]) {
                    [sself.delegate gameSession:sself didReceiveMessage:m fromPeer:from];
                }
            });
        }
        // 继续监听
        [sself listenForServerMessages];
    }];
}

#pragma mark - WebSocket Delegate

- (void)URLSession:(NSURLSession *)session
     webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
didOpenWithProtocol:(nullable NSString *)protocol {
    NSLog(@"[JFRemoteGameSession] WS open");
}

- (void)URLSession:(NSURLSession *)session
     webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
  didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode
            reason:(nullable NSData *)reason {
    NSLog(@"[JFRemoteGameSession] WS close %ld", (long)closeCode);
}

@end
