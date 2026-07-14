//
//  JFSokobanViewController.m
//  JiFeng_UpApp
//

#import "JFSokobanViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

typedef NS_OPTIONS(NSUInteger, JFSokobanTileFlags) {
    JFSokobanTileFloor  = 0,
    JFSokobanTileWall   = 1 << 0,
    JFSokobanTileGoal   = 1 << 1,
    JFSokobanTileBox    = 1 << 2,
    JFSokobanTilePlayer = 1 << 3,
};

@protocol JFSokobanBoardDataSource <NSObject>
- (NSInteger)sokobanRows;
- (NSInteger)sokobanColumns;
- (JFSokobanTileFlags)sokobanFlagsAtRow:(NSInteger)row column:(NSInteger)column;
@end

@interface JFSokobanBoardView : UIView
@property (nonatomic, weak) id<JFSokobanBoardDataSource> dataSource;
@end

@implementation JFSokobanBoardView

- (instancetype)init {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.clipsToBounds = YES;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"推箱子棋盘";
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    id<JFSokobanBoardDataSource> source = self.dataSource;
    NSInteger rows = source.sokobanRows;
    NSInteger columns = source.sokobanColumns;
    if (!source || rows <= 0 || columns <= 0) return;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat padding = 8;
    CGFloat tile = floor(MIN((self.bounds.size.width - padding * 2) / columns,
                             (self.bounds.size.height - padding * 2) / rows));
    CGFloat boardWidth = tile * columns;
    CGFloat boardHeight = tile * rows;
    CGFloat originX = floor((self.bounds.size.width - boardWidth) / 2.0);
    CGFloat originY = floor((self.bounds.size.height - boardHeight) / 2.0);

    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger column = 0; column < columns; column++) {
            CGRect cell = CGRectMake(originX + column * tile, originY + row * tile, tile, tile);
            JFSokobanTileFlags flags = [source sokobanFlagsAtRow:row column:column];

            UIColor *floor = ((row + column) % 2 == 0)
                ? [UIColor colorWithWhite:1 alpha:0.065]
                : [UIColor colorWithWhite:1 alpha:0.04];
            [floor setFill];
            CGContextFillRect(context, CGRectInset(cell, 0.5, 0.5));

            if (flags & JFSokobanTileWall) {
                CGRect wallRect = CGRectInset(cell, tile * 0.07, tile * 0.07);
                UIBezierPath *wall = [UIBezierPath bezierPathWithRoundedRect:wallRect cornerRadius:MAX(2, tile * 0.11)];
                [[JFTheme brandPrimary] setFill];
                [wall fill];
                UIBezierPath *shine = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(wallRect, tile * 0.12, tile * 0.12)
                                                                 cornerRadius:MAX(1, tile * 0.07)];
                [[[UIColor whiteColor] colorWithAlphaComponent:0.09] setFill];
                [shine fill];
                continue;
            }

            if (flags & JFSokobanTileGoal) {
                CGPoint center = CGPointMake(CGRectGetMidX(cell), CGRectGetMidY(cell));
                CGFloat radius = tile * 0.21;
                UIBezierPath *goal = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2)];
                goal.lineWidth = MAX(2, tile * 0.07);
                [[JFTheme accent] setStroke];
                [goal stroke];
                UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - tile * 0.055,
                                                                                       center.y - tile * 0.055,
                                                                                       tile * 0.11,
                                                                                       tile * 0.11)];
                [[JFTheme accent] setFill];
                [dot fill];
            }

            if (flags & JFSokobanTileBox) {
                BOOL placed = (flags & JFSokobanTileGoal) != 0;
                CGRect boxRect = CGRectInset(cell, tile * 0.12, tile * 0.12);
                UIBezierPath *box = [UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:MAX(3, tile * 0.11)];
                [(placed ? [JFTheme success] : [JFTheme warning]) setFill];
                [box fill];
                UIBezierPath *inner = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(boxRect, tile * 0.15, tile * 0.15)
                                                                  cornerRadius:MAX(2, tile * 0.05)];
                inner.lineWidth = MAX(1.5, tile * 0.045);
                [[[UIColor blackColor] colorWithAlphaComponent:0.25] setStroke];
                [inner stroke];
            }

            if (flags & JFSokobanTilePlayer) {
                CGPoint center = CGPointMake(CGRectGetMidX(cell), CGRectGetMidY(cell));
                CGFloat radius = tile * 0.34;
                UIBezierPath *body = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2)];
                [[JFTheme accent] setFill];
                [body fill];
                CGFloat eyeR = MAX(1.2, tile * 0.035);
                for (NSNumber *offset in @[@(-0.11), @(0.11)]) {
                    CGFloat eyeX = center.x + tile * offset.doubleValue;
                    UIBezierPath *eye = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(eyeX - eyeR,
                                                                                          center.y - tile * 0.08 - eyeR,
                                                                                          eyeR * 2,
                                                                                          eyeR * 2)];
                    [[UIColor colorWithWhite:0.08 alpha:0.9] setFill];
                    [eye fill];
                }
            }
        }
    }
}

