//
//  JFDiceNetworkRoomViewController.m
//  JiFeng_UpApp
//

#import "JFDiceNetworkRoomViewController.h"
#import "JFDiceRollSurface.h"
#import "JFDiceResultBoardView.h"
#import "JFGameSession.h"
#import "JFGameMessage.h"
#import "JFPlayerSetup.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFTheme.h"

@interface JFDiceNetworkRoomViewController () <JFGameSessionDelegate, JFDiceRollSurfaceDelegate>
@property (nonatomic, strong) JFDiceGameDefinition *definition;
@property (nonatomic, assign) NSInteger diceCount;
@property (nonatomic, assign) BOOL startsAsHost;
@property (nonatomic, copy) NSString *requestedRoomCode;

@property (nonatomic, strong) id<JFGameSession> session;
@property (nonatomic, assign) BOOL sessionStarted;
@property (nonatomic, assign) NSInteger round;
@property (nonatomic, assign) NSInteger reportedRound;
@property (nonatomic, assign) BOOL roundStarted;
@property (nonatomic, assign) BOOL roundSettled;
@property (nonatomic, assign) BOOL localSubmitted;
@property (nonatomic, strong) NSMutableSet<NSString *> *expectedPeerIds;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *submissions;

@property (nonatomic, strong) UILabel *roomLabel;
@property (nonatomic, strong) UILabel *roleLabel;
@property (nonatomic, strong) UIButton *roomCopyButton;
@property (nonatomic, strong) UILabel *participantsLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) JFDiceRollSurface *rollSurface;
@property (nonatomic, strong) UIButton *roundButton;
@property (nonatomic, strong) UIButton *forceRevealButton;
@property (nonatomic, strong) UILabel *instructionLabel;
@property (nonatomic, strong) JFDiceResultBoardView *resultBoard;
@end

