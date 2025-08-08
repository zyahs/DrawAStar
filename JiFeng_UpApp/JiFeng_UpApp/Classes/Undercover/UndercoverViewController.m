//
//  UndercoverViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import "UndercoverViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define SERVICE_TYPE @"undercover"

@interface UndercoverViewController () <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, UITextFieldDelegate>

@property (nonatomic, strong) MCPeerID *myPeerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;

@property (nonatomic, strong) NSMutableArray<MCPeerID *> *connectedPeers;
@property (nonatomic, assign) BOOL isHost;
@property (nonatomic, strong) UIButton *hostBtn;
@property (nonatomic, strong) UIButton *joinBtn;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) UITextField *spyCountField;
@property (nonatomic, strong) UITextField *civilCountField;
@property (nonatomic, strong) UITextField *spyWordField;
@property (nonatomic, strong) UITextField *civilWordField;
@property (nonatomic, strong) UIButton *viewIdentityBtn;
@property (nonatomic, strong) UITextView *summaryView;
@property (nonatomic, copy) NSString *identityString;



@property (nonatomic, strong) UIButton *voteButton;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *playerIdentities;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *eliminatedPlayers;
@property (nonatomic, assign) NSInteger myPlayerNumber;

@end

@implementation UndercoverViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"谁是卧底-联机Demo";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}

-(void)setupUI {
    CGFloat w = 180, h = 44, spacing = 30;
    self.hostBtn = [self buttonWithTitle:@"创建房间(房主)" frame:CGRectMake((self.view.bounds.size.width-w)/2, 100, w, h) sel:@selector(createHost)];
    self.joinBtn = [self buttonWithTitle:@"加入房间(玩家)" frame:CGRectMake((self.view.bounds.size.width-w)/2, 100+h+spacing, w, h) sel:@selector(joinHost)];
    self.startBtn = [self buttonWithTitle:@"开始游戏" frame:CGRectMake((self.view.bounds.size.width-w)/2, 100+2*(h+spacing), w, h) sel:@selector(startGame)];
    self.startBtn.enabled = NO;
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100+3*(h+spacing), self.view.bounds.size.width, 40)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor darkGrayColor];
    [self.view addSubview:self.hostBtn];
    [self.view addSubview:self.joinBtn];
    [self.view addSubview:self.startBtn];
    [self.view addSubview:self.statusLabel];
    
    // 新增输入框和按钮
    CGFloat textFieldY = CGRectGetMaxY(self.startBtn.frame) + spacing;
    self.spyCountField = [self textFieldWithPlaceholder:@"卧底人数 (留空自动判断)"];
    self.civilCountField = [self textFieldWithPlaceholder:@"平民人数 (选填)"];
    self.spyWordField = [self textFieldWithPlaceholder:@"卧底词 (留空随机)"];
    self.civilWordField = [self textFieldWithPlaceholder:@"平民词 (留空随机)"];
    NSArray *fields = @[self.spyCountField, self.civilCountField, self.spyWordField, self.civilWordField];
    for (UITextField *field in fields) {
        CGRect f = CGRectMake((self.view.bounds.size.width-w)/2, textFieldY, w, h);
        field.frame = f;
        field.delegate = self;
        field.returnKeyType = UIReturnKeyDone;
        field.hidden = YES; // 初始隐藏
        [self.view addSubview:field];
        textFieldY += h + 10;
    }
    self.viewIdentityBtn = [self buttonWithTitle:@"查看我的身份" frame:CGRectMake((self.view.bounds.size.width-w)/2, textFieldY + 20, w, h) sel:@selector(showIdentity)];
    self.viewIdentityBtn.hidden = YES;
    [self.view addSubview:self.viewIdentityBtn];
    [self.view bringSubviewToFront:self.viewIdentityBtn];
    
    CGFloat inputsBottom = CGRectGetMaxY(self.civilWordField.frame);
    self.voteButton = [self buttonWithTitle:@"开始投票" frame:CGRectMake((self.view.bounds.size.width - w)/2, inputsBottom + 20, w, h) sel:@selector(startVoting)];
    self.voteButton.hidden = !self.isHost;
    [self.view addSubview:self.voteButton];
}

