//
//  JFCardArcadeViewController.m
//  JiFeng_UpApp
//

#import "JFCardArcadeViewController.h"
#import "JFCard.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFGamePieceSkin.h"
#import "JFSkinStore.h"

static NSInteger const JFPyramidArtworkTag = 7418;

@interface JFArcadeCardFace : UIView
@property (nonatomic, strong, nullable) JFCard *card;
@property (nonatomic, assign) BOOL faceDown;
@property (nonatomic, strong) UILabel *cornerLabel;
@property (nonatomic, strong) UILabel *centerLabel;
@property (nonatomic, strong) UIImageView *backIcon;
@property (nonatomic, strong) JFGamePieceSkinView *skinView;
@property (nonatomic, strong) JFCardFaceArtworkView *artworkView;
- (void)showCard:(nullable JFCard *)card faceDown:(BOOL)faceDown;
@end

@implementation JFArcadeCardFace

- (instancetype)init {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.layer.cornerRadius = 8;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 1;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.24;
        self.layer.shadowRadius = 8;
        self.layer.shadowOffset = CGSizeMake(0, 4);

        _skinView = [[JFGamePieceSkinView alloc] init];
        _skinView.surfaceStyle = JFGamePieceSurfaceStyleCardBack;
        [self addSubview:_skinView];

        _artworkView = [[JFCardFaceArtworkView alloc] init];
        _artworkView.userInteractionEnabled = NO;
        [self addSubview:_artworkView];

        _cornerLabel = [[UILabel alloc] init];
        _cornerLabel.numberOfLines = 2;
        _cornerLabel.textAlignment = NSTextAlignmentCenter;
        _cornerLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        [self addSubview:_cornerLabel];

        _centerLabel = [[UILabel alloc] init];
        _centerLabel.textAlignment = NSTextAlignmentCenter;
        _centerLabel.font = [UIFont systemFontOfSize:38 weight:UIFontWeightBlack];
        _centerLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_centerLabel];

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightBlack];
        _backIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"suit.club.fill" withConfiguration:config]];
        _backIcon.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        _backIcon.contentMode = UIViewContentModeCenter;
        [self addSubview:_backIcon];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onSkinChanged)
                                                     name:JFSkinDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.skinView.frame = self.bounds;
    self.artworkView.frame = self.bounds;
    CGFloat cornerWidth = MIN(42, width * 0.38);
    self.cornerLabel.frame = CGRectMake(5, 5, cornerWidth, MIN(45, height * 0.36));
    self.centerLabel.frame = CGRectInset(self.bounds, width * 0.17, height * 0.17);
    self.backIcon.frame = self.bounds;
    self.cornerLabel.font = [UIFont systemFontOfSize:MAX(10, MIN(18, width * 0.16)) weight:UIFontWeightBold];
    self.centerLabel.font = [UIFont systemFontOfSize:MAX(18, MIN(44, width * 0.38)) weight:UIFontWeightBlack];
}

- (void)showCard:(JFCard *)card faceDown:(BOOL)faceDown {
    self.card = card;
    self.faceDown = faceDown;
    JFSkin *skin = [JFGamePieceSkin currentSkin];
    if (faceDown || !card) {
        self.backgroundColor = UIColor.clearColor;
        self.skinView.surfaceStyle = JFGamePieceSurfaceStyleCardBack;
        self.layer.borderColor = UIColor.clearColor.CGColor;
        self.cornerLabel.hidden = YES;
        self.centerLabel.hidden = YES;
        self.artworkView.hidden = YES;
        self.backIcon.hidden = YES;
        self.accessibilityLabel = faceDown ? @"背面牌" : @"空牌位";
        return;
    }
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    UIColor *ink = red ? [JFGamePieceSkin cardRedInkColorForSkin:skin]
                       : [JFGamePieceSkin cardBlackInkColorForSkin:skin];
    self.backgroundColor = UIColor.clearColor;
    self.skinView.surfaceStyle = JFGamePieceSurfaceStyleCardFace;
    self.layer.borderColor = UIColor.clearColor.CGColor;
    self.artworkView.hidden = NO;
    [self.artworkView configureWithRank:card.rank
                                   suit:card.suit
                                compact:self.bounds.size.width > 0 && self.bounds.size.width < 72];
    self.cornerLabel.textColor = ink;
    self.centerLabel.textColor = ink;
    self.cornerLabel.text = [NSString stringWithFormat:@"%@\n%@", card.rank, card.suit];
    self.centerLabel.text = card.suit;
    self.cornerLabel.hidden = YES;
    self.centerLabel.hidden = YES;
    self.backIcon.hidden = YES;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@%@", card.rank, card.suit];
}

- (void)onSkinChanged {
    [self showCard:self.card faceDown:self.faceDown];
}

@end

@interface JFCardArcadeViewController ()
@property (nonatomic, assign) JFCardArcadeMode mode;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *boardView;
@property (nonatomic, strong) UIStackView *actionStack;
@property (nonatomic, copy) NSArray<UIButton *> *actionButtons;

@property (nonatomic, strong) NSMutableArray<JFCard *> *deck;