@implementation JFDiceNetworkRoomViewController

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition
                          diceCount:(NSInteger)diceCount
                             asHost:(BOOL)asHost
                           roomCode:(NSString *)roomCode {
    if ((self = [super init])) {
        _definition = definition;
        _diceCount = MAX(1, MIN(100, diceCount));
        _startsAsHost = asHost;
        _requestedRoomCode = [[roomCode ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        _expectedPeerIds = [NSMutableSet set];
        _submissions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.definition.title;
    self.session = [JFGameSessionFactory sessionForServiceType:self.definition.serviceType mode:JFSessionModeRemote];
    self.session.delegate = self;
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    if (self.sessionStarted) return;
    __weak typeof(self) weakSelf = self;
    [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
        if (complete) [weakSelf startSession];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)dealloc {
    [self.session stop];
}

- (BOOL)canBecomeFirstResponder { return YES; }

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (UIButton *)commandButtonWithTitle:(NSString *)title symbol:(NSString *)symbol action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [JFTheme brandPrimary];
    button.tintColor = [JFTheme textPrimary];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    [button setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.58].CGColor;
    [button.heightAnchor constraintEqualToConstant:50].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)separator {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [JFTheme separator];
    [line.heightAnchor constraintEqualToConstant:1].active = YES;
    return line;
}

- (void)buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 10;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    UILabel *title = [self labelWithFont:[UIFont systemFontOfSize:28 weight:UIFontWeightBold]
                                   color:[JFTheme textPrimary]
                                   lines:1];
    title.text = self.definition.title;
    [content addArrangedSubview:title];

    self.roleLabel = [self labelWithFont:[JFTheme fontCallout] color:[JFTheme textSecondary] lines:1];
    self.roleLabel.text = [NSString stringWithFormat:@"%@ · 每人 %ld 颗", self.startsAsHost ? @"房主" : @"玩家", (long)self.diceCount];
    [content addArrangedSubview:self.roleLabel];
    [content setCustomSpacing:14 afterView:self.roleLabel];

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
    [content setCustomSpacing:14 afterView:self.participantsLabel];
    [content addArrangedSubview:[self separator]];
    [content setCustomSpacing:14 afterView:content.arrangedSubviews.lastObject];

    UILabel *rule = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textSecondary] lines:0];
    rule.text = self.definition.ruleGuide;
    [content addArrangedSubview:rule];
    [content setCustomSpacing:14 afterView:rule];

    self.statusLabel = [self labelWithFont:[UIFont systemFontOfSize:15 weight:UIFontWeightBold]
                                     color:[JFTheme textPrimary]
                                     lines:0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = self.startsAsHost ? @"正在创建线上骰桌..." : @"正在加入线上骰桌...";
    [content addArrangedSubview:self.statusLabel];

    self.resultBoard = [[JFDiceResultBoardView alloc] initWithDefinition:self.definition];
    self.resultBoard.hidden = YES;
    [content addArrangedSubview:self.resultBoard];

    self.rollSurface = [[JFDiceRollSurface alloc] initWithDiceCount:self.diceCount];
    self.rollSurface.delegate = self;
    self.rollSurface.concealsFinalResult = self.definition.mode != JFDiceGameModeLiar;
    self.rollSurface.rollEnabled = NO;
    [self.rollSurface.heightAnchor constraintEqualToConstant:329].active = YES;
    [content addArrangedSubview:self.rollSurface];

    self.roundButton = [self commandButtonWithTitle:@"开始第一轮" symbol:@"play.fill" action:@selector(startRound)];
    self.roundButton.hidden = !self.startsAsHost;
    self.roundButton.enabled = NO;
    self.roundButton.alpha = 0.38;
    [content addArrangedSubview:self.roundButton];

    self.forceRevealButton = [self commandButtonWithTitle:@"公布当前已完成结果" symbol:@"eye.fill" action:@selector(forceSettleRound)];
    self.forceRevealButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    self.forceRevealButton.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.forceRevealButton.hidden = YES;
    self.forceRevealButton.enabled = NO;
    [content addArrangedSubview:self.forceRevealButton];

    self.instructionLabel = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textPrimary] lines:0];
    self.instructionLabel.text = @"房主开局后，每个人在自己的手机上摇骰。";
    [content addArrangedSubview:self.instructionLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor constant:56],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:8],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:18],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-18],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-30],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-36],
    ]];
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

- (void)updateRoomCode {
    NSString *code = [self.session respondsToSelector:@selector(roomCode)] ? self.session.roomCode : nil;
    if (code.length == 0) code = self.requestedRoomCode;
    if (code.length == 0) return;
    self.roomLabel.text = [NSString stringWithFormat:@"房间码：%@", code];
    self.roomCopyButton.hidden = NO;
    if (!self.roundStarted) {
        self.statusLabel.text = self.startsAsHost ? @"骰桌已就绪，等待其他玩家加入。" : @"已进入骰桌，等待房主开始。";
    }
}

