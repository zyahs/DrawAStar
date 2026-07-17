//
//  JFNeverHaveIEverViewController.m
//  JiFeng_UpApp
//

#import "JFNeverHaveIEverViewController.h"
#import "JFTheme.h"
#import "JFSkinStore.h"
#import "JFProfileStore.h"
#import "JFPlayerSetup.h"
#import "JFAnalyticsTracker.h"
#import "JFGameSession.h"

static NSString * const JFHaveYouNotServiceType = @"haveyounot";
static NSString * const JFHaveYouNotPhaseLobby = @"lobby";
static NSString * const JFHaveYouNotPhaseStatement = @"statement";
static NSString * const JFHaveYouNotPhaseVoting = @"voting";
static NSString * const JFHaveYouNotPhaseResult = @"result";
static NSString * const JFHaveYouNotPhaseFinished = @"finished";

#pragma mark - Player

@interface JFHaveYouNotPlayer : NSObject
@property (nonatomic, copy) NSString *peerId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger fingers;
@end

@implementation JFHaveYouNotPlayer
@end

#pragma mark - Finger hand

@interface JFHaveYouNotHandView : UIView
@property (nonatomic, assign) NSInteger activeCount;
@property (nonatomic, assign) BOOL losingFinger;
@end

@implementation JFHaveYouNotHandView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        _activeCount = 5;
    }
    return self;
}

- (void)setActiveCount:(NSInteger)activeCount {
    _activeCount = MAX(0, MIN(5, activeCount));
    [self setNeedsDisplay];
}

- (void)setLosingFinger:(BOOL)losingFinger {
    _losingFinger = losingFinger;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    if (width <= 0 || height <= 0) return;

    CGFloat gap = MAX(2, width * 0.025);
    CGFloat padding = width * 0.08;
    CGFloat fingerWidth = (width - padding * 2 - gap * 4) / 5.0;
    CGFloat baseY = height * 0.72;
    NSArray<NSNumber *> *heightFactors = @[@0.48, @0.67, @0.78, @0.68, @0.52];
    UIColor *activeColor = [JFTheme accent];
    UIColor *offColor = [[JFTheme textTertiary] colorWithAlphaComponent:0.20];

    CGRect palmRect = CGRectMake(padding + fingerWidth * 0.34,
                                 baseY - 2,
                                 width - padding * 2 - fingerWidth * 0.68,
                                 height * 0.23);
    UIBezierPath *palm = [UIBezierPath bezierPathWithRoundedRect:palmRect
                                                    cornerRadius:MIN(10, CGRectGetHeight(palmRect) * 0.35)];
    [[[JFTheme brandPrimary] colorWithAlphaComponent:self.activeCount > 0 ? 0.28 : 0.12] setFill];
    [palm fill];

    for (NSInteger index = 0; index < 5; index++) {
        BOOL active = index < self.activeCount;
        BOOL losing = self.losingFinger && active && index == self.activeCount - 1;
        CGFloat fingerHeight = height * heightFactors[index].doubleValue;
        CGFloat x = padding + index * (fingerWidth + gap);
        CGRect fingerRect = CGRectMake(x, baseY - fingerHeight, fingerWidth, fingerHeight + height * 0.07);
        UIBezierPath *finger = [UIBezierPath bezierPathWithRoundedRect:fingerRect cornerRadius:fingerWidth / 2.0];
        UIColor *color = losing ? [JFTheme warning] : (active ? activeColor : offColor);
        CGContextSaveGState(UIGraphicsGetCurrentContext());
        if (active) {
            CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 2), losing ? 7 : 5,
                                        [color colorWithAlphaComponent:losing ? 0.68 : 0.38].CGColor);
        }
        [color setFill];
        [finger fill];
        CGContextRestoreGState(UIGraphicsGetCurrentContext());
    }
}

@end

#pragma mark - Controller

@interface JFNeverHaveIEverViewController () <JFGameSessionDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *infoButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong, nullable) UITextField *statementField;

@property (nonatomic, strong, nullable) id<JFGameSession> session;
@property (nonatomic, assign) BOOL host;
@property (nonatomic, assign) BOOL hasAuthoritativeState;
@property (nonatomic, assign) BOOL analyticsStarted;
@property (nonatomic, assign) BOOL resultReported;
@property (nonatomic, copy) NSString *requestedRoomCode;
@property (nonatomic, copy) NSString *hostPeerId;
@property (nonatomic, copy) NSString *phase;
@property (nonatomic, copy) NSString *speakerPeerId;
@property (nonatomic, copy) NSString *statement;
@property (nonatomic, assign) NSInteger round;
@property (nonatomic, assign) NSInteger revision;
@property (nonatomic, assign) NSInteger lastAppliedRevision;
@property (nonatomic, assign) NSInteger settlementToken;
@property (nonatomic, copy) NSString *peerSignature;
@property (nonatomic, strong) NSDate *gameStartedAt;
@property (nonatomic, strong) NSMutableArray<JFHaveYouNotPlayer *> *players;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *votes;
@property (nonatomic, strong) NSSet<NSString *> *resultNoPeerIds;
@property (nonatomic, strong, nullable) NSNumber *pendingVote;
@property (nonatomic, assign) BOOL pendingStatement;

@end


@implementation JFNeverHaveIEverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.players = [NSMutableArray array];
    self.votes = [NSMutableDictionary dictionary];
    self.resultNoPeerIds = [NSSet set];
    self.phase = JFHaveYouNotPhaseLobby;
    self.requestedRoomCode = @"";
    self.hostPeerId = @"";
    self.speakerPeerId = @"";
    self.statement = @"";
    [self buildBaseUI];
    [self renderContent];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onThemeChanged)
                                                 name:JFSkinDidChangeNotification
                                               object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{ [self presentModeMenu]; });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.session stop];
}

#pragma mark - Setup

- (void)presentModeMenu {
    if (self.session || self.presentedViewController) return;
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"我有你没有"
                                                                   message:@"每人使用自己的手机加入同一房间，昵称、手指和投票会实时同步。"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [menu addAction:[UIAlertAction actionWithTitle:@"创建房间" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf configureAsHost:YES roomCode:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"加入房间" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [weakSelf presentJoinPrompt];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];
    menu.popoverPresentationController.sourceView = self.view;
    menu.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), 80, 1, 1);
    [self presentViewController:menu animated:YES completion:nil];
}