// 高低牌 / 比大小共用双牌位。
@property (nonatomic, strong) UILabel *leftCaption;
@property (nonatomic, strong) UILabel *rightCaption;
@property (nonatomic, strong) JFArcadeCardFace *leftFace;
@property (nonatomic, strong) JFArcadeCardFace *rightFace;
@property (nonatomic, strong) JFCard *highCurrent;
@property (nonatomic, strong, nullable) JFCard *highRevealed;
@property (nonatomic, assign) NSInteger highScore;
@property (nonatomic, assign) NSInteger highStreak;
@property (nonatomic, assign) BOOL highTransitioning;

// 二十一点。
@property (nonatomic, strong) UILabel *dealerCaption;
@property (nonatomic, strong) UILabel *playerCaption;
@property (nonatomic, strong) NSMutableArray<JFCard *> *dealerHand;
@property (nonatomic, strong) NSMutableArray<JFCard *> *playerHand;
@property (nonatomic, copy) NSArray<JFArcadeCardFace *> *dealerCardViews;
@property (nonatomic, copy) NSArray<JFArcadeCardFace *> *playerCardViews;
@property (nonatomic, assign) BOOL blackjackDealerHidden;
@property (nonatomic, assign) BOOL blackjackFinished;
@property (nonatomic, assign) NSInteger blackjackWins;

// 金字塔。
@property (nonatomic, copy) NSArray<JFCard *> *pyramidCards;
@property (nonatomic, strong) NSMutableIndexSet *pyramidRemoved;
@property (nonatomic, copy) NSArray<UIButton *> *pyramidButtons;
@property (nonatomic, strong) UIButton *pyramidWasteButton;
@property (nonatomic, strong) UILabel *pyramidStockLabel;
@property (nonatomic, strong, nullable) JFCard *pyramidWaste;
@property (nonatomic, assign) NSInteger pyramidSelection; // -1 无，-2 底牌，其余为塔中位置
@property (nonatomic, assign) NSInteger pyramidScore;

// 双人比大小。
@property (nonatomic, strong) NSMutableArray<JFCard *> *warPlayerDeck;
@property (nonatomic, strong) NSMutableArray<JFCard *> *warCPUDeck;
@property (nonatomic, assign) NSInteger warPlayerWins;
@property (nonatomic, assign) NSInteger warCPUWins;
@property (nonatomic, assign) NSInteger warRound;
@end

@implementation JFCardArcadeViewController

- (instancetype)init {
    return [self initWithMode:JFCardArcadeModeHighLow];
}

- (instancetype)initWithMode:(JFCardArcadeMode)mode {
    if ((self = [super init])) {
        _mode = MAX(JFCardArcadeModeHighLow, MIN(JFCardArcadeModeWar, mode));
        _pyramidSelection = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self modeTitle];
    [self buildUI];
    [self startCurrentMode];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onArcadeSkinChanged)
                                                 name:JFSkinDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onArcadeSkinChanged {
    if (self.mode == JFCardArcadeModePyramid) [self updatePyramidBoard];
}

- (NSString *)modeTitle {
    return @[@"高低猜牌", @"二十一点", @"金字塔", @"双人比大小"][self.mode];
}

- (NSString *)modeSubtitle {
    return @[
        @"判断下一张更高还是更低，连续猜中会获得连击加成",
        @"A 可作 1 或 11；超过 21 点即爆牌",
        @"只可选择未被压住的牌；两张合计 13，K 可单独消除",
        @"与电脑各持 26 张牌，翻完后胜局更多的一方获胜",
    ][self.mode];
}

#pragma mark - UI

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [self modeTitle];
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = [self modeSubtitle];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.numberOfLines = 2;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.subtitleLabel];

    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.textColor = [JFTheme textPrimary];
    self.scoreLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    self.scoreLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.09];
    self.scoreLabel.layer.cornerRadius = 8;
    self.scoreLabel.layer.borderWidth = 1;
    self.scoreLabel.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.scoreLabel.clipsToBounds = YES;
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scoreLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    self.boardView = [[UIView alloc] init];
    self.boardView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    self.boardView.layer.cornerRadius = 8;
    self.boardView.layer.borderWidth = 1;
    self.boardView.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.boardView.clipsToBounds = YES;
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.boardView];

    self.actionStack = [[UIStackView alloc] init];
    self.actionStack.axis = UILayoutConstraintAxisHorizontal;
    self.actionStack.distribution = UIStackViewDistributionFillEqually;
    self.actionStack.spacing = 10;
    self.actionStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.actionStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:64],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-64],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:24],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-24],

        [self.scoreLabel.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:10],
        [self.scoreLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.scoreLabel.heightAnchor constraintEqualToConstant:32],
        [self.scoreLabel.widthAnchor constraintGreaterThanOrEqualToConstant:178],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.scoreLabel.bottomAnchor constant:7],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],

        [self.boardView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:10],
        [self.boardView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.boardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.boardView.bottomAnchor constraintEqualToAnchor:self.actionStack.topAnchor constant:-12],

        [self.actionStack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.actionStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.actionStack.heightAnchor constraintEqualToConstant:50],
        [self.actionStack.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-14],
    ]];
}

