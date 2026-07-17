//
//  JFDiceRollSurface.m
//  JiFeng_UpApp
//

#import "JFDiceRollSurface.h"
#import "JFTheme.h"
#import "JFGamePieceSkin.h"
#import "JFSkinStore.h"

@interface JFDiceRollSurface ()
@property (nonatomic, strong) UILabel *cueLabel;
@property (nonatomic, strong) JFGamePieceSkinView *trayView;
@property (nonatomic, copy) NSArray<JFSkinnedDieView *> *diceViews;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIButton *rollButton;
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactGenerator;
@property (nonatomic, copy, readwrite) NSArray<NSNumber *> *finalValues;
@property (nonatomic, assign, readwrite, getter=isRolling) BOOL rolling;
@property (nonatomic, assign) NSTimeInterval settleDeadline;
@property (nonatomic, assign) NSInteger animationTick;
@end

@implementation JFDiceRollSurface

- (instancetype)initWithDiceCount:(NSInteger)diceCount {
    if ((self = [super initWithFrame:CGRectZero])) {
        _diceCount = MAX(1, MIN(100, diceCount));
        _rollEnabled = YES;
        _finalValues = @[];
        [self buildUI];
        [self resetForNextRoll];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applyCurrentSkin)
                                                     name:JFSkinDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [self.animationTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window && self.rolling) [self stopAnimationTimer];
}