- (void)presentJoinPrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入房间"
                                                                   message:@"输入房主分享的 6 位房间码；留空会加入最近创建的房间。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"例如 A1B2C3";
        field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        [weakSelf presentModeMenu];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"加入" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *code = [[alert.textFields.firstObject.text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        [weakSelf configureAsHost:NO roomCode:code];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)configureAsHost:(BOOL)host roomCode:(NSString * _Nullable)roomCode {
    self.host = host;
    self.requestedRoomCode = roomCode ?: @"";
    self.phase = JFHaveYouNotPhaseLobby;
    self.hasAuthoritativeState = NO;
    [self.players removeAllObjects];
    [self.votes removeAllObjects];
    [self renderContent];

    __weak typeof(self) weakSelf = self;
    [JFPlayerSetup ensureFromViewController:self completion:^(BOOL complete) {
        if (!complete) return;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.session = [JFGameSessionFactory sessionForServiceType:JFHaveYouNotServiceType mode:JFSessionModeRemote];
        self.session.delegate = self;
        [self renderContent];
        if (host) {
            [self.session startAsHost];
        } else if (self.requestedRoomCode.length > 0 && [self.session respondsToSelector:@selector(startAsClientWithRoomCode:)]) {
            [self.session startAsClientWithRoomCode:self.requestedRoomCode];
        } else {
            [self.session startAsClient];
        }
    }];
}

#pragma mark - Base UI

- (void)buildBaseUI {
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"我有你没有";
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textColor = [JFTheme textPrimary];
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.font = [JFTheme fontCaption];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    [self.view addSubview:self.subtitleLabel];

    self.infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.infoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.infoButton setImage:[UIImage systemImageNamed:@"info.circle.fill"] forState:UIControlStateNormal];
    self.infoButton.tintColor = [JFTheme accent];
    self.infoButton.accessibilityLabel = @"查看玩法规则";
    [self.infoButton addTarget:self action:@selector(showRules) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.infoButton];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 12;
    [self.scrollView addSubview:self.contentStack];

    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    dismissTap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:dismissTap];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.infoButton.leadingAnchor constant:-8],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.infoButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.infoButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [self.infoButton.widthAnchor constraintEqualToConstant:38],
        [self.infoButton.heightAnchor constraintEqualToConstant:38],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:13],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:16],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-16],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32],
    ]];
}

- (void)renderContent {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self renderContent]; });
        return;
    }
    self.statementField = nil;
    for (UIView *view in self.contentStack.arrangedSubviews.copy) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    [self refreshSubtitle];

    if (!self.session) {
        [self renderConnectingContent];
    } else if ([self.phase isEqualToString:JFHaveYouNotPhaseLobby]) {
        [self renderLobbyContent];
    } else {
        [self renderRoundContent];
    }

    UIView *space = [[UIView alloc] init];
    [space.heightAnchor constraintEqualToConstant:18].active = YES;
    [self.contentStack addArrangedSubview:space];
}

- (void)refreshSubtitle {
    NSString *roomCode = [self currentRoomCode];
    if (roomCode.length > 0) {
        self.subtitleLabel.text = [NSString stringWithFormat:@"房间 %@ · %@", roomCode, self.host ? @"房主" : @"玩家"];
    } else if (self.session) {
        self.subtitleLabel.text = self.host ? @"正在创建实时房间…" : @"正在加入实时房间…";
    } else {
        self.subtitleLabel.text = @"实时房间 · 轮流发言 · 全员投票";
    }
}

- (void)renderConnectingContent {
    UIView *intro = [self surfaceView];
    UIStackView *stack = [self verticalStackInView:intro];
    [stack addArrangedSubview:[self labelWithText:@"每个人都在自己的手机上操作" font:[JFTheme fontHeadline] color:[JFTheme textPrimary]]];
    UILabel *body = [self labelWithText:@"创建或加入同一个房间后，所有人的昵称、剩余手指与投票进度都会实时显示。"
                                     font:[JFTheme fontBody]
                                    color:[JFTheme textSecondary]];
    body.numberOfLines = 0;
    [stack addArrangedSubview:body];
    [self.contentStack addArrangedSubview:intro];
}