// 其它方法不变...

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.placeholder = placeholder;
    tf.font = [UIFont systemFontOfSize:16];
    return tf;
}

- (UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame sel:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    btn.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:1 alpha:0.1];
    btn.layer.cornerRadius = 8;
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)createHost {
    self.isHost = YES;
    [self initSession];
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID discoveryInfo:nil serviceType:SERVICE_TYPE];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
    self.statusLabel.text = @"等待玩家加入...";
    self.startBtn.enabled = YES;
    self.hostBtn.enabled = NO;
    self.joinBtn.enabled = NO;
    for (UITextField *field in @[self.spyCountField, self.civilCountField, self.spyWordField, self.civilWordField]) {
        field.hidden = NO;
    }
}

- (void)joinHost {
    self.isHost = NO;
    [self initSession];
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerID serviceType:SERVICE_TYPE];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
    self.statusLabel.text = @"正在搜索房主...";
    self.hostBtn.enabled = NO;
    self.joinBtn.enabled = NO;
}

// 初始化会话，移除对 self.connectedPeers 的赋值和初始化，完全使用 self.session.connectedPeers
- (void)initSession {
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    self.session = [[MCSession alloc] initWithPeer:self.myPeerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    self.session.delegate = self;
}

// MARK: Host & Player 联机代理

#pragma mark - Advertiser (Host端监听)

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler {
    invitationHandler(YES, self.session);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.statusLabel setText:[NSString stringWithFormat:@"已连接: %@", peerID.displayName]];
        if (![self.connectedPeers containsObject:peerID]) {
            [self.connectedPeers addObject:peerID];
        }
    });
}

#pragma mark - Browser (玩家端寻找)

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info {
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:20];
    self.statusLabel.text = [NSString stringWithFormat:@"已发现房主: %@", peerID.displayName];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    self.statusLabel.text = @"房主离开/网络异常";
}

#pragma mark - Session Delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"连接状态变化：%@ -> %ld", peerID.displayName, (long)state);
        
        switch (state) {
            case MCSessionStateConnected:
                if (![self.connectedPeers containsObject:peerID]) {
                    [self.connectedPeers addObject:peerID];
                }
                self.statusLabel.text = [NSString stringWithFormat:@"连接: %@", peerID.displayName];
                break;
            case MCSessionStateConnecting:
                self.statusLabel.text = @"连接中...";
                break;
            case MCSessionStateNotConnected: {
                self.statusLabel.text = @"对方掉线，尝试重连...";
                [self.connectedPeers removeObject:peerID];
                // 重新开始广告或浏览
                if (self.isHost) [self.advertiser startAdvertisingPeer];
                else [self.browser startBrowsingForPeers];
                break;
            }
            default: break;
        }
    });
}

