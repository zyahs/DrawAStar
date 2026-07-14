//
//  CardsGameViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "CardsGameViewController.h"
#import "JFCardsPreviewGridVC.h"
#import "JFCard.h"
#import <QuartzCore/QuartzCore.h>
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFTheme.h"

static NSDictionary<NSString *, NSString *> *JFPartyRule(NSString *title, NSString *body) {
    return @{ @"title": title, @"body": body };
}

#pragma mark - Rules Banner UI

@interface JFRulesBannerView : UIView
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
- (void)showWithTitle:(NSString *)title body:(NSString *)body inView:(UIView *)parent autoHide:(BOOL)autoHide;
@end

@implementation JFRulesBannerView
- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;
        self.alpha = 0.0;
        // Gradient
        _gradient = [CAGradientLayer layer];
        _gradient.colors = @[(__bridge id)[UIColor colorWithRed:0.98 green:0.67 blue:0.94 alpha:1].CGColor,
                             (__bridge id)[UIColor colorWithRed:0.67 green:0.80 blue:1 alpha:1].CGColor,
                             (__bridge id)[UIColor colorWithRed:0.76 green:1 blue:0.86 alpha:1].CGColor];
        _gradient.startPoint = CGPointMake(0, 0);
        _gradient.endPoint = CGPointMake(1, 1);
        [self.layer addSublayer:_gradient];
        // Blur-like soft overlay
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        // Labels
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _bodyLabel.textColor = UIColor.whiteColor;
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_titleLabel];
        [self addSubview:_bodyLabel];
        // Subtle wobble animation
        CABasicAnimation *rot = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rot.fromValue = @( - M_PI / 360.0 * 2 );
        rot.toValue   = @(   M_PI / 360.0 * 2 );
        rot.duration = 2.2;
        rot.autoreverses = YES;
        rot.repeatCount = HUGE_VALF;
        [self.layer addAnimation:rot forKey:@"wobble"];
        // Animated gradient shift
        CABasicAnimation *grad = [CABasicAnimation animationWithKeyPath:@"colors"];
        grad.duration = 4.0;
        grad.repeatCount = HUGE_VALF;
        grad.autoreverses = YES;
        grad.toValue = @[(__bridge id)[UIColor colorWithRed:0.88 green:0.70 blue:1 alpha:1].CGColor,
                         (__bridge id)[UIColor colorWithRed:0.60 green:0.86 blue:1 alpha:1].CGColor,
                         (__bridge id)[UIColor colorWithRed:0.86 green:1 blue:0.78 alpha:1].CGColor];
        [_gradient addAnimation:grad forKey:@"shift"];
        // Tap to dismiss
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
//        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _gradient.frame = self.bounds;
    CGFloat pad = 16;
    _titleLabel.frame = CGRectMake(pad, pad, self.bounds.size.width - pad*2, 24);
    _bodyLabel.frame  = CGRectMake(pad, CGRectGetMaxY(_titleLabel.frame)+8, self.bounds.size.width - pad*2, self.bounds.size.height - pad*3 - 24);
}
- (void)showWithTitle:(NSString *)title body:(NSString *)body inView:(UIView *)parent autoHide:(BOOL)autoHide {
    _titleLabel.text = title;
    _bodyLabel.text  = body;
    if (!self.superview) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [parent addSubview:self];
        UILayoutGuide *safe = parent.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [self.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
            [self.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
            [self.topAnchor constraintEqualToAnchor:safe.topAnchor constant:80],
        ]];
        // Set an intrinsic height
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:160].active = YES;
    }
    [self.superview layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{ self.alpha = 1.0; }];
    if (autoHide) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self hide]; });
    }
}
- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0.0; } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end

#pragma mark - Card View (no assets, pure drawing)

@interface JFCardView : UIView
@property (nonatomic, strong) JFCard *card;
@end

