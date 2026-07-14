//
//  JFCardNetworkRoomViewController.m
//  JiFeng_UpApp
//

#import "JFCardNetworkRoomViewController.h"
#import "CardsGameViewController.h"
#import "JFGameSession.h"
#import "JFGameMessage.h"
#import "JFPlayerSetup.h"
#import "JFTheme.h"

@interface JFNetworkCardFace : UIView
@property (nonatomic, strong) UILabel *cornerLabel;
@property (nonatomic, strong) UILabel *centerLabel;
@property (nonatomic, strong) UIImageView *backIcon;
- (void)configureWithCard:(NSDictionary *)card faceDown:(BOOL)faceDown compact:(BOOL)compact;
@end

@implementation JFNetworkCardFace

- (instancetype)init {
    if ((self = [super init])) {
        self.layer.cornerRadius = 8;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 1;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.22;
        self.layer.shadowRadius = 6;
        self.layer.shadowOffset = CGSizeMake(0, 3);

        _cornerLabel = [[UILabel alloc] init];
        _cornerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _cornerLabel.numberOfLines = 2;
        _cornerLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_cornerLabel];

        _centerLabel = [[UILabel alloc] init];
        _centerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_centerLabel];

        _backIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"suit.club.fill"]];
        _backIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _backIcon.contentMode = UIViewContentModeScaleAspectFit;
        _backIcon.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        [self addSubview:_backIcon];

        [NSLayoutConstraint activateConstraints:@[
            [_cornerLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
            [_cornerLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            [_cornerLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:0.52],

            [_centerLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_centerLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_centerLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:8],
            [_centerLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-8],

            [_backIcon.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_backIcon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_backIcon.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.42],
            [_backIcon.heightAnchor constraintEqualToAnchor:_backIcon.widthAnchor],
        ]];
    }
    return self;
}

- (void)configureWithCard:(NSDictionary *)card faceDown:(BOOL)faceDown compact:(BOOL)compact {
    NSString *rank = [card[@"rank"] isKindOfClass:NSString.class] ? card[@"rank"] : @"?";
    NSString *suit = [card[@"suit"] isKindOfClass:NSString.class] ? card[@"suit"] : @"";
    if (faceDown) {
        self.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.96];
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.32].CGColor;
        self.cornerLabel.hidden = YES;
        self.centerLabel.hidden = YES;
        self.backIcon.hidden = NO;
        self.accessibilityLabel = @"未亮开的手牌";
        return;
    }

    BOOL red = [suit isEqualToString:@"♥"] || [suit isEqualToString:@"♦"];
    UIColor *ink = red ? [UIColor colorWithRed:0.88 green:0.10 blue:0.18 alpha:1] : [UIColor colorWithWhite:0.08 alpha:1];
    self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor;
    self.cornerLabel.hidden = NO;
    self.centerLabel.hidden = NO;
    self.backIcon.hidden = YES;
    self.cornerLabel.textColor = ink;
    self.centerLabel.textColor = ink;
    self.cornerLabel.font = [UIFont systemFontOfSize:compact ? 10 : 13 weight:UIFontWeightBold];
    self.centerLabel.font = [UIFont systemFontOfSize:compact ? 20 : 31 weight:UIFontWeightBlack];
    self.cornerLabel.text = compact ? rank : [NSString stringWithFormat:@"%@\n%@", rank, suit];
    self.centerLabel.text = suit;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@%@", rank, suit];
}

@end

@interface JFCardNetworkRoomViewController () <JFGameSessionDelegate>
@property (nonatomic, copy) NSString *gameTitle;
@property (nonatomic, copy) NSString *serviceType;
@property (nonatomic, copy) NSString *modeIdentifier;
@property (nonatomic, copy) NSString *ruleGuide;
@property (nonatomic, assign) NSInteger recommendedDealCount;
@property (nonatomic, assign) NSInteger partyMode;
@property (nonatomic, assign) BOOL startsAsHost;
@property (nonatomic, copy, nullable) NSString *requestedRoomCode;

