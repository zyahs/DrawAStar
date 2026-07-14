//
//  TruthOrDareViewController.m
//  JiFeng_UpApp
//

#import "TruthOrDareViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"

@interface TruthOrDareViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIView *scrimView;
@property (nonatomic, strong) CAGradientLayer *ambientLayer;
@property (nonatomic, strong) CAEmitterLayer *sparkLayer;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIView *wheelPanel;
@property (nonatomic, strong) UILabel *previousLabel;
@property (nonatomic, strong) UILabel *currentLabel;
@property (nonatomic, strong) UILabel *nextLabel;
@property (nonatomic, strong) UIView *centerLine;

@property (nonatomic, strong) UIView *resultCard;
@property (nonatomic, strong) CAGradientLayer *resultBorderLayer;
@property (nonatomic, strong) UILabel *resultTitleLabel;
@property (nonatomic, strong) UILabel *resultBodyLabel;

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) NSArray<NSString *> *items;
@property (nonatomic, assign) NSInteger selectedRow;
@property (nonatomic, assign) NSInteger spinIndex;
@property (nonatomic, assign) NSInteger remainingSteps;
@property (nonatomic, assign) NSInteger finalIndex;
@property (nonatomic, assign) BOOL rolling;
@property (nonatomic, assign) CFTimeInterval rollStartedAt;
@property (nonatomic, assign) NSTimeInterval rollDuration;
@property (nonatomic, assign) NSInteger rollStepCount;

@end

@implementation TruthOrDareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = self.item.count > 0 ? self.item : @[@"准备好了吗？"];
    self.selectedRow = 0;
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    [self setupBackground];
    [self setupContent];
    [self setupParticles];
    [self updateWheelLabelsAnimated:NO];
    [self animateEntrance];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.ambientLayer.frame = self.view.bounds;
    self.resultBorderLayer.frame = self.resultCard.bounds;
    self.resultBorderLayer.cornerRadius = self.resultCard.layer.cornerRadius;
    self.sparkLayer.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, -12);
    self.sparkLayer.emitterSize = CGSizeMake(self.view.bounds.size.width, 1);
}