@end

@interface JFSokobanViewController () <JFSokobanBoardDataSource>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *previousLevelButton;
@property (nonatomic, strong) UIButton *nextLevelButton;
@property (nonatomic, strong) UILabel *levelLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) JFSokobanBoardView *boardView;
@property (nonatomic, strong) UIView *controlPanel;
@property (nonatomic, strong) UIButton *undoButton;

@property (nonatomic, copy) NSArray<NSDictionary *> *levels;
@property (nonatomic, assign) NSInteger levelIndex;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, strong) NSMutableIndexSet *walls;
@property (nonatomic, strong) NSMutableIndexSet *goals;
@property (nonatomic, strong) NSMutableIndexSet *boxes;
@property (nonatomic, assign) NSInteger player;
@property (nonatomic, assign) NSInteger moves;
@property (nonatomic, assign) NSInteger pushes;
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *undoStack;
@end

@implementation JFSokobanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"推箱子";
    self.levels = [self buildLevels];
    self.levelIndex = MIN([[NSUserDefaults standardUserDefaults] integerForKey:@"jf_sokoban_last_level"], self.levels.count - 1);
    [self buildUI];
    [self loadLevel:self.levelIndex];
    [self installSwipeGestures];
}

- (NSArray<NSDictionary *> *)buildLevels {
    return @[
        @{@"name": @"第一次推动", @"map": @[@"######", @"# .  #", @"# $  #", @"#  @ #", @"######"]},
        @{@"name": @"左右配合", @"map": @[@"#######", @"#  .  #", @"#  $  #", @"# $@. #", @"#     #", @"#######"]},
        @{@"name": @"绕到背后", @"map": @[@"########", @"# .    #", @"#   $  #", @"#  #   #", @"#  @   #", @"#      #", @"########"]},
        @{@"name": @"双路线", @"map": @[@"#########", @"# .   . #", @"#   $ $ #", @"#  #    #", @"#  @    #", @"#       #", @"#########"]},
        @{@"name": @"错位目标", @"map": @[@"#########", @"#  . .  #", @"#       #", @"#  $$   #", @"#   #@  #", @"#       #", @"#########"]},
        @{@"name": @"三箱入库", @"map": @[@"##########", @"# . .  . #", @"# $ $  $ #", @"#    ##  #", @"#   @    #", @"#        #", @"##########"]},
        @{@"name": @"四重推进", @"map": @[@"##########", @"#  .. .. #", @"#        #", @"#  $$ $$ #", @"#   @    #", @"#        #", @"##########"]},
        @{@"name": @"横移再上推", @"map": @[@"#########", @"# . . . #", @"#       #", @"# $$$   #", @"#   @   #", @"#       #", @"#########"]},
        @{@"name": @"绕墙运输", @"map": @[@"##########", @"# .  .   #", @"#        #", @"# $    $ #", @"#  ##    #", @"#   @    #", @"#        #", @"##########"]},
        @{@"name": @"终场仓库", @"map": @[@"###########", @"#  . . .  #", @"#         #", @"#  $ $ $  #", @"#   # #   #", @"#    @    #", @"#         #", @"###########"]},
    ];
}