@property (nonatomic, strong) id<JFGameSession> session;
@property (nonatomic, assign) BOOL sessionStarted;
@property (nonatomic, assign) NSInteger round;
@property (nonatomic, assign) BOOL revealSent;
@property (nonatomic, assign) BOOL roundSettled;
@property (nonatomic, copy) NSArray<NSDictionary *> *hand;
@property (nonatomic, copy) NSSet<NSString *> *expectedPeerIds;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *reveals;

@property (nonatomic, strong) UILabel *roomLabel;
@property (nonatomic, strong) UIButton *roomCopyButton;
@property (nonatomic, strong) UILabel *participantsLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *taskLabel;
@property (nonatomic, strong) UILabel *logLabel;
@property (nonatomic, strong) UIScrollView *handScrollView;
@property (nonatomic, strong) UIStackView *handStack;
@property (nonatomic, strong) UIButton *dealButton;
@property (nonatomic, strong) UIButton *revealButton;
@property (nonatomic, strong) UIButton *settleButton;
@end

@implementation JFCardNetworkRoomViewController

- (instancetype)initWithGameTitle:(NSString *)gameTitle
                       serviceType:(NSString *)serviceType
                    modeIdentifier:(NSString *)modeIdentifier
                         ruleGuide:(NSString *)ruleGuide
              recommendedDealCount:(NSInteger)recommendedDealCount
                         partyMode:(NSInteger)partyMode
                            asHost:(BOOL)asHost
                          roomCode:(NSString *)roomCode {
    if ((self = [super init])) {
        _gameTitle = [gameTitle copy];
        _serviceType = [serviceType copy];
        _modeIdentifier = [modeIdentifier copy];
        _ruleGuide = [ruleGuide copy];
        _recommendedDealCount = MAX(1, MIN(52, recommendedDealCount));
        _partyMode = partyMode;
        _startsAsHost = asHost;
        _requestedRoomCode = [[roomCode ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        _reveals = [NSMutableDictionary dictionary];
        _hand = @[];
        _expectedPeerIds = [NSSet set];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.gameTitle;
    self.session = [JFGameSessionFactory sessionForServiceType:self.serviceType mode:JFSessionModeRemote];
    self.session.delegate = self;
    [self buildUI];
    [self renderHand];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.sessionStarted) return;
    __weak typeof(self) weakSelf = self;
    [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
        if (complete) [weakSelf startSession];
    }];
}

- (void)dealloc {
    [self.session stop];
}

#pragma mark - UI

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (UIView *)separator {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [JFTheme separator];
    [line.heightAnchor constraintEqualToConstant:1].active = YES;
    return line;
}

- (UIButton *)commandButtonWithTitle:(NSString *)title symbol:(NSString *)symbol primary:(BOOL)primary action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = primary ? [JFTheme brandPrimary] : [[UIColor whiteColor] colorWithAlphaComponent:0.09];
    button.tintColor = [JFTheme textPrimary];
    button.layer.cornerRadius = 8;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1;
    button.layer.borderColor = primary ? [[JFTheme accent] colorWithAlphaComponent:0.55].CGColor : [JFTheme cardBorder].CGColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    [button setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [button.heightAnchor constraintEqualToConstant:50].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];

    UIStackView *content = [[UIStackView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 10;
    [scroll addSubview:content];

    UILabel *title = [self labelWithFont:[UIFont systemFontOfSize:28 weight:UIFontWeightBold]
                                   color:[JFTheme textPrimary]
                                   lines:1];
    title.text = self.gameTitle;
    [content addArrangedSubview:title];

    UILabel *role = [self labelWithFont:[JFTheme fontCallout] color:[JFTheme textSecondary] lines:1];
    role.text = [NSString stringWithFormat:@"%@ · %@", self.startsAsHost ? @"房主" : @"玩家", JFPlayerSetup.currentDisplayName];
    [content addArrangedSubview:role];
    [content setCustomSpacing:18 afterView:role];

    UIStackView *roomRow = [[UIStackView alloc] init];
    roomRow.axis = UILayoutConstraintAxisHorizontal;
    roomRow.alignment = UIStackViewAlignmentCenter;
    roomRow.spacing = 8;
    self.roomLabel = [self labelWithFont:[UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightBold]
                                   color:[JFTheme textPrimary]
                                   lines:1];
    self.roomLabel.text = self.startsAsHost ? @"房间码：创建中" : @"房间码：连接中";
    [roomRow addArrangedSubview:self.roomLabel];
    self.roomCopyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.roomCopyButton setImage:[UIImage systemImageNamed:@"doc.on.doc"] forState:UIControlStateNormal];
    self.roomCopyButton.tintColor = [JFTheme accent];
    self.roomCopyButton.accessibilityLabel = @"复制房间码";
    self.roomCopyButton.hidden = YES;
    [self.roomCopyButton.widthAnchor constraintEqualToConstant:44].active = YES;
    [self.roomCopyButton.heightAnchor constraintEqualToConstant:44].active = YES;
    [self.roomCopyButton addTarget:self action:@selector(copyRoomCode) forControlEvents:UIControlEventTouchUpInside];
    [roomRow addArrangedSubview:self.roomCopyButton];
    [content addArrangedSubview:roomRow];

    self.participantsLabel = [self labelWithFont:[JFTheme fontCaption] color:[JFTheme textSecondary] lines:0];
    self.participantsLabel.text = @"参与者：等待连接";
    [content addArrangedSubview:self.participantsLabel];
    [content setCustomSpacing:16 afterView:self.participantsLabel];
    UIView *firstSeparator = [self separator];
    [content addArrangedSubview:firstSeparator];
    [content setCustomSpacing:16 afterView:firstSeparator];

    UILabel *ruleTitle = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                       color:[JFTheme textPrimary]
                                       lines:1];
    ruleTitle.text = @"本桌规则";
    [content addArrangedSubview:ruleTitle];
    UILabel *rule = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textSecondary] lines:0];
    rule.text = self.ruleGuide;
    [content addArrangedSubview:rule];
    [content setCustomSpacing:18 afterView:rule];

    UILabel *handTitle = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                       color:[JFTheme textPrimary]
                                       lines:1];
    handTitle.text = @"我的手牌";
    [content addArrangedSubview:handTitle];

    self.handScrollView = [[UIScrollView alloc] init];
    self.handScrollView.showsHorizontalScrollIndicator = NO;
    self.handScrollView.alwaysBounceHorizontal = YES;
    [self.handScrollView.heightAnchor constraintEqualToConstant:140].active = YES;
    self.handStack = [[UIStackView alloc] init];
    self.handStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.handStack.axis = UILayoutConstraintAxisHorizontal;
    self.handStack.alignment = UIStackViewAlignmentCenter;
    self.handStack.spacing = 10;
    [self.handScrollView addSubview:self.handStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.handStack.topAnchor constraintEqualToAnchor:self.handScrollView.contentLayoutGuide.topAnchor],
        [self.handStack.bottomAnchor constraintEqualToAnchor:self.handScrollView.contentLayoutGuide.bottomAnchor],
        [self.handStack.leadingAnchor constraintEqualToAnchor:self.handScrollView.contentLayoutGuide.leadingAnchor],
        [self.handStack.trailingAnchor constraintEqualToAnchor:self.handScrollView.contentLayoutGuide.trailingAnchor],
        [self.handStack.heightAnchor constraintEqualToAnchor:self.handScrollView.frameLayoutGuide.heightAnchor],
    ]];
    [content addArrangedSubview:self.handScrollView];

    self.taskLabel = [self labelWithFont:[JFTheme fontCallout] color:[JFTheme textPrimary] lines:0];
    self.taskLabel.text = @"手牌会先盖住，确认后统一亮牌。";
    [content addArrangedSubview:self.taskLabel];

    self.statusLabel = [self labelWithFont:[JFTheme fontCaption] color:[JFTheme textSecondary] lines:0];
    self.statusLabel.text = self.startsAsHost ? @"正在创建线上牌桌..." : @"正在加入线上牌桌...";
    [content addArrangedSubview:self.statusLabel];
    [content setCustomSpacing:16 afterView:self.statusLabel];

    self.dealButton = [self commandButtonWithTitle:@"开始新一轮发牌" symbol:@"rectangle.stack.fill" primary:YES action:@selector(dealRound)];
    self.dealButton.enabled = NO;
    self.dealButton.hidden = !self.startsAsHost;
    [content addArrangedSubview:self.dealButton];

    self.revealButton = [self commandButtonWithTitle:@"确认并亮牌" symbol:@"eye.fill" primary:!self.startsAsHost action:@selector(revealHand)];
    self.revealButton.enabled = NO;
    [content addArrangedSubview:self.revealButton];

    self.settleButton = [self commandButtonWithTitle:@"按当前进度结算" symbol:@"checkmark.seal.fill" primary:NO action:@selector(forceSettleRound)];
    self.settleButton.hidden = !self.startsAsHost;
    self.settleButton.enabled = NO;
    [content addArrangedSubview:self.settleButton];
    [content setCustomSpacing:18 afterView:self.settleButton];
    [content addArrangedSubview:[self separator]];

    UILabel *logTitle = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                      color:[JFTheme textPrimary]
                                      lines:1];
    logTitle.text = @"牌桌记录";
    [content addArrangedSubview:logTitle];
    self.logLabel = [self labelWithFont:[JFTheme fontCaption] color:[JFTheme textSecondary] lines:0];
    self.logLabel.text = @"尚未开始发牌";
    [content addArrangedSubview:self.logLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor constant:56],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:8],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-28],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40],
    ]];
}