@implementation JFCardView {
    UILabel *_tlRank, *_tlSuit, *_brRank, *_brSuit, *_centerLabel;
}
- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = UIColor.clearColor;
        self.layer.cornerRadius = 16;
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowRadius  = 12;
        self.layer.shadowOffset  = CGSizeMake(0, 6);

        UIView *cardBG = [[UIView alloc] init];
        cardBG.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96];
        cardBG.layer.cornerRadius = 16;
        cardBG.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
        cardBG.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        cardBG.tag = 101;
        [self addSubview:cardBG];

        _tlRank = [self label:18 weight:UIFontWeightSemibold];
        _tlSuit = [self label:18 weight:UIFontWeightRegular];
        _brRank = [self label:18 weight:UIFontWeightSemibold];
        _brSuit = [self label:18 weight:UIFontWeightRegular];
        _centerLabel = [self label:56 weight:UIFontWeightBlack];

        [self addSubview:_tlRank];
        [self addSubview:_tlSuit];
        [self addSubview:_brRank];
        [self addSubview:_brSuit];
        [self addSubview:_centerLabel];
    }
    return self;
}

- (UILabel *)label:(CGFloat)size weight:(UIFontWeight)w {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:size weight:w];
    l.textAlignment = NSTextAlignmentCenter;
    l.adjustsFontSizeToFitWidth = YES;
    return l;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *bg = [self viewWithTag:101];
    bg.frame = self.bounds;

    CGFloat pad = 12;
    _tlRank.frame = CGRectMake(pad, pad, 40, 22);
    _tlSuit.frame = CGRectMake(pad, CGRectGetMaxY(_tlRank.frame)-2, 40, 22);

    _brRank.frame = CGRectMake(self.bounds.size.width - pad - 40,
                               self.bounds.size.height - pad - 44, 40, 22);
    _brSuit.frame = CGRectMake(self.bounds.size.width - pad - 40,
                               self.bounds.size.height - pad - 22, 40, 22);

    _centerLabel.frame = CGRectInset(self.bounds, 24, 24);
}

- (void)setCard:(JFCard *)card {
    _card = card;
    // Fallback to placeholder when card is nil
    NSString *rank = card ? card.rank : @"999";
    NSString *suit = card ? card.suit : @"999";

    BOOL placeholder = [rank isEqualToString:@"999"];
    BOOL red = [suit isEqualToString:@"♥"] || [suit isEqualToString:@"♦"];
    UIColor *c = card ? (red ? [UIColor colorWithRed:0.90 green:0.11 blue:0.14 alpha:1]
                                : UIColor.blackColor)
                    : [UIColor secondaryLabelColor];

    _tlRank.textColor = c;
    _tlSuit.textColor = c;
    _brRank.textColor = c;
    _brSuit.textColor = c;
    _centerLabel.textColor = c;

    _tlRank.text = placeholder ? @"" : rank;
    _tlSuit.text = placeholder ? @"" : suit;
    _brRank.text = placeholder ? @"" : rank;
    _brSuit.text = placeholder ? @"" : suit;
    _centerLabel.text = placeholder ? @"抽牌" : [NSString stringWithFormat:@"%@%@", rank, suit];
}

@end

#pragma mark - Preview Controller

@interface JFCardsPreviewVC : UITableViewController
@property (nonatomic, copy) NSArray<JFCard *> *discarded;
@end

@implementation JFCardsPreviewVC
- (instancetype)init {
    if (self = [super initWithStyle:UITableViewStyleInsetGrouped]) {}
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"已出过的牌";
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                      target:self
                                                      action:@selector(close)];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discarded.count;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)idx {
    static NSString *rid = @"c";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:rid];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid];
    JFCard *card = self.discarded[idx.row];
    BOOL red = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@", card.rank, card.suit];
    cell.textLabel.textColor = red ? [UIColor systemRedColor] : UIColor.labelColor;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"第 %ld 张", (long)idx.row+1];
    return cell;
}
@end

@interface JFCardRulesViewController : UIViewController
@property (nonatomic, copy) NSString *rulesText;
@end

@implementation JFCardRulesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"完整规则";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                                           target:self
                                                                                           action:@selector(close)];

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.editable = NO;
    textView.selectable = YES;
    textView.backgroundColor = UIColor.clearColor;
    textView.textColor = UIColor.labelColor;
    textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    textView.text = self.rulesText;
    textView.textContainerInset = UIEdgeInsetsMake(18, 16, 24, 16);
    [self.view addSubview:textView];
    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - Main VC

@interface CardsGameViewController ()
@property (nonatomic, strong) NSMutableArray<JFCard *> *fullDeck;
@property (nonatomic, strong) NSMutableArray<JFCard *> *remainDeck;
@property (nonatomic, strong) NSMutableArray<JFCard *> *discarded;