#pragma mark - UI

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"推箱子";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.previousLevelButton = [self iconButton:@"chevron.left" accessibility:@"上一关" action:@selector(onPreviousLevel)];
    self.nextLevelButton = [self iconButton:@"chevron.right" accessibility:@"下一关" action:@selector(onNextLevel)];
    [self.view addSubview:self.previousLevelButton];
    [self.view addSubview:self.nextLevelButton];

    self.levelLabel = [[UILabel alloc] init];
    self.levelLabel.textColor = [JFTheme textPrimary];
    self.levelLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.levelLabel.textAlignment = NSTextAlignmentCenter;
    self.levelLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    self.levelLabel.layer.cornerRadius = 8;
    self.levelLabel.layer.borderWidth = 1;
    self.levelLabel.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.levelLabel.clipsToBounds = YES;
    self.levelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.levelLabel];

    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.textColor = [JFTheme textSecondary];
    self.scoreLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scoreLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    self.boardView = [[JFSokobanBoardView alloc] init];
    self.boardView.dataSource = self;
    self.boardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.boardView];

    self.controlPanel = [[UIView alloc] init];
    self.controlPanel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.07];
    self.controlPanel.layer.cornerRadius = 8;
    self.controlPanel.layer.borderWidth = 1;
    self.controlPanel.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.controlPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.controlPanel];

    self.undoButton = [self iconButton:@"arrow.uturn.backward" accessibility:@"撤销一步" action:@selector(onUndo)];
    UIButton *restart = [self iconButton:@"arrow.clockwise" accessibility:@"重新开始本关" action:@selector(onRestart)];
    UIButton *next = [self iconButton:@"forward.end.fill" accessibility:@"进入下一关" action:@selector(onNextLevel)];
    [self.controlPanel addSubview:self.undoButton];
    [self.controlPanel addSubview:restart];
    [self.controlPanel addSubview:next];

    UIButton *up = [self directionButton:@"chevron.up" row:-1 column:0 accessibility:@"向上"];
    UIButton *down = [self directionButton:@"chevron.down" row:1 column:0 accessibility:@"向下"];
    UIButton *left = [self directionButton:@"chevron.left" row:0 column:-1 accessibility:@"向左"];
    UIButton *right = [self directionButton:@"chevron.right" row:0 column:1 accessibility:@"向右"];
    for (UIButton *button in @[up, down, left, right]) [self.controlPanel addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:64],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-64],

        [self.levelLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:11],
        [self.levelLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.levelLabel.widthAnchor constraintEqualToConstant:190],
        [self.levelLabel.heightAnchor constraintEqualToConstant:34],
        [self.previousLevelButton.trailingAnchor constraintEqualToAnchor:self.levelLabel.leadingAnchor constant:-8],
        [self.previousLevelButton.centerYAnchor constraintEqualToAnchor:self.levelLabel.centerYAnchor],
        [self.nextLevelButton.leadingAnchor constraintEqualToAnchor:self.levelLabel.trailingAnchor constant:8],
        [self.nextLevelButton.centerYAnchor constraintEqualToAnchor:self.levelLabel.centerYAnchor],

        [self.scoreLabel.topAnchor constraintEqualToAnchor:self.levelLabel.bottomAnchor constant:7],
        [self.scoreLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [self.scoreLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.scoreLabel.bottomAnchor constant:4],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],

        [self.boardView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:9],
        [self.boardView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.boardView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.boardView.bottomAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:-10],

        [self.controlPanel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.controlPanel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.controlPanel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12],
        [self.controlPanel.heightAnchor constraintEqualToConstant:106],

        [self.undoButton.leadingAnchor constraintEqualToAnchor:self.controlPanel.leadingAnchor constant:14],
        [self.undoButton.topAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:14],
        [restart.leadingAnchor constraintEqualToAnchor:self.undoButton.trailingAnchor constant:10],
        [restart.centerYAnchor constraintEqualToAnchor:self.undoButton.centerYAnchor],
        [next.leadingAnchor constraintEqualToAnchor:self.undoButton.leadingAnchor],
        [next.topAnchor constraintEqualToAnchor:self.undoButton.bottomAnchor constant:10],

        [up.centerXAnchor constraintEqualToAnchor:self.controlPanel.trailingAnchor constant:-82],
        [up.topAnchor constraintEqualToAnchor:self.controlPanel.topAnchor constant:8],
        [left.trailingAnchor constraintEqualToAnchor:up.leadingAnchor constant:-5],
        [left.centerYAnchor constraintEqualToAnchor:self.controlPanel.centerYAnchor],
        [right.leadingAnchor constraintEqualToAnchor:up.trailingAnchor constant:5],
        [right.centerYAnchor constraintEqualToAnchor:self.controlPanel.centerYAnchor],
        [down.centerXAnchor constraintEqualToAnchor:up.centerXAnchor],
        [down.bottomAnchor constraintEqualToAnchor:self.controlPanel.bottomAnchor constant:-8],
    ]];
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

- (UIButton *)directionButton:(NSString *)symbol row:(NSInteger)row column:(NSInteger)column accessibility:(NSString *)accessibility {
    UIButton *button = [self iconButton:symbol accessibility:accessibility action:@selector(onDirectionButton:)];
    button.tag = (row + 1) * 3 + (column + 1);
    button.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.72];
    return button;
}

