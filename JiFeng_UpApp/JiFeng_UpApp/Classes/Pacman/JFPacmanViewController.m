//
//  JFPacmanViewController.m
//  JiFeng_UpApp
//

#import "JFPacmanViewController.h"
#import <GameplayKit/GameplayKit.h>
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

typedef NS_ENUM(NSInteger, JFPacDirection) {
    JFPacDirectionNone = 0,
    JFPacDirectionUp,
    JFPacDirectionDown,
    JFPacDirectionLeft,
    JFPacDirectionRight,
};

@interface JFPacGhost : NSObject
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) NSInteger startPosition;
@property (nonatomic, strong) UIColor *color;
@end

@implementation JFPacGhost
@end

@protocol JFPacmanBoardDataSource <NSObject>
- (NSInteger)pacmanRows;
- (NSInteger)pacmanColumns;
- (BOOL)pacmanWallAtPosition:(NSInteger)position;
- (BOOL)pacmanPelletAtPosition:(NSInteger)position;
- (BOOL)pacmanPowerAtPosition:(NSInteger)position;
- (NSInteger)pacmanPlayerPosition;
- (JFPacDirection)pacmanPlayerDirection;
- (NSArray<JFPacGhost *> *)pacmanGhosts;
- (BOOL)pacmanIsPowered;
- (NSInteger)pacmanAnimationTick;
@end

@interface JFPacmanBoardView : UIView
@property (nonatomic, weak) id<JFPacmanBoardDataSource> dataSource;
@end

@implementation JFPacmanBoardView

