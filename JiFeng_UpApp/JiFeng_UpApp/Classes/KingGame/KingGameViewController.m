//
//  KingGameViewController.m
//  JiFeng_UpApp
//
//  国王游戏 —— 房主分发牌,持有 K 的玩家是国王。
//  联机层使用 JFGameSession 协议(本地 Multipeer / 线上 WebSocket 可切换)。
//

#import "KingGameViewController.h"
#import "JFTheme.h"
#import "JFGameSession.h"
#import "JFPlayerSetup.h"

static NSString * const kKingGameServiceType = @"kinggame";

@interface KingGameViewController () <JFGameSessionDelegate>

// 联机
@property (nonatomic, strong) id<JFGameSession> session;
@property (nonatomic, assign) BOOL isHost;

// 数据
@property (nonatomic, copy, nullable)   NSString *receivedIdentity;
@property (nonatomic, copy, nullable)   NSString *kingCard;
@property (nonatomic, assign) NSInteger kingIndex;

// UI
@property (nonatomic, strong) UIView      *overlayView;
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UILabel     *subtitleLabel;
@property (nonatomic, strong) UIButton    *createButton;
@property (nonatomic, strong) UIButton    *joinButton;
@property (nonatomic, strong) UIButton    *startButton;
@property (nonatomic, strong) UILabel     *statusLabel;
@property (nonatomic, strong) UILabel     *identityLabel;
@property (nonatomic, strong) UIView      *identityCard;

@end

@implementation KingGameViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    [self buildBackground];
    [self buildContent];

    // 创建会话(本地)
    self.session = [JFGameSessionFactory sessionForServiceType:kKingGameServiceType mode:JFSessionModeRemote];
    self.session.delegate = self;
}

- (void)dealloc {
    [self.session stop];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [JFPlayerSetup ensureFromViewController:self completion:nil];
}

#pragma mark - UI 搭建

- (void)buildBackground {
    self.overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    [self.view addSubview:self.overlayView];
}

- (void)buildContent {
    // 返回按钮由 rootVcViewController 统一注入

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"国王游戏";
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textColor = [JFTheme textPrimary];
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.text = @"持有 K 的玩家便是国王";
    self.subtitleLabel.font = [JFTheme fontBody];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    [self.view addSubview:self.subtitleLabel];

    // 三个按钮
    self.createButton = [self primaryButtonWithTitle:@"创建房间(房主)" action:@selector(createGame)];
    self.joinButton   = [self ghostButtonWithTitle:@"加入房间(玩家)" action:@selector(joinGame)];
    self.startButton  = [self primaryButtonWithTitle:@"开始发牌" action:@selector(startGame)];
    self.startButton.hidden = YES;

    [self.view addSubview:self.createButton];
    [self.view addSubview:self.joinButton];
    [self.view addSubview:self.startButton];

    // 状态
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"";
    self.statusLabel.font = [JFTheme fontCaption];
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    // 身份卡片(发牌后展示)
    self.identityCard = [[UIView alloc] init];
    self.identityCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.identityCard.backgroundColor = [[JFTheme backgroundElevated] colorWithAlphaComponent:0.92];
    self.identityCard.layer.cornerRadius = JFRadiusLarge;
    self.identityCard.layer.cornerCurve = kCACornerCurveContinuous;
    self.identityCard.alpha = 0;
    [JFTheme applyCardShadow:self.identityCard];
    [self.view addSubview:self.identityCard];

    self.identityLabel = [[UILabel alloc] init];
    self.identityLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.identityLabel.font = [UIFont systemFontOfSize:120 weight:UIFontWeightHeavy];
    self.identityLabel.textColor = [JFTheme textPrimary];
    self.identityLabel.textAlignment = NSTextAlignmentCenter;
    [self.identityCard addSubview:self.identityLabel];

    // Layout
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:64],

        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],

        [self.createButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing24],
        [self.createButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing24],
        [self.createButton.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:JFSpacing32],
        [self.createButton.heightAnchor constraintEqualToConstant:54],

        [self.joinButton.leadingAnchor constraintEqualToAnchor:self.createButton.leadingAnchor],
        [self.joinButton.trailingAnchor constraintEqualToAnchor:self.createButton.trailingAnchor],
        [self.joinButton.topAnchor constraintEqualToAnchor:self.createButton.bottomAnchor constant:JFSpacing12],
        [self.joinButton.heightAnchor constraintEqualToConstant:54],

        [self.startButton.leadingAnchor constraintEqualToAnchor:self.createButton.leadingAnchor],
        [self.startButton.trailingAnchor constraintEqualToAnchor:self.createButton.trailingAnchor],
        [self.startButton.topAnchor constraintEqualToAnchor:self.joinButton.bottomAnchor constant:JFSpacing12],
        [self.startButton.heightAnchor constraintEqualToConstant:54],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.startButton.bottomAnchor constant:JFSpacing16],

        [self.identityCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.identityCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.identityCard.widthAnchor constraintEqualToConstant:240],
        [self.identityCard.heightAnchor constraintEqualToConstant:300],

        [self.identityLabel.centerXAnchor constraintEqualToAnchor:self.identityCard.centerXAnchor],
        [self.identityLabel.centerYAnchor constraintEqualToAnchor:self.identityCard.centerYAnchor],
        [self.identityLabel.leadingAnchor constraintEqualToAnchor:self.identityCard.leadingAnchor constant:JFSpacing16],
        [self.identityLabel.trailingAnchor constraintEqualToAnchor:self.identityCard.trailingAnchor constant:-JFSpacing16],
    ]];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)ghostButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor clearColor];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.borderWidth = 1.5;
    b.layer.borderColor = [JFTheme cardBorder].CGColor;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - 操作

