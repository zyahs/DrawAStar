//
//  JFRemoteGameSession.m
//
//  线上联机骨架,默认走 Mock(自连自,事件本地回放)便于业务先跑通。
//  正式接入步骤详见 JFRemoteGameSession.h 顶部注释。
//

#import "JFRemoteGameSession.h"
#import "JFRemoteEndpoint.h"

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

@end

@implementation JFRemoteGameSession

@synthesize delegate = _delegate;

- (instancetype)initWithServiceType:(NSString *)serviceType {
    if (self = [super init]) {
        _serviceType = [serviceType copy];
        _role = JFSessionRoleNone;
        _internalConnectedPeers = [NSMutableArray array];

        NSString *deviceName = [UIDevice currentDevice].name ?: @"iPhone";
        _localPeer = [[JFGamePeer alloc] init];
        _localPeer.displayName = deviceName;
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

- (void)startAsHost {
    self.role = JFSessionRoleHost;
    if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint webSocketURLString].length > 0) {
        [self connectWebSocketAsHost:YES];
    } else {
        // Mock:立刻当作"已连接到一个虚拟客户端",方便业务先跑
        [self mockConnectAsHost];
    }
}

- (void)startAsClient {
    self.role = JFSessionRoleClient;
    if ([JFRemoteEndpoint remoteEnabled] && [JFRemoteEndpoint webSocketURLString].length > 0) {
        [self connectWebSocketAsHost:NO];
    } else {
        [self mockConnectAsClient];
    }
}

- (void)stop {
    [self.socketTask cancel];
    self.socketTask = nil;
    [self.internalConnectedPeers removeAllObjects];
    self.role = JFSessionRoleNone;
}

- (BOOL)sendMessage:(JFGameMessage *)message toPeer:(nullable JFGamePeer *)peer {
    if (!message.from.length) message.from = self.localPeer.peerId;
    NSData *data = [message dataRepresentation];
    if (!data) return NO;

    if (self.socketTask) {
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
