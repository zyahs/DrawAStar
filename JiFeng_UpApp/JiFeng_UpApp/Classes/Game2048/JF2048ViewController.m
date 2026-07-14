//
//  JF2048ViewController.m
//

#import "JF2048ViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

static const NSInteger kBoardSize = 4;
static NSString *const kBest2048Key  = @"jf_2048_best";
static NSString *const kBoardSaveKey = @"jf_2048_board";
static NSString *const kScoreSaveKey = @"jf_2048_score";

@interface JF2048ViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *bestLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView  *boardView;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<UILabel *> *> *tileLabels;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *undoButton;

// 数据 4x4
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *grid;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *prevGrid;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger prevScore;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, assign) BOOL gameOver;
@property (nonatomic, assign) BOOL hasReported2048;

@end

@implementation JF2048ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:kBest2048Key];

    [self buildBackground];
    [self buildUI];
    [self setupGestures];

    if (![self loadGame]) {
        [self resetGameAfterAnimate:NO];
    } else {
        [self syncTiles];
        [self updateLabels];
    }
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
    self.titleLabel.text = @"2048";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.scoreLabel = [self badgeLabelWithText:@"得分 0"];
    self.bestLabel  = [self badgeLabelWithText:[NSString stringWithFormat:@"最高 %ld", (long)self.best]];

    UIStackView *badgeStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.scoreLabel, self.bestLabel]];
    badgeStack.translatesAutoresizingMaskIntoConstraints = NO;
    badgeStack.axis = UILayoutConstraintAxisHorizontal;
    badgeStack.spacing = JFSpacing8;
    badgeStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:badgeStack];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"上下左右滑动 · 合到 2048 解锁成就";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    self.boardView = [[UIView alloc] init];
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.boardView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
    self.boardView.layer.cornerRadius = JFRadiusMedium;
    self.boardView.layer.cornerCurve = kCACornerCurveContinuous;
    self.boardView.layer.borderWidth = 0.5;
    self.boardView.layer.borderColor = [JFTheme cardBorder].CGColor;
    [self.view addSubview:self.boardView];

    self.resetButton = [self primaryButtonWithTitle:@"重新开始" action:@selector(onReset)];
    self.undoButton  = [self ghostButtonWithTitle:@"撤销一步" action:@selector(onUndo)];

    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.undoButton, self.resetButton]];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:btnStack];

    NSLayoutConstraint *boardSquare = [self.boardView.widthAnchor constraintEqualToAnchor:self.boardView.heightAnchor];
    NSLayoutConstraint *boardMax = [self.boardView.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    boardMax.priority = UILayoutPriorityRequired;
    NSLayoutConstraint *boardPref = [self.boardView.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    boardPref.priority = UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *boardBottom = [self.boardView.bottomAnchor constraintLessThanOrEqualToAnchor:btnStack.topAnchor constant:-JFSpacing16];
    boardBottom.priority = UILayoutPriorityRequired;

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [badgeStack.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [badgeStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [badgeStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [badgeStack.heightAnchor   constraintEqualToConstant:32],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:badgeStack.bottomAnchor constant:JFSpacing8],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        boardSquare, boardMax, boardPref, boardBottom,
        [self.boardView.topAnchor      constraintGreaterThanOrEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing12],
        [self.boardView.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [btnStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [btnStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [btnStack.heightAnchor   constraintEqualToConstant:48],
        [btnStack.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];

    // 4x4 tile labels(纯 label 用作渲染层,数据驱动;先创建好,layoutSubviews 时摆位置)
    self.tileLabels = [NSMutableArray array];
    for (NSInteger r = 0; r < kBoardSize; r++) {
        NSMutableArray *row = [NSMutableArray array];
        for (NSInteger c = 0; c < kBoardSize; c++) {
            UILabel *l = [[UILabel alloc] init];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont systemFontOfSize:32 weight:UIFontWeightHeavy];
            l.layer.cornerRadius = JFRadiusSmall;
            l.layer.masksToBounds = YES;
            l.adjustsFontSizeToFitWidth = YES;
            l.minimumScaleFactor = 0.4;
            [self.boardView addSubview:l];
            [row addObject:l];
        }
        [self.tileLabels addObject:row];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self relayoutTiles];
}

- (void)relayoutTiles {
    CGFloat W = self.boardView.bounds.size.width;
    if (W <= 0) return;
    CGFloat pad = 8;
    CGFloat gap = 8;
    CGFloat tile = (W - pad * 2 - gap * (kBoardSize - 1)) / kBoardSize;
    for (NSInteger r = 0; r < kBoardSize; r++) {
        for (NSInteger c = 0; c < kBoardSize; c++) {
            UILabel *l = self.tileLabels[r][c];
            l.frame = CGRectMake(pad + c * (tile + gap),
                                 pad + r * (tile + gap),
                                 tile, tile);
            l.font = [UIFont systemFontOfSize:tile * 0.42 weight:UIFontWeightHeavy];
        }
    }
}

- (UILabel *)badgeLabelWithText:(NSString *)t {
    UILabel *l = [[UILabel alloc] init];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.text = t;
    l.textColor = [JFTheme textPrimary];
    l.font = [JFTheme fontHeadline];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    l.layer.cornerRadius = JFRadiusMedium;
    l.layer.cornerCurve = kCACornerCurveContinuous;
    l.layer.borderWidth = 0.5;
    l.layer.borderColor = [JFTheme cardBorder].CGColor;
    l.clipsToBounds = YES;
    return l;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [JFTheme brandPrimary];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)ghostButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [JFTheme cardBorder].CGColor;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Gestures

- (void)setupGestures {
    NSArray<NSNumber *> *dirs = @[ @(UISwipeGestureRecognizerDirectionUp),
                                   @(UISwipeGestureRecognizerDirectionDown),
                                   @(UISwipeGestureRecognizerDirectionLeft),
                                   @(UISwipeGestureRecognizerDirectionRight) ];
    for (NSNumber *n in dirs) {
        UISwipeGestureRecognizer *g = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
        g.direction = (UISwipeGestureRecognizerDirection)n.integerValue;
        [self.view addGestureRecognizer:g];
    }
}

- (void)onSwipe:(UISwipeGestureRecognizer *)g {
    if (self.gameOver) return;
    [self saveSnapshot];
    BOOL changed = NO;
    NSInteger gained = 0;
    switch (g.direction) {
        case UISwipeGestureRecognizerDirectionLeft:  changed = [self moveLeftGain:&gained]; break;
        case UISwipeGestureRecognizerDirectionRight: changed = [self moveRightGain:&gained]; break;
        case UISwipeGestureRecognizerDirectionUp:    changed = [self moveUpGain:&gained]; break;
        case UISwipeGestureRecognizerDirectionDown:  changed = [self moveDownGain:&gained]; break;
        default: break;
    }
    if (!changed) return;

    self.score += gained;
    [JFTheme hapticImpactLight];
    [self spawnTile];
    [self syncTiles];
    [self updateLabels];
    [self saveGame];

    NSInteger maxTile = [self maxTileValue];
    if (maxTile >= 2048 && !self.hasReported2048) {
        self.hasReported2048 = YES;
        [self reportToProfile:YES maxTile:maxTile];
    }

    if ([self isGameOver]) {
        self.gameOver = YES;
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
        if (self.score > self.best) {
            self.best = self.score;
            [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:kBest2048Key];
            self.statusLabel.text = [NSString stringWithFormat:@"无法移动 · 新纪录 %ld!", (long)self.score];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"无法移动 · 得分 %ld", (long)self.score];
        }
        [self reportToProfile:NO maxTile:maxTile];
        [self updateLabels];
    }
}

#pragma mark - Buttons

- (void)onReset {
    [JFTheme hapticImpactMedium];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"重新开始?" message:@"当前局面会被清空" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self resetGameAfterAnimate:YES];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)onUndo {
    if (!self.prevGrid) return;
    [JFTheme hapticSelection];
    self.grid = [self.prevGrid mutableCopy];
    self.score = self.prevScore;
    self.prevGrid = nil;
    self.gameOver = NO;
    [self syncTiles];
    [self updateLabels];
    [self saveGame];
}

#pragma mark - Game core

- (void)resetGameAfterAnimate:(BOOL)animate {
    self.grid = [self emptyGrid];
    self.score = 0;
    self.gameOver = NO;
    self.hasReported2048 = NO;
    self.prevGrid = nil;
    [self spawnTile];
    [self spawnTile];
    [self syncTiles];
    [self updateLabels];
    self.statusLabel.text = @"上下左右滑动 · 合到 2048 解锁成就";
    [self saveGame];
}

- (void)saveSnapshot {
    NSMutableArray *copy = [NSMutableArray array];
    for (NSMutableArray *row in self.grid) [copy addObject:[row mutableCopy]];
    self.prevGrid = copy;
    self.prevScore = self.score;
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)emptyGrid {
    NSMutableArray *g = [NSMutableArray array];
    for (NSInteger r = 0; r < kBoardSize; r++) {
        NSMutableArray *row = [NSMutableArray array];
        for (NSInteger c = 0; c < kBoardSize; c++) [row addObject:@0];
        [g addObject:row];
    }
    return g;
}

- (void)spawnTile {
    NSMutableArray<NSValue *> *empties = [NSMutableArray array];
    for (NSInteger r = 0; r < kBoardSize; r++) {
        for (NSInteger c = 0; c < kBoardSize; c++) {
            if (self.grid[r][c].integerValue == 0) {
                [empties addObject:[NSValue valueWithCGPoint:CGPointMake(c, r)]];
            }
        }
    }
    if (empties.count == 0) return;
    CGPoint p = [empties[arc4random_uniform((uint32_t)empties.count)] CGPointValue];
    NSInteger v = (arc4random_uniform(10) == 0) ? 4 : 2;
    self.grid[(NSInteger)p.y][(NSInteger)p.x] = @(v);
    UILabel *l = self.tileLabels[(NSInteger)p.y][(NSInteger)p.x];
    l.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.15 animations:^{
        l.transform = CGAffineTransformIdentity;
    }];
}

// 把一行非0元素提取出来,合并相邻相等;返回是否变化以及增加的分数
- (NSArray<NSNumber *> *)mergeLine:(NSArray<NSNumber *> *)line gain:(NSInteger *)gain {
    NSMutableArray *vals = [NSMutableArray array];
    for (NSNumber *n in line) if (n.integerValue != 0) [vals addObject:n];
    NSMutableArray *out = [NSMutableArray array];
    NSInteger i = 0;
    while (i < (NSInteger)vals.count) {
        NSInteger v = ((NSNumber *)vals[i]).integerValue;
        if (i + 1 < (NSInteger)vals.count && ((NSNumber *)vals[i+1]).integerValue == v) {
            NSInteger merged = v * 2;
            [out addObject:@(merged)];
            if (gain) *gain += merged;
            i += 2;
        } else {
            [out addObject:@(v)];
            i += 1;
        }
    }
    while ((NSInteger)out.count < kBoardSize) [out addObject:@0];
    return out;
}

- (BOOL)moveLeftGain:(NSInteger *)gain {
    BOOL changed = NO;
    NSInteger localGain = 0;
    for (NSInteger r = 0; r < kBoardSize; r++) {
        NSArray *before = [self.grid[r] copy];
        NSArray *after = [self mergeLine:self.grid[r] gain:&localGain];
        if (![before isEqualToArray:after]) changed = YES;
        self.grid[r] = [after mutableCopy];
    }
    if (gain) *gain = localGain;
    return changed;
}

- (BOOL)moveRightGain:(NSInteger *)gain {
    BOOL changed = NO;
    NSInteger localGain = 0;
    for (NSInteger r = 0; r < kBoardSize; r++) {
        NSArray *rev = [[[self.grid[r] reverseObjectEnumerator] allObjects] copy];
        NSArray *after = [self mergeLine:rev gain:&localGain];
        NSArray *afterRev = [[[after reverseObjectEnumerator] allObjects] copy];
        if (![self.grid[r] isEqualToArray:afterRev]) changed = YES;
        self.grid[r] = [afterRev mutableCopy];
    }
    if (gain) *gain = localGain;
    return changed;
}

- (BOOL)moveUpGain:(NSInteger *)gain {
    BOOL changed = NO;
    NSInteger localGain = 0;
    for (NSInteger c = 0; c < kBoardSize; c++) {
        NSMutableArray *col = [NSMutableArray array];
        for (NSInteger r = 0; r < kBoardSize; r++) [col addObject:self.grid[r][c]];
        NSArray *after = [self mergeLine:col gain:&localGain];
        for (NSInteger r = 0; r < kBoardSize; r++) {
            if (!changed && self.grid[r][c].integerValue != ((NSNumber *)after[r]).integerValue) changed = YES;
            self.grid[r][c] = (NSNumber *)after[r];
        }
    }
    if (gain) *gain = localGain;
    return changed;
}

- (BOOL)moveDownGain:(NSInteger *)gain {
    BOOL changed = NO;
    NSInteger localGain = 0;
    for (NSInteger c = 0; c < kBoardSize; c++) {
        NSMutableArray *col = [NSMutableArray array];
        for (NSInteger r = kBoardSize - 1; r >= 0; r--) [col addObject:self.grid[r][c]];
        NSArray *after = [self mergeLine:col gain:&localGain];
        for (NSInteger i = 0; i < kBoardSize; i++) {
            NSInteger r = kBoardSize - 1 - i;
            if (!changed && self.grid[r][c].integerValue != ((NSNumber *)after[i]).integerValue) changed = YES;
            self.grid[r][c] = (NSNumber *)after[i];
        }
    }
    if (gain) *gain = localGain;
    return changed;
}

- (BOOL)isGameOver {
    for (NSInteger r = 0; r < kBoardSize; r++) {
        for (NSInteger c = 0; c < kBoardSize; c++) {
            if (self.grid[r][c].integerValue == 0) return NO;
            if (c + 1 < kBoardSize && [self.grid[r][c] isEqual:self.grid[r][c+1]]) return NO;
            if (r + 1 < kBoardSize && [self.grid[r][c] isEqual:self.grid[r+1][c]]) return NO;
        }
    }
    return YES;
}

- (NSInteger)maxTileValue {
    NSInteger m = 0;
    for (NSArray *row in self.grid) {
        for (NSNumber *n in row) if (n.integerValue > m) m = n.integerValue;
    }
    return m;
}

#pragma mark - Render

- (void)syncTiles {
    for (NSInteger r = 0; r < kBoardSize; r++) {
        for (NSInteger c = 0; c < kBoardSize; c++) {
            NSInteger v = self.grid[r][c].integerValue;
            UILabel *l = self.tileLabels[r][c];
            if (v == 0) {
                l.text = @"";
                l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
                l.textColor = [UIColor clearColor];
            } else {
                l.text = [NSString stringWithFormat:@"%ld", (long)v];
                l.backgroundColor = [self colorForValue:v];
                l.textColor = (v <= 4) ? [UIColor colorWithWhite:0.1 alpha:1] : [UIColor whiteColor];
            }
        }
    }
}

- (UIColor *)colorForValue:(NSInteger)v {
    switch (v) {
        case 2:    return [UIColor colorWithRed:0.93 green:0.89 blue:0.85 alpha:1];
        case 4:    return [UIColor colorWithRed:0.93 green:0.88 blue:0.78 alpha:1];
        case 8:    return [UIColor colorWithRed:0.95 green:0.69 blue:0.47 alpha:1];
        case 16:   return [UIColor colorWithRed:0.96 green:0.58 blue:0.39 alpha:1];
        case 32:   return [UIColor colorWithRed:0.96 green:0.49 blue:0.37 alpha:1];
        case 64:   return [UIColor colorWithRed:0.96 green:0.37 blue:0.23 alpha:1];
        case 128:  return [UIColor colorWithRed:0.93 green:0.81 blue:0.45 alpha:1];
        case 256:  return [UIColor colorWithRed:0.93 green:0.80 blue:0.38 alpha:1];
        case 512:  return [UIColor colorWithRed:0.93 green:0.78 blue:0.31 alpha:1];
        case 1024: return [UIColor colorWithRed:0.93 green:0.77 blue:0.25 alpha:1];
        case 2048: return [UIColor colorWithRed:0.93 green:0.76 blue:0.18 alpha:1];
        default:   return [JFTheme accent];
    }
}

- (void)updateLabels {
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld", (long)self.score];
    self.bestLabel.text  = [NSString stringWithFormat:@"最高 %ld", (long)self.best];
}

#pragma mark - Persistence

- (void)saveGame {
    NSMutableArray *flat = [NSMutableArray array];
    for (NSArray *row in self.grid) [flat addObjectsFromArray:row];
    [[NSUserDefaults standardUserDefaults] setObject:flat forKey:kBoardSaveKey];
    [[NSUserDefaults standardUserDefaults] setInteger:self.score forKey:kScoreSaveKey];
}

- (BOOL)loadGame {
    NSArray *flat = [[NSUserDefaults standardUserDefaults] arrayForKey:kBoardSaveKey];
    if (!flat || flat.count != kBoardSize * kBoardSize) return NO;
    self.grid = [self emptyGrid];
    for (NSInteger i = 0; i < (NSInteger)flat.count; i++) {
        NSInteger r = i / kBoardSize;
        NSInteger c = i % kBoardSize;
        self.grid[r][c] = flat[i];
    }
    self.score = [[NSUserDefaults standardUserDefaults] integerForKey:kScoreSaveKey];
    if (self.score > self.best) self.best = self.score;
    return YES;
}

#pragma mark - Reporting

- (void)reportToProfile:(BOOL)gameEnd maxTile:(NSInteger)maxTile {
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKind2048 score:self.score win:YES];
    r.extra = @{ @"maxTile": @(maxTile), @"gameEnd": @(gameEnd) };
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKind2048 difficulty:0 score:self.score win:(maxTile >= 512)];
}

@end