- (instancetype)init {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.backgroundColor = [UIColor colorWithWhite:0.015 alpha:0.97];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.clipsToBounds = YES;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"吃豆人迷宫";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    id<JFPacmanBoardDataSource> source = self.dataSource;
    NSInteger rows = source.pacmanRows;
    NSInteger columns = source.pacmanColumns;
    if (!source || rows <= 0 || columns <= 0) return;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat padding = 5;
    CGFloat tile = floor(MIN((self.bounds.size.width - padding * 2) / columns,
                             (self.bounds.size.height - padding * 2) / rows));
    CGFloat mazeWidth = tile * columns;
    CGFloat mazeHeight = tile * rows;
    CGFloat originX = floor((self.bounds.size.width - mazeWidth) / 2.0);
    CGFloat originY = floor((self.bounds.size.height - mazeHeight) / 2.0);

    UIColor *wallFill = [[JFTheme brandPrimary] colorWithAlphaComponent:0.76];
    UIColor *wallEdge = [[JFTheme accent] colorWithAlphaComponent:0.72];
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger column = 0; column < columns; column++) {
            NSInteger position = row * columns + column;
            CGRect cell = CGRectMake(originX + column * tile, originY + row * tile, tile, tile);
            if ([source pacmanWallAtPosition:position]) {
                CGRect wallRect = CGRectInset(cell, tile * 0.08, tile * 0.08);
                UIBezierPath *wall = [UIBezierPath bezierPathWithRoundedRect:wallRect cornerRadius:MAX(1.5, tile * 0.2)];
                [wallFill setFill];
                [wall fill];
                wall.lineWidth = MAX(0.7, tile * 0.055);
                [wallEdge setStroke];
                [wall stroke];
            } else if ([source pacmanPowerAtPosition:position]) {
                CGFloat pulse = source.pacmanAnimationTick % 4 < 2 ? 0.24 : 0.19;
                CGFloat radius = tile * pulse;
                UIBezierPath *power = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(cell) - radius,
                                                                                         CGRectGetMidY(cell) - radius,
                                                                                         radius * 2,
                                                                                         radius * 2)];
                [[UIColor colorWithWhite:1 alpha:0.94] setFill];
                [power fill];
            } else if ([source pacmanPelletAtPosition:position]) {
                CGFloat radius = MAX(1.2, tile * 0.085);
                UIBezierPath *pellet = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(cell) - radius,
                                                                                          CGRectGetMidY(cell) - radius,
                                                                                          radius * 2,
                                                                                          radius * 2)];
                [[UIColor colorWithRed:1 green:0.86 blue:0.56 alpha:0.9] setFill];
                [pellet fill];
            }
        }
    }

    NSInteger playerPosition = source.pacmanPlayerPosition;
    NSInteger playerRow = playerPosition / columns;
    NSInteger playerColumn = playerPosition % columns;
    CGPoint playerCenter = CGPointMake(originX + (playerColumn + 0.5) * tile,
                                       originY + (playerRow + 0.5) * tile);
    CGFloat playerRadius = tile * 0.41;
    CGFloat directionAngle = 0;
    switch (source.pacmanPlayerDirection) {
        case JFPacDirectionUp: directionAngle = -M_PI_2; break;
        case JFPacDirectionDown: directionAngle = M_PI_2; break;
        case JFPacDirectionLeft: directionAngle = M_PI; break;
        default: directionAngle = 0; break;
    }
    CGFloat mouth = source.pacmanAnimationTick % 2 == 0 ? 0.2 : 0.06;
    UIBezierPath *player = [UIBezierPath bezierPath];
    [player moveToPoint:playerCenter];
    [player addArcWithCenter:playerCenter
                     radius:playerRadius
                 startAngle:directionAngle + mouth * M_PI
                   endAngle:directionAngle + (2.0 - mouth) * M_PI
                  clockwise:YES];
    [player closePath];
    [[UIColor colorWithRed:1 green:0.82 blue:0.12 alpha:1] setFill];
    [player fill];

    BOOL powered = source.pacmanIsPowered;
    [source.pacmanGhosts enumerateObjectsUsingBlock:^(JFPacGhost *ghost, NSUInteger idx, BOOL *stop) {
        NSInteger row = ghost.position / columns;
        NSInteger column = ghost.position % columns;
        CGPoint center = CGPointMake(originX + (column + 0.5) * tile,
                                     originY + (row + 0.5) * tile);
        UIColor *ghostColor = powered ? [UIColor colorWithRed:0.2 green:0.48 blue:0.96 alpha:1] : ghost.color;
        CGFloat radius = tile * 0.37;
        UIBezierPath *body = [UIBezierPath bezierPath];
        [body addArcWithCenter:CGPointMake(center.x, center.y - tile * 0.05)
                       radius:radius
                   startAngle:M_PI
                     endAngle:0
                    clockwise:YES];
        [body addLineToPoint:CGPointMake(center.x + radius, center.y + radius)];
        [body addLineToPoint:CGPointMake(center.x + radius * 0.45, center.y + radius * 0.72)];
        [body addLineToPoint:CGPointMake(center.x, center.y + radius)];
        [body addLineToPoint:CGPointMake(center.x - radius * 0.45, center.y + radius * 0.72)];
        [body addLineToPoint:CGPointMake(center.x - radius, center.y + radius)];
        [body closePath];
        [ghostColor setFill];
        [body fill];

        CGFloat eyeRadius = MAX(1.2, tile * 0.09);
        for (NSNumber *offset in @[@(-0.14), @(0.14)]) {
            CGPoint eyeCenter = CGPointMake(center.x + tile * offset.doubleValue, center.y - tile * 0.08);
            UIBezierPath *eye = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(eyeCenter.x - eyeRadius,
                                                                                   eyeCenter.y - eyeRadius,
                                                                                   eyeRadius * 2,
                                                                                   eyeRadius * 2)];
            [[UIColor whiteColor] setFill];
            [eye fill];
            CGFloat pupil = eyeRadius * 0.45;
            UIBezierPath *pupilPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(eyeCenter.x - pupil,
                                                                                        eyeCenter.y - pupil,
                                                                                        pupil * 2,
                                                                                        pupil * 2)];
            [[UIColor colorWithWhite:0.05 alpha:1] setFill];
            [pupilPath fill];
        }
    }];

    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor);
    CGContextStrokeRectWithWidth(context, CGRectMake(originX, originY, mazeWidth, mazeHeight), 1);
}

@end

@interface JFPacmanViewController () <JFPacmanBoardDataSource>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *livesLabel;
@property (nonatomic, strong) UILabel *levelLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) JFPacmanBoardView *boardView;
@property (nonatomic, strong) UIButton *startOverlayButton;
@property (nonatomic, strong) UIView *controlPanel;
@property (nonatomic, strong) UILabel *powerLabel;