- (UIButton *)actionButtonWithTitle:(NSString *)title primary:(BOOL)primary selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = primary ? [JFTheme brandPrimary] : [[UIColor whiteColor] colorWithAlphaComponent:0.09];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.layer.borderColor = primary ? [[JFTheme accent] colorWithAlphaComponent:0.5].CGColor : [JFTheme cardBorder].CGColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)setActionTitles:(NSArray<NSString *> *)titles selectors:(NSArray<NSString *> *)selectorNames {
    for (UIView *view in self.actionStack.arrangedSubviews.copy) {
        [self.actionStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        SEL selector = NSSelectorFromString(selectorNames[idx]);
        UIButton *button = [self actionButtonWithTitle:title primary:(idx == 0) selector:selector];
        [self.actionStack addArrangedSubview:button];
        [buttons addObject:button];
    }];
    self.actionButtons = buttons;
}

- (UILabel *)boardCaption:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [JFTheme textSecondary];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    [self.boardView addSubview:label];
    return label;
}

- (void)clearBoard {
    [self.boardView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.leftCaption = nil;
    self.rightCaption = nil;
    self.leftFace = nil;
    self.rightFace = nil;
    self.dealerCaption = nil;
    self.playerCaption = nil;
    self.dealerCardViews = @[];
    self.playerCardViews = @[];
    self.pyramidButtons = @[];
    self.pyramidWasteButton = nil;
    self.pyramidStockLabel = nil;
}

- (void)startCurrentMode {
    [self clearBoard];
    switch (self.mode) {
        case JFCardArcadeModeHighLow: [self setupHighLowBoard]; [self resetHighLow]; break;
        case JFCardArcadeModeBlackjack: [self setupBlackjackBoard]; [self startBlackjackRound]; break;
        case JFCardArcadeModePyramid: [self setupPyramidBoard]; [self resetPyramid]; break;
        case JFCardArcadeModeWar: [self setupWarBoard]; [self resetWar]; break;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    switch (self.mode) {
        case JFCardArcadeModeHighLow:
        case JFCardArcadeModeWar:
            [self layoutTwoCardBoard];
            break;
        case JFCardArcadeModeBlackjack:
            [self layoutBlackjackBoard];
            break;
        case JFCardArcadeModePyramid:
            [self layoutPyramidBoard];
            break;
    }
}

#pragma mark - Deck

- (NSMutableArray<JFCard *> *)freshDeck {
    NSMutableArray<JFCard *> *cards = [NSMutableArray arrayWithCapacity:52];
    for (NSString *suit in @[@"♠", @"♥", @"♦", @"♣"]) {
        for (NSString *rank in @[@"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"]) {
            JFCard *card = [JFCard new];
            card.rank = rank;
            card.suit = suit;
            [cards addObject:card];
        }
    }
    for (NSInteger idx = cards.count - 1; idx > 0; idx--) {
        NSInteger other = arc4random_uniform((uint32_t)(idx + 1));
        [cards exchangeObjectAtIndex:idx withObjectAtIndex:other];
    }
    return cards;
}

- (nullable JFCard *)drawFromDeck:(NSMutableArray<JFCard *> *)deck {
    if (deck.count == 0) return nil;
    JFCard *card = deck.lastObject;
    [deck removeLastObject];
    return card;
}

- (NSInteger)rankValue:(JFCard *)card {
    NSUInteger index = [@[@"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"] indexOfObject:card.rank];
    return index == NSNotFound ? 0 : (NSInteger)index + 1;
}

- (void)reportScore:(NSInteger)score win:(BOOL)win modeName:(NSString *)modeName {
    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindCard score:MAX(0, score) win:win];
    result.difficulty = self.mode + 1;
    result.extra = @{@"mode": modeName};
    [[JFProfileStore shared] reportResult:result];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindCard difficulty:result.difficulty score:result.score win:win];
}

#pragma mark - High / Low

- (void)setupHighLowBoard {
    self.leftCaption = [self boardCaption:@"当前牌"];
    self.rightCaption = [self boardCaption:@"下一张"];
    self.leftFace = [[JFArcadeCardFace alloc] init];
    self.rightFace = [[JFArcadeCardFace alloc] init];
    [self.boardView addSubview:self.leftFace];
    [self.boardView addSubview:self.rightFace];
    [self setActionTitles:@[@"更高", @"更低", @"重开"] selectors:@[@"onHighGuess", @"onLowGuess", @"resetHighLow"]];
}

- (void)resetHighLow {
    self.deck = [self freshDeck];
    self.highCurrent = [self drawFromDeck:self.deck];
    self.highRevealed = nil;
    self.highScore = 0;
    self.highStreak = 0;
    self.highTransitioning = NO;
    self.statusLabel.text = @"根据当前牌，判断下一张的点数";
    [self updateHighLowBoard];
}

- (void)updateHighLowBoard {
    [self.leftFace showCard:self.highCurrent faceDown:NO];
    [self.rightFace showCard:self.highRevealed faceDown:(self.highRevealed == nil)];
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld · 连击 %ld · 剩余 %ld", (long)self.highScore, (long)self.highStreak, (long)self.deck.count];
}