- (void)renderLobbyContent {
    [self.contentStack addArrangedSubview:[self roomPanel]];

    UIView *rule = [self surfaceView];
    UIStackView *ruleStack = [self verticalStackInView:rule];
    [ruleStack addArrangedSubview:[self labelWithText:@"这一局怎么进行" font:[JFTheme fontHeadline] color:[JFTheme textPrimary]]];
    UILabel *body = [self labelWithText:@"轮到你时，说一件“我有”的事。其他人选择“我有”或“我没有”，选择“我没有”的玩家熄灭一根手指。全员投完会自动进入下一位。"
                                     font:[JFTheme fontBody]
                                    color:[JFTheme textSecondary]];
    body.numberOfLines = 0;
    [ruleStack addArrangedSubview:body];
    [self.contentStack addArrangedSubview:rule];

    [self addPlayersSection];
    if (self.host) {
        UIButton *start = [self primaryButtonWithTitle:self.players.count >= 2 ? @"开始游戏" : @"至少等待 2 位玩家"
                                                symbol:@"play.fill"];
        start.enabled = self.players.count >= 2 && [self currentRoomCode].length > 0;
        start.alpha = start.enabled ? 1.0 : 0.48;
        [start addTarget:self action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
        [self.contentStack addArrangedSubview:start];
    } else {
        UILabel *waiting = [self labelWithText:@"等待房主开始游戏…" font:[JFTheme fontBody] color:[JFTheme textSecondary]];
        waiting.textAlignment = NSTextAlignmentCenter;
        [waiting.heightAnchor constraintEqualToConstant:48].active = YES;
        [self.contentStack addArrangedSubview:waiting];
    }
}

- (UIView *)roomPanel {
    UIView *panel = [self surfaceView];
    panel.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.14];
    UIStackView *row = [[UIStackView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 10;
    [panel addSubview:row];

    UIStackView *copy = [[UIStackView alloc] init];
    copy.axis = UILayoutConstraintAxisVertical;
    copy.spacing = 3;
    UILabel *eyebrow = [self labelWithText:@"房间码" font:[JFTheme fontCaption] color:[JFTheme textSecondary]];
    NSString *roomCode = [self currentRoomCode];
    UILabel *code = [self labelWithText:roomCode.length > 0 ? roomCode : @"连接中…"
                                    font:[UIFont monospacedSystemFontOfSize:25 weight:UIFontWeightBlack]
                                   color:[JFTheme textPrimary]];
    [copy addArrangedSubview:eyebrow];
    [copy addArrangedSubview:code];
    [row addArrangedSubview:copy];

    UIButton *copyButton = [self secondaryButtonWithTitle:@"复制" symbol:@"doc.on.doc"];
    copyButton.enabled = roomCode.length > 0;
    [copyButton addTarget:self action:@selector(copyRoomCode) forControlEvents:UIControlEventTouchUpInside];
    [copyButton.widthAnchor constraintEqualToConstant:92].active = YES;
    [row addArrangedSubview:copyButton];

    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:panel.topAnchor constant:14],
        [row.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [row.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [row.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-14],
    ]];
    return panel;
}

- (void)renderRoundContent {
    [self.contentStack addArrangedSubview:[self roundHeaderPanel]];

    JFHaveYouNotPlayer *speaker = [self playerForPeerId:self.speakerPeerId];
    BOOL localIsSpeaker = [self isLocalPeerId:self.speakerPeerId];
    if ([self.phase isEqualToString:JFHaveYouNotPhaseStatement]) {
        UIView *panel = [self surfaceView];
        UIStackView *stack = [self verticalStackInView:panel];
        NSString *title = localIsSpeaker ? @"轮到你说一件自己有的事" : [NSString stringWithFormat:@"等待 %@ 发言", speaker.name ?: @"当前玩家"];
        [stack addArrangedSubview:[self labelWithText:title font:[JFTheme fontHeadline] color:[JFTheme textPrimary]]];
        if (localIsSpeaker) {
            self.statementField = [[UITextField alloc] init];
            self.statementField.borderStyle = UITextBorderStyleNone;
            self.statementField.backgroundColor = [[JFTheme textPrimary] colorWithAlphaComponent:0.07];
            self.statementField.textColor = [JFTheme textPrimary];
            self.statementField.font = [JFTheme fontBody];
            self.statementField.placeholder = @"例如：我有独自旅行过";
            self.statementField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.statementField.returnKeyType = UIReturnKeySend;
            self.statementField.delegate = self;
            self.statementField.layer.cornerRadius = 8;
            self.statementField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
            self.statementField.leftViewMode = UITextFieldViewModeAlways;
            self.statementField.enabled = !self.pendingStatement;
            [self.statementField.heightAnchor constraintEqualToConstant:50].active = YES;
            [stack addArrangedSubview:self.statementField];

            UIButton *submit = [self primaryButtonWithTitle:self.pendingStatement ? @"等待房主确认…" : @"说完了，开始投票"
                                                      symbol:@"paperplane.fill"];
            submit.enabled = !self.pendingStatement;
            submit.alpha = submit.enabled ? 1.0 : 0.56;
            [submit addTarget:self action:@selector(submitStatement) forControlEvents:UIControlEventTouchUpInside];
            [stack addArrangedSubview:submit];
        } else {
            UILabel *hint = [self labelWithText:@"发言提交后，其他玩家的投票按钮会同时出现。"
                                            font:[JFTheme fontBody]
                                           color:[JFTheme textSecondary]];
            hint.numberOfLines = 0;
            [stack addArrangedSubview:hint];
        }
        [self.contentStack addArrangedSubview:panel];
    } else if ([self.phase isEqualToString:JFHaveYouNotPhaseVoting]) {
        [self.contentStack addArrangedSubview:[self statementPanelWithResult:NO]];
        [self addVotingControls];
    } else if ([self.phase isEqualToString:JFHaveYouNotPhaseResult]) {
        [self.contentStack addArrangedSubview:[self statementPanelWithResult:YES]];
    } else if ([self.phase isEqualToString:JFHaveYouNotPhaseFinished]) {
        [self.contentStack addArrangedSubview:[self winnerPanel]];
    }

    [self addPlayersSection];
    if ([self.phase isEqualToString:JFHaveYouNotPhaseFinished] && self.host) {
        UIButton *restart = [self primaryButtonWithTitle:@"用当前玩家再来一局" symbol:@"arrow.clockwise"];
        [restart addTarget:self action:@selector(startGame) forControlEvents:UIControlEventTouchUpInside];
        [self.contentStack addArrangedSubview:restart];
    }
    [self reportFinishedIfNeeded];
}

- (UIView *)roundHeaderPanel {
    UIView *panel = [self surfaceView];
    panel.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.11];
    UIStackView *stack = [self verticalStackInView:panel];
    UILabel *round = [self labelWithText:[NSString stringWithFormat:@"第 %ld 轮", (long)MAX(1, self.round)]
                                    font:[UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightBold]
                                   color:[JFTheme accent]];
    [stack addArrangedSubview:round];
    JFHaveYouNotPlayer *speaker = [self playerForPeerId:self.speakerPeerId];
    NSString *turn = [self.phase isEqualToString:JFHaveYouNotPhaseFinished]
        ? @"本局结束"
        : [NSString stringWithFormat:@"%@ 的回合", speaker.name ?: @"等待同步"];
    [stack addArrangedSubview:[self labelWithText:turn font:[UIFont systemFontOfSize:24 weight:UIFontWeightBlack] color:[JFTheme textPrimary]]];
    return panel;
}

- (UIView *)statementPanelWithResult:(BOOL)showResult {
    UIView *panel = [self surfaceView];
    UIStackView *stack = [self verticalStackInView:panel];
    JFHaveYouNotPlayer *speaker = [self playerForPeerId:self.speakerPeerId];
    [stack addArrangedSubview:[self labelWithText:[NSString stringWithFormat:@"%@ 说", speaker.name ?: @"当前玩家"]
                                            font:[JFTheme fontCaption]
                                           color:[JFTheme textSecondary]]];
    UILabel *statement = [self labelWithText:self.statement.length > 0 ? self.statement : @"等待发言…"
                                        font:[UIFont systemFontOfSize:23 weight:UIFontWeightBold]
                                       color:[JFTheme textPrimary]];
    statement.numberOfLines = 0;
    [stack addArrangedSubview:statement];

    if (showResult) {
        NSString *resultText;
        UIColor *resultColor;
        if (self.resultNoPeerIds.count == 0) {
            resultText = @"大家都有，所有人的手指都保留";
            resultColor = [JFTheme success];
        } else {
            NSMutableArray<NSString *> *names = [NSMutableArray array];
            for (JFHaveYouNotPlayer *player in self.players) {
                if ([self.resultNoPeerIds containsObject:player.peerId]) [names addObject:player.name ?: @"玩家"];
            }
            resultText = [NSString stringWithFormat:@"%@ 选择了“我没有”，各熄灭一根", [names componentsJoinedByString:@"、"]];
            resultColor = [JFTheme warning];
        }
        UILabel *result = [self labelWithText:resultText font:[JFTheme fontBody] color:resultColor];
        result.numberOfLines = 0;
        [stack addArrangedSubview:result];
    }
    return panel;
}