// 支持接收玩家编号数组（投票用）、身份信息字符串、投票结果等
// 支持接收玩家编号数组（投票用）、身份信息字符串、投票结果等
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    // 新增：支持 JSON 格式的身份和投票消息
    NSError *jsonError = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (!jsonError && dict && [dict isKindOfClass:[NSDictionary class]]) {
        if ([dict[@"type"] isEqualToString:@"vote"]) {
            // 主机端收到投票数据
            if (self.isHost) {
                NSInteger from = [dict[@"from"] integerValue];
                NSInteger to = [dict[@"to"] integerValue];
                NSLog(@"🗳️ 玩家投票：%ld -> %ld", (long)from, (long)to);
                if (self.isHost) {
                    NSString *logEntry = [NSString stringWithFormat:@"🗳️ 玩家%ld 投票给 玩家%ld\n", (long)from, (long)to];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.summaryView.text = [self.summaryView.text stringByAppendingString:logEntry];
                    });
                }
            }
            return;
        }
        if ([dict[@"type"] isEqualToString:@"identity"]) {
            // 客户端收到身份分发，记录玩家编号
            NSInteger number = [dict[@"number"] integerValue];
            NSString *role = dict[@"role"];
            NSString *word = dict[@"word"];
            self.myPlayerNumber = number;
            NSString *identity = [NSString stringWithFormat:@"你是第%ld号玩家\n身份：%@\n词语：%@", (long)number, role, word];
            self.identityString = identity;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.viewIdentityBtn.hidden = NO;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"你的身份" message:identity preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
            return;
        }
    }
    // 兼容原有的 NSKeyedArchiver 格式
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    // 1. 投票阶段 - 主机广播未淘汰玩家编号
    if ([object isKindOfClass:[NSArray class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showVoteButtonsForPlayerNumbers:(NSArray<NSNumber *> *)object];
        });
        return;
    }
    // 2. 客户端收到主机投票结果
    if ([object isKindOfClass:[NSDictionary class]] && !self.isHost) {
        NSDictionary *result = (NSDictionary *)object;
        NSNumber *num = result[@"voted"];
        NSString *role = result[@"role"];
        NSString *title = [role isEqualToString:@"卧底"] ? @"平民胜利" : @"继续游戏";
        NSString *msg = [NSString stringWithFormat:@"玩家%@是%@", num, role];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    // 3. 主机端收到客户端的投票（玩家编号）
    if ([object isKindOfClass:[NSNumber class]] && self.isHost) {
        NSNumber *votedNum = (NSNumber *)object;
        NSString *role = self.playerIdentities[votedNum];
        NSLog(@"[LOG] 玩家投票：%@ -> %@", votedNum, role ?: @"未知");
        NSDictionary *resultDict = @{
            @"voted": votedNum,
            @"role": role ?: @"未知"
        };
        NSData *resultData = [NSKeyedArchiver archivedDataWithRootObject:resultDict requiringSecureCoding:NO error:nil];
        [self.session sendData:resultData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
        if ([role isEqualToString:@"卧底"]) {
            [self showAlert:@"平民胜利" message:[NSString stringWithFormat:@"玩家%@是卧底", votedNum]];
        } else {
            [self.eliminatedPlayers addObject:votedNum];
            NSInteger aliveCount = self.playerIdentities.count - self.eliminatedPlayers.count;
            NSInteger spyLeft = 0;
            for (NSNumber *key in self.playerIdentities) {
                if (![self.eliminatedPlayers containsObject:key] &&
                    [self.playerIdentities[key] isEqualToString:@"卧底"]) {
                    spyLeft++;
                }
            }
            if (aliveCount <= 2 && spyLeft > 0) {
                [self showAlert:@"卧底胜利" message:@"剩下两人，卧底胜利"];
            } else {
                [self startVoting];
            }
        }
        return;
    }
    // 4. 默认处理（身份字符串）
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.identityString = msg;
        self.viewIdentityBtn.hidden = NO;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"你的身份" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {}

#pragma mark - Game 逻辑

- (void)startGame {
    if (!self.isHost) return;
    
    NSArray<MCPeerID *> *peers = self.session.connectedPeers;
    NSInteger playerCount = peers.count + 1;
    if (playerCount < 2) {
        self.statusLabel.text = @"至少2人才能开始游戏";
        return;
    }
    
    // 题库
    NSArray *wordPairs = @[
        @[@"苹果", @"香蕉"],
        @[@"飞机", @"火车"],
        @[@"篮球", @"足球"],
        @[@"铅笔", @"钢笔"],
        @[@"猫", @"狗"]
    ];
    NSString *spyWord = self.spyWordField.text.length > 0 ? self.spyWordField.text : nil;
    NSString *civilWord = self.civilWordField.text.length > 0 ? self.civilWordField.text : nil;
    if (!spyWord || !civilWord) {
        NSArray *pair = wordPairs[arc4random_uniform((uint32_t)wordPairs.count)];
        civilWord = civilWord ?: pair[0];
        spyWord = spyWord ?: pair[1];
    }
    
    NSInteger spyCount = self.spyCountField.text.integerValue;
    if (spyCount <= 0) {
        if (playerCount >= 9) spyCount = 3;
        else if (playerCount >= 6) spyCount = 2;
        else spyCount = 1;
    }
    
    NSMutableArray *allPeers = [NSMutableArray arrayWithArray:peers]; // 房主不加入
    
    self.playerIdentities = [NSMutableDictionary dictionary];
    self.eliminatedPlayers = [NSMutableSet set];
    
    NSMutableArray<NSNumber *> *spyIndexes = [NSMutableArray array];
    while (spyIndexes.count < spyCount) {
        NSInteger idx = arc4random_uniform((uint32_t)allPeers.count);
        if (![spyIndexes containsObject:@(idx)]) {
            [spyIndexes addObject:@(idx)];
        }
    }
    
    for (NSInteger i = 0; i < allPeers.count; i++) {
        BOOL isSpy = [spyIndexes containsObject:@(i)];
        NSString *word = isSpy ? spyWord : civilWord;
        NSString *role = isSpy ? @"卧底" : @"平民";
        self.playerIdentities[@(i+1)] = role;
        
        // 使用JSON格式发送身份信息
        NSDictionary *identityDict = @{
            @"type": @"identity",
            @"number": @(i + 1),
            @"role": role,
            @"word": word
        };
        NSData *identityData = [NSJSONSerialization dataWithJSONObject:identityDict options:0 error:nil];
        [self.session sendData:identityData toPeers:@[allPeers[i]] withMode:MCSessionSendDataReliable error:nil];
    }
    
    self.statusLabel.text = @"身份已分发";
    self.viewIdentityBtn.hidden = YES; // 房主无法查看身份
    
    if (self.isHost) {
        NSMutableString *summary = [NSMutableString string];
        for (NSInteger i = 0; i < allPeers.count; i++) {
            BOOL isSpy = [spyIndexes containsObject:@(i)];
            NSString *word = isSpy ? spyWord : civilWord;
            NSString *role = isSpy ? @"卧底" : @"平民";
            [summary appendFormat:@"玩家%ld：%@ - %@\n", (long)(i+1), role, word];
        }
        UITextView *summaryView = [[UITextView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.voteButton.frame) + 10, self.view.bounds.size.width - 40, 200)];
        summaryView.editable = NO;
        summaryView.text = summary;
        summaryView.font = [UIFont systemFontOfSize:16];
        summaryView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        summaryView.layer.borderWidth = 1;
        self.summaryView = summaryView;
        [self.view addSubview:summaryView];
    }
    
    // 确保投票按钮在主机可见
    if (self.isHost) {
        [self showVoteButton];
    }
}

- (void)showVoteButton {
    self.voteButton.hidden = NO;
}

// 开始投票：主机广播玩家编号，所有端展示投票按钮
- (void)startVoting {
    // 主机端广播当前所有未淘汰玩家编号
    if (self.isHost) {
        NSArray<NSNumber *> *activePlayers = [self.playerIdentities.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *num, NSDictionary *bindings) {
            return ![self.eliminatedPlayers containsObject:num];
        }]];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:activePlayers requiringSecureCoding:NO error:nil];
        [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    }
    // 主机本地也展示投票按钮
    NSArray<NSNumber *> *activePlayers = [self.playerIdentities.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *num, NSDictionary *bindings) {
        return ![self.eliminatedPlayers containsObject:num];
    }]];
    [self showVoteButtonsForPlayerNumbers:activePlayers];
}