- (void)onHighGuess { [self performHighLowGuessHigher:YES]; }
- (void)onLowGuess { [self performHighLowGuessHigher:NO]; }

- (void)performHighLowGuessHigher:(BOOL)higher {
    if (self.highTransitioning) return;
    if (self.deck.count == 0) {
        [self reportScore:self.highScore win:YES modeName:@"高低猜牌"];
        self.statusLabel.text = [NSString stringWithFormat:@"整副牌完成 · 最终得分 %ld", (long)self.highScore];
        return;
    }
    self.highTransitioning = YES;
    for (UIButton *button in self.actionButtons) button.enabled = NO;

    JFCard *next = [self drawFromDeck:self.deck];
    self.highRevealed = next;
    NSInteger currentValue = [self rankValue:self.highCurrent];
    NSInteger nextValue = [self rankValue:next];
    BOOL tie = currentValue == nextValue;
    BOOL correct = tie || (higher ? nextValue > currentValue : nextValue < currentValue);
    if (correct) {
        self.highStreak += 1;
        NSInteger gain = tie ? 5 : 10 + MIN(50, self.highStreak * 2);
        self.highScore += gain;
        self.statusLabel.text = tie ? @"同点也算过关 · +5" : [NSString stringWithFormat:@"判断正确 · 连击 %ld", (long)self.highStreak];
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    } else {
        self.highStreak = 0;
        self.statusLabel.text = higher ? @"下一张更低，连击中断" : @"下一张更高，连击中断";
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    }
    [self updateHighLowBoard];
    [UIView transitionWithView:self.rightFace duration:0.28 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{} completion:nil];
    [self reportScore:correct ? 10 : 0 win:correct modeName:@"高低猜牌"];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.72 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.mode != JFCardArcadeModeHighLow) return;
        self.highCurrent = next;
        self.highRevealed = nil;
        self.highTransitioning = NO;
        for (UIButton *button in self.actionButtons) button.enabled = YES;
        [self updateHighLowBoard];
    });
}

#pragma mark - Blackjack

- (void)setupBlackjackBoard {
    self.dealerCaption = [self boardCaption:@"庄家"];
    self.playerCaption = [self boardCaption:@"你"];
    [self setActionTitles:@[@"要牌", @"停牌", @"新局"] selectors:@[@"onBlackjackHit", @"onBlackjackStand", @"startBlackjackRound"]];
}

- (void)startBlackjackRound {
    self.deck = [self freshDeck];
    self.dealerHand = [NSMutableArray array];
    self.playerHand = [NSMutableArray array];
    [self.playerHand addObject:[self drawFromDeck:self.deck]];
    [self.dealerHand addObject:[self drawFromDeck:self.deck]];
    [self.playerHand addObject:[self drawFromDeck:self.deck]];
    [self.dealerHand addObject:[self drawFromDeck:self.deck]];
    self.blackjackDealerHidden = YES;
    self.blackjackFinished = NO;
    self.statusLabel.text = @"要牌继续接近 21，或停牌与庄家比较";
    self.actionButtons[0].enabled = YES;
    self.actionButtons[1].enabled = YES;
    [self refreshBlackjackBoard];
}

- (NSInteger)blackjackTotal:(NSArray<JFCard *> *)hand {
    NSInteger total = 0;
    NSInteger aces = 0;
    for (JFCard *card in hand) {
        NSInteger value = [self rankValue:card];
        if (value == 1) {
            total += 11;
            aces += 1;
        } else {
            total += MIN(value, 10);
        }
    }
    while (total > 21 && aces > 0) {
        total -= 10;
        aces -= 1;
    }
    return total;
}

- (void)refreshBlackjackBoard {
    [self.dealerCardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.playerCardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *dealerViews = [NSMutableArray array];
    [self.dealerHand enumerateObjectsUsingBlock:^(JFCard *card, NSUInteger idx, BOOL *stop) {
        JFArcadeCardFace *view = [[JFArcadeCardFace alloc] init];
        [view showCard:card faceDown:(self.blackjackDealerHidden && idx == 1)];
        [self.boardView addSubview:view];
        [dealerViews addObject:view];
    }];
    NSMutableArray *playerViews = [NSMutableArray array];
    for (JFCard *card in self.playerHand) {
        JFArcadeCardFace *view = [[JFArcadeCardFace alloc] init];
        [view showCard:card faceDown:NO];
        [self.boardView addSubview:view];
        [playerViews addObject:view];
    }
    self.dealerCardViews = dealerViews;
    self.playerCardViews = playerViews;
    NSInteger dealerVisible = self.blackjackDealerHidden ? MIN(10, [self rankValue:self.dealerHand.firstObject]) : [self blackjackTotal:self.dealerHand];
    NSInteger player = [self blackjackTotal:self.playerHand];
    self.dealerCaption.text = [NSString stringWithFormat:@"庄家 · %@", self.blackjackDealerHidden ? @"?" : @(dealerVisible)];
    self.playerCaption.text = [NSString stringWithFormat:@"你 · %ld 点", (long)player];
    self.scoreLabel.text = [NSString stringWithFormat:@"胜局 %ld · 本局 %ld 点", (long)self.blackjackWins, (long)player];
    [self.view setNeedsLayout];
}

- (void)onBlackjackHit {
    if (self.blackjackFinished) return;
    JFCard *card = [self drawFromDeck:self.deck];
    if (card) [self.playerHand addObject:card];
    NSInteger total = [self blackjackTotal:self.playerHand];
    [JFTheme hapticImpactLight];
    if (total > 21) {
        [self finishBlackjackWithWin:NO message:@"爆牌，庄家获胜"];
    } else if (total == 21) {
        [self onBlackjackStand];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"拿到 %@%@ · 当前 %ld 点", card.rank, card.suit, (long)total];
        [self refreshBlackjackBoard];
    }
}