@property (nonatomic, strong) JFCardView *centerCard;
@property (nonatomic, strong) UIButton *shuffleBtn;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UIButton *rulesBtn;
@property (nonatomic, strong) UILabel *counterLabel;

@property (nonatomic, strong) JFRulesBannerView *rulesBanner;
@property (nonatomic, assign) JFCardPartyMode partyMode;

- (NSString *)modeTitle;
- (NSString *)modeGuide;
- (NSDictionary<NSString *, NSString *> *)ruleForCard:(JFCard *)card;

@end

@implementation CardsGameViewController

+ (NSString *)titleForPartyMode:(JFCardPartyMode)mode {
    CardsGameViewController *provider = [[self alloc] initWithPartyMode:mode];
    return [provider modeTitle];
}

+ (NSString *)guideForPartyMode:(JFCardPartyMode)mode {
    CardsGameViewController *provider = [[self alloc] initWithPartyMode:mode];
    return [provider modeGuide];
}

+ (NSDictionary<NSString *,NSString *> *)ruleForRank:(NSString *)rank
                                                  suit:(NSString *)suit
                                             partyMode:(JFCardPartyMode)mode {
    CardsGameViewController *provider = [[self alloc] initWithPartyMode:mode];
    JFCard *card = [JFCard new];
    card.rank = rank ?: @"A";
    card.suit = suit ?: @"♠";
    return [provider ruleForCard:card];
}

- (instancetype)init {
    return [self initWithPartyMode:JFCardPartyModeMiss];
}

- (instancetype)initWithPartyMode:(JFCardPartyMode)mode {
    if ((self = [super init])) {
        _partyMode = MAX(JFCardPartyModeMiss, MIN(JFCardPartyModeLuckyDraw, mode));
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.title = [self modeTitle];

    [self buildDeck];

    // 先创建并安置规则条（常驻）
    self.rulesBanner = [JFRulesBannerView new];
    [self.rulesBanner showWithTitle:[self modeTitle]
                               body:[self modeGuide]
                             inView:self.view
                           autoHide:NO];

    // 再构建其余 UI（卡片会锚到 rulesBanner 底部）
    [self setupUI];

    // 洗牌并显示占位卡
    [self resetAndShuffle];
}

#pragma mark - Deck

- (void)buildDeck {
    self.fullDeck = [NSMutableArray arrayWithCapacity:52];
    NSArray *ranks = @[ @"A",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"J",@"Q",@"K" ];
    NSArray *suits = @[ @"♠",@"♥",@"♦",@"♣" ];
    for (NSString *s in suits) {
        for (NSString *r in ranks) {
            JFCard *c = [JFCard new]; c.rank = r; c.suit = s;
            [self.fullDeck addObject:c];
        }
    }
}

- (void)resetAndShuffle {
    self.remainDeck = self.fullDeck.mutableCopy;
    self.discarded = [NSMutableArray array];
    [self shuffle:self.remainDeck];
    [self updateCounter];

    // 显示占位牌面（不计入牌堆）
    self.centerCard.card = [self placeholderCard];
    [self.centerCard setNeedsLayout];
}

- (void)shuffle:(NSMutableArray<JFCard *> *)arr {
    for (NSInteger i = arr.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i+1));
        [arr exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
}

#pragma mark - UI

- (void)setupUI {
    // 中心卡片
    JFCardView *card = [[JFCardView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];
    self.centerCard = card;
  
    self.centerCard.card = [self placeholderCard];
    // 尺寸自适应（宽:高 = 5:7）
    CGFloat aspect = 7.0/5.0;
    CGFloat availableWidth = MIN(self.view.bounds.size.width * 0.56,
                                 MAX(178, (self.view.bounds.size.height - 390) / aspect));
    CGFloat maxW = MIN(224, availableWidth);

    // 计数标签
    UILabel *counter = [[UILabel alloc] init];
    counter.translatesAutoresizingMaskIntoConstraints = NO;
    counter.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    counter.textColor = [UIColor secondaryLabelColor];
    [self.view addSubview:counter];
    self.counterLabel = counter;

    // 洗牌按钮（左下）
    UIButton *shuffle = [self roundButton:@"洗牌"];
    [shuffle addTarget:self action:@selector(onShuffle) forControlEvents:UIControlEventTouchUpInside];
    shuffle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:shuffle];
    self.shuffleBtn = shuffle;

    // 预览按钮（右下）
    UIButton *preview = [self roundButton:@"预览"];
    [preview addTarget:self action:@selector(onPreview) forControlEvents:UIControlEventTouchUpInside];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:preview];
    self.previewBtn = preview;

    UIButton *rules = [UIButton buttonWithType:UIButtonTypeSystem];
    rules.translatesAutoresizingMaskIntoConstraints = NO;
    rules.tintColor = [JFTheme textPrimary];
    rules.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    rules.layer.cornerRadius = 8;
    [rules setImage:[UIImage systemImageNamed:@"info.circle.fill"] forState:UIControlStateNormal];
    [rules addTarget:self action:@selector(onShowAllRules) forControlEvents:UIControlEventTouchUpInside];
    rules.accessibilityLabel = @"查看完整规则";
    [self.view addSubview:rules];
    self.rulesBtn = rules;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [counter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [counter.topAnchor constraintEqualToAnchor:self.rulesBanner.bottomAnchor constant:8],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.topAnchor constraintEqualToAnchor:self.counterLabel.bottomAnchor constant:8],
        [card.widthAnchor constraintEqualToConstant:maxW],
        [card.heightAnchor constraintEqualToConstant:maxW * aspect],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [shuffle.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [shuffle.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-20],
        [shuffle.widthAnchor constraintEqualToConstant:88],
        [shuffle.heightAnchor constraintEqualToConstant:44],

        [preview.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [preview.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-20],
        [preview.widthAnchor constraintEqualToConstant:88],
        [preview.heightAnchor constraintEqualToConstant:44],

        [rules.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [rules.centerYAnchor constraintEqualToAnchor:shuffle.centerYAnchor],
        [rules.widthAnchor constraintEqualToConstant:44],
        [rules.heightAnchor constraintEqualToConstant:44],
    ]];

    // 只有牌面负责抽牌，底部按钮不会再同时触发发牌。
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAnywhere)];
    [self.centerCard addGestureRecognizer:tap];
}