- (void)addVotingControls {
    NSInteger required = [self requiredVoterCount];
    NSInteger submitted = [self submittedVoteCount];
    UILabel *progress = [self labelWithText:[NSString stringWithFormat:@"%ld / %ld 人已投票", (long)submitted, (long)required]
                                        font:[JFTheme fontBody]
                                       color:[JFTheme textSecondary]];
    progress.textAlignment = NSTextAlignmentCenter;
    [self.contentStack addArrangedSubview:progress];

    JFHaveYouNotPlayer *localPlayer = [self localPlayer];
    BOOL canVote = localPlayer.fingers > 0 && ![self isLocalPeerId:self.speakerPeerId];
    NSNumber *authoritativeVote = self.votes[localPlayer.peerId ?: @""];
    NSNumber *displayVote = authoritativeVote ?: self.pendingVote;
    if (!canVote) {
        UILabel *waiting = [self labelWithText:[self isLocalPeerId:self.speakerPeerId] ? @"你是本轮发言者，等待其他人投票" : @"本轮等待其他玩家投票"
                                            font:[JFTheme fontBody]
                                           color:[JFTheme textSecondary]];
        waiting.textAlignment = NSTextAlignmentCenter;
        [waiting.heightAnchor constraintEqualToConstant:44].active = YES;
        [self.contentStack addArrangedSubview:waiting];
        return;
    }
    if (displayVote) {
        NSString *choice = displayVote.boolValue ? @"我有" : @"我没有";
        NSString *text = authoritativeVote ? [NSString stringWithFormat:@"已选择：%@ · 等待其他玩家", choice]
                                           : [NSString stringWithFormat:@"正在提交：%@…", choice];
        UILabel *submittedLabel = [self labelWithText:text font:[JFTheme fontHeadline] color:displayVote.boolValue ? [JFTheme success] : [JFTheme warning]];
        submittedLabel.textAlignment = NSTextAlignmentCenter;
        [submittedLabel.heightAnchor constraintEqualToConstant:54].active = YES;
        [self.contentStack addArrangedSubview:submittedLabel];
        return;
    }

    UIStackView *buttons = [[UIStackView alloc] init];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.distribution = UIStackViewDistributionFillEqually;
    buttons.spacing = 10;
    UIButton *have = [self voteButtonWithTitle:@"我有" symbol:@"checkmark.circle.fill" color:[JFTheme success]];
    UIButton *haveNot = [self voteButtonWithTitle:@"我没有" symbol:@"minus.circle.fill" color:[JFTheme warning]];
    [have addTarget:self action:@selector(voteHave) forControlEvents:UIControlEventTouchUpInside];
    [haveNot addTarget:self action:@selector(voteHaveNot) forControlEvents:UIControlEventTouchUpInside];
    [buttons addArrangedSubview:have];
    [buttons addArrangedSubview:haveNot];
    [buttons.heightAnchor constraintEqualToConstant:58].active = YES;
    [self.contentStack addArrangedSubview:buttons];
    UILabel *hint = [self labelWithText:@"选择“我没有”会在本轮结算时熄灭一根手指"
                                   font:[JFTheme fontCaption]
                                  color:[JFTheme textTertiary]];
    hint.textAlignment = NSTextAlignmentCenter;
    [self.contentStack addArrangedSubview:hint];
}

- (UIView *)winnerPanel {
    UIView *panel = [self surfaceView];
    panel.backgroundColor = [[JFTheme success] colorWithAlphaComponent:0.13];
    UIStackView *stack = [self verticalStackInView:panel];
    JFHaveYouNotPlayer *winner = nil;
    for (JFHaveYouNotPlayer *player in self.players) {
        if (player.fingers > 0) { winner = player; break; }
    }
    UILabel *symbol = [self labelWithText:@"♛" font:[UIFont systemFontOfSize:42 weight:UIFontWeightBlack] color:[JFTheme success]];
    symbol.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:symbol];
    UILabel *title = [self labelWithText:winner ? [NSString stringWithFormat:@"%@ 留到了最后", winner.name] : @"本局结束"
                                     font:[UIFont systemFontOfSize:23 weight:UIFontWeightBlack]
                                    color:[JFTheme textPrimary]];
    title.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:title];
    return panel;
}

- (void)addPlayersSection {
    UILabel *heading = [self labelWithText:[NSString stringWithFormat:@"玩家状态 · %lu 人", (unsigned long)self.players.count]
                                      font:[JFTheme fontHeadline]
                                     color:[JFTheme textPrimary]];
    [self.contentStack addArrangedSubview:heading];
    if (self.players.count == 0) {
        UILabel *empty = [self labelWithText:@"正在同步房间成员…" font:[JFTheme fontBody] color:[JFTheme textSecondary]];
        [empty.heightAnchor constraintEqualToConstant:54].active = YES;
        [self.contentStack addArrangedSubview:empty];
        return;
    }
    for (JFHaveYouNotPlayer *player in self.players) {
        [self.contentStack addArrangedSubview:[self playerRow:player]];
    }
}