- (void)createGame {
    if (![JFPlayerSetup isComplete]) {
        __weak typeof(self) weakSelf = self;
        [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
            if (complete) [weakSelf beginCreateGame];
        }];
        return;
    }
    [self beginCreateGame];
}

- (void)beginCreateGame {
    [JFTheme hapticImpactMedium];
    self.isHost = YES;
    [self.session startAsHost];
    self.createButton.hidden = YES;
    self.joinButton.hidden = YES;
    self.startButton.hidden = NO;
    self.statusLabel.text = [NSString stringWithFormat:@"%@ 已创建房间，等待玩家加入...", JFPlayerSetup.currentDisplayName];
}

- (void)joinGame {
    if (![JFPlayerSetup isComplete]) {
        __weak typeof(self) weakSelf = self;
        [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
            if (complete) [weakSelf beginJoinGame];
        }];
        return;
    }
    [self beginJoinGame];
}

- (void)beginJoinGame {
    [JFTheme hapticImpactMedium];
    self.isHost = NO;
    [self.session startAsClient];
    self.createButton.hidden = YES;
    self.joinButton.hidden = YES;
    self.startButton.hidden = YES;
    self.statusLabel.text = [NSString stringWithFormat:@"%@ 正在搜索房间...", JFPlayerSetup.currentDisplayName];
}

- (void)startGame {
    if (!self.isHost) return;

    NSInteger total = self.session.connectedPeers.count + 1;
    if (total < 2 || total > 14) {
        self.statusLabel.text = @"需要 2~14 名玩家";
        [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
        return;
    }

    NSMutableArray<NSString *> *deck = [NSMutableArray arrayWithArray:@[
        @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"A"
    ]];
    NSMutableArray<NSString *> *selected = [[deck subarrayWithRange:NSMakeRange(0, total - 1)] mutableCopy];
    [selected addObject:@"K"];
    // Fisher-Yates 洗牌
    for (NSUInteger i = selected.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [selected exchangeObjectAtIndex:i withObjectAtIndex:j];
    }

    self.kingIndex = [selected indexOfObject:@"K"];
    self.kingCard = [NSString stringWithFormat:@"%ld", (long)(self.kingIndex + 1)];

    NSArray<JFGamePeer *> *peers = self.session.connectedPeers;
    for (NSInteger i = 0; i < (NSInteger)peers.count; i++) {
        JFGameMessage *m = [JFGameMessage messageWithType:JFMessageTypeKingDeal
                                                  payload:@{ @"card": selected[i], @"displayName": peers[i].displayName ?: @"玩家" }];
        [self.session sendMessage:m toPeer:peers[i]];
    }

    self.receivedIdentity = selected[peers.count];
    [self showIdentity:self.receivedIdentity];
    self.startButton.hidden = YES;
    self.statusLabel.text = [NSString stringWithFormat:@"%@，发牌完成 · K 在第 %ld 个位置",
                             JFPlayerSetup.currentDisplayName, (long)(self.kingIndex + 1)];
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

- (void)showIdentity:(NSString *)card {
    self.identityLabel.text = card;
    // 用渐变色装饰卡片
    NSArray<UIColor *> *colors = [JFTheme gradientColorsForIndex:[card hash]];
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = CGRectMake(0, 0, 240, 300);
    grad.cornerRadius = JFRadiusLarge;
    grad.colors = @[ (__bridge id)colors.firstObject.CGColor,
                     (__bridge id)colors.lastObject.CGColor ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint   = CGPointMake(1, 1);
    // 清掉旧渐变
    for (CALayer *l in [self.identityCard.layer.sublayers copy]) {
        if ([l isKindOfClass:[CAGradientLayer class]]) [l removeFromSuperlayer];
    }
    [self.identityCard.layer insertSublayer:grad atIndex:0];

    self.identityCard.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [UIView animateWithDuration:0.55
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.7
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.identityCard.alpha = 1.0;
        self.identityCard.transform = CGAffineTransformIdentity;
    } completion:nil];
}

#pragma mark - JFGameSessionDelegate

- (void)gameSession:(id<JFGameSession>)session
               peer:(JFGamePeer *)peer
     didChangeState:(JFSessionPeerState)state {
    if (state == JFSessionPeerStateConnected) {
        if (self.isHost) {
            NSArray *names = [session.connectedPeers valueForKey:@"displayName"];
            self.statusLabel.text = [NSString stringWithFormat:@"已加入 %lu 名玩家：%@",
                                     (unsigned long)session.connectedPeers.count,
                                     [names componentsJoinedByString:@"、"]];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"%@ 已连接到房主，等待发牌...", JFPlayerSetup.currentDisplayName];
        }
    } else if (state == JFSessionPeerStateNotConnected) {
        if (self.isHost) {
            NSArray *names = [session.connectedPeers valueForKey:@"displayName"];
            self.statusLabel.text = [NSString stringWithFormat:@"当前 %lu 名玩家：%@",
                                     (unsigned long)session.connectedPeers.count,
                                     [names componentsJoinedByString:@"、"]];
        }
    }
}

- (void)gameSession:(id<JFGameSession>)session
   didReceiveMessage:(JFGameMessage *)message
            fromPeer:(JFGamePeer *)peer {
    if ([message.type isEqualToString:JFMessageTypeKingDeal]) {
        NSString *card = message.payload[@"card"];
        if (card.length > 0) {
            self.receivedIdentity = card;
            [self showIdentity:card];
            NSString *name = [message.payload[@"displayName"] isKindOfClass:[NSString class]] ? message.payload[@"displayName"] : JFPlayerSetup.currentDisplayName;
            self.statusLabel.text = [NSString stringWithFormat:@"%@，你已收到自己的牌", name];
        }
    }
}

- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"出错:%@", error.localizedDescription];
}

@end