- (UIButton *)roundButton:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    b.layer.cornerRadius = 12;
    b.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1].CGColor;
    b.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    return b;
}

- (void)updateCounter {
    self.counterLabel.text = [NSString stringWithFormat:@"剩余：%lu / 52   已出：%lu",
                              (unsigned long)self.remainDeck.count, (unsigned long)self.discarded.count];
}

// 占位卡片
- (JFCard *)placeholderCard {
    JFCard *c = [JFCard new];
    c.rank = @"999";
    c.suit = @"999";
    return c;
}

- (NSString *)modeTitle {
    NSArray *titles = @[@"小姐牌", @"大姐牌", @"少爷牌", @"国王指令", @"真心话牌", @"默契挑战", @"反应禁令", @"幸运轮抽"];
    return titles[MAX(0, MIN((NSInteger)titles.count - 1, self.partyMode))];
}

- (NSString *)modeIntro {
    NSArray *intros = @[
        @"经典聚会规则。轻点牌面抽牌，当前牌的身份与任务会显示在上方。",
        @"抽到 2 的玩家成为大姐；领导全场、发起挑战，下一张 2 出现时交接。",
        @"抽到 J 的玩家成为少爷；用夸张、表演和即兴任务制造节目效果。",
        @"每张牌都是一道王令，K 可以改写一条全场规则，直到下一张 K。",
        @"红色牌回答真心话，黑色牌完成大冒险；问题随点数逐渐升级。",
        @"全员配合完成同步、猜词和心有灵犀挑战，失败者接受轻量惩罚。",
        @"看到牌后立刻完成动作；犹豫、做错或成为最后一名都会失分。",
        @"轮流抽牌累计个人点数，A 为 1 分、JQK 为 10 分；先到 30 分获胜。",
    ];
    return intros[MAX(0, MIN((NSInteger)intros.count - 1, self.partyMode))];
}