@property (nonatomic, copy) NSArray<NSString *> *mazeTemplate;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, strong) NSMutableIndexSet *walls;
@property (nonatomic, strong) NSMutableIndexSet *pellets;
@property (nonatomic, strong) NSMutableIndexSet *powerPellets;
@property (nonatomic, assign) NSInteger player;
@property (nonatomic, assign) NSInteger playerStart;
@property (nonatomic, assign) JFPacDirection direction;
@property (nonatomic, assign) JFPacDirection requestedDirection;
@property (nonatomic, copy) NSArray<JFPacGhost *> *ghosts;
@property (nonatomic, strong) GKGridGraph<GKGridGraphNode *> *pathGraph;

@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, assign) NSInteger lives;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) NSInteger tick;
@property (nonatomic, assign) NSInteger ghostCombo;
@property (nonatomic, assign) NSTimeInterval powerEndTime;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL gameStarted;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation JFPacmanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"吃豆人";
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:@"jf_pacman_best"];
    self.mazeTemplate = [self defaultMaze];
    [self buildUI];
    [self resetEntireGame];
    [self installSwipeGestures];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
}

- (NSArray<NSString *> *)defaultMaze {
    return @[
        @"###################",
        @"#o.......#.......o#",
        @"#.###.##.#.##.###.#",
        @"#.................#",
        @"#.###.#.###.#.###.#",
        @"#.....#...#...#...#",
        @"#####.###.#.###.###",
        @"#####.#.......#.###",
        @"#####.#.##G##.#.###",
        @"#.......G.G.......#",
        @"#####.#.#####.#.###",
        @"#####.#.......#.###",
        @"#####.#.#####.#.###",
        @"#........#........#",
        @"#.###.##.#.##.###.#",
        @"#o..#.....P...#..o#",
        @"###.#.#.#####.#.###",
        @"#...#.#...#...#...#",
        @"#.#####.#.#.#####.#",
        @"#.................#",
        @"###################",
    ];
}

