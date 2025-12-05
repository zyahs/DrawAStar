//
//  GestureBombViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/10/9.
//


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, JFGestureBombState) {
    JFGestureBombStateIdle,
    JFGestureBombStateCountingDown,
    JFGestureBombStateRunning,
};

@interface GestureBombViewController : UIViewController
@end

#pragma mark - Implementation

@interface GestureBombViewController ()
@property (nonatomic, strong) CAGradientLayer *bgGradient;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UILabel *targetLabel;     // 中央大图标（显示最终炸弹手势）
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) UIStackView *grid;        // 3x4 手势网格
@property (nonatomic, strong) NSArray<UIButton *> *gestureButtons;

@property (nonatomic, strong) NSTimer *roundTimer;      // 一局结束的计时（本版仅用于节奏控制）
@property (nonatomic, assign) JFGestureBombState state;

@property (nonatomic, copy) NSArray<NSString *> *gestures; // 12个手势
@property (nonatomic, copy) NSString *currentTarget;       // 当前炸弹手势

// 高亮光环（倒计时期间随机跳）
@property (nonatomic, strong) UIView   *glowView;
@property (nonatomic, strong) NSTimer  *glowTimer;
@property (nonatomic, assign) NSInteger glowIndex;
@property (nonatomic, assign) BOOL      isSpinning;
@property (nonatomic, strong) UILabel *tipLabel; // 常驻提示
@end

@implementation GestureBombViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.navigationItem.title = @"手势炸弹";

    // 12 个手势
    self.gestures = @[ @"✌️", @"🤟", @"🖖", @"✋",
                       @"🤞", @"👍",  @"👎",  @"👊",
                       @"☝️", @"🤘",  @"🤙",  @"👌" ];
    self.state = JFGestureBombStateIdle;

    [self setupGradientBackground];
    [self setupUI];
    [self animateGradientInfinitely];
    
   
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopRoundTimer];
    [self stopGlowShuffle];
}

#pragma mark - UI

- (void)setupGradientBackground {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = self.view.bounds;
    g.colors = @[
        (__bridge id)[UIColor colorWithRed:0.12 green:0.10 blue:0.25 alpha:1].CGColor, // 深蓝紫
        (__bridge id)[UIColor colorWithRed:0.24 green:0.08 blue:0.34 alpha:1].CGColor, // 葡萄紫
        (__bridge id)[UIColor colorWithRed:0.07 green:0.24 blue:0.33 alpha:1].CGColor, // 深青
        (__bridge id)[UIColor colorWithRed:0.15 green:0.14 blue:0.28 alpha:1].CGColor  // 靛紫
    ];
    g.startPoint = CGPointMake(0, 0);
    g.endPoint   = CGPointMake(1, 1);
    g.type       = kCAGradientLayerAxial;
    [self.view.layer insertSublayer:g atIndex:0];
    self.bgGradient = g;
}

- (void)animateGradientInfinitely {
    // 颜色缓慢流动
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"colors"];
    anim.duration = 6.0;
    anim.repeatCount = HUGE_VALF;
    anim.autoreverses = YES;
    anim.toValue = @[
        (__bridge id)[UIColor colorWithRed:0.20 green:0.08 blue:0.35 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.08 green:0.22 blue:0.36 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.18 green:0.10 blue:0.32 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:0.10 green:0.18 blue:0.32 alpha:1].CGColor
    ];
    [self.bgGradient addAnimation:anim forKey:@"bgFlow"];
}

- (UILabel *)makeNeonLabel:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *l = [[UILabel alloc] init];
    l.textColor = UIColor.whiteColor;
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont systemFontOfSize:size weight:weight];
    l.layer.shadowColor   = [UIColor colorWithRed:0.6 green:0.9 blue:1 alpha:1].CGColor;
    l.layer.shadowOpacity = 0.8;
    l.layer.shadowRadius  = 10;
    l.layer.shadowOffset  = CGSizeZero;
    return l;
}

