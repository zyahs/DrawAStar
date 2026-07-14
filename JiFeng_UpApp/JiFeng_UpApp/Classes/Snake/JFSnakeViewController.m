//
//  JFSnakeViewController.m
//  JiFeng_UpApp
//

#import "JFSnakeViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

typedef NS_ENUM(NSInteger, JFSnakeDirection) {
    JFSnakeDirUp,
    JFSnakeDirDown,
    JFSnakeDirLeft,
    JFSnakeDirRight,
};

static const NSInteger kSnakeCols = 18;
static const NSInteger kSnakeRows = 24;

@interface JFSnakeBoardView : UIView
@property (nonatomic, assign) NSInteger cols;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, copy)   NSArray<NSValue *> *snake;   // CGPoint, head 在 [0]
@property (nonatomic, assign) CGPoint food;
@end

@implementation JFSnakeBoardView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
        self.cols = kSnakeCols;
        self.rows = kSnakeRows;
        self.layer.cornerRadius = JFRadiusMedium;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.cols <= 0 || self.rows <= 0) return;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat cellW = w / self.cols;
    CGFloat cellH = h / self.rows;

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // 网格(很淡)
    CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] colorWithAlphaComponent:0.06].CGColor);
    CGContextSetLineWidth(ctx, 0.5);
    for (NSInteger i = 1; i < self.cols; i++) {
        CGContextMoveToPoint(ctx, i * cellW, 0);
        CGContextAddLineToPoint(ctx, i * cellW, h);
    }
    for (NSInteger j = 1; j < self.rows; j++) {
        CGContextMoveToPoint(ctx, 0, j * cellH);
        CGContextAddLineToPoint(ctx, w, j * cellH);
    }
    CGContextStrokePath(ctx);

    // 食物
    CGRect foodRect = CGRectMake(self.food.x * cellW + 2,
                                 self.food.y * cellH + 2,
                                 cellW - 4, cellH - 4);
    CGContextSetFillColorWithColor(ctx, [JFTheme accent].CGColor);
    CGContextFillEllipseInRect(ctx, foodRect);

    // 蛇身
    NSInteger n = self.snake.count;
    for (NSInteger i = 0; i < n; i++) {
        CGPoint p = [self.snake[i] CGPointValue];
        CGRect r = CGRectMake(p.x * cellW + 1,
                              p.y * cellH + 1,
                              cellW - 2, cellH - 2);
        UIColor *c;
        if (i == 0) {
            c = [JFTheme brandPrimary];
        } else {
            CGFloat t = 1.0 - (CGFloat)i / MAX(1.0, (CGFloat)n);
            c = [[JFTheme brandPrimary] colorWithAlphaComponent:0.4 + 0.5 * t];
        }
        CGContextSetFillColorWithColor(ctx, c.CGColor);
        UIBezierPath *bp = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:3];
        CGContextAddPath(ctx, bp.CGPath);
        CGContextFillPath(ctx);
    }
}

@end

#pragma mark - VC

@interface JFSnakeViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *bestLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) JFSnakeBoardView *board;
@property (nonatomic, strong) UIButton *playButton;     // 开始 / 暂停 / 继续
@property (nonatomic, strong) UIButton *resetButton;    // 重新开始

// 游戏状态
@property (nonatomic, strong) NSMutableArray<NSValue *> *snake; // CGPoint 数组
@property (nonatomic, assign) JFSnakeDirection direction;
@property (nonatomic, assign) JFSnakeDirection nextDirection;
@property (nonatomic, assign) CGPoint food;
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) CFTimeInterval lastTick;
@property (nonatomic, assign) CFTimeInterval tickInterval; // 秒

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL gameOver;

@end

@implementation JFSnakeViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.tickInterval = 0.18;
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:@"jf_snake_best"];

    [self buildBackground];
    [self buildUI];
    [self setupGestures];
    [self resetGameKeepBest];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self pause];
}