#pragma mark - UI

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"吃豆人";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.pauseButton = [self iconButton:@"pause.fill" accessibility:@"暂停" action:@selector(onPause)];
    [self.view addSubview:self.pauseButton];

    self.scoreLabel = [self badgeLabel];
    self.livesLabel = [self badgeLabel];
    self.levelLabel = [self badgeLabel];
    UIStackView *hud = [[UIStackView alloc] initWithArrangedSubviews:@[self.scoreLabel, self.livesLabel, self.levelLabel]];
    hud.axis = UILayoutConstraintAxisHorizontal;
    hud.distribution = UIStackViewDistributionFillEqually;
    hud.spacing = 7;
    hud.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hud];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    self.boardView = [[JFPacmanBoardView alloc] init];
    self.boardView.dataSource = self;
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.boardView];

    self.startOverlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startOverlayButton.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.94];
    self.startOverlayButton.layer.cornerRadius = 8;
    self.startOverlayButton.layer.borderWidth = 1;
    self.startOverlayButton.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.65].CGColor;
    [self.startOverlayButton setTitle:@"开始游戏" forState:UIControlStateNormal];
    [self.startOverlayButton setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    self.startOverlayButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.startOverlayButton addTarget:self action:@selector(onOverlayStart) forControlEvents:UIControlEventTouchUpInside];
    self.startOverlayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.boardView addSubview:self.startOverlayButton];

    self.controlPanel = [[UIView alloc] init];
    self.controlPanel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.07];
    self.controlPanel.layer.cornerRadius = 8;
    self.controlPanel.layer.borderWidth = 1;
    self.controlPanel.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.controlPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.controlPanel];

    UIButton *restart = [self iconButton:@"arrow.clockwise" accessibility:@"重新开始" action:@selector(onRestart)];
    [self.controlPanel addSubview:restart];
    self.powerLabel = [[UILabel alloc] init];
    self.powerLabel.text = @"能量待机";
    self.powerLabel.textColor = [JFTheme textSecondary];
    self.powerLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    self.powerLabel.textAlignment = NSTextAlignmentCenter;
    self.powerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlPanel addSubview:self.powerLabel];

    UIButton *up = [self directionButton:@"chevron.up" direction:JFPacDirectionUp accessibility:@"向上"];
    UIButton *down = [self directionButton:@"chevron.down" direction:JFPacDirectionDown accessibility:@"向下"];
    UIButton *left = [self directionButton:@"chevron.left" direction:JFPacDirectionLeft accessibility:@"向左"];
    UIButton *right = [self directionButton:@"chevron.right" direction:JFPacDirectionRight accessibility:@"向右"];
    for (UIButton *button in @[up, down, left, right]) [self.controlPanel addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.pauseButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.pauseButton.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],

        [hud.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:11],
        [hud.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [hud.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [hud.heightAnchor constraintEqualToConstant:31],

        [self.statusLabel.topAnchor constraintEqualToAnchor:hud.bottomAnchor constant:5],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.statusLabel.heightAnchor constraintEqualToConstant:19],

        [self.boardView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:6],
        [self.boardView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [self.boardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [self.boardView.bottomAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:-8],

        [self.startOverlayButton.centerXAnchor constraintEqualToAnchor:self.boardView.centerXAnchor],
        [self.startOverlayButton.centerYAnchor constraintEqualToAnchor:self.boardView.centerYAnchor],
        [self.startOverlayButton.widthAnchor constraintEqualToConstant:146],
        [self.startOverlayButton.heightAnchor constraintEqualToConstant:48],

        [self.controlPanel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.controlPanel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.controlPanel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-10],
        [self.controlPanel.heightAnchor constraintEqualToConstant:96],

        [restart.leadingAnchor constraintEqualToAnchor:self.controlPanel.leadingAnchor constant:14],
        [restart.topAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:13],
        [self.powerLabel.leadingAnchor constraintEqualToAnchor:self.controlPanel.leadingAnchor constant:7],
        [self.powerLabel.topAnchor constraintEqualToAnchor:restart.bottomAnchor constant:5],
        [self.powerLabel.widthAnchor constraintEqualToConstant:88],

        [up.centerXAnchor constraintEqualToAnchor:self.controlPanel.trailingAnchor constant:-80],
        [up.topAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:4],
        [left.trailingAnchor constraintEqualToAnchor:up.leadingAnchor constant:-5],
        [left.centerYAnchor constraintEqualToAnchor:self.controlPanel.centerYAnchor],
        [right.leadingAnchor constraintEqualToAnchor:up.trailingAnchor constant:5],
        [right.centerYAnchor constraintEqualToAnchor:self.controlPanel.centerYAnchor],
        [down.centerXAnchor constraintEqualToAnchor:up.centerXAnchor],
        [down.bottomAnchor constraintEqualToAnchor:self.controlPanel.bottomAnchor constant:-4],
    ]];
}

- (UILabel *)badgeLabel {
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [JFTheme textPrimary];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    label.layer.cornerRadius = 7;
    label.layer.borderWidth = 1;
    label.layer.borderColor = [JFTheme cardBorder].CGColor;
    label.clipsToBounds = YES;
    return label;
}

- (UIButton *)iconButton:(NSString *)symbol accessibility:(NSString *)accessibility action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];
    [button setImage:[UIImage systemImageNamed:symbol withConfiguration:config] forState:UIControlStateNormal];
    button.tintColor = [JFTheme textPrimary];
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.09];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [JFTheme cardBorder].CGColor;
    button.accessibilityLabel = accessibility;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:40],
        [button.heightAnchor constraintEqualToConstant:40],
    ]];
    return button;
}

- (UIButton *)directionButton:(NSString *)symbol direction:(JFPacDirection)direction accessibility:(NSString *)accessibility {
    UIButton *button = [self iconButton:symbol accessibility:accessibility action:@selector(onDirection:)];
    button.tag = direction;
    button.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.74];
    return button;
}

#pragma mark - Setup

