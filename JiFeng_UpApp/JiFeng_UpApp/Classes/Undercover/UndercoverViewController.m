//
//  UndercoverViewController.m
//  JiFeng_UpApp
//
//  谁是卧底 —— 联机层走 JFGameSession,UI 走 JFTheme。
//  消息统一为 JFGameMessage。
//

#import "UndercoverViewController.h"
#import "JFTheme.h"
#import "JFGameSession.h"

static NSString * const kServiceType = @"undercover";

@interface UndercoverViewController () <JFGameSessionDelegate, UITextFieldDelegate>

#pragma mark 联机
@property (nonatomic, strong) id<JFGameSession> session;
@property (nonatomic, assign) BOOL isHost;

#pragma mark UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIView      *contentCard;        // 玻璃卡片容器
@property (nonatomic, strong) UILabel     *titleLabel;
@property (nonatomic, strong) UILabel     *statusLabel;

@property (nonatomic, strong) UIButton    *hostBtn;
@property (nonatomic, strong) UIButton    *joinBtn;
@property (nonatomic, strong) UIButton    *startBtn;
@property (nonatomic, strong) UIButton    *voteButton;
@property (nonatomic, strong) UIButton    *viewIdentityBtn;

@property (nonatomic, strong) UITextField *spyCountField;
@property (nonatomic, strong) UITextField *civilCountField;
@property (nonatomic, strong) UITextField *spyWordField;
@property (nonatomic, strong) UITextField *civilWordField;

@property (nonatomic, strong) UITextView *summaryView;

#pragma mark 状态
@property (nonatomic, copy)   NSString *identityString;
@property (nonatomic, assign) NSInteger myPlayerNumber;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *playerIdentities; // 编号 -> 角色
@property (nonatomic, strong) NSMutableSet<NSNumber *> *eliminatedPlayers;
@property (nonatomic, strong) NSMapTable<NSNumber *, JFGamePeer *> *peerByNumber; // 编号 -> peer(房主用)

@property (nonatomic, strong) UIView *voteContainer;

@end

@implementation UndercoverViewController

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    self.session = [JFGameSessionFactory localSessionForServiceType:kServiceType];
    self.session.delegate = self;
    self.peerByNumber = [NSMapTable strongToStrongObjectsMapTable];

    [self setupBackground];
    [self setupUI];
}

- (void)dealloc {
    [self.session stop];
}

#pragma mark - 背景

- (void)setupBackground {
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"b3"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view insertSubview:self.bgImageView atIndex:0];

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:0.55];
    [self.view insertSubview:overlay aboveSubview:self.bgImageView];
}

#pragma mark - UI

