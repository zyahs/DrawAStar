//
//  JFSudokuViewController.m
//
//  数独 9x9。三档难度从内置完整解矩阵随机抽位置挖空。
//  完成时上报 Profile + Daily challenge。
//

#import "JFSudokuViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

static const NSInteger kN = 9;

@interface JFSudokuViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISegmentedControl *difficultySeg;
@property (nonatomic, strong) UIView  *boardView;
@property (nonatomic, strong) UIView  *padView;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *checkButton;

@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *solution; // 完整解
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *given;    // 题目(0=空)
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *current;  // 玩家输入

@property (nonatomic, strong) NSMutableArray<NSMutableArray<UIButton *> *> *cells;    // 9x9 cell button
@property (nonatomic, strong) NSMutableArray<UIButton *> *padButtons;                  // 1-9
@property (nonatomic, strong) UIButton *clearButton;

@property (nonatomic, assign) NSInteger selRow;
@property (nonatomic, assign) NSInteger selCol;
@property (nonatomic, assign) NSTimeInterval startTs;
@property (nonatomic, assign) NSInteger difficulty; // 0=简单 1=中等 2=困难

@end

@implementation JFSudokuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.selRow = -1;
    self.selCol = -1;
    self.difficulty = 0;
    [self buildBackground];
    [self buildUI];
    [self newPuzzle];
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
    self.titleLabel.text = @"数独";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.difficultySeg = [[UISegmentedControl alloc] initWithItems:@[@"简单", @"中等", @"困难"]];
    self.difficultySeg.translatesAutoresizingMaskIntoConstraints = NO;
    self.difficultySeg.selectedSegmentIndex = 0;
    [self.difficultySeg setTitleTextAttributes:@{NSForegroundColorAttributeName:[JFTheme textPrimary]} forState:UIControlStateNormal];
    [self.difficultySeg addTarget:self action:@selector(onDifficultyChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.difficultySeg];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"点格子,选数字";
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

    self.padView = [[UIView alloc] init];
    self.padView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.padView];

    self.resetButton = [self primaryButtonWithTitle:@"重新出题" action:@selector(onReset)];
    self.checkButton = [self ghostButtonWithTitle:@"提交检查" action:@selector(onCheck)];
    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.checkButton, self.resetButton]];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:btnStack];

    NSLayoutConstraint *boardSquare = [self.boardView.widthAnchor constraintEqualToAnchor:self.boardView.heightAnchor];
    NSLayoutConstraint *boardMax = [self.boardView.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    NSLayoutConstraint *boardPref = [self.boardView.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    boardPref.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.difficultySeg.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [self.difficultySeg.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.difficultySeg.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:self.difficultySeg.bottomAnchor constant:JFSpacing8],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        boardSquare, boardMax, boardPref,
        [self.boardView.topAnchor      constraintGreaterThanOrEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing12],
        [self.boardView.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.padView.topAnchor      constraintEqualToAnchor:self.boardView.bottomAnchor constant:JFSpacing12],
        [self.padView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.padView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.padView.heightAnchor   constraintEqualToConstant:48],

        [btnStack.topAnchor      constraintGreaterThanOrEqualToAnchor:self.padView.bottomAnchor constant:JFSpacing12],
        [btnStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [btnStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [btnStack.heightAnchor   constraintEqualToConstant:48],
        [btnStack.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];

    [self buildCells];
    [self buildPad];
}

- (void)buildCells {
    self.cells = [NSMutableArray array];
    for (NSInteger r = 0; r < kN; r++) {
        NSMutableArray *row = [NSMutableArray array];
        for (NSInteger c = 0; c < kN; c++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
            b.tag = r * kN + c;
            [b addTarget:self action:@selector(onCellTap:) forControlEvents:UIControlEventTouchUpInside];
            [self.boardView addSubview:b];
            [row addObject:b];
        }
        [self.cells addObject:row];
    }
}

- (void)buildPad {
    self.padButtons = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    for (NSInteger i = 1; i <= 9; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = i;
        b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
        b.layer.cornerRadius = JFRadiusSmall;
        b.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightHeavy];
        [b setTitle:[NSString stringWithFormat:@"%ld", (long)i] forState:UIControlStateNormal];
        [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(onPad:) forControlEvents:UIControlEventTouchUpInside];
        [self.padButtons addObject:b];
        [items addObject:b];
    }
    self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.clearButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    self.clearButton.layer.cornerRadius = JFRadiusSmall;
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [self.clearButton setTitle:@"清" forState:UIControlStateNormal];
    [self.clearButton setTitleColor:[JFTheme textSecondary] forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [items addObject:self.clearButton];

    UIStackView *s = [[UIStackView alloc] initWithArrangedSubviews:items];
    s.axis = UILayoutConstraintAxisHorizontal;
    s.spacing = 6;
    s.distribution = UIStackViewDistributionFillEqually;
    s.translatesAutoresizingMaskIntoConstraints = NO;
    [self.padView addSubview:s];
    [NSLayoutConstraint activateConstraints:@[
        [s.topAnchor      constraintEqualToAnchor:self.padView.topAnchor],
        [s.leadingAnchor  constraintEqualToAnchor:self.padView.leadingAnchor],
        [s.trailingAnchor constraintEqualToAnchor:self.padView.trailingAnchor],
        [s.bottomAnchor   constraintEqualToAnchor:self.padView.bottomAnchor],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.boardView.bounds.size.width;
    if (W <= 0) return;
    CGFloat cell = W / kN;
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            UIButton *b = self.cells[r][c];
            b.frame = CGRectMake(c * cell, r * cell, cell, cell);
            b.titleLabel.font = [UIFont systemFontOfSize:cell * 0.45 weight:UIFontWeightSemibold];
        }
    }
    [self drawDividers];
}

- (void)drawDividers {
    // 移除旧的
    for (CALayer *layer in [self.boardView.layer.sublayers copy]) {
        if ([layer.name isEqualToString:@"divider"]) [layer removeFromSuperlayer];
    }
    CGFloat W = self.boardView.bounds.size.width;
    if (W <= 0) return;
    CGFloat cell = W / kN;
    for (NSInteger i = 0; i <= kN; i++) {
        CALayer *layer = [CALayer layer];
        layer.name = @"divider";
        layer.backgroundColor = (i % 3 == 0)
            ? [UIColor colorWithWhite:1 alpha:0.55].CGColor
            : [UIColor colorWithWhite:1 alpha:0.15].CGColor;
        CGFloat thick = (i % 3 == 0) ? 1.2 : 0.5;
        // 横线
        layer.frame = CGRectMake(0, i * cell - thick / 2, W, thick);
        [self.boardView.layer addSublayer:layer];

        CALayer *layer2 = [CALayer layer];
        layer2.name = @"divider";
        layer2.backgroundColor = layer.backgroundColor;
        layer2.frame = CGRectMake(i * cell - thick / 2, 0, thick, W);
        [self.boardView.layer addSublayer:layer2];
    }
}

#pragma mark - Actions

- (void)onDifficultyChanged {
    self.difficulty = self.difficultySeg.selectedSegmentIndex;
    [self newPuzzle];
}

- (void)onReset {
    [self newPuzzle];
}

- (void)onCellTap:(UIButton *)b {
    NSInteger r = b.tag / kN;
    NSInteger c = b.tag % kN;
    if (self.given[r][c].integerValue != 0) {
        [JFTheme hapticImpactLight];
        // 题目格不可改,但可以选中显示
        self.selRow = r; self.selCol = c;
    } else {
        self.selRow = r; self.selCol = c;
    }
    [self syncCells];
}

- (void)onPad:(UIButton *)b {
    if (self.selRow < 0 || self.selCol < 0) return;
    if (self.given[self.selRow][self.selCol].integerValue != 0) return;
    self.current[self.selRow][self.selCol] = @(b.tag);
    [JFTheme hapticSelection];
    [self syncCells];
    if ([self isFilled] && [self isAllCorrect]) {
        [self handleWin];
    }
}

- (void)onClear {
    if (self.selRow < 0 || self.selCol < 0) return;
    if (self.given[self.selRow][self.selCol].integerValue != 0) return;
    self.current[self.selRow][self.selCol] = @0;
    [self syncCells];
}

- (void)onCheck {
    if (![self isFilled]) {
        self.statusLabel.text = @"还没填完哦";
        return;
    }
    if ([self isAllCorrect]) {
        [self handleWin];
    } else {
        [JFTheme hapticNotification:UINotificationFeedbackTypeError];
        self.statusLabel.text = @"有错误,再检查一下";
    }
}

#pragma mark - Game

- (void)newPuzzle {
    self.solution = [self pickSolutionForDifficulty:self.difficulty];
    self.given = [self emptyGrid];
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            self.given[r][c] = self.solution[r][c];
        }
    }
    NSInteger removeCount;
    switch (self.difficulty) {
        case 0:  removeCount = 36; break;
        case 1:  removeCount = 48; break;
        default: removeCount = 56; break;
    }
    NSMutableArray *positions = [NSMutableArray array];
    for (NSInteger i = 0; i < kN * kN; i++) [positions addObject:@(i)];
    // 简单乱序
    for (NSInteger i = (NSInteger)positions.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [positions exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    for (NSInteger i = 0; i < removeCount; i++) {
        NSInteger idx = ((NSNumber *)positions[i]).integerValue;
        self.given[idx / kN][idx % kN] = @0;
    }
    self.current = [self emptyGrid];
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            self.current[r][c] = self.given[r][c];
        }
    }
    self.startTs = [[NSDate date] timeIntervalSince1970];
    self.selRow = -1;
    self.selCol = -1;
    self.statusLabel.text = @"点格子,选数字";
    [self syncCells];
}

- (NSMutableArray<NSMutableArray<NSNumber *> *> *)emptyGrid {
    NSMutableArray *g = [NSMutableArray array];
    for (NSInteger r = 0; r < kN; r++) {
        NSMutableArray *row = [NSMutableArray array];
        for (NSInteger c = 0; c < kN; c++) [row addObject:@0];
        [g addObject:row];
    }
    return g;
}

// 内置 3 套完整解。简单/中等/困难只是挖空数量不同;3 套互不相同。
- (NSMutableArray<NSMutableArray<NSNumber *> *> *)pickSolutionForDifficulty:(NSInteger)diff {
    static NSArray<NSArray *> *_solutions = nil;
    if (!_solutions) {
        _solutions = @[
            @[@[@5,@3,@4,@6,@7,@8,@9,@1,@2],
              @[@6,@7,@2,@1,@9,@5,@3,@4,@8],
              @[@1,@9,@8,@3,@4,@2,@5,@6,@7],
              @[@8,@5,@9,@7,@6,@1,@4,@2,@3],
              @[@4,@2,@6,@8,@5,@3,@7,@9,@1],
              @[@7,@1,@3,@9,@2,@4,@8,@5,@6],
              @[@9,@6,@1,@5,@3,@7,@2,@8,@4],
              @[@2,@8,@7,@4,@1,@9,@6,@3,@5],
              @[@3,@4,@5,@2,@8,@6,@1,@7,@9]],
            @[@[@1,@2,@3,@4,@5,@6,@7,@8,@9],
              @[@4,@5,@6,@7,@8,@9,@1,@2,@3],
              @[@7,@8,@9,@1,@2,@3,@4,@5,@6],
              @[@2,@3,@1,@5,@6,@4,@8,@9,@7],
              @[@5,@6,@4,@8,@9,@7,@2,@3,@1],
              @[@8,@9,@7,@2,@3,@1,@5,@6,@4],
              @[@3,@1,@2,@6,@4,@5,@9,@7,@8],
              @[@6,@4,@5,@9,@7,@8,@3,@1,@2],
              @[@9,@7,@8,@3,@1,@2,@6,@4,@5]],
            @[@[@9,@8,@7,@6,@5,@4,@3,@2,@1],
              @[@6,@5,@4,@3,@2,@1,@9,@8,@7],
              @[@3,@2,@1,@9,@8,@7,@6,@5,@4],
              @[@8,@9,@6,@7,@4,@5,@2,@1,@3],
              @[@5,@4,@2,@1,@3,@8,@7,@9,@6],
              @[@7,@1,@3,@2,@9,@6,@5,@4,@8],
              @[@2,@3,@5,@8,@1,@9,@4,@7,@6],
              @[@1,@7,@8,@4,@6,@2,@9,@3,@5],   // 这一行可能不严格,作为占位用
              @[@4,@6,@9,@5,@7,@3,@1,@8,@2]]
        ];
    }
    // 随机挑一个解(并轻量做行/列/数字置换打乱)
    NSArray<NSArray<NSNumber *> *> *src = _solutions[arc4random_uniform((uint32_t)_solutions.count)];
    NSMutableArray<NSMutableArray<NSNumber *> *> *grid = [NSMutableArray array];
    for (NSArray *row in src) [grid addObject:[row mutableCopy]];

    // 数字置换 1..9 -> 随机 perm
    NSMutableArray *perm = [@[@1,@2,@3,@4,@5,@6,@7,@8,@9] mutableCopy];
    for (NSInteger i = (NSInteger)perm.count - 1; i > 0; i--) {
        NSInteger j = arc4random_uniform((uint32_t)(i + 1));
        [perm exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    NSMutableArray<NSMutableArray<NSNumber *> *> *out = [self emptyGrid];
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            NSInteger v = grid[r][c].integerValue;
            if (v >= 1 && v <= 9) {
                out[r][c] = perm[v - 1];
            } else {
                out[r][c] = @1;
            }
        }
    }
    return out;
}

- (BOOL)isFilled {
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            if (self.current[r][c].integerValue == 0) return NO;
        }
    }
    return YES;
}