- (NSString *)modeGuide {
    NSArray *guides = @[
        @"适合 3-12 人。顺时针轮流抽牌并执行当前规则；身份牌与禁令持续到同点数再次出现。规则冲突时以最新一张为准，无法完成时可统一改为扣 1 分或轻量表演。",
        @"适合 3-12 人。抽到 2 的玩家成为大姐并主持挑战，下一张 2 出现时完成交接。每项任务先点名、再开始、最后由全员确认是否过关。",
        @"适合 3-10 人。抽牌者在规定时间内完成即兴表演，全员投票是否过关；平票时由上一位抽牌者裁定，不过关扣 1 分或执行替代任务。",
        @"适合 4-12 人。抽牌者朗读并主持王令，涉及多人时先点名再行动。K 可以新增一条全场规则并持续到下一张 K，危险或冒犯性命令一律重抽。",
        @"红牌回答真心话，黑牌完成大冒险；本玩法已从游乐场入口移除，可继续从独立的真心话大冒险进入。",
        @"全员完成同步和默契挑战；本玩法已从游乐场入口移除。",
        @"适合 3-12 人。翻牌后所有人立即完成动作，主持人确认最后一名或出错者。有争议时本轮作废重发，避免连续惩罚同一位玩家。",
        @"适合 2-8 人。按顺时针轮流抽牌并累计个人分数，A 为 1，J/Q/K 为 10；红牌允许再抽一次，率先达到 30 分者获胜。",
    ];
    return guides[MAX(0, MIN((NSInteger)guides.count - 1, self.partyMode))];
}

- (NSInteger)rankIndex:(NSString *)rank {
    NSArray *ranks = @[@"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"];
    NSUInteger index = [ranks indexOfObject:rank ?: @""];
    return index == NSNotFound ? 0 : (NSInteger)index;
}