- (void)buildUI {
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.055];
    self.layer.cornerRadius = 8;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [JFTheme cardBorder].CGColor;

    self.cueLabel = [[UILabel alloc] init];
    self.cueLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.cueLabel.textColor = [JFTheme textSecondary];
    self.cueLabel.textAlignment = NSTextAlignmentCenter;
    self.cueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.cueLabel];

    self.trayView = [[JFGamePieceSkinView alloc] init];
    self.trayView.surfaceStyle = JFGamePieceSurfaceStyleDiceTray;
    self.trayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.trayView];

    NSMutableArray<JFSkinnedDieView *> *diceViews = [NSMutableArray arrayWithCapacity:12];
    for (NSInteger index = 0; index < 12; index++) {
        JFSkinnedDieView *die = [[JFSkinnedDieView alloc] init];
        [self.trayView addSubview:die];
        [diceViews addObject:die];
    }
    self.diceViews = diceViews;

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightBold];
    self.summaryLabel.textColor = [JFTheme textPrimary];
    self.summaryLabel.textAlignment = NSTextAlignmentCenter;
    self.summaryLabel.numberOfLines = 2;
    self.summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.summaryLabel];

    self.rollButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.rollButton.backgroundColor = [JFTheme brandPrimary];
    self.rollButton.tintColor = [JFTheme textPrimary];
    [self.rollButton setTitle:@"按住摇骰" forState:UIControlStateNormal];
    [self.rollButton setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    [self.rollButton setImage:[UIImage systemImageNamed:@"hand.tap.fill"] forState:UIControlStateNormal];
    self.rollButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.rollButton.layer.cornerRadius = 8;
    self.rollButton.layer.borderWidth = 1;
    self.rollButton.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.58].CGColor;
    self.rollButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rollButton addTarget:self action:@selector(onButtonDown) forControlEvents:UIControlEventTouchDown];
    [self.rollButton addTarget:self action:@selector(onButtonUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self addSubview:self.rollButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.cueLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
        [self.cueLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [self.cueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [self.cueLabel.heightAnchor constraintEqualToConstant:18],

        [self.trayView.topAnchor constraintEqualToAnchor:self.cueLabel.bottomAnchor constant:8],
        [self.trayView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.trayView.widthAnchor constraintEqualToConstant:264],
        [self.trayView.heightAnchor constraintEqualToConstant:176],

        [self.summaryLabel.topAnchor constraintEqualToAnchor:self.trayView.bottomAnchor constant:7],
        [self.summaryLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [self.summaryLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        [self.summaryLabel.heightAnchor constraintEqualToConstant:38],

        [self.rollButton.topAnchor constraintEqualToAnchor:self.summaryLabel.bottomAnchor constant:7],
        [self.rollButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
        [self.rollButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14],
        [self.rollButton.heightAnchor constraintEqualToConstant:50],
        [self.rollButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-13],
    ]];
    [self applyCurrentSkin];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger visibleCount = MIN(12, MAX(1, self.diceCount));
    NSInteger columns = MIN(4, visibleCount);
    NSInteger rows = (visibleCount + columns - 1) / columns;
    CGFloat spacing = 8;
    CGFloat side = MIN(50, MIN((self.trayView.bounds.size.width - 24 - spacing * (columns - 1)) / columns,
                               (self.trayView.bounds.size.height - 20 - spacing * (rows - 1)) / rows));
    CGFloat totalHeight = rows * side + (rows - 1) * spacing;
    CGFloat originY = floor((self.trayView.bounds.size.height - totalHeight) / 2.0);
    for (NSInteger index = 0; index < self.diceViews.count; index++) {
        JFSkinnedDieView *die = self.diceViews[index];
        if (index >= visibleCount) {
            die.hidden = YES;
            continue;
        }
        die.hidden = NO;
        NSInteger row = index / columns;
        NSInteger rowStart = row * columns;
        NSInteger rowCount = MIN(columns, visibleCount - rowStart);
        CGFloat rowWidth = rowCount * side + (rowCount - 1) * spacing;
        CGFloat originX = floor((self.trayView.bounds.size.width - rowWidth) / 2.0);
        NSInteger column = index - rowStart;
        die.frame = CGRectMake(originX + column * (side + spacing), originY + row * (side + spacing), side, side);
    }
}

- (void)setDiceCount:(NSInteger)diceCount {
    _diceCount = MAX(1, MIN(100, diceCount));
    [self resetForNextRoll];
    [self setNeedsLayout];
}

- (void)setRollEnabled:(BOOL)rollEnabled {
    _rollEnabled = rollEnabled;
    self.rollButton.enabled = rollEnabled;
    self.rollButton.alpha = rollEnabled ? 1 : 0.38;
    if (!rollEnabled && self.rolling) [self stopAnimationTimer];
}

- (NSArray<NSNumber *> *)randomValuesWithCount:(NSInteger)count {
    NSMutableArray<NSNumber *> *values = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger index = 0; index < count; index++) [values addObject:@(arc4random_uniform(6) + 1)];
    return values;
}

- (void)renderValues:(NSArray<NSNumber *> *)values locked:(BOOL)locked {
    NSInteger previewCount = MIN((NSInteger)values.count, 12);
    for (NSInteger index = 0; index < MIN(self.diceCount, 12); index++) {
        JFSkinnedDieView *die = self.diceViews[index];
        [die configureWithFace:(index < previewCount ? values[index].integerValue : 1) locked:locked];
        die.highlighted = !locked && self.finalValues.count > 0;
        die.transform = CGAffineTransformIdentity;
    }
}

- (void)applyCurrentSkin {
    self.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.rollButton.backgroundColor = [JFTheme brandPrimary];
    self.rollButton.tintColor = [JFTheme textPrimary];
    self.rollButton.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.58].CGColor;
    [self.trayView refreshSkin];
    for (JFSkinnedDieView *die in self.diceViews) [die setNeedsDisplay];
}

- (void)renderRandomPreview {
    NSArray<NSNumber *> *preview = [self randomValuesWithCount:MIN(self.diceCount, 12)];
    [self renderValues:preview locked:NO];
    for (NSInteger index = 0; index < MIN(self.diceCount, 12); index++) {
        CGFloat angle = ((NSInteger)arc4random_uniform(17) - 8) * M_PI / 180.0;
        self.diceViews[index].transform = CGAffineTransformMakeRotation(angle);
    }
}

- (void)onButtonDown {
    [self beginRolling];
}

- (void)onButtonUp {
    [self beginSettlementCountdown];
}

- (void)beginRolling {
    if (!self.isRollEnabled) return;
    if (self.finalValues.count > 0) [self resetForNextRoll];
    self.rolling = YES;
    self.settleDeadline = 0;
    self.animationTick = 0;
    self.cueLabel.text = @"正在摇动 · 停下后保持静止 2 秒";
    self.summaryLabel.text = [NSString stringWithFormat:@"%ld 颗骰子滚动中", (long)self.diceCount];
    [self.rollButton setTitle:@"松手开始封盘" forState:UIControlStateNormal];
    [self startAnimationTimerIfNeeded];
    [self renderRandomPreview];
}

- (void)beginSettlementCountdown {
    if (!self.isRollEnabled) return;
    if (!self.rolling) [self beginRolling];
    self.settleDeadline = NSProcessInfo.processInfo.systemUptime + 2.0;
    [self.rollButton setTitle:@"保持静止" forState:UIControlStateNormal];
}

- (void)startAnimationTimerIfNeeded {
    if (self.animationTimer) return;
    self.impactGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [self.impactGenerator prepare];
    self.animationTimer = [NSTimer timerWithTimeInterval:0.09 target:self selector:@selector(onAnimationTick) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAnimationTimer {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.impactGenerator = nil;
    self.rolling = NO;
}

- (void)onAnimationTick {
    self.animationTick += 1;
    NSTimeInterval remaining = self.settleDeadline > 0 ? self.settleDeadline - NSProcessInfo.processInfo.systemUptime : 0;
    NSInteger stride = remaining > 1.2 ? 1 : (remaining > 0.45 ? 2 : 4);
    if (self.settleDeadline == 0 || self.animationTick % stride == 0) [self renderRandomPreview];
    if (self.animationTick % 2 == 0) {
        [self.impactGenerator impactOccurredWithIntensity:remaining > 0 && remaining < 0.8 ? 0.22 : 0.48];
        [self.impactGenerator prepare];
    }
    if (self.settleDeadline > 0) {
        self.cueLabel.text = [NSString stringWithFormat:@"保持静止 %.1f 秒后封盘", MAX(0, remaining)];
        self.summaryLabel.text = self.diceCount > 12
            ? [NSString stringWithFormat:@"预览 12 / %ld 颗 · 正在减速", (long)self.diceCount]
            : @"骰子正在减速";
        if (remaining <= 0) [self finishRoll];
    }
}

- (void)finishRoll {
    self.finalValues = [self randomValuesWithCount:self.diceCount];
    [self stopAnimationTimer];
    if (self.concealsFinalResult) {
        [self renderValues:self.finalValues locked:YES];
        self.cueLabel.text = @"本轮结果已封存";
        self.summaryLabel.text = @"等待其他玩家完成后统一公布";
    } else {
        [self renderValues:self.finalValues locked:NO];
        [self updateVisibleStatistics];
    }
    [self.rollButton setTitle:@"本轮已完成" forState:UIControlStateNormal];
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    [self.delegate diceRollSurface:self didFinishValues:self.finalValues];
}

- (void)updateVisibleStatistics {
    NSInteger sum = 0;
    NSInteger counts[7] = {0};
    for (NSNumber *value in self.finalValues) {
        NSInteger face = value.integerValue;
        sum += face;
        if (face >= 1 && face <= 6) counts[face] += 1;
    }
    self.cueLabel.text = @"本轮点数已固定";
    self.summaryLabel.text = [NSString stringWithFormat:@"%lu 颗 · 总点 %ld\n1:%ld  2:%ld  3:%ld  4:%ld  5:%ld  6:%ld",
                              (unsigned long)self.finalValues.count, (long)sum,
                              (long)counts[1], (long)counts[2], (long)counts[3],
                              (long)counts[4], (long)counts[5], (long)counts[6]];
}

- (void)revealFinalValues {
    if (self.finalValues.count == 0) return;
    [self renderValues:self.finalValues locked:NO];
    [self updateVisibleStatistics];
}

- (void)resetForNextRoll {
    [self stopAnimationTimer];
    self.settleDeadline = 0;
    self.finalValues = @[];
    self.cueLabel.text = @"摇动手机，或按住下方按钮";
    self.summaryLabel.text = [NSString stringWithFormat:@"本轮使用 %ld 颗骰子", (long)self.diceCount];
    [self.rollButton setTitle:@"按住摇骰" forState:UIControlStateNormal];
    [self renderValues:[self randomValuesWithCount:MIN(self.diceCount, 12)] locked:NO];
    self.rollButton.enabled = self.isRollEnabled;
}

@end