- (void)resetEntireGame {
    [self stopTimer];
    [self.startOverlayButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.startOverlayButton addTarget:self action:@selector(onOverlayStart) forControlEvents:UIControlEventTouchUpInside];
    self.score = 0;
    self.lives = 3;
    self.level = 1;
    self.tick = 0;
    self.gameStarted = NO;
    self.running = NO;
    [self loadMaze];
    self.statusLabel.text = @"准备好了吗？";
    [self.startOverlayButton setTitle:@"开始游戏" forState:UIControlStateNormal];
    self.startOverlayButton.hidden = NO;
    [self.pauseButton setImage:[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal];
    [self updateHUD];
}

- (void)loadMaze {
    self.rows = self.mazeTemplate.count;
    self.columns = self.mazeTemplate.firstObject.length;
    self.walls = [NSMutableIndexSet indexSet];
    self.pellets = [NSMutableIndexSet indexSet];
    self.powerPellets = [NSMutableIndexSet indexSet];
    NSMutableArray<NSNumber *> *ghostStarts = [NSMutableArray array];

    [self.mazeTemplate enumerateObjectsUsingBlock:^(NSString *line, NSUInteger row, BOOL *stop) {
        for (NSInteger column = 0; column < self.columns; column++) {
            unichar character = [line characterAtIndex:column];
            NSInteger position = row * self.columns + column;
            if (character == '#') [self.walls addIndex:position];
            if (character == '.') [self.pellets addIndex:position];
            if (character == 'o') [self.powerPellets addIndex:position];
            if (character == 'P') self.playerStart = position;
            if (character == 'G') [ghostStarts addObject:@(position)];
        }
    }];
    self.player = self.playerStart;
    self.direction = JFPacDirectionNone;
    self.requestedDirection = JFPacDirectionNone;
    self.powerEndTime = 0;
    self.ghostCombo = 0;

    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.98 green:0.24 blue:0.30 alpha:1],
        [UIColor colorWithRed:0.98 green:0.42 blue:0.78 alpha:1],
        [UIColor colorWithRed:0.18 green:0.82 blue:0.90 alpha:1],
    ];
    NSMutableArray<JFPacGhost *> *ghosts = [NSMutableArray array];
    [ghostStarts enumerateObjectsUsingBlock:^(NSNumber *position, NSUInteger idx, BOOL *stop) {
        JFPacGhost *ghost = [JFPacGhost new];
        ghost.position = position.integerValue;
        ghost.startPosition = position.integerValue;
        ghost.color = colors[idx % colors.count];
        [ghosts addObject:ghost];
    }];
    self.ghosts = ghosts;
    [self buildPathGraph];
    [self.boardView setNeedsDisplay];
}

- (void)buildPathGraph {
    self.pathGraph = [[GKGridGraph alloc] initFromGridStartingAt:(vector_int2){0, 0}
                                                          width:(int32_t)self.columns
                                                         height:(int32_t)self.rows
                                               diagonalsAllowed:NO];
    NSMutableArray<GKGridGraphNode *> *wallNodes = [NSMutableArray array];
    [self.walls enumerateIndexesUsingBlock:^(NSUInteger position, BOOL *stop) {
        int32_t row = (int32_t)(position / self.columns);
        int32_t column = (int32_t)(position % self.columns);
        GKGridGraphNode *node = [self.pathGraph nodeAtGridPosition:(vector_int2){column, row}];
        if (node) [wallNodes addObject:node];
    }];
    [self.pathGraph removeNodes:wallNodes];
}

#pragma mark - Controls

- (void)installSwipeGestures {
    for (NSNumber *direction in @[@(UISwipeGestureRecognizerDirectionUp),
                                   @(UISwipeGestureRecognizerDirectionDown),
                                   @(UISwipeGestureRecognizerDirectionLeft),
                                   @(UISwipeGestureRecognizerDirectionRight)]) {
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
        swipe.direction = direction.integerValue;
        [self.boardView addGestureRecognizer:swipe];
    }
}