- (NSDictionary<NSString *, NSString *> *)ruleForCard:(JFCard *)card {
    if (!card || [card.rank isEqualToString:@"999"]) return JFPartyRule([self modeTitle], [self modeIntro]);
    NSInteger index = [self rankIndex:card.rank];
    NSArray<NSDictionary *> *rules = nil;
    switch (self.partyMode) {
        case JFCardPartyModeMiss:
            rules = @[
                JFPartyRule(@"命令牌", @"指定任意一位玩家完成一个轻量任务，或保留到稍后使用。"),
                JFPartyRule(@"小姐登场", @"你成为本轮小姐并给自己起名。其他玩家受罚时可以点名请你陪同，直到下一张 2。"),
                JFPartyRule(@"逛三园", @"选一个主题，大家依次说出相关事物；重复、停顿或说错的人受罚。"),
                JFPartyRule(@"发起小游戏", @"立即选择石头剪刀布、十五二十或任意十秒小游戏。"),
                JFPartyRule(@"照相机", @"你可以突然喊“照相机”，所有人定格，最先动的人受罚。"),
                JFPartyRule(@"摸鼻子", @"找时机偷偷摸鼻子，其他人跟随，最后发现的人受罚。"),
                JFPartyRule(@"逢七过", @"依次报数，含 7 或 7 的倍数用拍手代替，出错者受罚。"),
                JFPartyRule(@"通行证", @"获得一次离席通行证，也可以把它送给其他玩家。"),
                JFPartyRule(@"自选惩罚", @"为自己选择真心话、表演或一项轻量惩罚。"),
                JFPartyRule(@"禁言角色", @"成为特殊角色，别人主动和你说话就算挑战失败，直到下一张 10。"),
                JFPartyRule(@"左边行动", @"左手边玩家完成你指定的任务。"),
                JFPartyRule(@"右边行动", @"右手边玩家完成你指定的任务。"),
                JFPartyRule(@"制定规则", @"新增一条全场规则，持续到下一张 K。"),
            ];
            break;
        case JFCardPartyModeBigSister:
            rules = @[
                JFPartyRule(@"大姐点名", @"点一位玩家用三个词夸你，不能重复别人说过的词。"),
                JFPartyRule(@"大姐上位", @"你成为新大姐。先宣布一个称号，再指定大家对你的称呼。"),
                JFPartyRule(@"夸夸接龙", @"从你开始顺时针夸下一位，犹豫超过三秒的人接受挑战。"),
                JFPartyRule(@"同步摆拍", @"大姐摆一个姿势，全员三秒内复制，最不像的人表演节目。"),
                JFPartyRule(@"大姐说", @"玩一轮“大姐说”，只有带“大姐说”的命令才能执行。"),
                JFPartyRule(@"反话局", @"接下来一轮只能说反话，第一位说正常话的人失败。"),
                JFPartyRule(@"关键词", @"定一个关键词，谁先说到它就要完成大姐的任务。"),
                JFPartyRule(@"护驾牌", @"保留此牌，可以替任意玩家抵消一次任务。"),
                JFPartyRule(@"个人秀", @"获得二十秒舞台，讲笑话、唱一句或展示隐藏技能。"),
                JFPartyRule(@"禁词", @"指定一个全场禁词，持续到下一张 10。"),
                JFPartyRule(@"左护法", @"左手边玩家成为护法，帮你完成下一项双人任务。"),
                JFPartyRule(@"右护法", @"右手边玩家成为护法，和你完成一次同步挑战。"),
                JFPartyRule(@"交接仪式", @"大姐宣布一条临时规则，并选择下一位主持抽牌。"),
            ];
            break;
        case JFCardPartyModeYoungMaster:
            rules = @[
                JFPartyRule(@"豪气宣言", @"用最夸张的语气说一句登场台词，全员投票是否过关。"),
                JFPartyRule(@"跟班任务", @"任选一位玩家当一轮跟班，与你完成镜像动作。"),
                JFPartyRule(@"三秒耍帅", @"三秒内摆出自认为最帅的姿势，不能笑场。"),
                JFPartyRule(@"四字成语", @"说一个成语，下一位用末字开头继续，卡住者失败。"),
                JFPartyRule(@"五连拍", @"连续完成五个不同表情，其他人不能笑。"),
                JFPartyRule(@"六秒广告", @"为桌上的任意物品做六秒即兴广告。"),
                JFPartyRule(@"反向口令", @"你说左大家指右，你说站大家坐，错的人接受任务。"),
                JFPartyRule(@"八拍动作", @"编一个八拍动作，下一位完整复刻。"),
                JFPartyRule(@"九宫夸张", @"任选一种情绪，把它演到九分夸张。"),
                JFPartyRule(@"十秒挑战", @"指定一位玩家十秒内说出五个同类词。"),
                JFPartyRule(@"少爷登场", @"你成为本轮少爷，获得一次指定双人挑战的权利。"),
                JFPartyRule(@"搭档选择", @"选一位搭档完成心有灵犀手势，失败就一起表演。"),
                JFPartyRule(@"全场买单", @"全员共同完成一项任务；任何人失败就重新来一次。"),
            ];
            break;
        case JFCardPartyModeKingsOrder:
            rules = @[
                JFPartyRule(@"王令一", @"指定两位玩家交换座位，并用对方的语气说一句话。"),
                JFPartyRule(@"王令二", @"选两人进行石头剪刀布，输者接受胜者的一项轻量任务。"),
                JFPartyRule(@"王令三", @"三位玩家组成临时组合，摆出同一主题的造型。"),
                JFPartyRule(@"王令四", @"所有人按生日月份快速排序，最后完成的人失败。"),
                JFPartyRule(@"王令五", @"五秒内全员指向最符合你问题的人，票数最高者回应。"),
                JFPartyRule(@"王令六", @"指定一人闭眼，另一人用声音引导他完成一个手势。"),
                JFPartyRule(@"王令七", @"从 1 报到 21，带 7 的数字必须用拍桌代替。"),
                JFPartyRule(@"王令八", @"任选两人背对背，同时用手指回答一道默契题。"),
                JFPartyRule(@"王令九", @"指定一人模仿一种职业，大家限时猜。"),
                JFPartyRule(@"王令十", @"所有人十秒内不能笑，抽牌者负责逗笑大家。"),
                JFPartyRule(@"侍从", @"左手边玩家协助你完成下一道王令。"),
                JFPartyRule(@"王后", @"右手边玩家可以否决一次王令并换成真心话。"),
                JFPartyRule(@"新法令", @"制定一条新规则，持续到下一张 K 出现。"),
            ];
            break;
        case JFCardPartyModeTruthDare: {
            BOOL truth = [card.suit isEqualToString:@"♥"] || [card.suit isEqualToString:@"♦"];
            NSArray *truths = @[@"最近一次让你开心的小事是什么？", @"你最想立刻学会什么能力？", @"说一个没人知道的小习惯。", @"你做过最冲动的决定是什么？", @"最想回到哪一天？", @"在场谁最懂你？为什么？", @"承认一个无伤大雅的秘密。", @"你最怕别人误解你什么？", @"最近一次说谎是因为什么？", @"给未来的自己一句忠告。", @"你最羡慕谁的一项特质？", @"选一位玩家，说出你对他的第一印象。", @"回答全场共同提出的一道真心话。"];
            NSArray *dares = @[@"用播音腔介绍自己。", @"模仿一种动物直到有人猜中。", @"给通讯录第十位发一个表情。", @"闭眼原地转四圈后走直线。", @"用五种情绪说同一句话。", @"和左边玩家合拍一个定格动作。", @"唱一句大家指定的歌。", @"用方言念一段广告词。", @"保持搞怪表情九秒。", @"十秒内夸完在场每个人。", @"模仿一位在场玩家。", @"让右边玩家设计一个动作并复刻。", @"接受全场投票选出的大冒险。"];
            return JFPartyRule(truth ? @"真心话" : @"大冒险", truth ? truths[index] : dares[index]);
        }
        case JFCardPartyModeChemistry:
            rules = @[
                JFPartyRule(@"同频选择", @"两人同时说出最想去的城市，一致则得一分。"),
                JFPartyRule(@"镜像动作", @"和搭档面对面同步做动作，坚持十秒不笑场。"),
                JFPartyRule(@"三连猜", @"搭档猜你最喜欢的颜色、季节和饮品，猜中两项过关。"),
                JFPartyRule(@"四指答案", @"背对背同时伸出 1 到 4 根手指，相同即成功。"),
                JFPartyRule(@"无声排序", @"全员不说话，按身高或生日月份完成排序。"),
                JFPartyRule(@"接半句话", @"你说上半句，搭档立刻补出最默契的下半句。"),
                JFPartyRule(@"关键词联想", @"两人听到关键词后同时说联想词，说出相同答案过关。"),
                JFPartyRule(@"动作传递", @"第一个人做动作，依次背对背传到最后，看是否一致。"),
                JFPartyRule(@"九秒画面", @"全员九秒内组成一张指定主题的合照姿势。"),
                JFPartyRule(@"十问快答", @"搭档连续问十个二选一问题，你必须立即回答。"),
                JFPartyRule(@"左边搭档", @"与左边玩家完成一次同时指人挑战。"),
                JFPartyRule(@"右边搭档", @"与右边玩家同时说出对方最常说的一句话。"),
                JFPartyRule(@"全员同频", @"给出一道二选一问题，全员同时站队，少数派完成任务。"),
            ];
            break;
        case JFCardPartyModeReaction:
            rules = @[
                JFPartyRule(@"拍 A", @"所有人立刻拍桌一次，最后的人失败。"),
                JFPartyRule(@"双手抱头", @"看到牌后三秒内双手抱头，动作最慢的人失败。"),
                JFPartyRule(@"三连拍", @"按“桌面、双手、桌面”完成三拍，出错者失败。"),
                JFPartyRule(@"四方向", @"抽牌者随机喊方向，所有人必须看向相反方向。"),
                JFPartyRule(@"禁止眨眼", @"互相对视五秒，先眨眼或笑的人失败。"),
                JFPartyRule(@"数字陷阱", @"快速从 1 数到 6，但不能说出牌面点数。"),
                JFPartyRule(@"举手陷阱", @"抽牌者可以随时举手，最后跟随的人失败。"),
                JFPartyRule(@"颜色判断", @"红牌拍左手、黑牌拍右手，做反的人失败。"),
                JFPartyRule(@"九秒静止", @"所有人保持当前动作九秒，先动的人失败。"),
                JFPartyRule(@"反口令", @"抽牌者连续发三个口令，大家必须执行相反动作。"),
                JFPartyRule(@"左手抢答", @"所有人只能用左手碰桌面，最后的人失败。"),
                JFPartyRule(@"右手抢答", @"所有人只能用右手指向天花板，最后的人失败。"),
                JFPartyRule(@"王者冻结", @"看到 K 全员立刻定格，抽牌者负责找出先动的人。"),
            ];
            break;
        case JFCardPartyModeLuckyDraw: {
            NSInteger value = MIN(10, index + 1);
            return JFPartyRule([NSString stringWithFormat:@"幸运 +%ld", (long)value], @"把牌面分数记到当前玩家名下；红色牌可以再抽一次，先累计到 30 分获胜。");
        }
    }
    return rules[index];
}