- (void)setupUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // 滚动容器,避免低版本机型 / 字段全展开后内容被挤出屏幕
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    // 返回按钮由 rootVcViewController 统一注入,这里不重复加

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"谁是卧底";
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:self.titleLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"等待开始";
    self.statusLabel.font = [JFTheme fontCallout];
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.numberOfLines = 0;
    [content addSubview:self.statusLabel];

    // 主操作按钮
    self.hostBtn  = [self primaryButtonWithTitle:@"创建房间(房主)" sel:@selector(actionCreateHost)];
    self.joinBtn  = [self primaryButtonWithTitle:@"加入房间(玩家)" sel:@selector(actionJoin)];
    self.startBtn = [self primaryButtonWithTitle:@"开始游戏"        sel:@selector(actionStart)];
    self.startBtn.enabled = NO; self.startBtn.alpha = 0.5;
    self.hostBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.joinBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.startBtn.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.hostBtn, self.joinBtn, self.startBtn]];
    btnStack.axis = UILayoutConstraintAxisVertical;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFill;
    btnStack.alignment = UIStackViewAlignmentFill;
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:btnStack];

    // 输入字段
    self.spyCountField   = [self textFieldWithPlaceholder:@"卧底人数(留空自动)"];
    self.civilCountField = [self textFieldWithPlaceholder:@"平民人数(选填)"];
    self.spyWordField    = [self textFieldWithPlaceholder:@"卧底词(留空随机)"];
    self.civilWordField  = [self textFieldWithPlaceholder:@"平民词(留空随机)"];
    self.spyCountField.translatesAutoresizingMaskIntoConstraints = NO;
    self.civilCountField.translatesAutoresizingMaskIntoConstraints = NO;
    self.spyWordField.translatesAutoresizingMaskIntoConstraints = NO;
    self.civilWordField.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *fieldStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.spyCountField, self.civilCountField, self.spyWordField, self.civilWordField
    ]];
    fieldStack.axis = UILayoutConstraintAxisVertical;
    fieldStack.spacing = JFSpacing8;
    fieldStack.distribution = UIStackViewDistributionFill;
    fieldStack.alignment = UIStackViewAlignmentFill;
    fieldStack.translatesAutoresizingMaskIntoConstraints = NO;
    fieldStack.hidden = YES;
    fieldStack.tag = 9001;
    [content addSubview:fieldStack];

    // 查看身份按钮(客户端)
    self.viewIdentityBtn = [self ghostButtonWithTitle:@"查看我的身份" sel:@selector(showIdentity)];
    self.viewIdentityBtn.translatesAutoresizingMaskIntoConstraints = NO;
    self.viewIdentityBtn.hidden = YES;
    [content addSubview:self.viewIdentityBtn];

    // 投票按钮(房主)
    self.voteButton = [self primaryButtonWithTitle:@"开始投票" sel:@selector(actionStartVoting)];
    self.voteButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.voteButton.hidden = YES;
    [content addSubview:self.voteButton];

    // 房主投票汇总
    self.summaryView = [[UITextView alloc] init];
    self.summaryView.editable = NO;
    self.summaryView.font = [JFTheme fontCaption];
    self.summaryView.textColor = [JFTheme textPrimary];
    self.summaryView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
    self.summaryView.layer.cornerRadius = JFRadiusSmall;
    self.summaryView.layer.cornerCurve  = kCACornerCurveContinuous;
    self.summaryView.layer.borderWidth  = 0.5;
    self.summaryView.layer.borderColor  = [JFTheme cardBorder].CGColor;
    self.summaryView.contentInset = UIEdgeInsetsMake(JFSpacing8, JFSpacing8, JFSpacing8, JFSpacing8);
    self.summaryView.hidden = YES;
    self.summaryView.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:self.summaryView];

    // 投票按钮容器(客户端动态填充)
    self.voteContainer = [[UIView alloc] init];
    self.voteContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.voteContainer.hidden = YES;
    [content addSubview:self.voteContainer];

    [NSLayoutConstraint activateConstraints:@[
        // 滚动容器铺满 view(顶部留出返回按钮高度)
        [scroll.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:56],
        [scroll.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],

        // content 撑满 scroll 宽度
        [content.topAnchor      constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.leadingAnchor  constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.bottomAnchor   constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor    constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],

        // 标题/状态
        [self.titleLabel.topAnchor      constraintEqualToAnchor:content.topAnchor constant:JFSpacing12],
        [self.titleLabel.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],

        // 主按钮组
        [btnStack.topAnchor      constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing24],
        [btnStack.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [btnStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],
        [self.hostBtn.heightAnchor  constraintEqualToConstant:50],
        [self.joinBtn.heightAnchor  constraintEqualToConstant:50],
        [self.startBtn.heightAnchor constraintEqualToConstant:50],

        // 输入字段
        [fieldStack.topAnchor      constraintEqualToAnchor:btnStack.bottomAnchor constant:JFSpacing16],
        [fieldStack.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [fieldStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],
        [self.spyCountField.heightAnchor   constraintEqualToConstant:44],
        [self.civilCountField.heightAnchor constraintEqualToConstant:44],
        [self.spyWordField.heightAnchor    constraintEqualToConstant:44],
        [self.civilWordField.heightAnchor  constraintEqualToConstant:44],

        // 查看身份(客户端)
        [self.viewIdentityBtn.topAnchor      constraintEqualToAnchor:fieldStack.bottomAnchor constant:JFSpacing16],
        [self.viewIdentityBtn.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.viewIdentityBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],
        [self.viewIdentityBtn.heightAnchor   constraintEqualToConstant:46],

        // 开始投票(房主)
        [self.voteButton.topAnchor      constraintEqualToAnchor:self.viewIdentityBtn.bottomAnchor constant:JFSpacing12],
        [self.voteButton.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.voteButton.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],
        [self.voteButton.heightAnchor   constraintEqualToConstant:46],

        // 投票按钮容器
        [self.voteContainer.topAnchor      constraintEqualToAnchor:self.voteButton.bottomAnchor constant:JFSpacing12],
        [self.voteContainer.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.voteContainer.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],

        // 投票汇总(房主)
        [self.summaryView.topAnchor      constraintEqualToAnchor:self.voteContainer.bottomAnchor constant:JFSpacing12],
        [self.summaryView.leadingAnchor  constraintEqualToAnchor:content.leadingAnchor constant:JFSpacing20],
        [self.summaryView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-JFSpacing20],
        [self.summaryView.heightAnchor   constraintGreaterThanOrEqualToConstant:120],
        [self.summaryView.bottomAnchor   constraintEqualToAnchor:content.bottomAnchor constant:-JFSpacing24],
    ]];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)t sel:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.backgroundColor = [JFTheme brandPrimary];
    b.tintColor = [JFTheme textOnAccent];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)ghostButtonWithTitle:(NSString *)t sel:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve  = kCACornerCurveContinuous;
    b.layer.borderWidth  = 1;
    b.layer.borderColor  = [JFTheme cardBorder].CGColor;
    b.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.06];
    b.titleLabel.font    = [JFTheme fontCallout];
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.borderStyle = UITextBorderStyleNone;
    tf.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    tf.textColor = [JFTheme textPrimary];
    tf.font = [JFTheme fontBody];
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
                                                              attributes:@{NSForegroundColorAttributeName: [JFTheme textTertiary]}];
    tf.layer.cornerRadius = JFRadiusSmall;
    tf.layer.cornerCurve = kCACornerCurveContinuous;
    tf.delegate = self;
    tf.returnKeyType = UIReturnKeyDone;
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
    tf.leftView = padding; tf.leftViewMode = UITextFieldViewModeAlways;
    tf.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)]; tf.rightViewMode = UITextFieldViewModeAlways;
    return tf;
}