- (void)setupBackground {
    self.scrimView = [[UIView alloc] init];
    self.scrimView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.24];
    [self.view addSubview:self.scrimView];

    self.ambientLayer = [CAGradientLayer layer];
    self.ambientLayer.colors = @[
        (__bridge id)[[JFTheme brandPrimary] colorWithAlphaComponent:0.34].CGColor,
        (__bridge id)[[JFTheme backgroundPrimary] colorWithAlphaComponent:0.72].CGColor,
        (__bridge id)[[JFTheme accent] colorWithAlphaComponent:0.22].CGColor,
    ];
    self.ambientLayer.startPoint = CGPointMake(0, 0);
    self.ambientLayer.endPoint = CGPointMake(1, 1);
    [self.view.layer addSublayer:self.ambientLayer];

    CABasicAnimation *flow = [CABasicAnimation animationWithKeyPath:@"colors"];
    flow.toValue = @[
        (__bridge id)[[JFTheme brandSecondary] colorWithAlphaComponent:0.36].CGColor,
        (__bridge id)[[JFTheme backgroundSecondary] colorWithAlphaComponent:0.72].CGColor,
        (__bridge id)[[self accentColor] colorWithAlphaComponent:0.30].CGColor,
    ];
    flow.duration = 5.5;
    flow.autoreverses = YES;
    flow.repeatCount = HUGE_VALF;
    [self.ambientLayer addAnimation:flow forKey:@"ambient.flow"];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrimView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupContent {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = self.displayText ?: @"真心话大冒险";
    self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBlack];
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintLabel.text = @"让命运停在那一格";
    self.hintLabel.font = [JFTheme fontCallout];
    self.hintLabel.textColor = [JFTheme textSecondary];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.hintLabel];

    self.wheelPanel = [[UIView alloc] init];
    self.wheelPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.wheelPanel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.wheelPanel.layer.cornerRadius = 28;
    self.wheelPanel.layer.cornerCurve = kCACornerCurveContinuous;
    self.wheelPanel.layer.borderWidth = 1;
    self.wheelPanel.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16].CGColor;
    self.wheelPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.wheelPanel.layer.shadowOpacity = 0.35;
    self.wheelPanel.layer.shadowRadius = 22;
    self.wheelPanel.layer.shadowOffset = CGSizeMake(0, 12);
    self.wheelPanel.clipsToBounds = YES;
    [self.view addSubview:self.wheelPanel];

    self.previousLabel = [self wheelLabelWithScale:0.72 alpha:0.42];
    self.currentLabel = [self wheelLabelWithScale:1.0 alpha:1.0];
    self.nextLabel = [self wheelLabelWithScale:0.72 alpha:0.42];
    [self.wheelPanel addSubview:self.previousLabel];
    [self.wheelPanel addSubview:self.currentLabel];
    [self.wheelPanel addSubview:self.nextLabel];

    self.centerLine = [[UIView alloc] init];
    self.centerLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.centerLine.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.28];
    self.centerLine.layer.cornerRadius = 24;
    self.centerLine.layer.cornerCurve = kCACornerCurveContinuous;
    [self.wheelPanel insertSubview:self.centerLine atIndex:0];

    self.resultCard = [[UIView alloc] init];
    self.resultCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultCard.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.70];
    self.resultCard.layer.cornerRadius = 26;
    self.resultCard.layer.cornerCurve = kCACornerCurveContinuous;
    self.resultCard.layer.shadowColor = [self accentColor].CGColor;
    self.resultCard.layer.shadowOpacity = 0.0;
    self.resultCard.layer.shadowRadius = 30;
    self.resultCard.layer.shadowOffset = CGSizeZero;
    self.resultCard.alpha = 0.78;
    [self.view addSubview:self.resultCard];

    self.resultBorderLayer = [CAGradientLayer layer];
    self.resultBorderLayer.colors = @[
        (__bridge id)[[self accentColor] colorWithAlphaComponent:0.90].CGColor,
        (__bridge id)[[self secondaryColor] colorWithAlphaComponent:0.62].CGColor,
        (__bridge id)[UIColor colorWithWhite:1 alpha:0.20].CGColor,
    ];
    self.resultBorderLayer.startPoint = CGPointMake(0, 0);
    self.resultBorderLayer.endPoint = CGPointMake(1, 1);
    [self.resultCard.layer insertSublayer:self.resultBorderLayer atIndex:0];

    UIView *inner = [[UIView alloc] init];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.82];
    inner.layer.cornerRadius = 24;
    inner.layer.cornerCurve = kCACornerCurveContinuous;
    [self.resultCard addSubview:inner];

    self.resultTitleLabel = [[UILabel alloc] init];
    self.resultTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultTitleLabel.text = @"待抽取";
    self.resultTitleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.resultTitleLabel.textColor = [self accentColor];
    [inner addSubview:self.resultTitleLabel];

    self.resultBodyLabel = [[UILabel alloc] init];
    self.resultBodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultBodyLabel.text = @"点击开始，让滚轮替你决定。";
    self.resultBodyLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.resultBodyLabel.textColor = [JFTheme textPrimary];
    self.resultBodyLabel.numberOfLines = 0;
    [inner addSubview:self.resultBodyLabel];

    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.startButton.tintColor = [JFTheme textOnAccent];
    self.startButton.backgroundColor = [self accentColor];
    self.startButton.layer.cornerRadius = 24;
    self.startButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [self.startButton setTitle:@"开始抽取" forState:UIControlStateNormal];
    [self.startButton setImage:[UIImage systemImageNamed:@"sparkles"] forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startRolling) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:64],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing24],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing24],

        [self.hintLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing8],
        [self.hintLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.hintLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.wheelPanel.topAnchor constraintEqualToAnchor:self.hintLabel.bottomAnchor constant:JFSpacing24],
        [self.wheelPanel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.wheelPanel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.wheelPanel.heightAnchor constraintEqualToConstant:184],

        [self.centerLine.leadingAnchor constraintEqualToAnchor:self.wheelPanel.leadingAnchor constant:JFSpacing12],
        [self.centerLine.trailingAnchor constraintEqualToAnchor:self.wheelPanel.trailingAnchor constant:-JFSpacing12],
        [self.centerLine.centerYAnchor constraintEqualToAnchor:self.wheelPanel.centerYAnchor],
        [self.centerLine.heightAnchor constraintEqualToConstant:64],

        [self.previousLabel.leadingAnchor constraintEqualToAnchor:self.wheelPanel.leadingAnchor constant:JFSpacing20],
        [self.previousLabel.trailingAnchor constraintEqualToAnchor:self.wheelPanel.trailingAnchor constant:-JFSpacing20],
        [self.previousLabel.centerYAnchor constraintEqualToAnchor:self.wheelPanel.centerYAnchor constant:-58],

        [self.currentLabel.leadingAnchor constraintEqualToAnchor:self.previousLabel.leadingAnchor],
        [self.currentLabel.trailingAnchor constraintEqualToAnchor:self.previousLabel.trailingAnchor],
        [self.currentLabel.centerYAnchor constraintEqualToAnchor:self.wheelPanel.centerYAnchor],

        [self.nextLabel.leadingAnchor constraintEqualToAnchor:self.previousLabel.leadingAnchor],
        [self.nextLabel.trailingAnchor constraintEqualToAnchor:self.previousLabel.trailingAnchor],
        [self.nextLabel.centerYAnchor constraintEqualToAnchor:self.wheelPanel.centerYAnchor constant:58],

        [self.resultCard.topAnchor constraintEqualToAnchor:self.wheelPanel.bottomAnchor constant:JFSpacing24],
        [self.resultCard.leadingAnchor constraintEqualToAnchor:self.wheelPanel.leadingAnchor],
        [self.resultCard.trailingAnchor constraintEqualToAnchor:self.wheelPanel.trailingAnchor],
        [self.resultCard.heightAnchor constraintGreaterThanOrEqualToConstant:164],

        [inner.topAnchor constraintEqualToAnchor:self.resultCard.topAnchor constant:2],
        [inner.leadingAnchor constraintEqualToAnchor:self.resultCard.leadingAnchor constant:2],
        [inner.trailingAnchor constraintEqualToAnchor:self.resultCard.trailingAnchor constant:-2],
        [inner.bottomAnchor constraintEqualToAnchor:self.resultCard.bottomAnchor constant:-2],

        [self.resultTitleLabel.topAnchor constraintEqualToAnchor:inner.topAnchor constant:JFSpacing20],
        [self.resultTitleLabel.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:JFSpacing20],
        [self.resultTitleLabel.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-JFSpacing20],

        [self.resultBodyLabel.topAnchor constraintEqualToAnchor:self.resultTitleLabel.bottomAnchor constant:JFSpacing12],
        [self.resultBodyLabel.leadingAnchor constraintEqualToAnchor:self.resultTitleLabel.leadingAnchor],
        [self.resultBodyLabel.trailingAnchor constraintEqualToAnchor:self.resultTitleLabel.trailingAnchor],
        [self.resultBodyLabel.bottomAnchor constraintLessThanOrEqualToAnchor:inner.bottomAnchor constant:-JFSpacing20],

        [self.startButton.topAnchor constraintGreaterThanOrEqualToAnchor:self.resultCard.bottomAnchor constant:JFSpacing24],
        [self.startButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing32],
        [self.startButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing32],
        [self.startButton.heightAnchor constraintEqualToConstant:54],
        [self.startButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing24],
    ]];
}