- (void)onSwipe:(UISwipeGestureRecognizer *)swipe {
    switch (swipe.direction) {
        case UISwipeGestureRecognizerDirectionUp: [self requestDirection:JFPacDirectionUp]; break;
        case UISwipeGestureRecognizerDirectionDown: [self requestDirection:JFPacDirectionDown]; break;
        case UISwipeGestureRecognizerDirectionLeft: [self requestDirection:JFPacDirectionLeft]; break;
        case UISwipeGestureRecognizerDirectionRight: [self requestDirection:JFPacDirectionRight]; break;
        default: break;
    }
}

- (void)onDirection:(UIButton *)button {
    [self requestDirection:(JFPacDirection)button.tag];
}

- (void)requestDirection:(JFPacDirection)direction {
    self.requestedDirection = direction;
    if (!self.gameStarted) [self onOverlayStart];
    [JFTheme hapticSelection];
}

- (void)onOverlayStart {
    if (!self.gameStarted) self.gameStarted = YES;
    [self startTimer];
    self.startOverlayButton.hidden = YES;
    self.statusLabel.text = @"追逐开始";
}

- (void)onPause {
    if (!self.gameStarted) return;
    if (self.running) {
        [self stopTimer];
        self.statusLabel.text = @"已暂停";
        [self.startOverlayButton setTitle:@"继续游戏" forState:UIControlStateNormal];
        self.startOverlayButton.hidden = NO;
        [self.pauseButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    } else {
        [self onOverlayStart];
    }
    [JFTheme hapticSelection];
}

- (void)onRestart {
    [JFTheme hapticImpactMedium];
    [self resetEntireGame];
}

- (void)startTimer {
    if (self.running) return;
    self.running = YES;
    [self.pauseButton setImage:[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal];
    NSTimeInterval interval = MAX(0.085, 0.145 - (self.level - 1) * 0.008);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(onGameTick) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    self.running = NO;
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - Game loop

- (void)onGameTick {
    self.tick += 1;
    NSInteger oldPlayer = self.player;
    NSMutableArray<NSNumber *> *oldGhostPositions = [NSMutableArray arrayWithCapacity:self.ghosts.count];
    for (JFPacGhost *ghost in self.ghosts) [oldGhostPositions addObject:@(ghost.position)];

    if ([self canMoveFrom:self.player direction:self.requestedDirection]) self.direction = self.requestedDirection;
    if ([self canMoveFrom:self.player direction:self.direction]) self.player = [self positionFrom:self.player direction:self.direction];
    [self consumeCurrentTile];
    if (!self.running) {
        [self updateHUD];
        [self.boardView setNeedsDisplay];
        return;
    }

    BOOL powered = [self pacmanIsPowered];
    NSInteger ghostCadence = powered ? 3 : (self.level >= 3 ? 1 : 2);
    if (self.tick % ghostCadence == 0) {
        [self.ghosts enumerateObjectsUsingBlock:^(JFPacGhost *ghost, NSUInteger idx, BOOL *stop) {
            [self moveGhost:ghost index:idx frightened:powered];
        }];
    }

    [self resolveCollisionsFromOldPlayer:oldPlayer oldGhosts:oldGhostPositions];
    [self updateHUD];
    [self.boardView setNeedsDisplay];
}

- (NSInteger)positionFrom:(NSInteger)position direction:(JFPacDirection)direction {
    NSInteger row = position / self.columns;
    NSInteger column = position % self.columns;
    switch (direction) {
        case JFPacDirectionUp: row -= 1; break;
        case JFPacDirectionDown: row += 1; break;
        case JFPacDirectionLeft: column -= 1; break;
        case JFPacDirectionRight: column += 1; break;
        default: break;
    }
    if (row < 0 || row >= self.rows || column < 0 || column >= self.columns) return position;
    return row * self.columns + column;
}

- (BOOL)canMoveFrom:(NSInteger)position direction:(JFPacDirection)direction {
    if (direction == JFPacDirectionNone) return NO;
    NSInteger next = [self positionFrom:position direction:direction];
    return next != position && ![self.walls containsIndex:next];
}

- (void)consumeCurrentTile {
    if ([self.pellets containsIndex:self.player]) {
        [self.pellets removeIndex:self.player];
        self.score += 10;
    }
    if ([self.powerPellets containsIndex:self.player]) {
        [self.powerPellets removeIndex:self.player];
        self.score += 50;
        self.powerEndTime = NSDate.date.timeIntervalSince1970 + 8.0;
        self.ghostCombo = 0;
        self.statusLabel.text = @"能量激活，可以反吃追兵";
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    }
    if (self.pellets.count == 0 && self.powerPellets.count == 0) [self completeLevel];
}

- (void)moveGhost:(JFPacGhost *)ghost index:(NSInteger)index frightened:(BOOL)frightened {
    GKGridGraphNode *start = [self graphNodeForPosition:ghost.position];
    if (!start) return;
    if (frightened) {
        NSArray<GKGridGraphNode *> *neighbors = (NSArray<GKGridGraphNode *> *)start.connectedNodes;
        GKGridGraphNode *best = nil;
        NSInteger bestDistance = NSIntegerMin;
        for (GKGridGraphNode *node in neighbors) {
            NSInteger position = node.gridPosition.y * self.columns + node.gridPosition.x;
            NSInteger distance = [self manhattanFrom:position to:self.player];
            if (distance > bestDistance) {
                bestDistance = distance;
                best = node;
            }
        }
        if (best) ghost.position = best.gridPosition.y * self.columns + best.gridPosition.x;
        return;
    }

    NSInteger targetPosition = self.player;
    if (index == 1) {
        NSInteger ahead = self.player;
        for (NSInteger step = 0; step < 3; step++) {
            NSInteger next = [self positionFrom:ahead direction:self.direction];
            if (next == ahead || [self.walls containsIndex:next]) break;
            ahead = next;
        }
        targetPosition = ahead;
    } else if (index == 2 && (self.tick / 18) % 2 == 1) {
        targetPosition = (self.rows - 2) * self.columns + 1;
    }
    GKGridGraphNode *target = [self graphNodeForPosition:targetPosition] ?: [self graphNodeForPosition:self.player];
    if (!target) return;
    NSArray<GKGraphNode *> *path = [self.pathGraph findPathFromNode:start toNode:target];
    if (path.count == 0) return;
    GKGridGraphNode *next = (GKGridGraphNode *)path.firstObject;
    if (next.gridPosition.x == start.gridPosition.x && next.gridPosition.y == start.gridPosition.y && path.count > 1) {
        next = (GKGridGraphNode *)path[1];
    }
    ghost.position = next.gridPosition.y * self.columns + next.gridPosition.x;
}

- (GKGridGraphNode *)graphNodeForPosition:(NSInteger)position {
    int32_t row = (int32_t)(position / self.columns);
    int32_t column = (int32_t)(position % self.columns);
    return [self.pathGraph nodeAtGridPosition:(vector_int2){column, row}];
}

- (NSInteger)manhattanFrom:(NSInteger)from to:(NSInteger)to {
    NSInteger fromRow = from / self.columns;
    NSInteger fromColumn = from % self.columns;
    NSInteger toRow = to / self.columns;
    NSInteger toColumn = to % self.columns;
    return labs(fromRow - toRow) + labs(fromColumn - toColumn);
}

- (void)resolveCollisionsFromOldPlayer:(NSInteger)oldPlayer oldGhosts:(NSArray<NSNumber *> *)oldGhosts {
    BOOL powered = [self pacmanIsPowered];
    [self.ghosts enumerateObjectsUsingBlock:^(JFPacGhost *ghost, NSUInteger idx, BOOL *stop) {
        NSInteger oldGhost = oldGhosts[idx].integerValue;
        BOOL sameCell = ghost.position == self.player;
        BOOL crossed = oldGhost == self.player && ghost.position == oldPlayer;
        if (!sameCell && !crossed) return;
        if (powered) {
            NSInteger gain = 200 * (1 << MIN(3, self.ghostCombo));
            self.score += gain;
            self.ghostCombo += 1;
            ghost.position = ghost.startPosition;
            self.statusLabel.text = [NSString stringWithFormat:@"反吃追兵 +%ld", (long)gain];
            [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        } else {
            [self loseLife];
            *stop = YES;
        }
    }];
}

- (void)loseLife {
    self.lives -= 1;
    [JFTheme hapticNotification:UINotificationFeedbackTypeError];
    if (self.lives <= 0) {
        [self gameOver];
        return;
    }
    [self stopTimer];
    self.player = self.playerStart;
    self.direction = JFPacDirectionNone;
    self.requestedDirection = JFPacDirectionNone;
    for (JFPacGhost *ghost in self.ghosts) ghost.position = ghost.startPosition;
    self.statusLabel.text = [NSString stringWithFormat:@"被追兵抓住，还剩 %ld 条命", (long)self.lives];
    [self.startOverlayButton setTitle:@"继续" forState:UIControlStateNormal];
    self.startOverlayButton.hidden = NO;
    [self updateHUD];
    [self.boardView setNeedsDisplay];
}

- (void)completeLevel {
    [self stopTimer];
    NSInteger completedLevel = self.level;
    NSInteger roundScore = self.score;
    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindPacman score:roundScore win:YES];
    result.difficulty = completedLevel;
    result.extra = @{@"level": @(completedLevel), @"lives": @(self.lives)};
    [[JFProfileStore shared] reportResult:result];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindPacman difficulty:completedLevel score:roundScore win:YES];

    self.level += 1;
    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:@"jf_pacman_best"];
    }
    [self loadMaze];
    self.statusLabel.text = [NSString stringWithFormat:@"迷宫清空，进入第 %ld 关", (long)self.level];
    [self.startOverlayButton setTitle:@"下一关" forState:UIControlStateNormal];
    self.startOverlayButton.hidden = NO;
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    [self updateHUD];
}

