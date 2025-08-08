//
//  KingGameViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

// KingGameViewController.m
#import "KingGameViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>



@interface KingGameViewController () <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, assign) BOOL isHost;
@property (nonatomic, strong) NSMutableArray<MCPeerID *> *connectedPeers;

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UILabel *identityLabel;

@property (nonatomic, strong) NSString *receivedIdentity;
@property (nonatomic, strong) NSString *kingCard;

@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIButton *joinButton;

@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, assign) NSInteger kingIndex;

@end

@implementation KingGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = UIColor.whiteColor;
    
//    CAGradientLayer *gradient = [ColorButton createFancyAnimatedGradientForView:self.view];
//    [self.view.layer insertSublayer:gradient atIndex:0];
    
    self.connectedPeers = [NSMutableArray array];
    
    self.peerID = [[MCPeerID alloc] initWithDisplayName:UIDevice.currentDevice.name];
    self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    self.session.delegate = self;

    NSString *serviceType = @"kinggame"; // <= 确保合法

    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:serviceType];
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceType];

    self.advertiser.delegate = self;
    self.browser.delegate = self;

    [self setupUI];
}

- (void)setupUI {
    self.identityLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.identityLabel.font = [UIFont boldSystemFontOfSize:100];
    self.identityLabel.textAlignment = NSTextAlignmentCenter;
    self.identityLabel.alpha = 0;
    [self.view addSubview:self.identityLabel];

    [self setupCommonConnectionUI];
}

- (void)setupCommonConnectionUI {
    CGFloat w = 180, h = 44, spacing = 30;
    self.createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.createButton.frame = CGRectMake((self.view.bounds.size.width - w) / 2, 100, w, h);
    [self.createButton setTitle:@"创建房间(房主)" forState:UIControlStateNormal];
    [self.createButton addTarget:self action:@selector(createGame) forControlEvents:UIControlEventTouchUpInside];
    
    self.joinButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.joinButton.frame = CGRectMake((self.view.bounds.size.width - w) / 2, 100 + h + spacing, w, h);
    [self.joinButton setTitle:@"加入房间(玩家)" forState:UIControlStateNormal];
    [self.joinButton addTarget:self action:@selector(joinGame) forControlEvents:UIControlEventTouchUpInside];
    
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.frame = CGRectMake((self.view.bounds.size.width - w) / 2, 100 + 2 * (h + spacing), w, h);
    [self.startButton setTitle:@"开始游戏" forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
    self.startButton.enabled = NO;
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100 + 3 * (h + spacing), self.view.bounds.size.width, 40)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor darkGrayColor];
    
    [self.view addSubview:self.createButton];
    [self.view addSubview:self.joinButton];
    [self.view addSubview:self.startButton];
    [self.view addSubview:self.statusLabel];
}

- (void)createGame {
    self.isHost = YES;
    [self.advertiser startAdvertisingPeer];
    self.advertiser.delegate = self;
    self.session.delegate = self;
    self.createButton.hidden = YES;
    self.joinButton.hidden = YES;
    self.startButton.hidden = NO;
    self.statusLabel.text = @"等待玩家加入...";
    self.startButton.enabled = YES;
}

- (void)joinGame {
    self.isHost = NO;
    [self.browser startBrowsingForPeers];
    self.browser.delegate = self;
    self.session.delegate = self;
    self.createButton.hidden = YES;
    self.joinButton.hidden = YES;
    self.startButton.hidden = YES;
    self.statusLabel.text = @"Enjoy Games";
}

- (void)startGame {
    if (!self.isHost) return;
    
    NSInteger count = self.connectedPeers.count + 1;
    if (count < 1 || count > 14) return;

    NSMutableArray *deck = [NSMutableArray arrayWithArray:@[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"A"]];
    [deck removeObject:@"K"];
    NSMutableArray *selected = [[deck subarrayWithRange:NSMakeRange(0, count - 1)] mutableCopy];
    [selected addObject:@"K"];
    for (NSUInteger i = selected.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [selected exchangeObjectAtIndex:i withObjectAtIndex:j];
    }

    self.kingIndex = [selected indexOfObject:@"K"];
    self.kingCard = [NSString stringWithFormat:@"%ld", (long)(self.kingIndex + 1)];

    // 分发身份
    NSArray *peers = self.session.connectedPeers;
    for (int i = 0; i < peers.count; i++) {
        NSData *data = [selected[i] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        [self.session sendData:data toPeers:@[peers[i]] withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"发送失败给 %@", error);
        } else {
            NSLog(@"已发送 %@", selected[i]);
        }
    }

    self.receivedIdentity = selected[peers.count];
    self.identityLabel.text = self.receivedIdentity;
    self.identityLabel.alpha = 1;
    self.view.backgroundColor = [self randomGradient];
//    self.viewKingButton.hidden = YES;  房主不显示查看按钮
}


#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (state == MCSessionStateConnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.connectedPeers containsObject:peerID]) {
                [self.connectedPeers addObject:peerID];
            }
            if (self.isHost) {
                self.statusLabel.text = [NSString stringWithFormat:@"当前已加入玩家人数: %lu", (unsigned long)self.connectedPeers.count];
            }
            NSLog(@"已连接到玩家: %@", peerID.displayName);
        });
    }
    else if (state == MCSessionStateNotConnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connectedPeers removeObject:peerID];
            if (self.isHost) {
                self.statusLabel.text = [NSString stringWithFormat:@"当前已加入玩家人数: %lu", (unsigned long)self.connectedPeers.count];
            }
        });
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSString *identity = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到身份信息: %@", identity);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.receivedIdentity = identity;
        self.identityLabel.text = identity;
        self.identityLabel.alpha = 1;
        self.view.backgroundColor = [self randomGradient];
        [self.view bringSubviewToFront:self.identityLabel];
    });
}

- (UIColor *)randomGradient {
    CGFloat red = arc4random_uniform(256) / 255.0;
    CGFloat green = arc4random_uniform(256) / 255.0;
    CGFloat blue = arc4random_uniform(256) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

#pragma mark - Other required protocol stubs
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    invitationHandler(YES, self.session);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"Advertiser failed to start: %@", error);
}

#pragma mark - MCNearbyServiceBrowserDelegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info {
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:10];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"Browser failed to start: %@", error);
}

@end
