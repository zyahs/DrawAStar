//
//  JFLocalGameSession.m
//

#import "JFLocalGameSession.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "JFProfileStore.h"

@interface JFLocalGameSession () <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>
@property (nonatomic, copy, readwrite)   NSString *serviceType;
@property (nonatomic, assign, readwrite) JFSessionRole role;
@property (nonatomic, strong, readwrite) JFGamePeer *localPeer;

@property (nonatomic, strong) MCPeerID  *myPeerID;
@property (nonatomic, strong) MCSession *mcSession;
@property (nonatomic, strong, nullable) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong, nullable) MCNearbyServiceBrowser    *browser;

@property (nonatomic, strong) NSMapTable<MCPeerID *, JFGamePeer *> *peerMap; // strong->strong
@end

@implementation JFLocalGameSession

@synthesize delegate = _delegate;

#pragma mark - Init

- (instancetype)initWithServiceType:(NSString *)serviceType {
    if (self = [super init]) {
        // Bonjour 服务类型限制:1–15 字符,小写字母数字与连字符
        _serviceType = [self sanitizedServiceType:serviceType];
        _role = JFSessionRoleNone;
        _peerMap = [NSMapTable strongToStrongObjectsMapTable];

        [self rebuildIdentityWithDisplayName:[self currentDisplayName]];
    }
    return self;
}

- (NSString *)sanitizedServiceType:(NSString *)raw {
    NSMutableString *s = [NSMutableString string];
    for (NSUInteger i = 0; i < raw.length && s.length < 15; i++) {
        unichar c = [raw characterAtIndex:i];
        if ((c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') ||
             c == '-') {
            [s appendFormat:@"%C", c];
        } else if (c >= 'A' && c <= 'Z') {
            [s appendFormat:@"%C", (unichar)(c + 32)];
        }
    }
    return s.length ? [s copy] : @"jfgame";
}

- (NSString *)idForPeer:(MCPeerID *)peer {
    return [NSString stringWithFormat:@"%@#%lu", peer.displayName, (unsigned long)peer.hash];
}

- (NSString *)currentDisplayName {
    NSString *name = [JFProfileStore shared].displayName;
    if (name.length == 0) name = @"新玩家";
    if (name.length > 60) name = [name substringToIndex:60];
    return name;
}

- (void)rebuildIdentityWithDisplayName:(NSString *)displayName {
    self.mcSession.delegate = nil;
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.mcSession = [[MCSession alloc] initWithPeer:self.myPeerID
                                   securityIdentity:nil
                               encryptionPreference:MCEncryptionOptional];
    self.mcSession.delegate = self;
    [self.peerMap removeAllObjects];

    self.localPeer = [[JFGamePeer alloc] init];
    self.localPeer.displayName = displayName;
    self.localPeer.peerId = [self idForPeer:self.myPeerID];
}

- (void)refreshIdentityIfNeeded {
    NSString *name = [self currentDisplayName];
    if (![self.myPeerID.displayName isEqualToString:name]) {
        [self rebuildIdentityWithDisplayName:name];
    }
}

#pragma mark - Public

- (NSArray<JFGamePeer *> *)connectedPeers {
    NSMutableArray *arr = [NSMutableArray array];
    for (MCPeerID *p in self.mcSession.connectedPeers) {
        JFGamePeer *gp = [self.peerMap objectForKey:p] ?: [self peerFromMC:p];
        [arr addObject:gp];
    }
    return arr;
}

- (JFGamePeer *)peerFromMC:(MCPeerID *)mc {
    JFGamePeer *gp = [self.peerMap objectForKey:mc];
    if (gp) return gp;
    gp = [[JFGamePeer alloc] init];
    gp.displayName = mc.displayName;
    gp.peerId = [self idForPeer:mc];
    [self.peerMap setObject:gp forKey:mc];
    return gp;
}

- (void)startAsHost {
    [self stop];
    [self refreshIdentityIfNeeded];
    self.role = JFSessionRoleHost;
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID
                                                        discoveryInfo:nil
                                                          serviceType:self.serviceType];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}

- (void)startAsClient {
    [self stop];
    [self refreshIdentityIfNeeded];
    self.role = JFSessionRoleClient;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerID
                                                    serviceType:self.serviceType];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

- (void)stop {
    [self.advertiser stopAdvertisingPeer];
    [self.browser stopBrowsingForPeers];
    self.advertiser = nil;
    self.browser = nil;
    [self.mcSession disconnect];
    // 复用同一个 mcSession 不重建,避免身份切换;如需完全重置可重新 init
    self.mcSession.delegate = self;
    self.role = JFSessionRoleNone;
}

- (BOOL)sendMessage:(JFGameMessage *)message toPeer:(nullable JFGamePeer *)peer {
    if (!message.from.length) message.from = self.localPeer.peerId;
    NSData *data = [message dataRepresentation];
    if (!data) return NO;

    NSArray<MCPeerID *> *targets;
    if (peer == nil) {
        targets = self.mcSession.connectedPeers;
    } else {
        targets = [self mcPeersForGamePeer:peer];
    }
    if (targets.count == 0) return NO;

    NSError *err = nil;
    BOOL ok = [self.mcSession sendData:data
                               toPeers:targets
                              withMode:MCSessionSendDataReliable
                                 error:&err];
    if (err) {
        NSLog(@"[JFLocalGameSession] send error: %@", err);
    }
    return ok;
}

- (NSArray<MCPeerID *> *)mcPeersForGamePeer:(JFGamePeer *)gp {
    NSMutableArray *arr = [NSMutableArray array];
    for (MCPeerID *p in self.mcSession.connectedPeers) {
        if ([[self idForPeer:p] isEqualToString:gp.peerId]) {
            [arr addObject:p];
        }
    }
    return arr;
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    JFGamePeer *gp = [self peerFromMC:peerID];
    JFSessionPeerState s;
    switch (state) {
        case MCSessionStateConnected:    s = JFSessionPeerStateConnected;    break;
        case MCSessionStateConnecting:   s = JFSessionPeerStateConnecting;   break;
        case MCSessionStateNotConnected:
        default:                          s = JFSessionPeerStateNotConnected; break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:peer:didChangeState:)]) {
            [self.delegate gameSession:self peer:gp didChangeState:s];
        }
    });
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    JFGameMessage *msg = [JFGameMessage messageFromData:data];
    if (!msg) {
        NSLog(@"[JFLocalGameSession] drop invalid msg from %@", peerID.displayName);
        return;
    }
    JFGamePeer *gp = [self peerFromMC:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:didReceiveMessage:fromPeer:)]) {
            [self.delegate gameSession:self didReceiveMessage:msg fromPeer:gp];
        }
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {}

#pragma mark - Advertiser

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    invitationHandler(YES, self.mcSession);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:didFailWithError:)]) {
            [self.delegate gameSession:self didFailWithError:error];
        }
    });
}

#pragma mark - Browser

- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info {
    [browser invitePeer:peerID toSession:self.mcSession withContext:nil timeout:20];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(gameSession:didFailWithError:)]) {
            [self.delegate gameSession:self didFailWithError:error];
        }
    });
}

@end