- (void)copyRoomCode {
    NSString *code = [self.session respondsToSelector:@selector(roomCode)] ? self.session.roomCode : nil;
    if (code.length == 0) code = self.requestedRoomCode;
    if (code.length == 0) return;
    UIPasteboard.generalPasteboard.string = code;
    self.statusLabel.text = @"房间码已复制";
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

- (void)updateParticipants {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (self.session.localPeer.displayName.length > 0) [names addObject:self.session.localPeer.displayName];
    for (JFGamePeer *peer in self.session.connectedPeers) {
        if (peer.displayName.length > 0) [names addObject:peer.displayName];
    }
    self.participantsLabel.text = [NSString stringWithFormat:@"参与者（%lu）：%@",
                                   (unsigned long)names.count,
                                   names.count ? [names componentsJoinedByString:@"、"] : @"等待连接"];

    BOOL canStart = self.startsAsHost && self.session.connectedPeers.count > 0 && (!self.roundStarted || self.roundSettled);
    self.roundButton.enabled = canStart;
    self.roundButton.alpha = canStart ? 1 : 0.38;

    if (self.startsAsHost && self.roundStarted && !self.roundSettled) {
        NSMutableSet<NSString *> *connected = [NSMutableSet setWithObject:self.session.localPeer.peerId];
        for (JFGamePeer *peer in self.session.connectedPeers) [connected addObject:peer.peerId];
        for (NSString *peerId in self.expectedPeerIds.copy) {
            BOOL alreadySubmitted = self.submissions[peerId] != nil;
            if (![connected containsObject:peerId] && !alreadySubmitted) [self.expectedPeerIds removeObject:peerId];
        }
        if (self.expectedPeerIds.count > 0 && [self completedSubmissionCount] >= self.expectedPeerIds.count) [self settleRound];
    }
}

- (NSUInteger)completedSubmissionCount {
    NSUInteger count = 0;
    for (NSString *peerId in self.expectedPeerIds) {
        if (self.submissions[peerId]) count += 1;
    }
    return count;
}

#pragma mark - Round

- (void)startRound {
    if (!self.startsAsHost || self.session.connectedPeers.count == 0) {
        self.statusLabel.text = @"至少等待一名玩家加入后再开始。";
        [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
        return;
    }
    self.round += 1;
    self.roundStarted = YES;
    self.roundSettled = NO;
    self.localSubmitted = NO;
    [self.submissions removeAllObjects];
    [self.expectedPeerIds removeAllObjects];
    [self.expectedPeerIds addObject:self.session.localPeer.peerId];
    for (JFGamePeer *peer in self.session.connectedPeers) [self.expectedPeerIds addObject:peer.peerId];

    NSDictionary *payload = @{@"round": @(self.round),
                              @"mode": self.definition.serviceType,
                              @"diceCount": @(self.diceCount),
                              @"participants": self.expectedPeerIds.allObjects};
    JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeDiceRound payload:payload];
    [self.session sendMessage:message toPeer:nil];
    [self acceptRoundPayload:payload];
    [self.roundButton setTitle:@"等待全员封盘" forState:UIControlStateNormal];
    self.roundButton.enabled = NO;
    self.roundButton.alpha = 0.38;
    self.forceRevealButton.hidden = YES;
    self.forceRevealButton.enabled = NO;
    [self.resultBoard reset];
    self.resultBoard.hidden = YES;
    self.rollSurface.hidden = NO;
    self.instructionLabel.hidden = NO;
    self.instructionLabel.text = @"所有结果会先封存；最后一名完成后自动统一公布。";
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

- (void)acceptRoundPayload:(NSDictionary *)payload {
    NSInteger incomingRound = [payload[@"round"] integerValue];
    if (incomingRound < self.round) return;
    NSArray<NSString *> *participants = [payload[@"participants"] isKindOfClass:NSArray.class] ? payload[@"participants"] : @[];
    if (participants.count > 0 && ![participants containsObject:self.session.localPeer.peerId]) {
        self.statusLabel.text = @"本轮已经开始，你将在下一轮加入。";
        self.rollSurface.rollEnabled = NO;
        return;
    }
    self.round = incomingRound;
    self.roundStarted = YES;
    self.roundSettled = NO;
    self.localSubmitted = NO;
    self.diceCount = MAX(1, MIN(100, [payload[@"diceCount"] integerValue]));
    self.roleLabel.text = [NSString stringWithFormat:@"%@ · 每人 %ld 颗", self.startsAsHost ? @"房主" : @"玩家", (long)self.diceCount];
    self.rollSurface.diceCount = self.diceCount;
    self.rollSurface.concealsFinalResult = self.definition.mode != JFDiceGameModeLiar;
    self.rollSurface.rollEnabled = YES;
    [self.rollSurface resetForNextRoll];
    [self.resultBoard reset];
    self.resultBoard.hidden = YES;
    self.rollSurface.hidden = NO;
    self.instructionLabel.hidden = NO;
    self.instructionLabel.text = @"摇定后会先封盘，全员完成再开盅。";
    self.statusLabel.text = [NSString stringWithFormat:@"第 %ld 轮 · 摇动手机开始", (long)self.round];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) [self.rollSurface beginRolling];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) [self.rollSurface beginSettlementCountdown];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) [self.rollSurface beginSettlementCountdown];
}