- (void)renderHand {
    for (UIView *view in self.handStack.arrangedSubviews.copy) {
        [self.handStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    if (self.hand.count == 0) {
        UILabel *placeholder = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textTertiary] lines:1];
        placeholder.text = @"等待房主发牌";
        [self.handStack addArrangedSubview:placeholder];
        return;
    }

    BOOL compact = self.hand.count > 10;
    CGFloat width = compact ? 54 : 82;
    CGFloat height = compact ? 84 : 118;
    for (NSDictionary *card in self.hand) {
        JFNetworkCardFace *face = [[JFNetworkCardFace alloc] init];
        [face configureWithCard:card faceDown:!self.revealSent compact:compact];
        [face.widthAnchor constraintEqualToConstant:width].active = YES;
        [face.heightAnchor constraintEqualToConstant:height].active = YES;
        [self.handStack addArrangedSubview:face];
    }
}

#pragma mark - Session

- (void)startSession {
    if (self.sessionStarted) return;
    self.sessionStarted = YES;
    if (self.startsAsHost) {
        [self.session startAsHost];
    } else if (self.requestedRoomCode.length > 0 && [self.session respondsToSelector:@selector(startAsClientWithRoomCode:)]) {
        [self.session startAsClientWithRoomCode:self.requestedRoomCode];
    } else {
        [self.session startAsClient];
    }
    [self updateParticipants];
}

