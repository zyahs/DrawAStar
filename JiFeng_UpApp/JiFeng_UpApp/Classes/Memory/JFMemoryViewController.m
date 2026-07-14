//
//  JFMemoryViewController.m
//
//  记忆翻牌 三档难度。SF Symbol 图标作为牌面,匹配相同图标即消除。
//  完成时上报 Profile/Daily。
//

#import "JFMemoryViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

@interface JFMemoryViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *movesLabel;
@property (nonatomic, strong) UISegmentedControl *difficultySeg;
@property (nonatomic, strong) UIView  *boardView;
@property (nonatomic, strong) UIButton *resetButton;

@property (nonatomic, assign) NSInteger cols;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, strong) NSArray<NSString *> *symbols;     // 卡牌图标
@property (nonatomic, strong) NSMutableArray<UIButton *> *cardButtons;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *cardSymbolIndex; // 每张牌对应 symbol 下标
@property (nonatomic, strong) NSMutableArray<NSNumber *> *cardMatched;     // 是否已经配对
@property (nonatomic, assign) NSInteger flippedA;
@property (nonatomic, assign) NSInteger flippedB;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) NSInteger moves;
@property (nonatomic, assign) NSInteger matchedPairs;
@property (nonatomic, assign) NSTimeInterval startTs;

@end

@implementation JFMemoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    [self buildBackground];
    [self buildUI];
    [self resetWithDifficulty:0];
}

- (void)buildBackground {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.22];
    [self.view addSubview:overlay];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"记忆翻牌";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.difficultySeg = [[UISegmentedControl alloc] initWithItems:@[@"4×3", @"4×4", @"6×5"]];
    self.difficultySeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.difficultySeg.selectedSegmentIndex = 0;
    [self.difficultySeg setTitleTextAttributes:@{NSForegroundColorAttributeName:[JFTheme textPrimary]} forState:UIControlStateNormal];
    [self.difficultySeg addTarget:self action:@selector(onDifficulty) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.difficultySeg];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"找出所有相同的对子";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    self.movesLabel = [[UILabel alloc] init];
    self.movesLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.movesLabel.text = @"步数 0";
    self.movesLabel.textColor = [JFTheme textPrimary];
    self.movesLabel.font = [JFTheme fontHeadline];
    self.movesLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.movesLabel];

    self.boardView = [[UIView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
    self.boardView.layer.cornerRadius = JFRadiusMedium;
    self.boardView.layer.borderWidth = 0.5;
    self.boardView.layer.borderColor = [JFTheme cardBorder].CGColor;
    [self.view addSubview:self.boardView];

    self.resetButton = [self primaryButtonWithTitle:@"重新开始" action:@selector(onReset)];
    [self.view addSubview:self.resetButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.difficultySeg.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [self.difficultySeg.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.difficultySeg.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:self.difficultySeg.bottomAnchor constant:JFSpacing8],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.movesLabel.topAnchor      constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing4],
        [self.movesLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.boardView.topAnchor      constraintEqualToAnchor:self.movesLabel.bottomAnchor constant:JFSpacing12],
        [self.boardView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.boardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.resetButton.topAnchor      constraintEqualToAnchor:self.boardView.bottomAnchor constant:JFSpacing16],
        [self.resetButton.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.resetButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.resetButton.heightAnchor   constraintEqualToConstant:48],
        [self.resetButton.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self relayoutCards];
}

- (void)relayoutCards {
    if (self.cardButtons.count == 0) return;
    CGFloat W = self.boardView.bounds.size.width;
    CGFloat H = self.boardView.bounds.size.height;
    if (W <= 0 || H <= 0) return;
    CGFloat pad = 8;
    CGFloat gap = 6;
    CGFloat tw = (W - pad * 2 - gap * (self.cols - 1)) / self.cols;
    CGFloat th = (H - pad * 2 - gap * (self.rows - 1)) / self.rows;
    for (NSInteger i = 0; i < (NSInteger)self.cardButtons.count; i++) {
        NSInteger r = i / self.cols;
        NSInteger c = i % self.cols;
        UIButton *b = self.cardButtons[i];
        b.frame = CGRectMake(pad + c * (tw + gap),
                             pad + r * (th + gap),
                             tw, th);
        b.titleLabel.font = [UIFont systemFontOfSize:MIN(tw, th) * 0.4 weight:UIFontWeightSemibold];
    }
}

#pragma mark - Buttons

- (void)onDifficulty {
    [self resetWithDifficulty:self.difficultySeg.selectedSegmentIndex];
}

- (void)onReset {
    [JFTheme hapticImpactMedium];
    [self resetWithDifficulty:self.difficultySeg.selectedSegmentIndex];
}

- (void)resetWithDifficulty:(NSInteger)diff {
    switch (diff) {
        case 0: self.cols = 4; self.rows = 3; break;
        case 1: self.cols = 4; self.rows = 4; break;
        default: self.cols = 6; self.rows = 5; break;
    }
    NSInteger total = self.cols * self.rows;
    if (total % 2 != 0) total -= 1;
    NSInteger pairs = total / 2;
    NSArray<NSString *> *pool = @[@"star.fill", @"heart.fill", @"moon.fill", @"sun.max.fill",
                                   @"flame.fill", @"bolt.fill", @"leaf.fill", @"snowflake",
                                   @"cloud.fill", @"flag.fill", @"crown.fill", @"gift.fill",
                                   @"music.note", @"camera.fill", @"airplane", @"car.fill"];
    NSMutableArray *symbols = [NSMutableArray array];
    NSMutableArray<NSNumber *> *idxs = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)pool.count; i++) [idxs addObject:@(i)];
    for (NSInteger i = (NSInteger)idxs.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [idxs exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    for (NSInteger i = 0; i < pairs; i++) [symbols addObject:pool[((NSNumber *)idxs[i]).integerValue]];
    self.symbols = symbols;

    NSMutableArray *order = [NSMutableArray array];
    for (NSInteger i = 0; i < pairs; i++) {
        [order addObject:@(i)];
        [order addObject:@(i)];
    }
    for (NSInteger i = (NSInteger)order.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [order exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    self.cardSymbolIndex = order;
    self.cardMatched = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)order.count; i++) [self.cardMatched addObject:@NO];

    // 重建按钮
    for (UIView *v in [self.boardView.subviews copy]) [v removeFromSuperview];
    self.cardButtons = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)order.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = i;
        b.backgroundColor = [JFTheme brandPrimary];
        b.layer.cornerRadius = JFRadiusSmall;
        b.tintColor = [UIColor whiteColor];
//        b.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightSemibold];
        [b addTarget:self action:@selector(onCard:) forControlEvents:UIControlEventTouchUpInside];
        [self.boardView addSubview:b];
        [self.cardButtons addObject:b];
    }
    self.flippedA = -1;
    self.flippedB = -1;
    self.locked = NO;
    self.moves = 0;
    self.matchedPairs = 0;
    self.startTs = [[NSDate date] timeIntervalSince1970];
    self.movesLabel.text = @"步数 0";
    self.statusLabel.text = @"找出所有相同的对子";
    [self relayoutCards];
}