- (void)onBlackjackStand {
    if (self.blackjackFinished) return;
    self.blackjackDealerHidden = NO;
    while ([self blackjackTotal:self.dealerHand] < 17) {
        JFCard *card = [self drawFromDeck:self.deck];
        if (!card) break;
        [self.dealerHand addObject:card];
    }
    NSInteger player = [self blackjackTotal:self.playerHand];
    NSInteger dealer = [self blackjackTotal:self.dealerHand];
    BOOL win = player <= 21 && (dealer > 21 || player > dealer);
    BOOL push = player == dealer && player <= 21;
    NSString *message = push ? @"平局，本轮不计胜负" : (win ? @"你更接近 21，获胜" : @"庄家获胜");
    [self finishBlackjackWithWin:win message:message];
}

- (void)finishBlackjackWithWin:(BOOL)win message:(NSString *)message {
    if (self.blackjackFinished) return;
    self.blackjackFinished = YES;
    self.blackjackDealerHidden = NO;
    if (win) self.blackjackWins += 1;
    self.actionButtons[0].enabled = NO;
    self.actionButtons[1].enabled = NO;
    self.statusLabel.text = message;
    [self refreshBlackjackBoard];
    [JFTheme hapticNotification:win ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeError];
    [self reportScore:win ? 100 : [self blackjackTotal:self.playerHand] win:win modeName:@"二十一点"];
}

#pragma mark - Pyramid

- (void)setupPyramidBoard {
    NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:28];
    for (NSInteger idx = 0; idx < 28; idx++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = idx;
        button.titleLabel.numberOfLines = 2;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        button.layer.cornerRadius = 5;
        button.layer.borderWidth = 1;
        JFCardFaceArtworkView *artwork = [[JFCardFaceArtworkView alloc] init];
        artwork.tag = JFPyramidArtworkTag;
        artwork.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [button insertSubview:artwork atIndex:0];
        [button addTarget:self action:@selector(onPyramidCard:) forControlEvents:UIControlEventTouchUpInside];
        [self.boardView addSubview:button];
        [buttons addObject:button];
    }
    self.pyramidButtons = buttons;

    self.pyramidWasteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.pyramidWasteButton.titleLabel.numberOfLines = 2;
    self.pyramidWasteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.pyramidWasteButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    self.pyramidWasteButton.layer.cornerRadius = 6;
    self.pyramidWasteButton.layer.borderWidth = 2;
    JFCardFaceArtworkView *wasteArtwork = [[JFCardFaceArtworkView alloc] init];
    wasteArtwork.tag = JFPyramidArtworkTag;
    wasteArtwork.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.pyramidWasteButton insertSubview:wasteArtwork atIndex:0];
    [self.pyramidWasteButton addTarget:self action:@selector(onPyramidWaste) forControlEvents:UIControlEventTouchUpInside];
    [self.boardView addSubview:self.pyramidWasteButton];

    self.pyramidStockLabel = [self boardCaption:@"底牌"];
    [self setActionTitles:@[@"翻底牌", @"重开"] selectors:@[@"onPyramidDraw", @"resetPyramid"]];
}

- (void)resetPyramid {
    self.deck = [self freshDeck];
    NSMutableArray<JFCard *> *tower = [NSMutableArray arrayWithCapacity:28];
    for (NSInteger idx = 0; idx < 28; idx++) {
        JFCard *card = [self drawFromDeck:self.deck];
        if (card) [tower addObject:card];
    }
    self.pyramidCards = tower;
    self.pyramidRemoved = [NSMutableIndexSet indexSet];
    self.pyramidWaste = nil;
    self.pyramidSelection = -1;
    self.pyramidScore = 0;
    self.statusLabel.text = @"先从最底层开始；选择两张合计 13 的牌";
    [self updatePyramidBoard];
}

- (NSInteger)pyramidRowForIndex:(NSInteger)index {
    NSInteger row = 0;
    while (row < 7) {
        NSInteger start = row * (row + 1) / 2;
        NSInteger end = start + row;
        if (index >= start && index <= end) return row;
        row += 1;
    }
    return 6;
}