- (void)updateParticipants {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (self.session.localPeer.displayName.length > 0) [names addObject:self.session.localPeer.displayName];
    for (JFGamePeer *peer in self.session.connectedPeers) {
        if (peer.displayName.length > 0) [names addObject:peer.displayName];
    }
    self.participantsLabel.text = [NSString stringWithFormat:@"参与者（%lu）：%@",
                                   (unsigned long)names.count,
                                   [names componentsJoinedByString:@"、"]];
    self.dealButton.enabled = self.startsAsHost && self.session.connectedPeers.count > 0;
}

- (void)updateRoomCode {
    NSString *code = nil;
    if ([self.session respondsToSelector:@selector(roomCode)]) code = self.session.roomCode;
    if (code.length == 0) code = self.requestedRoomCode;
    if (code.length > 0) {
        self.roomLabel.text = [NSString stringWithFormat:@"房间码：%@", code];
        self.roomCopyButton.hidden = NO;
        if (self.round == 0) {
            self.statusLabel.text = self.startsAsHost ? @"牌桌已就绪，把房间码发给其他玩家。" : @"已进入牌桌，等待房主发牌。";
        }
    }
}

- (void)copyRoomCode {
    NSString *code = nil;
    if ([self.session respondsToSelector:@selector(roomCode)]) code = self.session.roomCode;
    code = code.length > 0 ? code : self.requestedRoomCode;
    if (code.length == 0) return;
    UIPasteboard.generalPasteboard.string = code;
    self.statusLabel.text = @"房间码已复制";
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

#pragma mark - Deal

- (NSMutableArray<NSDictionary *> *)shuffledShoeForCardCount:(NSInteger)cardCount {
    NSInteger deckCount = MAX(1, (cardCount + 51) / 52);
    NSMutableArray<NSDictionary *> *shoe = [NSMutableArray arrayWithCapacity:deckCount * 52];
    for (NSInteger deck = 0; deck < deckCount; deck++) {
        for (NSString *suit in @[@"♠", @"♥", @"♦", @"♣"]) {
            for (NSString *rank in @[@"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"]) {
                [shoe addObject:@{@"rank": rank, @"suit": suit}];
            }
        }
    }
    for (NSInteger idx = shoe.count - 1; idx > 0; idx--) {
        NSInteger swap = arc4random_uniform((uint32_t)(idx + 1));
        [shoe exchangeObjectAtIndex:idx withObjectAtIndex:swap];
    }
    return shoe;
}

- (NSDictionary *)ruleForHand:(NSArray<NSDictionary *> *)hand {
    if (self.partyMode >= JFCardPartyModeMiss && self.partyMode <= JFCardPartyModeLuckyDraw && hand.count > 0) {
        NSDictionary *card = hand.firstObject;
        return [CardsGameViewController ruleForRank:card[@"rank"]
                                              suit:card[@"suit"]
                                         partyMode:(JFCardPartyMode)self.partyMode];
    }
    return @{@"title": @"本轮手牌", @"body": self.ruleGuide ?: @"按本桌规则完成本轮。"};
}

- (void)dealRound {
    if (!self.startsAsHost || self.session.connectedPeers.count == 0) {
        self.statusLabel.text = @"至少等待一名玩家加入后再发牌。";
        [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
        return;
    }

    NSArray<JFGamePeer *> *peers = self.session.connectedPeers;
    NSInteger playerCount = peers.count + 1;
    NSMutableArray<NSDictionary *> *shoe = [self shuffledShoeForCardCount:playerCount * self.recommendedDealCount];
    self.round += 1;
    self.roundSettled = NO;
    self.revealSent = NO;
    [self.reveals removeAllObjects];

    NSMutableSet<NSString *> *peerIds = [NSMutableSet setWithObject:self.session.localPeer.peerId];
    for (JFGamePeer *peer in peers) [peerIds addObject:peer.peerId];
    self.expectedPeerIds = peerIds.copy;

    JFGameMessage *roundMessage = [JFGameMessage messageWithType:JFMessageTypeCardRound
                                                         payload:@{@"round": @(self.round),
                                                                   @"game": self.modeIdentifier,
                                                                   @"dealCount": @(self.recommendedDealCount),
                                                                   @"playerCount": @(playerCount)}];
    [self.session sendMessage:roundMessage toPeer:nil];

    NSInteger cursor = 0;
    for (NSInteger index = 0; index < playerCount; index++) {
        NSArray<NSDictionary *> *hand = [shoe subarrayWithRange:NSMakeRange(cursor, self.recommendedDealCount)];
        cursor += self.recommendedDealCount;
        JFGamePeer *target = index == 0 ? nil : peers[index - 1];
        NSString *name = target ? target.displayName : self.session.localPeer.displayName;
        NSDictionary *rule = [self ruleForHand:hand];
        NSDictionary *payload = @{
            @"round": @(self.round),
            @"game": self.modeIdentifier,
            @"displayName": name ?: @"玩家",
            @"cards": hand,
            @"ruleTitle": rule[@"title"] ?: @"本轮任务",
            @"ruleBody": rule[@"body"] ?: self.ruleGuide,
        };
        if (target) {
            JFGameMessage *deal = [JFGameMessage messageWithType:JFMessageTypeCardDeal payload:payload];
            [self.session sendMessage:deal toPeer:target];
        } else {
            [self acceptDealPayload:payload];
        }
    }

    self.statusLabel.text = [NSString stringWithFormat:@"第 %ld 轮已私发给 %ld 名玩家，等待统一亮牌。",
                             (long)self.round, (long)playerCount];
    self.logLabel.text = [NSString stringWithFormat:@"第 %ld 轮：房主 %@ 完成发牌",
                          (long)self.round, self.session.localPeer.displayName];
    self.settleButton.enabled = NO;
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

- (void)acceptDealPayload:(NSDictionary *)payload {
    NSInteger incomingRound = [payload[@"round"] integerValue];
    if (incomingRound < self.round) return;
    self.round = incomingRound;
    self.hand = [payload[@"cards"] isKindOfClass:NSArray.class] ? payload[@"cards"] : @[];
    self.revealSent = NO;
    self.roundSettled = NO;
    self.revealButton.enabled = self.hand.count > 0;
    NSString *title = [payload[@"ruleTitle"] isKindOfClass:NSString.class] ? payload[@"ruleTitle"] : @"本轮任务";
    NSString *body = [payload[@"ruleBody"] isKindOfClass:NSString.class] ? payload[@"ruleBody"] : self.ruleGuide;
    self.taskLabel.text = [NSString stringWithFormat:@"%@\n%@", title, body];
    self.statusLabel.text = [NSString stringWithFormat:@"已收到第 %ld 轮手牌，确认后再亮牌。", (long)self.round];
    [self renderHand];
    [JFTheme hapticImpactMedium];
}

#pragma mark - Reveal and result

- (NSInteger)rankValue:(NSString *)rank {
    if ([rank isEqualToString:@"A"]) return 14;
    if ([rank isEqualToString:@"K"]) return 13;
    if ([rank isEqualToString:@"Q"]) return 12;
    if ([rank isEqualToString:@"J"]) return 11;
    return rank.integerValue;
}

- (NSInteger)blackjackValueForCards:(NSArray<NSDictionary *> *)cards {
    NSInteger total = 0;
    NSInteger aces = 0;
    for (NSDictionary *card in cards) {
        NSString *rank = card[@"rank"];
        if ([rank isEqualToString:@"A"]) {
            total += 11;
            aces++;
        } else if ([rank isEqualToString:@"J"] || [rank isEqualToString:@"Q"] || [rank isEqualToString:@"K"]) {
            total += 10;
        } else {
            total += rank.integerValue;
        }
    }
    while (total > 21 && aces > 0) {
        total -= 10;
        aces--;
    }
    return total;
}

- (NSInteger)scoreForCards:(NSArray<NSDictionary *> *)cards {
    if ([self.modeIdentifier isEqualToString:@"card-blackjack"]) return [self blackjackValueForCards:cards];
    NSDictionary *card = [self.modeIdentifier isEqualToString:@"card-highlow"] ? cards.lastObject : cards.firstObject;
    return [self rankValue:card[@"rank"]];
}

- (void)revealHand {
    if (self.hand.count == 0 || self.revealSent) return;
    self.revealSent = YES;
    self.revealButton.enabled = NO;
    [self renderHand];

    NSDictionary *payload = @{
        @"round": @(self.round),
        @"playerId": self.session.localPeer.peerId,
        @"displayName": self.session.localPeer.displayName ?: @"玩家",
        @"cards": self.hand,
        @"score": @([self scoreForCards:self.hand]),
    };
    if (self.startsAsHost) {
        [self registerReveal:payload fromPeerId:self.session.localPeer.peerId];
    } else {
        JFGamePeer *host = self.session.connectedPeers.firstObject;
        JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeCardReveal payload:payload];
        [self.session sendMessage:message toPeer:host];
    }
    self.statusLabel.text = @"已提交亮牌，等待房主统一公布结果。";
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

- (void)registerReveal:(NSDictionary *)payload fromPeerId:(NSString *)peerId {
    if (!self.startsAsHost || [payload[@"round"] integerValue] != self.round || peerId.length == 0) return;
    self.reveals[peerId] = payload;
    self.settleButton.enabled = self.reveals.count > 0;
    self.statusLabel.text = [NSString stringWithFormat:@"已确认 %lu / %lu 人亮牌",
                             (unsigned long)self.reveals.count,
                             (unsigned long)self.expectedPeerIds.count];
    if (self.expectedPeerIds.count > 0 && self.reveals.count >= self.expectedPeerIds.count) {
        [self settleRound];
    }
}

- (NSString *)shortCardsText:(NSArray<NSDictionary *> *)cards {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSInteger limit = MIN(5, (NSInteger)cards.count);
    for (NSInteger idx = 0; idx < limit; idx++) {
        NSDictionary *card = cards[idx];
        [parts addObject:[NSString stringWithFormat:@"%@%@", card[@"rank"] ?: @"?", card[@"suit"] ?: @""]];
    }
    if (cards.count > limit) [parts addObject:[NSString stringWithFormat:@"等 %lu 张", (unsigned long)cards.count]];
    return [parts componentsJoinedByString:@" "];
}

- (NSString *)resultSummaryForReveals:(NSArray<NSDictionary *> *)reveals {
    if (reveals.count == 0) return @"本轮没有有效亮牌。";
    if (self.partyMode >= 0) {
        return [NSString stringWithFormat:@"%lu 名玩家已亮牌，请按各自收到的任务继续本轮。", (unsigned long)reveals.count];
    }
    if ([self.modeIdentifier isEqualToString:@"card-pyramid"]) {
        return [NSString stringWithFormat:@"%lu 份金字塔牌组已确认，按本桌规则继续竞速。", (unsigned long)reveals.count];
    }

    NSInteger best = NSIntegerMin;
    NSMutableArray<NSString *> *winners = [NSMutableArray array];
    for (NSDictionary *reveal in reveals) {
        NSInteger score = [reveal[@"score"] integerValue];
        if ([self.modeIdentifier isEqualToString:@"card-blackjack"] && score > 21) continue;
        NSString *name = reveal[@"displayName"] ?: @"玩家";
        if (score > best) {
            best = score;
            [winners removeAllObjects];
            [winners addObject:name];
        } else if (score == best) {
            [winners addObject:name];
        }
    }
    if (winners.count == 0) return @"所有玩家都已爆牌，本轮无人获胜。";
    NSString *unit = [self.modeIdentifier isEqualToString:@"card-blackjack"] ? @"点" : @"点牌";
    return [NSString stringWithFormat:@"%@ 以 %ld %@获得本轮最高成绩。",
            [winners componentsJoinedByString:@"、"], (long)best, unit];
}

- (void)forceSettleRound {
    if (!self.startsAsHost || self.reveals.count == 0) return;
    [self settleRound];
}

- (void)settleRound {
    if (self.roundSettled) return;
    self.roundSettled = YES;
    NSArray<NSDictionary *> *reveals = self.reveals.allValues;
    NSString *summary = [self resultSummaryForReveals:reveals];
    NSDictionary *payload = @{@"round": @(self.round), @"summary": summary, @"reveals": reveals};
    JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeCardResult payload:payload];
    [self.session sendMessage:message toPeer:nil];
    [self displayResultPayload:payload];
}

- (void)displayResultPayload:(NSDictionary *)payload {
    NSString *summary = [payload[@"summary"] isKindOfClass:NSString.class] ? payload[@"summary"] : @"本轮结束";
    NSArray<NSDictionary *> *reveals = [payload[@"reveals"] isKindOfClass:NSArray.class] ? payload[@"reveals"] : @[];
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"第 %ld 轮 · %@", (long)[payload[@"round"] integerValue], summary]];
    for (NSDictionary *reveal in reveals) {
        NSString *name = reveal[@"displayName"] ?: @"玩家";
        NSArray *cards = [reveal[@"cards"] isKindOfClass:NSArray.class] ? reveal[@"cards"] : @[];
        [lines addObject:[NSString stringWithFormat:@"%@：%@", name, [self shortCardsText:cards]]];
    }
    self.logLabel.text = [lines componentsJoinedByString:@"\n"];
    self.statusLabel.text = summary;
    self.settleButton.enabled = NO;
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

#pragma mark - JFGameSessionDelegate

- (void)gameSessionDidUpdateRoom:(id<JFGameSession>)session {
    [self updateRoomCode];
    [self updateParticipants];
}

- (void)gameSession:(id<JFGameSession>)session
               peer:(JFGamePeer *)peer
     didChangeState:(JFSessionPeerState)state {
    [self updateParticipants];
    if (state == JFSessionPeerStateConnected && self.round == 0) {
        self.statusLabel.text = self.startsAsHost
            ? [NSString stringWithFormat:@"%@ 已加入，可以开始发牌。", peer.displayName]
            : [NSString stringWithFormat:@"已连接到房主 %@，等待发牌。", peer.displayName];
    } else if (state == JFSessionPeerStateNotConnected) {
        self.statusLabel.text = [NSString stringWithFormat:@"%@ 已离开牌桌。", peer.displayName];
    }
}

- (void)gameSession:(id<JFGameSession>)session
  didReceiveMessage:(JFGameMessage *)message
           fromPeer:(JFGamePeer *)peer {
    NSDictionary *payload = message.payload ?: @{};
    if ([message.type isEqualToString:JFMessageTypeCardRound] && !self.startsAsHost) {
        NSInteger incomingRound = [payload[@"round"] integerValue];
        if (incomingRound >= self.round) {
            self.round = incomingRound;
            self.hand = @[];
            self.revealSent = NO;
            self.revealButton.enabled = NO;
            self.statusLabel.text = [NSString stringWithFormat:@"第 %ld 轮开始，正在接收私有手牌...", (long)self.round];
            [self renderHand];
        }
        return;
    }
    if ([message.type isEqualToString:JFMessageTypeCardDeal] && !self.startsAsHost) {
        [self acceptDealPayload:payload];
        return;
    }
    if ([message.type isEqualToString:JFMessageTypeCardReveal] && self.startsAsHost) {
        [self registerReveal:payload fromPeerId:peer.peerId];
        return;
    }
    if ([message.type isEqualToString:JFMessageTypeCardResult] && !self.startsAsHost) {
        self.roundSettled = YES;
        [self displayResultPayload:payload];
    }
}

- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"联机失败：%@", error.localizedDescription ?: @"请稍后重试"];
    [JFTheme hapticNotification:UINotificationFeedbackTypeError];
}

@end
