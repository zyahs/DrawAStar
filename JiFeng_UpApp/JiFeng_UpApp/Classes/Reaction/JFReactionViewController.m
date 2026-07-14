//
//  JFReactionViewController.m
//
//  反应力测试 30 秒。屏幕随机出现目标圆点,玩家点击得分。
//  分数 = 命中数。50 命中解锁成就。
//

#import "JFReactionViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

static const NSTimeInterval kRoundSeconds = 30.0;
static NSString *const kBestKey = @"jf_reaction_best";

@interface JFReactionViewController ()
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIView   *playArea;
@property (nonatomic, strong) UIView   *target;

@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger best;
@property (nonatomic, assign) NSTimeInterval endTs;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *displayTimer;
@property (nonatomic, assign) BOOL running;
@end

@implementation JFReactionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.best = [[NSUserDefaults standardUserDefaults] integerForKey:kBestKey];

    [self buildBackground];
    [self buildUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopRound];
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
    self.titleLabel.text = @"反应力测试";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.timeLabel  = [self badgeLabel];
    self.timeLabel.text = @"30s";
    self.scoreLabel = [self badgeLabel];
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 0 · 最佳 %ld", (long)self.best];

    UIStackView *bs = [[UIStackView alloc] initWithArrangedSubviews:@[self.timeLabel, self.scoreLabel]];
    bs.translatesAutoresizingMaskIntoConstraints = NO;
    bs.axis = UILayoutConstraintAxisHorizontal;
    bs.spacing = JFSpacing8;
    bs.distribution = UIStackViewDistributionFillEqually;
    [self.view addSubview:bs];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"30 秒内点中尽可能多的圆点";
    self.statusLabel.textColor = [JFTheme textSecondary];
    self.statusLabel.font = [JFTheme fontBody];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    self.playArea = [[UIView alloc] init];
    self.playArea.translatesAutoresizingMaskIntoConstraints = NO;
    self.playArea.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
    self.playArea.layer.cornerRadius = JFRadiusMedium;
    self.playArea.layer.borderWidth = 0.5;
    self.playArea.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.playArea.clipsToBounds = YES;
    [self.view addSubview:self.playArea];

    self.target = [[UIView alloc] init];
    self.target.backgroundColor = [JFTheme accent];
    self.target.layer.cornerRadius = 30;
    self.target.hidden = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTargetTap)];
    [self.target addGestureRecognizer:tap];
    [self.playArea addSubview:self.target];

    self.startButton = [self primaryButtonWithTitle:@"开始" action:@selector(onStart)];
    [self.view addSubview:self.startButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [bs.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing12],
        [bs.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [bs.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [bs.heightAnchor   constraintEqualToConstant:32],

        [self.statusLabel.topAnchor      constraintEqualToAnchor:bs.bottomAnchor constant:JFSpacing8],
        [self.statusLabel.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [self.playArea.topAnchor      constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:JFSpacing12],
        [self.playArea.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [self.playArea.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.startButton.topAnchor      constraintEqualToAnchor:self.playArea.bottomAnchor constant:JFSpacing16],
        [self.startButton.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.startButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.startButton.heightAnchor   constraintEqualToConstant:48],
        [self.startButton.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing16],
    ]];
}

- (UILabel *)badgeLabel {
    UILabel *l = [[UILabel alloc] init];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.textColor = [JFTheme textPrimary];
    l.font = [JFTheme fontHeadline];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    l.layer.cornerRadius = JFRadiusMedium;
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
    [b setTitle:t forState:UIControlStateNormal];
    [b setTitleColor:[JFTheme textOnAccent] forState:UIControlStateNormal];
    b.titleLabel.font = [JFTheme fontHeadline];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Game

- (void)onStart {
    if (self.running) return;
    self.running = YES;
    self.score = 0;
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 0 · 最佳 %ld", (long)self.best];
    self.endTs = [[NSDate date] timeIntervalSince1970] + kRoundSeconds;
    self.statusLabel.text = @"快点!";
    [self.startButton setTitle:@"进行中..." forState:UIControlStateNormal];
    self.startButton.enabled = NO;
    [self spawnTarget];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onTimerTick) userInfo:nil repeats:YES];
}

- (void)onTimerTick {
    NSTimeInterval remain = self.endTs - [[NSDate date] timeIntervalSince1970];
    if (remain <= 0) {
        self.timeLabel.text = @"0s";
        [self stopRound];
        return;
    }
    self.timeLabel.text = [NSString stringWithFormat:@"%.1fs", remain];
}

- (void)spawnTarget {
    if (!self.running) return;
    CGFloat W = self.playArea.bounds.size.width;
    CGFloat H = self.playArea.bounds.size.height;
    CGFloat size = 60;
    if (W < size + 16 || H < size + 16) {
        size = MIN(W, H) - 16;
    }
    CGFloat x = arc4random_uniform((uint32_t)MAX(1, W - size));
    CGFloat y = arc4random_uniform((uint32_t)MAX(1, H - size));
    self.target.frame = CGRectMake(x, y, size, size);
    self.target.layer.cornerRadius = size / 2;
    self.target.hidden = NO;
    self.target.alpha = 1.0;
    [self.target.layer removeAllAnimations];
    self.target.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [UIView animateWithDuration:0.12 animations:^{
        self.target.transform = CGAffineTransformIdentity;
    }];

    // 自动消失:逐渐变难,初期 1.0s,中期 0.7s,后期 0.5s
    NSTimeInterval remain = self.endTs - [[NSDate date] timeIntervalSince1970];
    NSTimeInterval life = 1.0;
    if (remain < kRoundSeconds * 2 / 3) life = 0.7;
    if (remain < kRoundSeconds / 3) life = 0.5;
    [self.displayTimer invalidate];
    self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:life target:self selector:@selector(onTargetMissed) userInfo:nil repeats:NO];
}

- (void)onTargetTap {
    if (!self.running) return;
    self.score += 1;
    [JFTheme hapticImpactLight];
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld · 最佳 %ld", (long)self.score, (long)self.best];
    [self.displayTimer invalidate];
    self.target.hidden = YES;
    [self performSelector:@selector(spawnTarget) withObject:nil afterDelay:0.05 + (CGFloat)arc4random_uniform(150) / 1000.0];
}

- (void)onTargetMissed {
    if (!self.running) return;
    self.target.hidden = YES;
    [self spawnTarget];
}

- (void)stopRound {
    if (!self.running) return;
    self.running = NO;
    [self.timer invalidate];
    self.timer = nil;
    [self.displayTimer invalidate];
    self.displayTimer = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(spawnTarget) object:nil];
    self.target.hidden = YES;
    [self.startButton setTitle:@"再来一次" forState:UIControlStateNormal];
    self.startButton.enabled = YES;

    if (self.score > self.best) {
        self.best = self.score;
        [[NSUserDefaults standardUserDefaults] setInteger:self.best forKey:kBestKey];
        self.statusLabel.text = [NSString stringWithFormat:@"结束 · 新纪录 %ld!", (long)self.best];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"结束 · 得分 %ld", (long)self.score];
    }
    self.scoreLabel.text = [NSString stringWithFormat:@"得分 %ld · 最佳 %ld", (long)self.score, (long)self.best];

    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindReaction score:self.score win:YES];
    r.duration = kRoundSeconds;
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindReaction difficulty:0 score:self.score win:(self.score >= 30)];
}

@end