- (BOOL)isPyramidCardExposed:(NSInteger)index {
    if ([self.pyramidRemoved containsIndex:index]) return NO;
    NSInteger row = [self pyramidRowForIndex:index];
    if (row == 6) return YES;
    NSInteger childStart = (row + 1) * (row + 2) / 2;
    NSInteger col = index - row * (row + 1) / 2;
    return [self.pyramidRemoved containsIndex:childStart + col] &&
           [self.pyramidRemoved containsIndex:childStart + col + 1];
}

- (void)stylePyramidButton:(UIButton *)button card:(JFCard *)card selected:(BOOL)selected available:(BOOL)available {
    JFSkin *skin = [JFGamePieceSkin currentSkin];
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    UIColor *ink = red ? [JFGamePieceSkin cardRedInkColorForSkin:skin]
                       : [JFGamePieceSkin cardBlackInkColorForSkin:skin];
    JFCardFaceArtworkView *artwork = (JFCardFaceArtworkView *)[button viewWithTag:JFPyramidArtworkTag];
    artwork.frame = button.bounds;
    artwork.skin = skin;
    [artwork configureWithRank:card.rank suit:card.suit compact:YES];
    [button setTitle:@"" forState:UIControlStateNormal];
    [button setTitleColor:ink forState:UIControlStateNormal];
    button.backgroundColor = [[JFGamePieceSkin cardFaceColorForSkin:skin] colorWithAlphaComponent:available ? 1 : 0.78];
    button.layer.borderColor = selected ? [JFTheme accent].CGColor : [[JFGamePieceSkin cardBorderColorForSkin:skin] colorWithAlphaComponent:0.64].CGColor;
    button.layer.borderWidth = selected ? 3 : 1;
    button.alpha = available ? 1 : 0.78;
    button.enabled = available;
}

- (void)updatePyramidBoard {
    [self.pyramidButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        BOOL removed = [self.pyramidRemoved containsIndex:idx];
        button.hidden = removed;
        if (!removed) {
            [self stylePyramidButton:button
                                card:self.pyramidCards[idx]
                            selected:(self.pyramidSelection == (NSInteger)idx)
                           available:[self isPyramidCardExposed:idx]];
        }
    }];
    if (self.pyramidWaste) {
        self.pyramidWasteButton.hidden = NO;
        [self stylePyramidButton:self.pyramidWasteButton
                            card:self.pyramidWaste
                        selected:(self.pyramidSelection == -2)
                       available:YES];
    } else {
        self.pyramidWasteButton.hidden = NO;
        JFCardFaceArtworkView *artwork = (JFCardFaceArtworkView *)[self.pyramidWasteButton viewWithTag:JFPyramidArtworkTag];
        [artwork configureWithRank:@"" suit:@"" compact:YES];
        self.pyramidWasteButton.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.7];
        self.pyramidWasteButton.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.pyramidWasteButton.layer.borderWidth = 1;
        [self.pyramidWasteButton setTitle:@"底牌\n待翻" forState:UIControlStateNormal];
        [self.pyramidWasteButton setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    }
    self.pyramidStockLabel.text = [NSString stringWithFormat:@"底牌剩余 %ld", (long)self.deck.count];
    self.scoreLabel.text = [NSString stringWithFormat:@"已拆 %ld / 28 · 得分 %ld", (long)self.pyramidRemoved.count, (long)self.pyramidScore];
    [self.view setNeedsLayout];
}

- (void)onPyramidCard:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (![self isPyramidCardExposed:index]) return;
    JFCard *card = self.pyramidCards[index];
    NSInteger value = [self rankValue:card];
    if (value == 13) {
        [self.pyramidRemoved addIndex:index];
        self.pyramidSelection = -1;
        self.pyramidScore += 15;
        self.statusLabel.text = @"K 可单独消除";
        [self pyramidDidRemoveCards];
        return;
    }
    if (self.pyramidSelection == index) {
        self.pyramidSelection = -1;
        self.statusLabel.text = @"已取消选择";
    } else if (self.pyramidSelection >= 0) {
        NSInteger first = self.pyramidSelection;
        NSInteger sum = [self rankValue:self.pyramidCards[first]] + value;
        if (sum == 13) {
            [self.pyramidRemoved addIndex:first];
            [self.pyramidRemoved addIndex:index];
            self.pyramidSelection = -1;
            self.pyramidScore += 30;
            self.statusLabel.text = @"配对成功，牌塔露出新位置";
            [self pyramidDidRemoveCards];
            return;
        }
        self.pyramidSelection = index;
        self.statusLabel.text = [NSString stringWithFormat:@"合计 %ld，不等于 13", (long)sum];
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    } else if (self.pyramidSelection == -2 && self.pyramidWaste) {
        NSInteger sum = [self rankValue:self.pyramidWaste] + value;
        if (sum == 13) {
            [self.pyramidRemoved addIndex:index];
            self.pyramidWaste = nil;
            self.pyramidSelection = -1;
            self.pyramidScore += 25;
            self.statusLabel.text = @"与底牌配对成功";
            [self pyramidDidRemoveCards];
            return;
        }
        self.pyramidSelection = index;
        self.statusLabel.text = [NSString stringWithFormat:@"合计 %ld，不等于 13", (long)sum];
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    } else {
        self.pyramidSelection = index;
        self.statusLabel.text = [NSString stringWithFormat:@"已选 %@%@，再选一张凑 13", card.rank, card.suit];
        [JFTheme hapticSelection];
    }
    [self updatePyramidBoard];
}