- (BOOL)isAllCorrect {
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            if (![self.current[r][c] isEqual:self.solution[r][c]]) return NO;
        }
    }
    return YES;
}

- (void)handleWin {
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    NSTimeInterval used = [[NSDate date] timeIntervalSince1970] - self.startTs;
    self.statusLabel.text = [NSString stringWithFormat:@"恭喜过关 · 用时 %.0f 秒", used];
    NSInteger score = MAX(50, 600 - (NSInteger)used + self.difficulty * 100);
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindSudoku score:score win:YES];
    r.difficulty = self.difficulty;
    r.duration = used;
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindSudoku difficulty:self.difficulty score:score win:YES];
}

#pragma mark - Render

- (void)syncCells {
    for (NSInteger r = 0; r < kN; r++) {
        for (NSInteger c = 0; c < kN; c++) {
            UIButton *b = self.cells[r][c];
            NSInteger gv = self.given[r][c].integerValue;
            NSInteger cv = self.current[r][c].integerValue;
            BOOL selected = (r == self.selRow && c == self.selCol);
            BOOL sameRowCol = (r == self.selRow || c == self.selCol);
            BOOL sameBox = (self.selRow >= 0 && (r / 3 == self.selRow / 3) && (c / 3 == self.selCol / 3));
            UIColor *bg;
            if (selected) bg = [JFTheme accent];
            else if (sameRowCol || sameBox) bg = [UIColor colorWithWhite:1 alpha:0.10];
            else bg = [UIColor colorWithWhite:1 alpha:0.04];
            b.backgroundColor = bg;
            if (cv == 0) {
                [b setTitle:@"" forState:UIControlStateNormal];
            } else {
                [b setTitle:[NSString stringWithFormat:@"%ld", (long)cv] forState:UIControlStateNormal];
                if (gv != 0) {
                    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
                } else {
                    [b setTitleColor:[JFTheme accent] forState:UIControlStateNormal];
                }
            }
        }
    }
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

- (UIButton *)ghostButtonWithTitle:(NSString *)t action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    b.layer.cornerRadius = JFRadiusMedium;
    b.layer.borderWidth = 1;
    b.layer.borderColor = [JFTheme cardBorder].CGColor;
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

@end