- (void)diceRollSurface:(JFDiceRollSurface *)surface didFinishValues:(NSArray<NSNumber *> *)values {
    if (!self.roundStarted || self.roundSettled || self.localSubmitted) return;
    self.localSubmitted = YES;
    surface.rollEnabled = NO;
    NSDictionary *payload = @{@"round": @(self.round),
                              @"playerId": self.session.localPeer.peerId,
                              @"displayName": self.session.localPeer.displayName ?: @"玩家",
                              @"values": values};
    if (self.startsAsHost) {
        [self registerSubmission:payload fromPeerId:self.session.localPeer.peerId];
    } else {
        JFGamePeer *host = self.session.connectedPeers.firstObject;
        JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeDiceSubmit payload:payload];
        [self.session sendMessage:message toPeer:host];
        self.statusLabel.text = self.definition.mode == JFDiceGameModeLiar
            ? @"已提交；保留自己的骰子，等待全员后再统一开盅。"
            : @"结果已封存并提交，等待其他玩家。";
    }
}

- (NSArray<NSNumber *> *)normalizedValues:(id)rawValues {
    NSArray *values = [rawValues isKindOfClass:NSArray.class] ? rawValues : @[];
    NSMutableArray<NSNumber *> *normalized = [NSMutableArray arrayWithCapacity:MIN(100, values.count)];
    for (id value in values) {
        if (normalized.count >= 100) break;
        NSInteger face = [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;
        if (face >= 1 && face <= 6) [normalized addObject:@(face)];
    }
    return normalized;
}

- (void)registerSubmission:(NSDictionary *)payload fromPeerId:(NSString *)peerId {
    if (!self.startsAsHost || self.roundSettled || [payload[@"round"] integerValue] != self.round) return;
    NSString *playerId = peerId;
    if (playerId.length == 0 || ![self.expectedPeerIds containsObject:playerId]) return;
    NSArray<NSNumber *> *values = [self normalizedValues:payload[@"values"]];
    if (values.count != self.diceCount) return;
    NSString *name = [payload[@"displayName"] isKindOfClass:NSString.class] ? payload[@"displayName"] : @"玩家";
    self.submissions[playerId] = @{@"playerId": playerId, @"displayName": name, @"values": values};
    self.forceRevealButton.hidden = NO;
    self.forceRevealButton.enabled = YES;
    NSUInteger completed = [self completedSubmissionCount];
    self.statusLabel.text = [NSString stringWithFormat:@"已封盘 %lu / %lu 人",
                             (unsigned long)completed,
                             (unsigned long)self.expectedPeerIds.count];
    if (self.expectedPeerIds.count > 0 && completed >= self.expectedPeerIds.count) [self settleRound];
}

- (void)forceSettleRound {
    if (!self.startsAsHost || self.roundSettled || self.submissions.count == 0) return;
    [self settleRound];
}

- (void)settleRound {
    if (!self.startsAsHost || self.roundSettled || self.submissions.count == 0) return;
    self.roundSettled = YES;
    self.forceRevealButton.hidden = YES;
    self.forceRevealButton.enabled = NO;
    NSMutableArray<NSDictionary *> *submittedResults = [NSMutableArray array];
    for (NSString *peerId in self.expectedPeerIds) {
        NSDictionary *submission = self.submissions[peerId];
        if (submission) [submittedResults addObject:submission];
    }
    NSArray<NSDictionary *> *results = [submittedResults sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"displayName"] compare:right[@"displayName"] options:NSCaseInsensitiveSearch];
    }];
    NSString *summary = [self.definition resultSummaryForResults:results];
    NSDictionary *payload = @{@"round": @(self.round), @"summary": summary, @"results": results};
    JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeDiceResult payload:payload];
    [self.session sendMessage:message toPeer:nil];
    [self displayResultPayload:payload];
}