- (UILabel *)wheelLabelWithScale:(CGFloat)scale alpha:(CGFloat)alpha {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [JFTheme textPrimary];
    label.font = [UIFont systemFontOfSize:scale > 0.9 ? 24 : 18 weight:scale > 0.9 ? UIFontWeightBlack : UIFontWeightSemibold];
    label.numberOfLines = 2;
    label.alpha = alpha;
    label.transform = CGAffineTransformMakeScale(scale, scale);
    return label;
}

- (void)setupParticles {
    self.sparkLayer = [CAEmitterLayer layer];
    self.sparkLayer.emitterShape = kCAEmitterLayerLine;
    self.sparkLayer.renderMode = kCAEmitterLayerAdditive;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (__bridge id)[[UIImage imageNamed:@"spark"] CGImage];
    cell.birthRate = 5;
    cell.lifetime = 4.0;
    cell.velocity = 34;
    cell.velocityRange = 24;
    cell.yAcceleration = 16;
    cell.scale = 0.035;
    cell.scaleRange = 0.025;
    cell.alphaSpeed = -0.20;
    cell.emissionRange = M_PI;
    cell.spin = 1.4;
    self.sparkLayer.emitterCells = @[cell];
    [self.view.layer addSublayer:self.sparkLayer];
}

- (void)animateEntrance {
    NSArray<UIView *> *views = @[self.titleLabel, self.hintLabel, self.wheelPanel, self.resultCard, self.startButton];
    for (NSInteger i = 0; i < views.count; i++) {
        UIView *view = views[i];
        view.alpha = 0;
        view.transform = CGAffineTransformMakeTranslation(0, 18);
        [UIView animateWithDuration:0.55 delay:0.08 * i usingSpringWithDamping:0.86 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.alpha = 1;
            view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

#pragma mark - Rolling

- (void)startRolling {
    if (self.rolling || self.items.count == 0) return;
    self.rolling = YES;
    self.startButton.enabled = NO;
    self.startButton.alpha = 0.72;
    [JFTheme hapticImpactMedium];

    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindTruthOrDare score:10 win:YES];
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindTruthOrDare difficulty:0 score:10 win:YES];

    NSInteger randomIndex = arc4random_uniform((uint32_t)self.items.count);
    self.finalIndex = randomIndex;
    self.rollDuration = 3.0;
    self.rollStartedAt = CACurrentMediaTime();
    self.rollStepCount = 0;
    self.remainingSteps = NSIntegerMax;
    self.spinIndex = self.selectedRow;
    self.resultTitleLabel.text = @"抽取中";
    self.resultBodyLabel.text = @"屏住呼吸...";
    [self animateNextStep];
}

- (void)animateNextStep {
    CFTimeInterval elapsed = CACurrentMediaTime() - self.rollStartedAt;
    if (elapsed >= self.rollDuration && self.rollStepCount >= 10) {
        self.selectedRow = self.finalIndex;
        [self updateWheelLabelsAnimated:YES];
        [self revealResult:self.items[self.selectedRow]];
        return;
    }

    self.spinIndex = (self.spinIndex + 1) % self.items.count;
    self.selectedRow = self.spinIndex;
    self.remainingSteps -= 1;
    self.rollStepCount += 1;

    NSTimeInterval progress = MIN(1.0, MAX(0.0, elapsed / MAX(0.01, self.rollDuration)));
    NSTimeInterval duration = 0.045 + progress * progress * 0.17;

    [UIView animateWithDuration:duration * 0.48 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.wheelPanel.transform = CGAffineTransformMakeTranslation(0, -14);
        self.currentLabel.alpha = 0.42;
    } completion:^(__unused BOOL finished) {
        [self updateWheelLabelsAnimated:NO];
        self.wheelPanel.transform = CGAffineTransformMakeTranslation(0, 18);
        [UIView animateWithDuration:duration * 0.52 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.wheelPanel.transform = CGAffineTransformIdentity;
            self.currentLabel.alpha = 1.0;
        } completion:^(__unused BOOL done) {
            [self animateNextStep];
        }];
    }];
}