- (UIView *)playerRow:(JFHaveYouNotPlayer *)player {
    UIView *row = [self surfaceView];
    BOOL speaker = [player.peerId isEqualToString:self.speakerPeerId] && ![self.phase isEqualToString:JFHaveYouNotPhaseFinished];
    BOOL losing = [self.phase isEqualToString:JFHaveYouNotPhaseResult] && [self.resultNoPeerIds containsObject:player.peerId];
    if (speaker) {
        row.layer.borderColor = [JFTheme accent].CGColor;
        row.layer.borderWidth = 2;
    } else if (losing) {
        row.layer.borderColor = [JFTheme warning].CGColor;
        row.layer.borderWidth = 2;
    }

    UIStackView *layout = [[UIStackView alloc] init];
    layout.translatesAutoresizingMaskIntoConstraints = NO;
    layout.axis = UILayoutConstraintAxisHorizontal;
    layout.alignment = UIStackViewAlignmentCenter;
    layout.spacing = 11;
    [row addSubview:layout];

    UILabel *avatar = [self labelWithText:[self initialForName:player.name]
                                     font:[UIFont systemFontOfSize:17 weight:UIFontWeightBlack]
                                    color:[JFTheme textPrimary]];
    avatar.textAlignment = NSTextAlignmentCenter;
    avatar.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.16];
    avatar.layer.cornerRadius = 20;
    avatar.clipsToBounds = YES;
    [avatar.widthAnchor constraintEqualToConstant:40].active = YES;
    [avatar.heightAnchor constraintEqualToConstant:40].active = YES;
    [layout addArrangedSubview:avatar];

    UIStackView *copy = [[UIStackView alloc] init];
    copy.axis = UILayoutConstraintAxisVertical;
    copy.spacing = 2;
    NSString *name = player.name ?: @"玩家";
    if ([self isLocalPeerId:player.peerId]) name = [name stringByAppendingString:@"（我）"];
    if ([player.peerId isEqualToString:self.hostPeerId]) name = [name stringByAppendingString:@" · 房主"];
    [copy addArrangedSubview:[self labelWithText:name font:[JFTheme fontBody] color:player.fingers > 0 ? [JFTheme textPrimary] : [JFTheme textTertiary]]];
    [copy addArrangedSubview:[self labelWithText:[self statusTextForPlayer:player]
                                            font:[JFTheme fontCaption]
                                           color:[self statusColorForPlayer:player]]];
    [layout addArrangedSubview:copy];

    JFHaveYouNotHandView *hand = [[JFHaveYouNotHandView alloc] init];
    hand.activeCount = player.fingers;
    hand.losingFinger = losing;
    [hand.widthAnchor constraintEqualToConstant:92].active = YES;
    [hand.heightAnchor constraintEqualToConstant:64].active = YES;
    [layout addArrangedSubview:hand];

    UILabel *count = [self labelWithText:[NSString stringWithFormat:@"%ld", (long)player.fingers]
                                    font:[UIFont monospacedDigitSystemFontOfSize:18 weight:UIFontWeightBlack]
                                   color:player.fingers > 0 ? [JFTheme textPrimary] : [JFTheme textTertiary]];
    count.textAlignment = NSTextAlignmentRight;
    [count.widthAnchor constraintEqualToConstant:20].active = YES;
    [layout addArrangedSubview:count];

    [NSLayoutConstraint activateConstraints:@[
        [layout.topAnchor constraintEqualToAnchor:row.topAnchor constant:9],
        [layout.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:12],
        [layout.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-12],
        [layout.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-9],
    ]];
    return row;
}

#pragma mark - Game actions

- (void)startGame {
    if (!self.host || self.players.count < 2) return;
    self.settlementToken += 1;
    for (JFHaveYouNotPlayer *player in self.players) player.fingers = 5;
    self.phase = JFHaveYouNotPhaseStatement;
    self.round = 1;
    self.speakerPeerId = self.players.firstObject.peerId ?: @"";
    self.statement = @"";
    [self.votes removeAllObjects];
    self.resultNoPeerIds = [NSSet set];
    self.resultReported = NO;
    self.gameStartedAt = [NSDate date];
    self.analyticsStarted = YES;
    [[JFAnalyticsTracker shared] beginGameSession:JFGameKindNeverHaveIEver source:@"remote_room"];
    [self broadcastState];
    [self renderContent];
    [JFTheme hapticImpactMedium];
}

- (void)submitStatement {
    NSString *text = [self.statementField.text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        [self showToast:@"先说一件自己有的事"];
        return;
    }
    if (![text hasPrefix:@"我有"]) text = [@"我有" stringByAppendingString:text];
    if (text.length < 4) {
        [self showToast:@"再说具体一点吧"];
        return;
    }
    if (text.length > 60) text = [text substringToIndex:60];
    [self dismissKeyboard];
    if (self.host) {
        [self hostAcceptStatement:text fromPeerId:self.session.localPeer.peerId round:self.round];
    } else {
        self.pendingStatement = YES;
        JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeHaveYouNotStatement
                                                        payload:@{ @"round": @(self.round), @"statement": text }];
        [self.session sendMessage:message toPeer:nil];
        [self renderContent];
        [self clearPendingStatementIfNeededForRound:self.round];
    }
}

- (void)voteHave { [self submitVote:YES]; }
- (void)voteHaveNot { [self submitVote:NO]; }

- (void)submitVote:(BOOL)hasIt {
    JFHaveYouNotPlayer *local = [self localPlayer];
    if (!local || local.fingers <= 0 || [self isLocalPeerId:self.speakerPeerId] || self.votes[local.peerId]) return;
    if (self.host) {
        [self hostAcceptVote:hasIt fromPeerId:local.peerId round:self.round];
    } else {
        self.pendingVote = @(hasIt);
        JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeHaveYouNotVote
                                                        payload:@{ @"round": @(self.round), @"has": @(hasIt) }];
        [self.session sendMessage:message toPeer:nil];
        [self renderContent];
        [self clearPendingVoteIfNeededForRound:self.round];
    }
    [JFTheme hapticSelection];
}

- (void)hostAcceptStatement:(NSString *)statement fromPeerId:(NSString *)peerId round:(NSInteger)round {
    if (!self.host || ![self.phase isEqualToString:JFHaveYouNotPhaseStatement] || round != self.round) return;
    if (![peerId isEqualToString:self.speakerPeerId] || statement.length == 0) return;
    self.statement = statement;
    self.phase = JFHaveYouNotPhaseVoting;
    [self.votes removeAllObjects];
    self.pendingStatement = NO;
    [[JFAnalyticsTracker shared] trackEvent:@"have_you_not_statement"
                                  gameKind:JFGameKindNeverHaveIEver
                                properties:@{ @"round": @(self.round) }];
    [self broadcastState];
    [self renderContent];
}

- (void)hostAcceptVote:(BOOL)hasIt fromPeerId:(NSString *)peerId round:(NSInteger)round {
    if (!self.host || ![self.phase isEqualToString:JFHaveYouNotPhaseVoting] || round != self.round) return;
    JFHaveYouNotPlayer *player = [self playerForPeerId:peerId];
    if (!player || player.fingers <= 0 || [peerId isEqualToString:self.speakerPeerId] || self.votes[peerId]) return;
    self.votes[peerId] = @(hasIt);
    if ([peerId isEqualToString:self.session.localPeer.peerId]) self.pendingVote = nil;
    if ([self submittedVoteCount] >= [self requiredVoterCount]) {
        [self settleVotes];
    } else {
        [self broadcastState];
        [self renderContent];
    }
}