- (void)onCard:(UIButton *)b {
    if (self.locked) return;
    NSInteger idx = b.tag;
    if (self.cardMatched[idx].boolValue) return;
    if (idx == self.flippedA) return;
    [self showCard:idx animated:YES];
    if (self.flippedA == -1) {
        self.flippedA = idx;
        return;
    }
    self.flippedB = idx;
    self.moves += 1;
    self.movesLabel.text = [NSString stringWithFormat:@"步数 %ld", (long)self.moves];

    NSInteger sa = self.cardSymbolIndex[self.flippedA].integerValue;
    NSInteger sb = self.cardSymbolIndex[self.flippedB].integerValue;
    if (sa == sb) {
        self.cardMatched[self.flippedA] = @YES;
        self.cardMatched[self.flippedB] = @YES;
        self.flippedA = -1;
        self.flippedB = -1;
        self.matchedPairs += 1;
        [JFTheme hapticImpactLight];
        if (self.matchedPairs == (NSInteger)self.symbols.count) {
            [self handleWin];
        }
    } else {
        self.locked = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideCard:self.flippedA];
            [self hideCard:self.flippedB];
            self.flippedA = -1;
            self.flippedB = -1;
            self.locked = NO;
        });
    }
}

- (void)showCard:(NSInteger)idx animated:(BOOL)animated {
    if (idx < 0 || idx >= (NSInteger)self.cardButtons.count) return;
    UIButton *b = self.cardButtons[idx];
    NSInteger s = self.cardSymbolIndex[idx].integerValue;
    NSString *sym = self.symbols[s];
    [UIView transitionWithView:b duration:animated ? 0.25 : 0 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        b.backgroundColor = [JFTheme accent];
        [b setImage:[UIImage systemImageNamed:sym] forState:UIControlStateNormal];
    } completion:nil];
}

- (void)hideCard:(NSInteger)idx {
    if (idx < 0 || idx >= (NSInteger)self.cardButtons.count) return;
    UIButton *b = self.cardButtons[idx];
    [UIView transitionWithView:b duration:0.25 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        b.backgroundColor = [JFTheme brandPrimary];
        [b setImage:nil forState:UIControlStateNormal];
    } completion:nil];
}

- (void)handleWin {
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    NSTimeInterval used = [[NSDate date] timeIntervalSince1970] - self.startTs;
    self.statusLabel.text = [NSString stringWithFormat:@"通关 · 用时 %.0f 秒 · %ld 步", used, (long)self.moves];
    NSInteger diff = self.difficultySeg.selectedSegmentIndex;
    NSInteger score = MAX(50, 500 - self.moves * 5 - (NSInteger)used + diff * 100);
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindMemory score:score win:YES];
    r.difficulty = diff;
    r.duration = used;
    r.extra = @{@"moves": @(self.moves)};
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindMemory difficulty:diff score:score win:YES];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

@end