- (void)updateWheelLabelsAnimated:(BOOL)animated {
    NSInteger count = self.items.count;
    if (count == 0) return;
    NSInteger prev = (self.selectedRow - 1 + count) % count;
    NSInteger next = (self.selectedRow + 1) % count;
    void (^changes)(void) = ^{
        self.previousLabel.text = self.items[prev];
        self.currentLabel.text = self.items[self.selectedRow];
        self.nextLabel.text = self.items[next];
    };
    if (animated) {
        [UIView transitionWithView:self.wheelPanel duration:0.22 options:UIViewAnimationOptionTransitionCrossDissolve animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)revealResult:(NSString *)text {
    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    self.rolling = NO;
    self.startButton.enabled = YES;
    self.startButton.alpha = 1;

    self.resultTitleLabel.text = @"抽取结果";
    self.resultBodyLabel.text = text;
    self.resultCard.alpha = 0;
    self.resultCard.transform = CGAffineTransformMakeScale(0.92, 0.92);
    self.resultCard.layer.shadowOpacity = 0.0;

    CABasicAnimation *border = [CABasicAnimation animationWithKeyPath:@"locations"];
    border.fromValue = @[@0.0, @0.15, @0.36];
    border.toValue = @[@0.62, @0.86, @1.0];
    border.duration = 1.05;
    border.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.resultBorderLayer addAnimation:border forKey:@"border.sweep"];

    [UIView animateWithDuration:0.62 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.resultCard.alpha = 1;
        self.resultCard.transform = CGAffineTransformIdentity;
        self.resultCard.layer.shadowOpacity = 0.36;
    } completion:nil];
}

#pragma mark - Colors

- (UIColor *)accentColor {
    if ([self.displayText containsString:@"冒险"]) {
        return [UIColor colorWithRed:0.24 green:0.68 blue:1.0 alpha:1.0];
    }
    return [UIColor colorWithRed:1.0 green:0.36 blue:0.66 alpha:1.0];
}

- (UIColor *)secondaryColor {
    if ([self.displayText containsString:@"冒险"]) {
        return [UIColor colorWithRed:0.56 green:0.96 blue:1.0 alpha:1.0];
    }
    return [UIColor colorWithRed:1.0 green:0.72 blue:0.34 alpha:1.0];
}

@end