// 新增：展示投票按钮列表，适配任意玩家数
- (void)showVoteButtonsForPlayerNumbers:(NSArray<NSNumber *> *)numbers {
    // 如果是主机，则不显示投票按钮区域
    if (self.isHost) return;
    [[self.view viewWithTag:999] removeFromSuperview];
    NSInteger count = numbers.count;
    CGFloat areaW = self.view.bounds.size.width - 40;
    CGFloat areaH = 200;
    UIView *voteView = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.viewIdentityBtn.frame) + 10, areaW, areaH)];
    voteView.tag = 999;

    // 动态布局：一行最多4个，多的分多行
    NSInteger maxCol = 4;
    NSInteger rowCount = (count + maxCol - 1) / maxCol;
    CGFloat buttonW = 60;
    CGFloat buttonH = 60;
    CGFloat spacing = 20;
    CGFloat totalHeight = rowCount * buttonH + (rowCount - 1) * spacing;
    CGFloat startY = (areaH - totalHeight) / 2;
    for (NSInteger i = 0; i < count; i++) {
        NSInteger row = i / maxCol;
        NSInteger col = i % maxCol;
        // 计算本行有多少按钮
        NSInteger buttonsInRow = (row == rowCount - 1 && count % maxCol != 0) ? (count % maxCol) : maxCol;
        CGFloat totalW = buttonsInRow * buttonW + (buttonsInRow-1)*spacing;
        CGFloat startX = (areaW - totalW) / 2;
        CGFloat x = startX + col * (buttonW + spacing);
        CGFloat y = startY + row * (buttonH + spacing);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, y, buttonW, buttonH);
        btn.layer.cornerRadius = buttonW / 2;
        btn.clipsToBounds = YES;
        btn.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:1 alpha:1];
        [btn setTitle:[NSString stringWithFormat:@"玩家%@", numbers[i]] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btn.tag = [numbers[i] integerValue];
        [btn addTarget:self action:@selector(voteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [voteView addSubview:btn];
    }
    [self.view addSubview:voteView];
}

// 投票按钮点击事件：客户端发送投票到主机
- (void)voteButtonTapped:(UIButton *)sender {
    // 客户端发起投票
    if (!self.isHost) {
        NSInteger targetIndex = sender.tag;
        NSInteger myIndex = self.myPlayerNumber;
        [self sendVoteToHost:targetIndex fromPlayer:myIndex];
        // 提交后隐藏投票按钮，防止重复投票
        [[self.view viewWithTag:999] removeFromSuperview];
    }
}

- (void)showIdentity {
    if (!self.identityString) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"我的身份" message:self.identityString preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// 其它代理方法
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = [NSString stringWithFormat:@"房主广播失败: %@", error.localizedDescription];
        NSLog(@"MCNearbyServiceAdvertiser failed: %@", error);
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = [NSString stringWithFormat:@"浏览器启动失败: %@", error.localizedDescription];
        NSLog(@"NSNetServiceBrowser did not search with error: %@", error);
    });
}



// 辅助弹窗方法
- (void)showAlert:(NSString *)title message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}


// 新增：客户端发送投票到主机
- (void)sendVoteToHost:(NSInteger)targetIndex fromPlayer:(NSInteger)myIndex {
    NSDictionary *voteDict = @{
        @"type": @"vote",
        @"from": @(myIndex),
        @"to": @(targetIndex)
    };
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:voteDict options:0 error:&error];
    if (!error && data) {
        if (self.session.connectedPeers.count > 0) {
            [self.session sendData:data
                           toPeers:self.session.connectedPeers
                          withMode:MCSessionSendDataReliable
                             error:&error];
            if (error) {
                NSLog(@"📤 投票发送失败: %@", error.localizedDescription);
            } else {
                NSLog(@"📤 投票发送成功: %@ -> %@", voteDict[@"from"], voteDict[@"to"]);
            }
        } else {
            NSLog(@"⚠️ 没有连接的主机，投票未发送");
        }
    } else {
        NSLog(@"⚠️ JSON 序列化失败: %@", error.localizedDescription);
    }
}
@end