- (void)gameOver {
    [self stopTimer];
    self.gameStarted = NO;
    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:@"jf_pacman_best"];
        self.statusLabel.text = [NSString stringWithFormat:@"游戏结束 · 新纪录 %ld", (long)self.best];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"游戏结束 · 得分 %ld", (long)self.score];
    }
    [self.startOverlayButton setTitle:@"重新开始" forState:UIControlStateNormal];
    [self.startOverlayButton removeTarget:self action:@selector(onOverlayStart) forControlEvents:UIControlEventTouchUpInside];
    [self.startOverlayButton addTarget:self action:@selector(onRestart) forControlEvents:UIControlEventTouchUpInside];
    self.startOverlayButton.hidden = NO;

    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindPacman score:self.score win:NO];
    result.difficulty = self.level;
    result.extra = @{@"level": @(self.level)};
    [[JFProfileStore shared] reportResult:result];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindPacman difficulty:self.level score:self.score win:NO];
}

- (void)updateHUD {
    if (self.score > self.best) self.best = self.score;
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld", (long)self.score];
    self.livesLabel.text = [NSString stringWithFormat:@"生命 %ld", (long)self.lives];
    self.levelLabel.text = [NSString stringWithFormat:@"关卡 %ld", (long)self.level];
    NSTimeInterval remaining = MAX(0, self.powerEndTime - NSDate.date.timeIntervalSince1970);
    self.powerLabel.text = remaining > 0 ? [NSString stringWithFormat:@"能量 %.1fs", remaining] : [NSString stringWithFormat:@"最佳 %ld", (long)self.best];
}

#pragma mark - Board data source

- (NSInteger)pacmanRows { return self.rows; }
- (NSInteger)pacmanColumns { return self.columns; }
- (BOOL)pacmanWallAtPosition:(NSInteger)position { return [self.walls containsIndex:position]; }
- (BOOL)pacmanPelletAtPosition:(NSInteger)position { return [self.pellets containsIndex:position]; }
- (BOOL)pacmanPowerAtPosition:(NSInteger)position { return [self.powerPellets containsIndex:position]; }
- (NSInteger)pacmanPlayerPosition { return self.player; }
- (JFPacDirection)pacmanPlayerDirection { return self.direction; }
- (NSArray<JFPacGhost *> *)pacmanGhosts { return self.ghosts; }
- (BOOL)pacmanIsPowered { return self.powerEndTime > NSDate.date.timeIntervalSince1970; }
- (NSInteger)pacmanAnimationTick { return self.tick; }

@end