- (NSString *)ruleTitleForCard:(JFCard *)card {
    NSDictionary *rule = [self ruleForCard:card];
    return [NSString stringWithFormat:@"%@ · %@", card.rank ?: @"", rule[@"title"]];
}

- (NSString *)ruleBodyForCard:(JFCard *)card {
    return [self ruleForCard:card][@"body"];
}

#pragma mark - Actions

- (void)onShuffle {
    [self resetAndShuffle];

    // 小反馈
    UIImpactFeedbackGenerator *h = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [h impactOccurred];
    // 更新规则为开场提示且常驻
    [self.rulesBanner showWithTitle:[self modeTitle]
                               body:[self modeGuide]
                             inView:self.view
                           autoHide:NO];
}

- (void)onPreview {
    if (self.discarded.count == 0) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"还没有出牌"
                                                                   message:@"点屏幕抽牌后，再来看看预览吧～"
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }
    JFCardsPreviewGridVC *vc = [JFCardsPreviewGridVC new];
    vc.allCards = self.discarded.copy; // 不强制顺序，预览里会随机
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPageSheet; // iPhone: 底部弹起 / iPad: 置中页
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onTapAnywhere {
    if (self.remainDeck.count == 0) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"牌发完啦"
                                                                   message:@"点击左下角“洗牌”可重新开始"
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }

    // 随机抽一张
    NSUInteger idx = arc4random_uniform((uint32_t)self.remainDeck.count);
    JFCard *next = self.remainDeck[idx];
    [self.remainDeck removeObjectAtIndex:idx];
    [self.discarded addObject:next];
    [self updateCounter];

    // 上报一次抽牌动作（用于成就/每日挑战累计）
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindCard score:5 win:YES];
    r.extra = @{ @"mode": [self modeTitle] };
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindCard difficulty:0 score:5 win:YES];

    // 翻牌动画（Y 轴翻转）
    [self flipToCard:next];
}