- (void)displayResultPayload:(NSDictionary *)payload {
    NSInteger resultRound = [payload[@"round"] integerValue];
    if (resultRound < self.round) return;
    self.round = resultRound;
    self.roundStarted = YES;
    self.roundSettled = YES;
    self.forceRevealButton.hidden = YES;
    self.forceRevealButton.enabled = NO;
    self.rollSurface.rollEnabled = NO;
    [self.rollSurface revealFinalValues];

    NSString *summary = [payload[@"summary"] isKindOfClass:NSString.class] ? payload[@"summary"] : @"本轮结束";
    NSArray<NSDictionary *> *results = [payload[@"results"] isKindOfClass:NSArray.class] ? payload[@"results"] : @[];
    NSDictionary *localResult = nil;
    for (NSDictionary *result in results) {
        if ([result[@"playerId"] isEqualToString:self.session.localPeer.peerId]) localResult = result;
    }
    self.rollSurface.hidden = YES;
    self.instructionLabel.hidden = YES;
    self.resultBoard.hidden = NO;
    [self.resultBoard showResults:results summary:summary localPlayerId:self.session.localPeer.peerId];
    self.statusLabel.text = [NSString stringWithFormat:@"第 %ld 轮已统一公布", (long)self.round];
    if (self.startsAsHost) {
        [self.roundButton setTitle:@"开始下一轮" forState:UIControlStateNormal];
        self.roundButton.enabled = self.session.connectedPeers.count > 0;
        self.roundButton.alpha = self.roundButton.enabled ? 1 : 0.38;
    }
    if (localResult && self.reportedRound != self.round) {
        self.reportedRound = self.round;
        NSInteger score = 0;
        for (NSNumber *value in localResult[@"values"]) score += value.integerValue;
        JFGameResult *gameResult = [JFGameResult resultWithKind:JFGameKindDice score:score win:YES];
        gameResult.difficulty = self.diceCount;
        gameResult.extra = @{@"mode": self.definition.serviceType,
                             @"playerCount": @(results.count),
                             @"diceCount": @(self.diceCount),
                             @"online": @YES};
        [[JFProfileStore shared] reportResult:gameResult];
        [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindDice difficulty:self.diceCount score:score win:YES];
    }
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
    if (state == JFSessionPeerStateConnected && !self.roundStarted) {
        self.statusLabel.text = self.startsAsHost
            ? [NSString stringWithFormat:@"%@ 已加入，可以开局。", peer.displayName]
            : [NSString stringWithFormat:@"已连接房主 %@，等待开局。", peer.displayName];
    } else if (state == JFSessionPeerStateNotConnected) {
        self.statusLabel.text = [NSString stringWithFormat:@"%@ 已离开骰桌。", peer.displayName];
    }
}

- (void)gameSession:(id<JFGameSession>)session
  didReceiveMessage:(JFGameMessage *)message
           fromPeer:(JFGamePeer *)peer {
    NSDictionary *payload = message.payload ?: @{};
    if ([message.type isEqualToString:JFMessageTypeDiceRound] && !self.startsAsHost) {
        [self acceptRoundPayload:payload];
        return;
    }
    if ([message.type isEqualToString:JFMessageTypeDiceSubmit] && self.startsAsHost) {
        [self registerSubmission:payload fromPeerId:peer.peerId];
        return;
    }
    if ([message.type isEqualToString:JFMessageTypeDiceResult] && !self.startsAsHost) {
        [self displayResultPayload:payload];
    }
}

- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"联机失败：%@", error.localizedDescription ?: @"请稍后重试"];
    [JFTheme hapticNotification:UINotificationFeedbackTypeError];
}

@end
