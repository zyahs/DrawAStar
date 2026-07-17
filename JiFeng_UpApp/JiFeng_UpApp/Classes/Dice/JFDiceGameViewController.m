//
//  JFDiceGameViewController.m
//  JiFeng_UpApp
//

#import "JFDiceGameViewController.h"
#import "JFDiceRollSurface.h"
#import "JFDiceResultBoardView.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFTheme.h"

@interface JFDiceGameViewController () <JFDiceRollSurfaceDelegate>
@property (nonatomic, strong) JFDiceGameDefinition *definition;
@property (nonatomic, assign) NSInteger diceCount;
@property (nonatomic, assign) NSInteger playerCount;
@property (nonatomic, assign) NSInteger currentPlayerIndex;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *results;
@property (nonatomic, strong) UILabel *roundLabel;
@property (nonatomic, strong) UILabel *ruleLabel;
@property (nonatomic, strong) JFDiceRollSurface *rollSurface;
@property (nonatomic, strong) UILabel *instructionLabel;
@property (nonatomic, strong) JFDiceResultBoardView *resultBoard;
@property (nonatomic, strong) UIButton *actionButton;
@end

@implementation JFDiceGameViewController

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition
                          diceCount:(NSInteger)diceCount
                        playerCount:(NSInteger)playerCount {
    if ((self = [super init])) {
        _definition = definition;
        _diceCount = MAX(1, MIN(100, diceCount));
        _playerCount = MAX(1, MIN(12, playerCount));
        _results = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.definition.title;
    [self buildUI];
    [self beginNewRound];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder { return YES; }

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (UIButton *)commandButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [[JFTheme accent] colorWithAlphaComponent:0.9];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    button.layer.cornerRadius = 8;
    [button.heightAnchor constraintEqualToConstant:48].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
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

    UILabel *meta = [self labelWithFont:[JFTheme fontCallout] color:[JFTheme textSecondary] lines:1];
    meta.text = [NSString stringWithFormat:@"本机 %ld 人 · 每人 %ld 颗", (long)self.playerCount, (long)self.diceCount];
    [content addArrangedSubview:meta];
    [content setCustomSpacing:16 afterView:meta];

    self.ruleLabel = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textSecondary] lines:0];
    self.ruleLabel.text = self.definition.ruleGuide;
    [content addArrangedSubview:self.ruleLabel];
    [content setCustomSpacing:15 afterView:self.ruleLabel];

    self.roundLabel = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightBold]
                                    color:[JFTheme textPrimary]
                                    lines:2];
    self.roundLabel.textAlignment = NSTextAlignmentCenter;
    [content addArrangedSubview:self.roundLabel];

    self.resultBoard = [[JFDiceResultBoardView alloc] initWithDefinition:self.definition];
    self.resultBoard.hidden = YES;
    [content addArrangedSubview:self.resultBoard];

    self.rollSurface = [[JFDiceRollSurface alloc] initWithDiceCount:self.diceCount];
    self.rollSurface.delegate = self;
    [self.rollSurface.heightAnchor constraintEqualToConstant:329].active = YES;
    [content addArrangedSubview:self.rollSurface];

    self.actionButton = [self commandButtonWithTitle:@"交给下一位" action:@selector(onActionButton)];
    self.actionButton.hidden = YES;
    [content addArrangedSubview:self.actionButton];

    self.instructionLabel = [self labelWithFont:[JFTheme fontBody] color:[JFTheme textPrimary] lines:0];
    self.instructionLabel.textAlignment = NSTextAlignmentLeft;
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

- (NSString *)nameForPlayerIndex:(NSInteger)index {
    if (index == 0 && [JFProfileStore shared].displayName.length > 0) return [JFProfileStore shared].displayName;
    return [NSString stringWithFormat:@"玩家 %ld", (long)index + 1];
}

- (NSString *)playerIdForIndex:(NSInteger)index {
    return index == 0 ? @"local-owner" : [NSString stringWithFormat:@"local-player-%ld", (long)index + 1];
}

- (void)beginNewRound {
    self.currentPlayerIndex = 0;
    [self.results removeAllObjects];
    self.instructionLabel.hidden = NO;
    self.instructionLabel.text = @"所有人完成前，点数都会保持封存。";
    [self.resultBoard reset];
    self.resultBoard.hidden = YES;
    self.rollSurface.hidden = NO;
    self.actionButton.hidden = YES;
    self.rollSurface.rollEnabled = YES;
    self.rollSurface.concealsFinalResult = self.playerCount > 1 && self.definition.mode != JFDiceGameModeLiar;
    [self.rollSurface resetForNextRoll];
    [self updateCurrentPlayerLabel];
}

- (void)updateCurrentPlayerLabel {
    NSString *name = [self nameForPlayerIndex:self.currentPlayerIndex];
    self.roundLabel.text = [NSString stringWithFormat:@"轮到 %@\n摇动手机，停下后保持静止", name];
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
    NSString *name = [self nameForPlayerIndex:self.currentPlayerIndex];
    [self.results addObject:@{@"playerId": [self playerIdForIndex:self.currentPlayerIndex],
                              @"displayName": name,
                              @"values": values}];
    surface.rollEnabled = NO;

    if (self.currentPlayerIndex + 1 < self.playerCount) {
        NSString *nextName = [self nameForPlayerIndex:self.currentPlayerIndex + 1];
        self.roundLabel.text = [NSString stringWithFormat:@"%@ 已封盘", name];
        self.instructionLabel.text = self.definition.mode == JFDiceGameModeLiar
            ? [NSString stringWithFormat:@"记住自己的骰子后交给 %@；下一页会先清空本轮点数。", nextName]
            : [NSString stringWithFormat:@"请把手机交给 %@，上一位的结果不会提前显示。", nextName];
        [self.actionButton setTitle:[NSString stringWithFormat:@"交给 %@", nextName] forState:UIControlStateNormal];
        self.actionButton.hidden = NO;
        return;
    }
    [self finishRound];
}

- (void)onActionButton {
    if (self.results.count >= self.playerCount) {
        [self beginNewRound];
        return;
    }
    self.currentPlayerIndex += 1;
    self.actionButton.hidden = YES;
    self.instructionLabel.text = @"结果继续保密，完成后再交给下一位。";
    self.rollSurface.rollEnabled = YES;
    [self.rollSurface resetForNextRoll];
    [self updateCurrentPlayerLabel];
    [JFTheme hapticSelection];
}

- (void)finishRound {
    [self.rollSurface revealFinalValues];
    self.roundLabel.text = @"所有玩家已完成 · 统一开盅";
    self.rollSurface.hidden = YES;
    self.instructionLabel.hidden = YES;
    self.resultBoard.hidden = NO;
    [self.resultBoard showResults:self.results
                          summary:[self.definition resultSummaryForResults:self.results]
                    localPlayerId:@"local-owner"];
    [self.actionButton setTitle:@"开始下一轮" forState:UIControlStateNormal];
    self.actionButton.hidden = NO;

    NSInteger score = 0;
    for (NSDictionary *result in self.results) {
        for (NSNumber *value in result[@"values"]) score += value.integerValue;
    }
    JFGameResult *gameResult = [JFGameResult resultWithKind:JFGameKindDice score:score win:YES];
    gameResult.difficulty = self.diceCount;
    gameResult.extra = @{@"mode": self.definition.serviceType,
                         @"playerCount": @(self.playerCount),
                         @"diceCount": @(self.diceCount)};
    [[JFProfileStore shared] reportResult:gameResult];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindDice difficulty:self.diceCount score:score win:YES];
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
}

@end