#pragma mark - Level parsing

- (void)loadLevel:(NSInteger)index {
    self.levelIndex = MAX(0, MIN((NSInteger)self.levels.count - 1, index));
    NSDictionary *level = self.levels[self.levelIndex];
    NSArray<NSString *> *map = level[@"map"];
    self.rows = map.count;
    self.columns = 0;
    for (NSString *line in map) self.columns = MAX(self.columns, (NSInteger)line.length);
    self.walls = [NSMutableIndexSet indexSet];
    self.goals = [NSMutableIndexSet indexSet];
    self.boxes = [NSMutableIndexSet indexSet];
    self.player = 0;

    [map enumerateObjectsUsingBlock:^(NSString *line, NSUInteger row, BOOL *stop) {
        for (NSInteger column = 0; column < self.columns; column++) {
            unichar character = column < line.length ? [line characterAtIndex:column] : '#';
            NSInteger position = row * self.columns + column;
            if (character == '#') [self.walls addIndex:position];
            if (character == '.' || character == '*' || character == '+') [self.goals addIndex:position];
            if (character == '$' || character == '*') [self.boxes addIndex:position];
            if (character == '@' || character == '+') self.player = position;
        }
    }];
    self.moves = 0;
    self.pushes = 0;
    self.completed = NO;
    self.undoStack = [NSMutableArray array];
    self.statusLabel.text = @"滑动棋盘或使用方向键，把所有箱子推进圆形目标";
    [[NSUserDefaults standardUserDefaults] setInteger:self.levelIndex forKey:@"jf_sokoban_last_level"];
    [self updateHUD];
    [self.boardView setNeedsDisplay];
}

- (void)updateHUD {
    NSDictionary *level = self.levels[self.levelIndex];
    self.levelLabel.text = [NSString stringWithFormat:@"第 %ld 关 · %@", (long)self.levelIndex + 1, level[@"name"]];
    NSInteger best = [[NSUserDefaults standardUserDefaults] integerForKey:[self bestKey]];
    self.scoreLabel.text = best > 0
        ? [NSString stringWithFormat:@"移动 %ld · 推动 %ld · 最佳 %ld", (long)self.moves, (long)self.pushes, (long)best]
        : [NSString stringWithFormat:@"移动 %ld · 推动 %ld", (long)self.moves, (long)self.pushes];
    self.previousLevelButton.enabled = self.levelIndex > 0;
    self.previousLevelButton.alpha = self.previousLevelButton.enabled ? 1 : 0.35;
    self.nextLevelButton.enabled = self.levelIndex < self.levels.count - 1;
    self.nextLevelButton.alpha = self.nextLevelButton.enabled ? 1 : 0.35;
    self.undoButton.enabled = self.undoStack.count > 0;
    self.undoButton.alpha = self.undoButton.enabled ? 1 : 0.35;
}

- (NSString *)bestKey {
    return [NSString stringWithFormat:@"jf_sokoban_best_%ld", (long)self.levelIndex];
}

#pragma mark - Movement

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
        case UISwipeGestureRecognizerDirectionUp: [self moveRow:-1 column:0]; break;
        case UISwipeGestureRecognizerDirectionDown: [self moveRow:1 column:0]; break;
        case UISwipeGestureRecognizerDirectionLeft: [self moveRow:0 column:-1]; break;
        case UISwipeGestureRecognizerDirectionRight: [self moveRow:0 column:1]; break;
        default: break;
    }
}

- (void)onDirectionButton:(UIButton *)button {
    NSInteger row = button.tag / 3 - 1;
    NSInteger column = button.tag % 3 - 1;
    [self moveRow:row column:column];
}