- (void)settleVotes {
    NSMutableSet<NSString *> *noPeerIds = [NSMutableSet set];
    for (JFHaveYouNotPlayer *player in self.players) {
        NSNumber *vote = self.votes[player.peerId];
        if (player.fingers > 0 && ![player.peerId isEqualToString:self.speakerPeerId] && vote && !vote.boolValue) {
            player.fingers = MAX(0, player.fingers - 1);
            [noPeerIds addObject:player.peerId];
        }
    }
    self.resultNoPeerIds = noPeerIds.copy;
    self.phase = JFHaveYouNotPhaseResult;
    self.settlementToken += 1;
    NSInteger token = self.settlementToken;
    [[JFAnalyticsTracker shared] trackEvent:@"have_you_not_round_settle"
                                  gameKind:JFGameKindNeverHaveIEver
                                properties:@{ @"round": @(self.round), @"lossCount": @(noPeerIds.count) }];
    [self broadcastState];
    [self renderContent];
    [JFTheme hapticNotification:noPeerIds.count > 0 ? UINotificationFeedbackTypeWarning : UINotificationFeedbackTypeSuccess];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.host && token == self.settlementToken && [self.phase isEqualToString:JFHaveYouNotPhaseResult]) {
            [self advanceToNextRound];
        }
    });
}

- (void)advanceToNextRound {
    NSArray<JFHaveYouNotPlayer *> *active = [self activePlayers];
    if (active.count <= 1) {
        self.phase = JFHaveYouNotPhaseFinished;
        [self broadcastState];
        [self renderContent];
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        return;
    }
    NSInteger currentIndex = [self indexOfPlayerId:self.speakerPeerId];
    for (NSInteger offset = 1; offset <= self.players.count; offset++) {
        NSInteger candidateIndex = (currentIndex + offset) % self.players.count;
        JFHaveYouNotPlayer *candidate = self.players[candidateIndex];
        if (candidate.fingers > 0) {
            self.speakerPeerId = candidate.peerId;
            break;
        }
    }
    self.round += 1;
    self.phase = JFHaveYouNotPhaseStatement;
    self.statement = @"";
    self.pendingVote = nil;
    self.pendingStatement = NO;
    [self.votes removeAllObjects];
    self.resultNoPeerIds = [NSSet set];
    [self broadcastState];
    [self renderContent];
}

#pragma mark - State sync

- (void)syncLobbyPlayersFromSession {
    if (!self.session) return;
    NSMutableArray<JFGamePeer *> *peers = [NSMutableArray arrayWithObject:self.session.localPeer];
    [peers addObjectsFromArray:self.session.connectedPeers ?: @[]];
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:peers.count];
    for (JFGamePeer *peer in peers) {
        [parts addObject:[NSString stringWithFormat:@"%@:%@", peer.peerId ?: @"", peer.displayName ?: @""]];
    }
    NSString *signature = [parts componentsJoinedByString:@"|"];
    if ([signature isEqualToString:self.peerSignature] && self.players.count > 0) return;
    self.peerSignature = signature;

    NSMutableArray<JFHaveYouNotPlayer *> *next = [NSMutableArray arrayWithCapacity:peers.count];
    for (JFGamePeer *peer in peers) {
        if (peer.peerId.length == 0) continue;
        JFHaveYouNotPlayer *player = [self playerForPeerId:peer.peerId] ?: [[JFHaveYouNotPlayer alloc] init];
        player.peerId = peer.peerId;
        player.name = peer.displayName.length > 0 ? peer.displayName : @"玩家";
        player.fingers = player.fingers > 0 ? player.fingers : 5;
        [next addObject:player];
    }
    self.players = next;
    if (self.host) self.hostPeerId = self.session.localPeer.peerId ?: @"";
    self.hasAuthoritativeState = self.host;
    if (self.host && [self currentRoomCode].length > 0) [self broadcastState];
    [self renderContent];
}

- (NSDictionary *)statePayload {
    NSMutableArray<NSDictionary *> *playerPayloads = [NSMutableArray arrayWithCapacity:self.players.count];
    for (JFHaveYouNotPlayer *player in self.players) {
        [playerPayloads addObject:@{
            @"peerId": player.peerId ?: @"",
            @"name": player.name ?: @"玩家",
            @"fingers": @(player.fingers),
        }];
    }
    return @{
        @"version": @1,
        @"revision": @(self.revision),
        @"phase": self.phase ?: JFHaveYouNotPhaseLobby,
        @"round": @(self.round),
        @"hostPeerId": self.hostPeerId ?: @"",
        @"speakerPeerId": self.speakerPeerId ?: @"",
        @"statement": self.statement ?: @"",
        @"players": playerPayloads,
        @"votes": self.votes.copy ?: @{},
        @"resultNoPeerIds": self.resultNoPeerIds.allObjects ?: @[],
    };
}

- (void)broadcastState {
    if (!self.host || !self.session || [self currentRoomCode].length == 0) return;
    self.revision += 1;
    JFGameMessage *message = [JFGameMessage messageWithType:JFMessageTypeHaveYouNotState payload:[self statePayload]];
    [self.session sendMessage:message toPeer:nil];
}