#pragma mark - Actions

- (void)actionCreateHost {
    [JFTheme hapticImpactMedium];
    self.isHost = YES;
    [self.session startAsHost];
    self.statusLabel.text = @"等待玩家加入...";
    self.startBtn.enabled = YES; self.startBtn.alpha = 1.0;
    self.hostBtn.enabled = NO; self.hostBtn.alpha = 0.5;
    self.joinBtn.enabled = NO; self.joinBtn.alpha = 0.5;
    [self.view viewWithTag:9001].hidden = NO;
}

- (void)actionJoin {
    [JFTheme hapticImpactMedium];
    self.isHost = NO;
    [self.session startAsClient];
    self.statusLabel.text = @"正在搜索房主...";
    self.hostBtn.enabled = NO; self.hostBtn.alpha = 0.5;
    self.joinBtn.enabled = NO; self.joinBtn.alpha = 0.5;
}

- (void)actionStart {
    if (!self.isHost) return;
    NSArray<JFGamePeer *> *peers = self.session.connectedPeers;
    NSInteger playerCount = peers.count + 1; // 含房主
    if (playerCount < 2) {
        self.statusLabel.text = @"至少 2 人才能开始";
        return;
    }

    [JFTheme hapticImpactMedium];

    // 词库
    NSArray<NSArray<NSString *> *> *wordPairs = @[
        @[@"苹果", @"香蕉"], @[@"飞机", @"火车"], @[@"篮球", @"足球"],
        @[@"铅笔", @"钢笔"], @[@"猫", @"狗"]
    ];
    NSString *spyWord   = self.spyWordField.text.length   > 0 ? self.spyWordField.text   : nil;
    NSString *civilWord = self.civilWordField.text.length > 0 ? self.civilWordField.text : nil;
    if (!spyWord || !civilWord) {
        NSArray *pair = wordPairs[arc4random_uniform((uint32_t)wordPairs.count)];
        civilWord = civilWord ?: pair[0];
        spyWord   = spyWord   ?: pair[1];
    }

    NSInteger spyCount = self.spyCountField.text.integerValue;
    if (spyCount <= 0) {
        if (playerCount >= 9) spyCount = 3;
        else if (playerCount >= 6) spyCount = 2;
        else spyCount = 1;
    }
    if (spyCount >= playerCount) spyCount = playerCount - 1;

    // 房主不参与游戏(沿用原逻辑) —— 把卧底分配给随机的客户端
    self.playerIdentities = [NSMutableDictionary dictionary];
    self.eliminatedPlayers = [NSMutableSet set];
    [self.peerByNumber removeAllObjects];

    NSMutableArray<NSNumber *> *spyIndexes = [NSMutableArray array];
    while (spyIndexes.count < spyCount) {
        NSInteger idx = arc4random_uniform((uint32_t)peers.count);
        if (![spyIndexes containsObject:@(idx)]) [spyIndexes addObject:@(idx)];
    }

    NSMutableString *summary = [NSMutableString string];
    for (NSInteger i = 0; i < peers.count; i++) {
        BOOL isSpy = [spyIndexes containsObject:@(i)];
        NSString *role = isSpy ? @"卧底" : @"平民";
        NSString *word = isSpy ? spyWord : civilWord;
        NSNumber *num  = @(i + 1);
        self.playerIdentities[num] = role;
        [self.peerByNumber setObject:peers[i] forKey:num];

        JFGameMessage *msg = [JFGameMessage messageWithType:JFMessageTypeIdentity
                                                    payload:@{@"number": num,
                                                              @"role": role,
                                                              @"word": word}];
        [self.session sendMessage:msg toPeer:peers[i]];

        [summary appendFormat:@"玩家%@:%@ - %@\n", num, role, word];
    }

    self.statusLabel.text = [NSString stringWithFormat:@"已开局 · %ld 玩家", (long)peers.count];
    self.viewIdentityBtn.hidden = YES;     // 房主无身份
    self.summaryView.hidden = NO;
    self.summaryView.text = summary;
    self.voteButton.hidden = NO;
}