- (void)moveRow:(NSInteger)rowDelta column:(NSInteger)columnDelta {
    if (self.completed) return;
    NSInteger playerRow = self.player / self.columns;
    NSInteger playerColumn = self.player % self.columns;
    NSInteger nextRow = playerRow + rowDelta;
    NSInteger nextColumn = playerColumn + columnDelta;
    if (nextRow < 0 || nextRow >= self.rows || nextColumn < 0 || nextColumn >= self.columns) return;
    NSInteger next = nextRow * self.columns + nextColumn;
    if ([self.walls containsIndex:next]) {
        [JFTheme hapticImpactLight];
        return;
    }

    BOOL pushing = [self.boxes containsIndex:next];
    NSInteger beyond = -1;
    if (pushing) {
        NSInteger beyondRow = nextRow + rowDelta;
        NSInteger beyondColumn = nextColumn + columnDelta;
        if (beyondRow < 0 || beyondRow >= self.rows || beyondColumn < 0 || beyondColumn >= self.columns) return;
        beyond = beyondRow * self.columns + beyondColumn;
        if ([self.walls containsIndex:beyond] || [self.boxes containsIndex:beyond]) {
            [JFTheme hapticNotification:UINotificationFeedbackTypeWarning];
            return;
        }
    }

    [self saveUndoSnapshot];
    if (pushing) {
        [self.boxes removeIndex:next];
        [self.boxes addIndex:beyond];
        self.pushes += 1;
        [JFTheme hapticImpactMedium];
    } else {
        [JFTheme hapticImpactLight];
    }
    self.player = next;
    self.moves += 1;
    [self.boardView setNeedsDisplay];
    [self updateHUD];
    [self checkCompletion];
}

- (void)saveUndoSnapshot {
    NSDictionary *snapshot = @{
        @"player": @(self.player),
        @"boxes": self.boxes.copy,
        @"moves": @(self.moves),
        @"pushes": @(self.pushes),
    };
    [self.undoStack addObject:snapshot];
    if (self.undoStack.count > 120) [self.undoStack removeObjectAtIndex:0];
}

- (void)onUndo {
    NSDictionary *snapshot = self.undoStack.lastObject;
    if (!snapshot) return;
    [self.undoStack removeLastObject];
    self.player = [snapshot[@"player"] integerValue];
    self.boxes = [snapshot[@"boxes"] mutableCopy];
    self.moves = [snapshot[@"moves"] integerValue];
    self.pushes = [snapshot[@"pushes"] integerValue];
    self.completed = NO;
    self.statusLabel.text = @"已撤销一步";
    [self.boardView setNeedsDisplay];
    [self updateHUD];
    [JFTheme hapticSelection];
}

- (void)onRestart {
    [JFTheme hapticImpactMedium];
    [self loadLevel:self.levelIndex];
}

- (void)onPreviousLevel {
    if (self.levelIndex > 0) [self loadLevel:self.levelIndex - 1];
}

- (void)onNextLevel {
    if (self.levelIndex < self.levels.count - 1) [self loadLevel:self.levelIndex + 1];
}

- (void)checkCompletion {
    __block BOOL done = self.boxes.count == self.goals.count;
    [self.boxes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (![self.goals containsIndex:idx]) {
            done = NO;
            *stop = YES;
        }
    }];
    if (!done) return;

    self.completed = YES;
    NSInteger best = [[NSUserDefaults standardUserDefaults] integerForKey:[self bestKey]];
    BOOL newBest = best == 0 || self.moves < best;
    if (newBest) [[NSUserDefaults standardUserDefaults] setInteger:self.moves forKey:[self bestKey]];
    self.statusLabel.text = self.levelIndex == self.levels.count - 1
        ? @"全部关卡完成！仓库已经整理得井井有条"
        : (newBest ? @"通关并刷新最佳步数，进入下一关吧" : @"通关！可以继续挑战下一关");
    NSInteger score = MAX(100, 1000 + self.levelIndex * 100 - self.moves * 8 - self.pushes * 3);
    JFGameResult *result = [JFGameResult resultWithKind:JFGameKindSokoban score:score win:YES];
    result.difficulty = self.levelIndex + 1;
    result.extra = @{@"moves": @(self.moves), @"pushes": @(self.pushes)};
    [[JFProfileStore shared] reportResult:result];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindSokoban difficulty:result.difficulty score:score win:YES];
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    [self updateHUD];
}

#pragma mark - Board data source

- (NSInteger)sokobanRows { return self.rows; }
- (NSInteger)sokobanColumns { return self.columns; }

- (JFSokobanTileFlags)sokobanFlagsAtRow:(NSInteger)row column:(NSInteger)column {
    NSInteger position = row * self.columns + column;
    JFSokobanTileFlags flags = JFSokobanTileFloor;
    if ([self.walls containsIndex:position]) flags |= JFSokobanTileWall;
    if ([self.goals containsIndex:position]) flags |= JFSokobanTileGoal;
    if ([self.boxes containsIndex:position]) flags |= JFSokobanTileBox;
    if (self.player == position) flags |= JFSokobanTilePlayer;
    return flags;
}

@end