- (void)applyStatePayload:(NSDictionary *)payload {
    NSInteger incomingRevision = [payload[@"revision"] integerValue];
    if (incomingRevision > 0 && incomingRevision <= self.lastAppliedRevision) return;
    NSArray *rawPlayers = [payload[@"players"] isKindOfClass:NSArray.class] ? payload[@"players"] : nil;
    if (!rawPlayers) return;

    NSString *oldPhase = self.phase;
    NSInteger oldRound = self.round;
    NSMutableArray<JFHaveYouNotPlayer *> *next = [NSMutableArray arrayWithCapacity:rawPlayers.count];
    for (NSDictionary *dict in rawPlayers) {
        if (![dict isKindOfClass:NSDictionary.class]) continue;
        NSString *peerId = [dict[@"peerId"] isKindOfClass:NSString.class] ? dict[@"peerId"] : @"";
        if (peerId.length == 0) continue;
        JFHaveYouNotPlayer *player = [[JFHaveYouNotPlayer alloc] init];
        player.peerId = peerId;
        player.name = [dict[@"name"] isKindOfClass:NSString.class] ? dict[@"name"] : @"玩家";
        player.fingers = MAX(0, MIN(5, [dict[@"fingers"] integerValue]));
        [next addObject:player];
    }
    self.players = next;
    self.phase = [payload[@"phase"] isKindOfClass:NSString.class] ? payload[@"phase"] : JFHaveYouNotPhaseLobby;
    self.round = [payload[@"round"] integerValue];
    self.hostPeerId = [payload[@"hostPeerId"] isKindOfClass:NSString.class] ? payload[@"hostPeerId"] : self.hostPeerId;
    self.speakerPeerId = [payload[@"speakerPeerId"] isKindOfClass:NSString.class] ? payload[@"speakerPeerId"] : @"";
    self.statement = [payload[@"statement"] isKindOfClass:NSString.class] ? payload[@"statement"] : @"";
    NSDictionary *rawVotes = [payload[@"votes"] isKindOfClass:NSDictionary.class] ? payload[@"votes"] : @{};
    self.votes = [rawVotes mutableCopy];
    NSArray *rawResult = [payload[@"resultNoPeerIds"] isKindOfClass:NSArray.class] ? payload[@"resultNoPeerIds"] : @[];
    self.resultNoPeerIds = [NSSet setWithArray:rawResult];
    self.lastAppliedRevision = MAX(self.lastAppliedRevision, incomingRevision);
    self.hasAuthoritativeState = YES;

    NSString *localId = self.session.localPeer.peerId ?: @"";
    if (self.votes[localId]) self.pendingVote = nil;
    if (![self.phase isEqualToString:JFHaveYouNotPhaseStatement] || ![self.speakerPeerId isEqualToString:localId]) self.pendingStatement = NO;
    if ((!oldPhase || [oldPhase isEqualToString:JFHaveYouNotPhaseLobby] || [oldPhase isEqualToString:JFHaveYouNotPhaseFinished])
        && ![self.phase isEqualToString:JFHaveYouNotPhaseLobby]
        && ![self.phase isEqualToString:JFHaveYouNotPhaseFinished]) {
        self.resultReported = NO;
        self.gameStartedAt = [NSDate date];
        if (!self.analyticsStarted) {
            self.analyticsStarted = YES;
            [[JFAnalyticsTracker shared] beginGameSession:JFGameKindNeverHaveIEver source:@"remote_room"];
        }
    }
    if (oldRound != self.round) {
        self.pendingVote = nil;
        self.pendingStatement = NO;
    }
    [self renderContent];
}

#pragma mark - Session delegate

- (void)gameSessionDidUpdateRoom:(id<JFGameSession>)session {
    if (self.host && [self.phase isEqualToString:JFHaveYouNotPhaseLobby]) {
        [self syncLobbyPlayersFromSession];
    } else if (!self.hasAuthoritativeState && [self.phase isEqualToString:JFHaveYouNotPhaseLobby]) {
        [self syncLobbyPlayersFromSession];
    } else {
        [self refreshSubtitle];
    }
}

- (void)gameSession:(id<JFGameSession>)session
               peer:(JFGamePeer *)peer
     didChangeState:(JFSessionPeerState)state {
    if ([self.phase isEqualToString:JFHaveYouNotPhaseLobby]) [self syncLobbyPlayersFromSession];
}

- (void)gameSession:(id<JFGameSession>)session
   didReceiveMessage:(JFGameMessage *)message
            fromPeer:(JFGamePeer *)peer {
    if ([message.type isEqualToString:JFMessageTypeHaveYouNotState] && !self.host) {
        [self applyStatePayload:message.payload];
        return;
    }
    if (!self.host) return;
    NSString *senderId = message.from.length > 0 ? message.from : peer.peerId;
    if ([message.type isEqualToString:JFMessageTypeHaveYouNotStatement]) {
        NSString *statement = [message.payload[@"statement"] isKindOfClass:NSString.class] ? message.payload[@"statement"] : @"";
        [self hostAcceptStatement:statement fromPeerId:senderId round:[message.payload[@"round"] integerValue]];
    } else if ([message.type isEqualToString:JFMessageTypeHaveYouNotVote]) {
        [self hostAcceptVote:[message.payload[@"has"] boolValue]
                  fromPeerId:senderId
                       round:[message.payload[@"round"] integerValue]];
    }
}

- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"房间连接失败"
                                                                       message:error.localizedDescription ?: @"请检查网络后重试。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        if (!self.presentedViewController) [self presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Helpers

- (NSString *)currentRoomCode {
    if ([self.session respondsToSelector:@selector(roomCode)]) return self.session.roomCode ?: @"";
    return @"";
}

- (JFHaveYouNotPlayer *)playerForPeerId:(NSString *)peerId {
    if (peerId.length == 0) return nil;
    for (JFHaveYouNotPlayer *player in self.players) {
        if ([player.peerId isEqualToString:peerId]) return player;
    }
    return nil;
}

- (JFHaveYouNotPlayer *)localPlayer {
    return [self playerForPeerId:self.session.localPeer.peerId];
}

- (BOOL)isLocalPeerId:(NSString *)peerId {
    return peerId.length > 0 && [peerId isEqualToString:self.session.localPeer.peerId];
}

- (NSInteger)indexOfPlayerId:(NSString *)peerId {
    for (NSInteger index = 0; index < self.players.count; index++) {
        if ([self.players[index].peerId isEqualToString:peerId]) return index;
    }
    return 0;
}

- (NSArray<JFHaveYouNotPlayer *> *)activePlayers {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JFHaveYouNotPlayer *player, NSDictionary *bindings) {
        return player.fingers > 0;
    }];
    return [self.players filteredArrayUsingPredicate:predicate];
}

- (NSInteger)requiredVoterCount {
    NSInteger count = 0;
    for (JFHaveYouNotPlayer *player in self.players) {
        if (player.fingers > 0 && ![player.peerId isEqualToString:self.speakerPeerId]) count += 1;
    }
    return count;
}

- (NSInteger)submittedVoteCount {
    NSInteger count = 0;
    for (JFHaveYouNotPlayer *player in self.players) {
        if (player.fingers > 0 && ![player.peerId isEqualToString:self.speakerPeerId] && self.votes[player.peerId]) count += 1;
    }
    return count;
}