- (UIButton *)makeNeonButtonWithTitle:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    b.layer.cornerRadius = 14;
    b.layer.borderWidth  = 1.0 / UIScreen.mainScreen.scale;
    b.layer.borderColor  = [UIColor colorWithRed:0.7 green:0.9 blue:1 alpha:0.6].CGColor;
    b.layer.shadowColor  = [UIColor colorWithRed:0.5 green:0.9 blue:1 alpha:1].CGColor;
    b.layer.shadowOpacity = 0.9;
    b.layer.shadowRadius  = 12;
    b.layer.shadowOffset  = CGSizeZero;
    return b;
}

- (UIButton *)makeGestureButton:(NSString *)emoji {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:emoji forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:38 weight:UIFontWeightBlack];
    b.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    b.layer.cornerRadius = 14;
    b.layer.borderWidth  = 1.0 / UIScreen.mainScreen.scale;
    b.layer.borderColor  = [UIColor colorWithRed:0.9 green:0.9 blue:1 alpha:0.5].CGColor;
    b.layer.shadowColor  = [UIColor colorWithRed:0.6 green:0.9 blue:1 alpha:1].CGColor;
    b.layer.shadowOpacity = 0.7;
    b.layer.shadowRadius  = 10;
    b.layer.shadowOffset  = CGSizeZero;
    [b addTarget:self action:@selector(onGestureTap:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

-(void)setupUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // 标题
    UILabel *title = [UILabel new];
    // 上面的写法是笔误，这里正确赋值：
    title = [self makeNeonLabel:22 weight:UIFontWeightBold];
    title.text = @"手势炸弹";
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:title];
    self.titleLabel = title;

    // 自定义返回按钮（左上角）
    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    back.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *backImg = [UIImage imageNamed:@"back"];
    if (backImg) {
        [back setImage:[backImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [back setTitle:@"返回" forState:UIControlStateNormal];
        [back setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        back.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    }
    back.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6); // 提升点击热区
    back.accessibilityLabel = @"返回";
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    self.backButton = back;

    // 中央目标（显示最后抽中的炸弹手势）
    UILabel *target = [self makeNeonLabel:96 weight:UIFontWeightBlack];
    target.text = @"🚀";
    target.alpha = 0.0;
    target.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:target];
    self.targetLabel = target;

    // 321 倒计时
    UILabel *countdown = [self makeNeonLabel:90 weight:UIFontWeightBlack];
    countdown.text = @"";
    countdown.alpha = 0.0;
    countdown.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:countdown];
    self.countdownLabel = countdown;

    // 12 个按钮
    NSMutableArray *btns = [NSMutableArray arrayWithCapacity:12];
    for (NSString *g in self.gestures) {
        [btns addObject:[self makeGestureButton:g]];
    }
    self.gestureButtons = btns;
    for (UIButton *b in self.gestureButtons) {
        b.translatesAutoresizingMaskIntoConstraints = NO;
        [[b.heightAnchor constraintEqualToAnchor:b.widthAnchor] setActive:YES];
    }

    // 3 行 × 4 列
    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[btns[0],btns[1],btns[2],btns[3]]];
    UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[btns[4],btns[5],btns[6],btns[7]]];
    UIStackView *row3 = [[UIStackView alloc] initWithArrangedSubviews:@[btns[8],btns[9],btns[10],btns[11]]];
    for (UIStackView *r in @[row1,row2,row3]) {
        r.axis = UILayoutConstraintAxisHorizontal;
        r.spacing = 12;
        r.distribution = UIStackViewDistributionFillEqually;
    }
    UIStackView *grid = [[UIStackView alloc] initWithArrangedSubviews:@[row1,row2,row3]];
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = 12;
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:grid];
    self.grid = grid;
    self.grid.distribution = UIStackViewDistributionFillEqually;

    // 高亮光环（发光描边）
    self.glowView = [[UIView alloc] initWithFrame:CGRectZero];
    self.glowView.userInteractionEnabled = NO;
    self.glowView.layer.cornerRadius = 12;
    self.glowView.layer.borderWidth  = 3.0;
    self.glowView.layer.borderColor  = [UIColor colorWithRed:0.9 green:1 blue:0.6 alpha:0.95].CGColor;
    self.glowView.layer.shadowColor  = [UIColor colorWithRed:1 green:0.95 blue:0.6 alpha:1].CGColor;
    self.glowView.layer.shadowOpacity= 0.9;
    self.glowView.layer.shadowRadius = 14;
    self.glowView.layer.shadowOffset = CGSizeZero;
    self.glowView.alpha = 0.0; // 初始隐藏
    [self.view addSubview:self.glowView];

    // 开始按钮
    UIButton *start = [self makeNeonButtonWithTitle:@"开始"];
    [start addTarget:self action:@selector(onStart) forControlEvents:UIControlEventTouchUpInside];
    start.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:start];
    self.startButton = start;

    // 常驻底部提示
    UILabel *tip = [self makeNeonLabel:16 weight:UIFontWeightSemibold];
    tip.text = @"点“开始”，随机选择炸弹手势。使用它的人喝酒";
    tip.alpha = 1.0;
    tip.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tip];
    self.tipLabel = tip;

    // 约束
    [NSLayoutConstraint activateConstraints:@[
        [back.topAnchor constraintEqualToAnchor:safe.topAnchor constant:6],
        [back.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [back.widthAnchor constraintEqualToConstant:36],
        [back.heightAnchor constraintEqualToConstant:36],

        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [target.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [target.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],

        [grid.topAnchor constraintEqualToAnchor:target.bottomAnchor constant:28],
        [grid.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [grid.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [grid.bottomAnchor constraintEqualToAnchor:tip.topAnchor constant:-16],

        [start.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [start.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-18],
        [start.widthAnchor constraintEqualToConstant:160],
        [start.heightAnchor constraintEqualToConstant:52],

        [tip.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [tip.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:16],
        [tip.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-16],
        [tip.bottomAnchor constraintEqualToAnchor:start.topAnchor constant:-12],

        [countdown.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [countdown.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    // 保证返回按钮在最上层可点
    [self.view bringSubviewToFront:self.backButton];
}

#pragma mark - 返回

- (void)onBack {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Game Flow

- (void)onStart {
    if (self.state == JFGestureBombStateCountingDown) return;

    [self stopRoundTimer];
    self.state = JFGestureBombStateCountingDown;
    self.currentTarget = nil;

    self.startButton.enabled = NO;
    self.tipLabel.text = @"随机中… 3、2、1 后揭晓";

    // 倒计时期间随机高亮跳转
    [self startGlowShuffle];

    [self animateCountdownThenStartRound];
}

- (void)animateCountdownThenStartRound {
    self.countdownLabel.alpha = 1.0;
    [self showCountdown:@"3" completion:^{
        [self showCountdown:@"2" completion:^{
            [self showCountdown:@"1" completion:^{
                [self showCountdown:@"GO!" completion:^{
                    [UIView animateWithDuration:0.15 animations:^{
                        self.countdownLabel.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        [self startRound];
                    }];
                }];
            }];
        }];
    }];
}

- (void)showCountdown:(NSString *)text completion:(void(^)(void))completion {
    self.countdownLabel.text = text;
    self.countdownLabel.transform = CGAffineTransformMakeScale(0.3, 0.3);
    [UIView animateWithDuration:0.22 animations:^{
        self.countdownLabel.alpha = 1.0;
        self.countdownLabel.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            self.countdownLabel.alpha = 0.0;
        } completion:^(BOOL finished2) {
            if (completion) completion();
        }];
    }];
}

- (void)startRound {
    self.state = JFGestureBombStateRunning;

    // 本轮“炸弹手势”从 12 个里随机一个，若正在转动则用高亮索引
    NSInteger chosen = self.isSpinning ? self.glowIndex : arc4random_uniform((uint32_t)self.gestures.count);
    chosen = MAX(0, MIN((NSInteger)self.gestures.count - 1, chosen));
    self.currentTarget = self.gestures[chosen];

    // 停止光环跳转，定位到选中的按钮
    [self stopGlowShuffle];
    UIButton *chosenBtn = self.gestureButtons[chosen];
    [self moveGlowToButton:chosenBtn animated:YES show:YES];

    // 选中按钮放大强调
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        chosenBtn.transform = CGAffineTransformMakeScale(1.20, 1.20);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            chosenBtn.transform = CGAffineTransformIdentity;
        }];
    }];

    // 中央显示结果
    self.targetLabel.text = self.currentTarget;
    self.targetLabel.alpha = 0.0;
    self.targetLabel.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [UIView animateWithDuration:0.18 animations:^{
        self.targetLabel.alpha = 1.0;
        self.targetLabel.transform = CGAffineTransformIdentity;
    }];

    // 提示文案
    self.tipLabel.text = [NSString stringWithFormat:@"本轮炸弹手势：%@  使用它的人喝酒！", self.currentTarget];

    // 本轮结束，允许再次开始
    self.startButton.enabled = YES;
}

- (void)stopRoundTimer {
    [self.roundTimer invalidate];
    self.roundTimer = nil;
}

#pragma mark - Glow Shuffle（随机高亮光环）

- (void)startGlowShuffle {
    if (self.isSpinning) return;
    self.isSpinning = YES;
    self.glowView.alpha = 1.0;

    // 先定位到一个随机按钮
    self.glowIndex = arc4random_uniform((uint32_t)self.gestureButtons.count);
    [self moveGlowToButton:self.gestureButtons[self.glowIndex] animated:NO show:YES];

    __weak typeof(self) weakSelf = self;
    self.glowTimer = [NSTimer scheduledTimerWithTimeInterval:0.20 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSInteger next = self.glowIndex;
        while (next == self.glowIndex) {
            next = arc4random_uniform((uint32_t)self.gestureButtons.count);
        }
        self.glowIndex = next;
        UIButton *btn = self.gestureButtons[self.glowIndex];
        [self moveGlowToButton:btn animated:YES show:YES];
    }];
}

- (void)stopGlowShuffle {
    self.isSpinning = NO;
    [self.glowTimer invalidate];
    self.glowTimer = nil;
}

- (void)moveGlowToButton:(UIButton *)btn animated:(BOOL)animated show:(BOOL)show {
    // 将按钮 frame 转换到控制器根 view 坐标系，再外扩一点当描边
    CGRect frameInView = [btn.superview convertRect:btn.frame toView:self.view];
    CGRect pad = CGRectInset(frameInView, -6, -6);
    self.glowView.layer.cornerRadius = 14 + 6;

    if (animated) {
        [UIView animateWithDuration:0.10 animations:^{
            self.glowView.frame = pad;
            self.glowView.alpha = show ? 1.0 : 0.0;
        }];
    } else {
        self.glowView.frame = pad;
        self.glowView.alpha = show ? 1.0 : 0.0;
    }
}

#pragma mark - Interactions

- (void)onGestureTap:(UIButton *)sender {
    // 点击做一个弹跳反馈；规则是“使用本轮炸弹手势的人喝”，不用在此判输赢
    [self buttonPop:sender];
    if (self.currentTarget.length > 0) {
        self.tipLabel.text = [NSString stringWithFormat:@"本轮炸弹：%@  使用它的人喝酒", self.currentTarget];
    }
}

#pragma mark - FX / Haptics / Toast

- (void)buttonPop:(UIView *)v {
    [UIView animateWithDuration:0.08 animations:^{
        v.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            v.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)showToast:(NSString *)text {
    UILabel *t = [self makeNeonLabel:16 weight:UIFontWeightSemibold];
    t.text = text;
    t.alpha = 0.0;
    t.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
    t.layer.cornerRadius = 10;
    t.layer.masksToBounds = YES;
    t.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:t];

    [NSLayoutConstraint activateConstraints:@[
        [t.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [t.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-90],
        [t.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-60]
    ]];

    [UIView animateWithDuration:0.15 animations:^{
        t.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.18 animations:^{
                t.alpha = 0.0;
            } completion:^(BOOL finished2) {
                [t removeFromSuperview];
            }];
        });
    }];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bgGradient.frame = self.view.bounds;

    // 适配旋转/尺寸变化时，若 glow 可见则跟随当前索引的按钮更新位置
    if (self.glowView.alpha > 0.0 && self.gestureButtons.count == 12) {
        NSInteger idx = MAX(0, MIN(self.glowIndex, (NSInteger)self.gestureButtons.count - 1));
        UIButton *btn = self.gestureButtons[idx];
        [self moveGlowToButton:btn animated:NO show:YES];
    }
}

@end