// 翻牌动画
- (void)flipToCard:(JFCard *)card {
    // 半程：翻到背面
    [UIView transitionWithView:self.centerCard
                      duration:0.22
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.centerCard.layer.transform = CATransform3DMakeScale(0.98, 0.98, 1);
                        self.centerCard.layer.opacity = 0.0;
                    } completion:^(BOOL finished) {
                        // 更新卡面
                        self.centerCard.card = card;
                        // 回程：展示正面
                        [UIView transitionWithView:self.centerCard
                                          duration:0.28
                                           options:UIViewAnimationOptionTransitionFlipFromRight
                                        animations:^{
                                            self.centerCard.layer.transform = CATransform3DIdentity;
                                            self.centerCard.layer.opacity = 1.0;
                                        } completion:^(BOOL finished2){
                                            if (![card.rank isEqualToString:@"999"]) {
                                                NSString *title = [self ruleTitleForCard:card];
                                                NSString *body  = [self ruleBodyForCard:card];
                                                [self.rulesBanner showWithTitle:title body:body inView:self.view autoHide:NO];
                                            }
                                        }];
                    }];
}

// 显示全部规则
- (void)onShowAllRules {
    NSArray *ranks = @[@"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"];
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithCapacity:ranks.count];
    for (NSString *rank in ranks) {
        JFCard *card = [JFCard new];
        card.rank = rank;
        card.suit = @"♥";
        NSDictionary *rule = [self ruleForCard:card];
        [lines addObject:[NSString stringWithFormat:@"%@  %@\n%@", rank, rule[@"title"], rule[@"body"]]];
    }
    NSString *all = [NSString stringWithFormat:@"【开局与结算】\n%@\n\n【每张牌的规则】\n\n%@",
                     [self modeGuide], [lines componentsJoinedByString:@"\n\n"]];
    JFCardRulesViewController *rules = [[JFCardRulesViewController alloc] init];
    rules.rulesText = all;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rules];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

@end