- (void)onPyramidWaste {
    if (!self.pyramidWaste) {
        [self onPyramidDraw];
        return;
    }
    NSInteger value = [self rankValue:self.pyramidWaste];
    if (value == 13) {
        self.pyramidWaste = nil;
        self.pyramidSelection = -1;
        self.pyramidScore += 10;
        self.statusLabel.text = @"底牌 K 单独消除";
        [self updatePyramidBoard];
        return;
    }
    if (self.pyramidSelection >= 0) {
        NSInteger first = self.pyramidSelection;
        NSInteger sum = [self rankValue:self.pyramidCards[first]] + value;
        if (sum == 13) {
            [self.pyramidRemoved addIndex:first];
            self.pyramidWaste = nil;
            self.pyramidSelection = -1;
            self.pyramidScore += 25;
            self.statusLabel.text = @"与底牌配对成功";
            [self pyramidDidRemoveCards];
            return;
        }
        self.statusLabel.text = [NSString stringWithFormat:@"合计 %ld，不等于 13", (long)sum];
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    }
    self.pyramidSelection = self.pyramidSelection == -2 ? -1 : -2;
    [self updatePyramidBoard];
}

- (void)onPyramidDraw {
    JFCard *card = [self drawFromDeck:self.deck];
    if (!card) {
        self.statusLabel.text = @"底牌已翻完，尝试清理当前可见牌";
        [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
        return;
    }
    self.pyramidWaste = card;
    self.pyramidSelection = -1;
    self.statusLabel.text = [NSString stringWithFormat:@"翻出 %@%@，可与塔中牌凑 13", card.rank, card.suit];
    [JFTheme hapticImpactLight];
    [self updatePyramidBoard];
}

- (void)pyramidDidRemoveCards {
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    [self updatePyramidBoard];
    if (self.pyramidRemoved.count == 28) {
        self.statusLabel.text = @"牌塔全部拆除，通关！";
        [self reportScore:500 + self.pyramidScore win:YES modeName:@"金字塔"];
    }
}

#pragma mark - War

- (void)setupWarBoard {
    self.leftCaption = [self boardCaption:@"你"];
    self.rightCaption = [self boardCaption:@"电脑"];
    self.leftFace = [[JFArcadeCardFace alloc] init];
    self.rightFace = [[JFArcadeCardFace alloc] init];
    [self.boardView addSubview:self.leftFace];
    [self.boardView addSubview:self.rightFace];
    [self setActionTitles:@[@"翻牌", @"重开"] selectors:@[@"onWarDraw", @"resetWar"]];
}

- (void)resetWar {
    NSMutableArray<JFCard *> *cards = [self freshDeck];
    self.warPlayerDeck = [NSMutableArray array];
    self.warCPUDeck = [NSMutableArray array];
    BOOL toPlayer = YES;
    for (JFCard *card in cards) {
        [(toPlayer ? self.warPlayerDeck : self.warCPUDeck) addObject:card];
        toPlayer = !toPlayer;
    }
    self.warPlayerWins = 0;
    self.warCPUWins = 0;
    self.warRound = 0;
    [self.leftFace showCard:nil faceDown:YES];
    [self.rightFace showCard:nil faceDown:YES];
    self.statusLabel.text = @"点击翻牌，同时揭晓双方点数";
    [self updateWarScore];
    self.actionButtons.firstObject.enabled = YES;
}

- (void)updateWarScore {
    self.scoreLabel.text = [NSString stringWithFormat:@"你 %ld : %ld 电脑 · 第 %ld / 26 轮", (long)self.warPlayerWins, (long)self.warCPUWins, (long)self.warRound];
}

- (void)onWarDraw {
    if (self.warPlayerDeck.count == 0 || self.warCPUDeck.count == 0) return;
    JFCard *player = [self drawFromDeck:self.warPlayerDeck];
    JFCard *cpu = [self drawFromDeck:self.warCPUDeck];
    self.warRound += 1;
    [self.leftFace showCard:player faceDown:NO];
    [self.rightFace showCard:cpu faceDown:NO];
    NSInteger playerValue = [self rankValue:player];
    NSInteger cpuValue = [self rankValue:cpu];
    if (playerValue > cpuValue) {
        self.warPlayerWins += 1;
        self.statusLabel.text = @"这一轮你更大";
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    } else if (cpuValue > playerValue) {
        self.warCPUWins += 1;
        self.statusLabel.text = @"这一轮电脑更大";
        [JFTheme hapticImpactLight];
    } else {
        self.statusLabel.text = @"点数相同，本轮平局";
        [JFTheme hapticSelection];
    }
    [self updateWarScore];
    [UIView transitionWithView:self.boardView duration:0.25 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{} completion:nil];
    if (self.warRound == 26) {
        BOOL win = self.warPlayerWins > self.warCPUWins;
        self.statusLabel.text = win ? @"26 轮结束，你赢下了整场！" : (self.warPlayerWins == self.warCPUWins ? @"26 轮结束，双方战平" : @"26 轮结束，电脑获胜");
        self.actionButtons.firstObject.enabled = NO;
        [self reportScore:self.warPlayerWins * 20 win:win modeName:@"双人比大小"];
    }
}

#pragma mark - Layout

- (void)layoutTwoCardBoard {
    CGFloat width = self.boardView.bounds.size.width;
    CGFloat height = self.boardView.bounds.size.height;
    if (width <= 0 || height <= 0 || !self.leftFace) return;
    CGFloat gap = 20;
    CGFloat cardWidth = MIN(132, (width - 44 - gap) / 2.0);
    CGFloat cardHeight = MIN(cardWidth * 1.4, height - 68);
    cardWidth = MIN(cardWidth, cardHeight / 1.4);
    CGFloat total = cardWidth * 2 + gap;
    CGFloat left = (width - total) / 2.0;
    CGFloat top = MAX(40, (height - cardHeight) / 2.0 + 8);
    self.leftCaption.frame = CGRectMake(left, 12, cardWidth, 22);
    self.rightCaption.frame = CGRectMake(left + cardWidth + gap, 12, cardWidth, 22);
    self.leftFace.frame = CGRectMake(left, top, cardWidth, cardHeight);
    self.rightFace.frame = CGRectMake(left + cardWidth + gap, top, cardWidth, cardHeight);
}

- (void)layoutBlackjackBoard {
    CGFloat width = self.boardView.bounds.size.width;
    CGFloat height = self.boardView.bounds.size.height;
    if (width <= 0 || height <= 0) return;
    CGFloat half = height / 2.0;
    self.dealerCaption.frame = CGRectMake(12, 8, width - 24, 20);
    self.playerCaption.frame = CGRectMake(12, half + 3, width - 24, 20);
    [self layoutCardViews:self.dealerCardViews inRect:CGRectMake(12, 32, width - 24, MAX(65, half - 38))];
    [self layoutCardViews:self.playerCardViews inRect:CGRectMake(12, half + 28, width - 24, MAX(65, half - 36))];
}

- (void)layoutCardViews:(NSArray<JFArcadeCardFace *> *)views inRect:(CGRect)rect {
    if (views.count == 0) return;
    CGFloat cardHeight = MIN(110, rect.size.height);
    CGFloat cardWidth = cardHeight / 1.4;
    CGFloat step = views.count == 1 ? 0 : MIN(cardWidth + 7, (rect.size.width - cardWidth) / (views.count - 1));
    CGFloat total = cardWidth + step * (views.count - 1);
    CGFloat startX = rect.origin.x + MAX(0, (rect.size.width - total) / 2.0);
    CGFloat y = rect.origin.y + MAX(0, (rect.size.height - cardHeight) / 2.0);
    [views enumerateObjectsUsingBlock:^(JFArcadeCardFace *view, NSUInteger idx, BOOL *stop) {
        view.frame = CGRectMake(startX + idx * step, y, cardWidth, cardHeight);
    }];
}

- (void)layoutPyramidBoard {
    CGFloat width = self.boardView.bounds.size.width;
    CGFloat height = self.boardView.bounds.size.height;
    if (width <= 0 || height <= 0 || self.pyramidButtons.count != 28) return;
    CGFloat gap = 3;
    CGFloat cardWidth = MIN(44, (width - 30 - gap * 6) / 7.0);
    CGFloat cardHeight = cardWidth * 1.28;
    CGFloat rowStep = MIN(cardHeight * 0.61, MAX(24, (height - 112 - cardHeight) / 6.0));
    NSInteger idx = 0;
    for (NSInteger row = 0; row < 7; row++) {
        CGFloat rowWidth = (row + 1) * cardWidth + row * gap;
        CGFloat x = (width - rowWidth) / 2.0;
        CGFloat y = 8 + row * rowStep;
        for (NSInteger col = 0; col <= row; col++) {
            self.pyramidButtons[idx].frame = CGRectMake(x + col * (cardWidth + gap), y, cardWidth, cardHeight);
            [self.pyramidButtons[idx] viewWithTag:JFPyramidArtworkTag].frame = self.pyramidButtons[idx].bounds;
            idx += 1;
        }
    }
    CGFloat wasteWidth = MIN(58, cardWidth * 1.22);
    CGFloat wasteHeight = wasteWidth * 1.28;
    CGFloat wasteY = MIN(height - wasteHeight - 8, 8 + 6 * rowStep + cardHeight + 12);
    self.pyramidWasteButton.frame = CGRectMake((width - wasteWidth) / 2.0, wasteY, wasteWidth, wasteHeight);
    [self.pyramidWasteButton viewWithTag:JFPyramidArtworkTag].frame = self.pyramidWasteButton.bounds;
    self.pyramidStockLabel.frame = CGRectMake(12, wasteY + (wasteHeight - 24) / 2.0, (width - wasteWidth) / 2.0 - 24, 24);
}

@end