- (NSString *)statusTextForPlayer:(JFHaveYouNotPlayer *)player {
    if (player.fingers <= 0) return @"手指已全部熄灭";
    if ([self.phase isEqualToString:JFHaveYouNotPhaseLobby]) return @"已加入 · 剩余 5 根";
    if ([self.phase isEqualToString:JFHaveYouNotPhaseFinished]) return @"本局胜者";
    if ([player.peerId isEqualToString:self.speakerPeerId]) return @"本轮发言者";
    if ([self.phase isEqualToString:JFHaveYouNotPhaseVoting]) {
        if (self.votes[player.peerId]) return @"已投票";
        if ([self isLocalPeerId:player.peerId] && self.pendingVote) return @"正在提交投票";
        return @"等待投票";
    }
    if ([self.phase isEqualToString:JFHaveYouNotPhaseResult]) {
        if ([self.resultNoPeerIds containsObject:player.peerId]) return @"我没有 · 熄灭 1 根";
        if (self.votes[player.peerId].boolValue) return @"我有 · 保留手指";
    }
    return [NSString stringWithFormat:@"剩余 %ld 根", (long)player.fingers];
}

- (UIColor *)statusColorForPlayer:(JFHaveYouNotPlayer *)player {
    if (player.fingers <= 0) return [JFTheme textTertiary];
    if ([self.phase isEqualToString:JFHaveYouNotPhaseFinished]) return [JFTheme success];
    if ([player.peerId isEqualToString:self.speakerPeerId]) return [JFTheme accent];
    if ([self.resultNoPeerIds containsObject:player.peerId]) return [JFTheme warning];
    if (self.votes[player.peerId]) return [JFTheme success];
    return [JFTheme textSecondary];
}

- (NSString *)initialForName:(NSString *)name {
    if (name.length == 0) return @"玩";
    NSRange range = [name rangeOfComposedCharacterSequenceAtIndex:0];
    return [name substringWithRange:range];
}

- (void)reportFinishedIfNeeded {
    if (![self.phase isEqualToString:JFHaveYouNotPhaseFinished] || self.resultReported) return;
    JFHaveYouNotPlayer *local = [self localPlayer];
    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindNeverHaveIEver
                                                  score:MAX(0, local.fingers) * 100 + MIN(self.round, 99)
                                                    win:local.fingers > 0];
    result.duration = [[NSDate date] timeIntervalSinceDate:self.gameStartedAt ?: [NSDate date]];
    result.extra = @{ @"players": @(self.players.count), @"rounds": @(self.round), @"remote": @YES };
    [[JFProfileStore shared] reportResult:result];
    self.resultReported = YES;
}

- (void)clearPendingVoteIfNeededForRound:(NSInteger)round {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *localId = self.session.localPeer.peerId ?: @"";
        if (self.round == round && self.pendingVote && !self.votes[localId]) {
            self.pendingVote = nil;
            [self renderContent];
            [self showToast:@"投票尚未同步，请再试一次"];
        }
    });
}

- (void)clearPendingStatementIfNeededForRound:(NSInteger)round {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.round == round && self.pendingStatement && [self.phase isEqualToString:JFHaveYouNotPhaseStatement]) {
            self.pendingStatement = NO;
            [self renderContent];
            [self showToast:@"发言尚未同步，请再试一次"];
        }
    });
}

- (void)copyRoomCode {
    NSString *roomCode = [self currentRoomCode];
    if (roomCode.length == 0) return;
    UIPasteboard.generalPasteboard.string = roomCode;
    [JFTheme hapticSelection];
    [self showToast:@"房间码已复制"];
}

- (void)showRules {
    NSString *message = @"1. 每位玩家用自己的手机加入同一房间，从五根手指开始。\n\n"
                         @"2. 按房间顺序轮流发言。轮到你时，说一件自己有、但别人可能没有的事。\n\n"
                         @"3. 除发言者外，所有仍有手指的玩家选择“我有”或“我没有”。\n\n"
                         @"4. 选择“我没有”的玩家熄灭一根手指。所有人投完后自动结算，再轮到下一位。\n\n"
                         @"5. 手指归零后不再参与发言和投票，最后仍有手指的玩家获胜。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"我有你没有怎么玩"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)text {
    UILabel *toast = [self labelWithText:text font:[JFTheme fontBody] color:UIColor.whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
    toast.layer.cornerRadius = 8;
    toast.clipsToBounds = YES;
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [toast.heightAnchor constraintEqualToConstant:42],
        [toast.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-48],
        [toast.widthAnchor constraintGreaterThanOrEqualToConstant:150],
    ]];
    toast.alpha = 0;
    [UIView animateWithDuration:0.18 animations:^{ toast.alpha = 1; } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.22 delay:1.25 options:UIViewAnimationOptionCurveEaseIn animations:^{ toast.alpha = 0; }
                         completion:^(__unused BOOL done) { [toast removeFromSuperview]; }];
    }];
}

- (void)dismissKeyboard { [self.view endEditing:YES]; }

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitStatement];
    return YES;
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
 replacementString:(NSString *)string {
    NSString *next = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return next.length <= 60;
}

- (void)onThemeChanged {
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.infoButton.tintColor = [JFTheme accent];
    [self renderContent];
}

#pragma mark - UI helpers

- (UIView *)surfaceView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [[JFTheme backgroundElevated] colorWithAlphaComponent:0.88];
    view.layer.cornerRadius = 8;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [JFTheme cardBorder].CGColor;
    return view;
}

- (UIStackView *)verticalStackInView:(UIView *)view {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 9;
    [view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:view.topAnchor constant:15],
        [stack.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:15],
        [stack.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-15],
        [stack.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-15],
    ]];
    return stack;
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.adjustsFontSizeToFitWidth = NO;
    return label;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title symbol:(NSString *)symbol {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:symbol];
    configuration.imagePadding = 8;
    configuration.baseBackgroundColor = [JFTheme brandPrimary];
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleSmall;
    button.configuration = configuration;
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [button.heightAnchor constraintEqualToConstant:54].active = YES;
    return button;
}

- (UIButton *)secondaryButtonWithTitle:(NSString *)title symbol:(NSString *)symbol {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:symbol];
    configuration.imagePadding = 6;
    configuration.baseBackgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.16];
    configuration.baseForegroundColor = [JFTheme accent];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleSmall;
    button.configuration = configuration;
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    return button;
}

- (UIButton *)voteButtonWithTitle:(NSString *)title symbol:(NSString *)symbol color:(UIColor *)color {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:symbol];
    configuration.imagePadding = 7;
    configuration.baseBackgroundColor = color;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleSmall;
    button.configuration = configuration;
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBlack];
    return button;
}

@end