- (void)dealloc {
    [_link invalidate];
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
    self.titleLabel.text = @"贪吃蛇";
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
    self.statusLabel.text = @"上下左右滑动改变方向";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    self.board = [[JFSnakeBoardView alloc] init];
    self.board.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.board];

    self.playButton  = [self primaryButtonWithTitle:@"开始" action:@selector(onPlayTapped)];
    self.resetButton = [self ghostButtonWithTitle:@"重置" action:@selector(onResetTapped)];

    UIStackView *btnStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.playButton, self.resetButton]];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = JFSpacing12;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:btnStack];

    CGFloat boardAspect = (CGFloat)kSnakeCols / (CGFloat)kSnakeRows; // w/h

    NSLayoutConstraint *boardWidthEqHeight = [self.board.widthAnchor constraintEqualToAnchor:self.board.heightAnchor multiplier:boardAspect];
    boardWidthEqHeight.priority = UILayoutPriorityRequired;

    NSLayoutConstraint *boardBottomToBtn = [self.board.bottomAnchor constraintLessThanOrEqualToAnchor:btnStack.topAnchor constant:-JFSpacing16];
    boardBottomToBtn.priority = UILayoutPriorityRequired;

    NSLayoutConstraint *boardWidthMax = [self.board.widthAnchor constraintLessThanOrEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    boardWidthMax.priority = UILayoutPriorityRequired;

    // 期望尽量大:把宽度往 safeWidth-32 顶,高度由 aspect 自动算
    NSLayoutConstraint *boardWidthPref = [self.board.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-JFSpacing32];
    boardWidthPref.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        boardWidthEqHeight,
        boardBottomToBtn,
        boardWidthMax,
        boardWidthPref,
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [badgeStack.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [badgeStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [badgeStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [badgeStack.heightAnchor   constraintEqualToConstant:32],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:badgeStack.bottomAnchor constant:JFSpacing8],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.board.topAnchor      constraintGreaterThanOrEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing12],
        [self.board.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],
        [self.board.leadingAnchor  constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.board.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [btnStack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [btnStack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [btnStack.heightAnchor   constraintEqualToConstant:48],
        [btnStack.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];
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
    NSArray *dirs = @[
        @[@(UISwipeGestureRecognizerDirectionUp),    @(JFSnakeDirUp)],
        @[@(UISwipeGestureRecognizerDirectionDown),  @(JFSnakeDirDown)],
        @[@(UISwipeGestureRecognizerDirectionLeft),  @(JFSnakeDirLeft)],
        @[@(UISwipeGestureRecognizerDirectionRight), @(JFSnakeDirRight)],
    ];
    for (NSArray *pair in dirs) {
        UISwipeGestureRecognizer *g = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
        g.direction = (UISwipeGestureRecognizerDirection)[pair[0] integerValue];
        [self.view addGestureRecognizer:g];
    }
}

- (void)onSwipe:(UISwipeGestureRecognizer *)g {
    JFSnakeDirection dir = self.direction;
    switch (g.direction) {
        case UISwipeGestureRecognizerDirectionUp:    dir = JFSnakeDirUp; break;
        case UISwipeGestureRecognizerDirectionDown:  dir = JFSnakeDirDown; break;
        case UISwipeGestureRecognizerDirectionLeft:  dir = JFSnakeDirLeft; break;
        case UISwipeGestureRecognizerDirectionRight: dir = JFSnakeDirRight; break;
        default: break;
    }
    // 不能 180° 反向
    if ((self.direction == JFSnakeDirUp    && dir == JFSnakeDirDown) ||
        (self.direction == JFSnakeDirDown  && dir == JFSnakeDirUp)   ||
        (self.direction == JFSnakeDirLeft  && dir == JFSnakeDirRight)||
        (self.direction == JFSnakeDirRight && dir == JFSnakeDirLeft)) {
        return;
    }
    self.nextDirection = dir;
}

#pragma mark - Buttons

- (void)onPlayTapped {
    [JFTheme hapticImpactMedium];
    if (self.gameOver) {
        [self resetGameKeepBest];
        [self start];
        return;
    }
    if (self.running) {
        [self pause];
    } else {
        [self start];
    }
}

- (void)onResetTapped {
    [JFTheme hapticImpactMedium];
    [self pause];
    [self resetGameKeepBest];
}

#pragma mark - Game

- (void)resetGameKeepBest {
    self.snake = [NSMutableArray array];
    NSInteger startX = kSnakeCols / 2;
    NSInteger startY = kSnakeRows / 2;
    [self.snake addObject:[NSValue valueWithCGPoint:CGPointMake(startX, startY)]];
    [self.snake addObject:[NSValue valueWithCGPoint:CGPointMake(startX - 1, startY)]];
    [self.snake addObject:[NSValue valueWithCGPoint:CGPointMake(startX - 2, startY)]];
    self.direction = JFSnakeDirRight;
    self.nextDirection = JFSnakeDirRight;
    self.score = 0;
    self.gameOver = NO;
    self.tickInterval = 0.18;
    [self spawnFood];
    [self syncBoard];
    [self updateLabels];
    [self.statusLabel setText:@"上下左右滑动改变方向 · 点开始"];
    [self.playButton setTitle:@"开始" forState:UIControlStateNormal];
}

- (void)start {
    if (self.gameOver) return;
    self.running = YES;
    [self.playButton setTitle:@"暂停" forState:UIControlStateNormal];
    self.statusLabel.text = @"加油!";
    if (!self.link) {
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick:)];
        [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.lastTick = 0;
    self.link.paused = NO;
}

- (void)pause {
    self.running = NO;
    self.link.paused = YES;
    if (!self.gameOver) {
        [self.playButton setTitle:@"继续" forState:UIControlStateNormal];
        self.statusLabel.text = @"已暂停";
    }
}

- (void)onTick:(CADisplayLink *)link {
    if (!self.running) return;
    if (self.lastTick == 0) {
        self.lastTick = link.timestamp;
        return;
    }
    if (link.timestamp - self.lastTick < self.tickInterval) return;
    self.lastTick = link.timestamp;
    [self stepOnce];
}

- (void)stepOnce {
    self.direction = self.nextDirection;
    CGPoint head = [self.snake.firstObject CGPointValue];
    CGPoint nh = head;
    switch (self.direction) {
        case JFSnakeDirUp:    nh.y -= 1; break;
        case JFSnakeDirDown:  nh.y += 1; break;
        case JFSnakeDirLeft:  nh.x -= 1; break;
        case JFSnakeDirRight: nh.x += 1; break;
    }
    // 撞墙
    if (nh.x < 0 || nh.x >= kSnakeCols || nh.y < 0 || nh.y >= kSnakeRows) {
        [self handleGameOver];
        return;
    }
    // 撞自己(吃到尾巴最后一格也算成功避开,因为尾巴会移开 —— 简化:全部 body 检查)
    for (NSInteger i = 0; i < (NSInteger)self.snake.count - 1; i++) {
        CGPoint p = [self.snake[i] CGPointValue];
        if ((NSInteger)p.x == (NSInteger)nh.x && (NSInteger)p.y == (NSInteger)nh.y) {
            [self handleGameOver];
            return;
        }
    }

    BOOL ate = ((NSInteger)nh.x == (NSInteger)self.food.x && (NSInteger)nh.y == (NSInteger)self.food.y);
    [self.snake insertObject:[NSValue valueWithCGPoint:nh] atIndex:0];
    if (ate) {
        self.score += 1;
        [JFTheme hapticSelection];
        // 加速
        if (self.tickInterval > 0.07) self.tickInterval -= 0.005;
        [self spawnFood];
        [self updateLabels];
    } else {
        [self.snake removeLastObject];
    }
    [self syncBoard];
}

- (void)spawnFood {
    NSMutableSet *occ = [NSMutableSet set];
    for (NSValue *v in self.snake) {
        CGPoint p = [v CGPointValue];
        [occ addObject:[NSString stringWithFormat:@"%ld_%ld", (long)p.x, (long)p.y]];
    }
    NSInteger total = kSnakeCols * kSnakeRows;
    if ((NSInteger)occ.count >= total) return;
    while (1) {
        NSInteger x = arc4random_uniform((uint32_t)kSnakeCols);
        NSInteger y = arc4random_uniform((uint32_t)kSnakeRows);
        NSString *k = [NSString stringWithFormat:@"%ld_%ld", (long)x, (long)y];
        if (![occ containsObject:k]) {
            self.food = CGPointMake(x, y);
            return;
        }
    }
}

- (void)syncBoard {
    self.board.snake = [self.snake copy];
    self.board.food = self.food;
    [self.board setNeedsDisplay];
}

- (void)updateLabels {
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld", (long)self.score];
    self.bestLabel.text  = [NSString stringWithFormat:@"最高 %ld", (long)self.best];
}

- (void)handleGameOver {
    self.gameOver = YES;
    [self pause];
    [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:@"jf_snake_best"];
        self.statusLabel.text = [NSString stringWithFormat:@"游戏结束 · 新纪录 %ld!", (long)self.best];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"游戏结束 · 得分 %ld", (long)self.score];
    }
    [self.playButton setTitle:@"再来一局" forState:UIControlStateNormal];
    [self updateLabels];

    // 上报 Profile / Daily
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindSnake score:self.score win:YES];
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindSnake difficulty:0 score:self.score win:(self.score >= 30)];
}

@end