- (void)actionStartVoting {
    if (!self.isHost) return;
    [JFTheme hapticImpactMedium];
    NSArray<NSNumber *> *active = [self activePlayerNumbers];

    JFGameMessage *msg = [JFGameMessage messageWithType:JFMessageTypeVoteList
                                                payload:@{@"players": active}];
    [self.session sendMessage:msg toPeer:nil]; // 广播

    NSMutableString *log = [(self.summaryView.text ?: @"") mutableCopy];
    [log appendFormat:@"\n— 投票轮 (%@) —\n", [NSDate date]];
    self.summaryView.text = log;
}

- (NSArray<NSNumber *> *)activePlayerNumbers {
    NSMutableArray *arr = [NSMutableArray array];
    for (NSNumber *n in self.playerIdentities.allKeys) {
        if (![self.eliminatedPlayers containsObject:n]) [arr addObject:n];
    }
    [arr sortUsingSelector:@selector(compare:)];
    return arr;
}

- (void)showIdentity {
    if (!self.identityString.length) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"我的身份"
                                                                   message:self.identityString
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Vote UI(客户端)

- (void)showVoteButtonsForPlayerNumbers:(NSArray<NSNumber *> *)numbers {
    if (self.isHost) return;
    [self.voteContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.voteContainer.hidden = NO;

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"投票:";
    hint.font = [JFTheme fontCallout];
    hint.textColor = [JFTheme textSecondary];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.voteContainer addSubview:hint];

    UIStackView *grid = [[UIStackView alloc] init];
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = JFSpacing8;
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    [self.voteContainer addSubview:grid];

    NSInteger maxCol = 4;
    NSInteger total = numbers.count;
    NSInteger rows = (total + maxCol - 1) / maxCol;
    NSInteger idx = 0;
    for (NSInteger r = 0; r < rows; r++) {
        UIStackView *row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = JFSpacing8;
        row.distribution = UIStackViewDistributionFillEqually;
        for (NSInteger c = 0; c < maxCol && idx < total; c++) {
            NSNumber *n = numbers[idx++];
            UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
            b.layer.cornerRadius = JFRadiusMedium;
            b.layer.cornerCurve = kCACornerCurveContinuous;
            b.backgroundColor = [JFTheme brandSecondary];
            [b.heightAnchor constraintEqualToConstant:48].active = YES;
            [b setTitle:[NSString stringWithFormat:@"#%@", n] forState:UIControlStateNormal];
            [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
            b.titleLabel.font = [JFTheme fontHeadline];
            b.tag = n.integerValue;
            [b addTarget:self action:@selector(voteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [row addArrangedSubview:b];
        }
        // 不足一行时补占位
        while (row.arrangedSubviews.count < maxCol) {
            UIView *p = [[UIView alloc] init];
            [row addArrangedSubview:p];
        }
        [grid addArrangedSubview:row];
    }

    [NSLayoutConstraint activateConstraints:@[
        [hint.topAnchor      constraintEqualToAnchor:self.voteContainer.topAnchor],
        [hint.leadingAnchor  constraintEqualToAnchor:self.voteContainer.leadingAnchor],
        [grid.topAnchor      constraintEqualToAnchor:hint.bottomAnchor constant:JFSpacing8],
        [grid.leadingAnchor  constraintEqualToAnchor:self.voteContainer.leadingAnchor],
        [grid.trailingAnchor constraintEqualToAnchor:self.voteContainer.trailingAnchor],
        [grid.bottomAnchor   constraintEqualToAnchor:self.voteContainer.bottomAnchor],
    ]];
}

- (void)voteButtonTapped:(UIButton *)sender {
    if (self.isHost) return;
    [JFTheme hapticImpactLight];
    NSInteger to = sender.tag;
    JFGameMessage *msg = [JFGameMessage messageWithType:JFMessageTypeVote
                                                payload:@{@"from": @(self.myPlayerNumber),
                                                          @"to": @(to)}];
    [self.session sendMessage:msg toPeer:nil];   // 广播,房主收
    self.voteContainer.hidden = YES;
    [self.voteContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark - JFGameSessionDelegate

- (void)gameSession:(id<JFGameSession>)session
               peer:(JFGamePeer *)peer
     didChangeState:(JFSessionPeerState)state {
    NSInteger n = self.session.connectedPeers.count;
    switch (state) {
        case JFSessionPeerStateConnected:
            self.statusLabel.text = self.isHost
                ? [NSString stringWithFormat:@"已加入 %ld 人", (long)n]
                : [NSString stringWithFormat:@"已连接到房主:%@", peer.displayName];
            break;
        case JFSessionPeerStateConnecting:
            self.statusLabel.text = @"连接中...";
            break;
        case JFSessionPeerStateNotConnected:
            self.statusLabel.text = self.isHost
                ? [NSString stringWithFormat:@"%@ 离开 · 当前 %ld 人", peer.displayName, (long)n]
                : @"连接断开,稍候重试...";
            break;
    }
}

- (void)gameSession:(id<JFGameSession>)session
  didReceiveMessage:(JFGameMessage *)message
           fromPeer:(JFGamePeer *)peer {
    NSString *type = message.type;
    NSDictionary *p = message.payload ?: @{};

    if ([type isEqualToString:JFMessageTypeIdentity] && !self.isHost) {
        // 客户端拿到身份
        NSInteger num = [p[@"number"] integerValue];
        NSString *role = p[@"role"];
        NSString *word = p[@"word"];
        self.myPlayerNumber = num;
        self.identityString = [NSString stringWithFormat:@"你是第%ld号玩家\n身份:%@\n词语:%@",
                               (long)num, role, word];
        self.viewIdentityBtn.hidden = NO;
        [self showIdentity];
        return;
    }

    if ([type isEqualToString:JFMessageTypeVoteList] && !self.isHost) {
        NSArray *players = p[@"players"] ?: @[];
        [self showVoteButtonsForPlayerNumbers:players];
        return;
    }

    if ([type isEqualToString:JFMessageTypeVote] && self.isHost) {
        [self handleVoteFrom:[p[@"from"] integerValue] target:[p[@"to"] integerValue]];
        return;
    }

    if ([type isEqualToString:JFMessageTypeVoteResult] && !self.isHost) {
        NSString *title = [p[@"role"] isEqualToString:@"卧底"] ? @"平民胜利!" : @"继续游戏";
        NSString *msg = [NSString stringWithFormat:@"玩家%@ 是 %@", p[@"voted"], p[@"role"]];
        UIAlertController *a = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }
}

- (void)handleVoteFrom:(NSInteger)from target:(NSInteger)to {
    if (!self.isHost) return;
    NSNumber *votedNum = @(to);
    NSString *role = self.playerIdentities[votedNum] ?: @"未知";

    NSString *log = [NSString stringWithFormat:@"玩家%ld 投给 玩家%ld\n", (long)from, (long)to];
    self.summaryView.text = [(self.summaryView.text ?: @"") stringByAppendingString:log];

    // 简单模式:直接把"被投者"按角色判定输赢(沿用原逻辑)
    JFGameMessage *result = [JFGameMessage messageWithType:JFMessageTypeVoteResult
                                                   payload:@{@"voted": votedNum, @"role": role}];
    [self.session sendMessage:result toPeer:nil];

    if ([role isEqualToString:@"卧底"]) {
        [self showAlert:@"平民胜利" message:[NSString stringWithFormat:@"玩家%@ 是卧底", votedNum]];
    } else {
        [self.eliminatedPlayers addObject:votedNum];
        NSInteger alive = self.playerIdentities.count - self.eliminatedPlayers.count;
        NSInteger spyLeft = 0;
        for (NSNumber *k in self.playerIdentities) {
            if (![self.eliminatedPlayers containsObject:k] &&
                [self.playerIdentities[k] isEqualToString:@"卧底"]) spyLeft++;
        }
        if (alive <= 2 && spyLeft > 0) {
            [self showAlert:@"卧底胜利" message:@"剩下两人,卧底胜利"];
        } else {
            [self actionStartVoting]; // 自动进入下一轮
        }
    }
}

- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"联机错误:%@", error.localizedDescription];
}

#pragma mark - Helpers

- (void)showAlert:(NSString *)title message:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title
                                                               message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder]; return YES;
}

@end
