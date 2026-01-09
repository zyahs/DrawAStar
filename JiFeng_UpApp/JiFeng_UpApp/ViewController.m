//
//  ViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/5.
//

#import "ViewController.h"
#import "TruthOrDareViewController.h"
#import <objc/runtime.h>
#import "FiveQiVc.h"
#import "StarDrawingView.h"
#import "StarDrawingViewController.h"
#import "CubeViewController.h"
#import "TDSwitchViewController.h"
#import "UndercoverViewController.h"
#import "KingGameViewController.h"
#import "EntangleMergeViewController.h"
#import "JGMenuTileView.h"
#import "CardsGameViewController.h"
#import "GestureBombViewController.h"
@interface ViewController ()
@property (nonatomic, strong) StarDrawingView *drawingView;


@property (nonatomic, strong) UIView *centerCircle;
@property (nonatomic, strong) UIView *topCircle;
@property (nonatomic, strong) UIView *bottomCircle;

@property (nonatomic, strong) NSMutableArray<UIButton *> *menuBalls;
@property (nonatomic, strong) NSMutableArray<NSValue *> *menuVelocities; // NSValue(CGPoint)
@property (nonatomic, strong) CADisplayLink *menuDisplayLink;
@property (nonatomic, assign) CGFloat menuBallDiameter;
@property (nonatomic, assign) UIEdgeInsets playSafeInsets;
@property (nonatomic, strong) UIImageView *bgImageView;      // 背景（你的 333.png）
@property (nonatomic, strong) UIView *portalInView;           // 左上吸入传送门的高光圈
@property (nonatomic, strong) UIView *portalOutView;          // 左下弹出传送门的高光圈
@property (nonatomic, strong) NSTimer *teleportTimer;         // 定时传送
@property (nonatomic, strong) NSMapTable<UIButton*, NSValue*> *originalActions; // 按钮 -> 原方法
@property (nonatomic, strong) NSTimer *shuffleTimer;
@end


@implementation ViewController

#pragma mark - Properties

// 圆形菜单按钮
- (NSMutableArray<UIButton *> *)menuBalls {
    if (!_menuBalls) {
        _menuBalls = [NSMutableArray array];
    }
    return _menuBalls;
}

// 原 action 映射表（用于点击时先做特效再调用原方法）
- (NSMapTable<UIButton *, NSValue *> *)originalActions {
    if (!_originalActions) {
        _originalActions = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _originalActions;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.menuBallDiameter = 86.0;
    self.playSafeInsets = UIEdgeInsetsZero;
    
    // 背景图
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"3333"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];
    
    // 背景波纹（轻量）
    [self addBackgroundRippleEffect];
    
    // 设置菜单按钮（固定 2 行 4 列）
    [self setupMenuButtons];
    
    // 启动每 5 秒一次的“随机散开”动画
    [self startShuffleTimer];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (@available(iOS 11.0, *)) {
        self.playSafeInsets = self.view.safeAreaInsets;
    } else {
        self.playSafeInsets = UIEdgeInsetsZero;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 回到首页时，确保打乱计时器还在跑
    [self startShuffleTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 离开首页时停止定时器，防止不必要的开销
    [self.shuffleTimer invalidate];
    self.shuffleTimer = nil;
}

- (void)dealloc {
    [self.shuffleTimer invalidate];
    self.shuffleTimer = nil;
}

#pragma mark - 背景波纹

- (void)addBackgroundRippleEffect {
    CAShapeLayer *ripple = [CAShapeLayer layer];
    CGFloat size = 220;
    ripple.frame = CGRectMake(self.view.center.x - size/2.0,
                              self.view.center.y - size/2.0,
                              size,
                              size);
    ripple.cornerRadius = size / 2.0;
    ripple.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    ripple.opacity = 0.0;
    
    [self.bgImageView.layer addSublayer:ripple];
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.6;
    scale.toValue   = @2.4;
    
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @0.45;
    fade.toValue   = @0.0;
    
    CAAnimationGroup *grp = [CAAnimationGroup animation];
    grp.animations = @[scale, fade];
    grp.duration = 4.5;
    grp.repeatCount = HUGE_VALF;
    grp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [ripple addAnimation:grp forKey:@"rippleWave"];
}

#pragma mark - 菜单按钮初始化

- (void)setupMenuButtons {
    // 先清一下旧的（防止重复添加）
    for (UIButton *btn in self.menuBalls) {
        [btn removeFromSuperview];
    }
    [self.menuBalls removeAllObjects];
    
    NSArray *titles  = @[
        @"画板",
        @"真心话\n大冒险",
        @"骰子游戏",
        @"五子棋",
        @"谁是卧底",
        @"国王游戏",
        @"小姐牌",
        @"手势游戏"
    ];
    
    NSArray *actions = @[
        NSStringFromSelector(@selector(showTruth)),
        NSStringFromSelector(@selector(showDare)),
        NSStringFromSelector(@selector(showDareNoaml)),
        NSStringFromSelector(@selector(jumpFive)),
        NSStringFromSelector(@selector(jumpUnder)),
        NSStringFromSelector(@selector(jumpKing)),
        NSStringFromSelector(@selector(jumpcard)),
        NSStringFromSelector(@selector(jumpGest))
    ];
    
    NSArray *images = @[
        [UIImage imageNamed:@"x1"],
        [UIImage imageNamed:@"x2"],
        [UIImage imageNamed:@"x3"],
        [UIImage imageNamed:@"x4"],
        [UIImage imageNamed:@"x5"],
        [UIImage imageNamed:@"x6"],
        [UIImage imageNamed:@"x7"],
        [UIImage imageNamed:@"x7"]
    ];
    
    CGFloat diameter = self.menuBallDiameter;
    CGFloat spacing  = 22.0;
    
    // 两行四列固定布局
    CGFloat totalWidth = 4 * diameter + 3 * spacing;
    CGFloat startX = (self.view.bounds.size.width - totalWidth) / 2.0;
    CGFloat rowY1  = self.view.bounds.size.height * 0.42;
    CGFloat rowY2  = rowY1 + diameter + 30.0;
    
    for (NSInteger i = 0; i < titles.count; i++) {
        NSString *title  = titles[i];
        SEL sel          = NSSelectorFromString(actions[i]);
        UIImage *img     = images[i];
        
        UIButton *ball = [self createPlanetButtonWithTitle:title image:img];
        [self registerMenuButton:ball action:sel];
        
        NSInteger row = i / 4;
        NSInteger col = i % 4;
        CGFloat x = startX + col * (diameter + spacing);
        CGFloat y = (row == 0) ? rowY1 : rowY2;
        
        ball.frame = CGRectMake(x, y, diameter, diameter);
        [self.view addSubview:ball];
        [self.menuBalls addObject:ball];
    }
}

#pragma mark - 创建圆形按钮（彩色晕圈 + 呼吸光 + 微漂浮）

- (UIButton *)createPlanetButtonWithTitle:(NSString *)title image:(UIImage *)fillImage {
    CGFloat diameter = self.menuBallDiameter;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, diameter, diameter);
    btn.layer.cornerRadius = diameter / 2.0;
    btn.clipsToBounds = YES;
    btn.adjustsImageWhenHighlighted = NO;
    
    if (fillImage) {
        [btn setBackgroundImage:fillImage forState:UIControlStateNormal];
        btn.imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        // 万一某个没图，给个渐变底
        CAGradientLayer *grad = [CAGradientLayer layer];
        grad.frame = btn.bounds;
        grad.colors = @[
            (__bridge id)[UIColor colorWithRed:1 green:0.65 blue:0.95 alpha:1].CGColor,
            (__bridge id)[UIColor colorWithRed:0.45 green:0.80 blue:1 alpha:1].CGColor,
            (__bridge id)[UIColor colorWithRed:0.55 green:1 blue:0.75 alpha:1].CGColor
        ];
        grad.startPoint = CGPointMake(0, 0);
        grad.endPoint   = CGPointMake(1, 1);
        grad.cornerRadius = btn.layer.cornerRadius;
        [btn.layer insertSublayer:grad atIndex:0];
    }
    
    // 外发光
    btn.layer.shadowColor   = [UIColor colorWithRed:0.6 green:0.9 blue:1 alpha:1].CGColor;
    btn.layer.shadowOpacity = 0.9;
    btn.layer.shadowRadius  = 18;
    btn.layer.shadowOffset  = CGSizeZero;
    
    // 标题
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.numberOfLines = 2;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    
    // 彩色光晕层（在按钮外面一圈）
    CAGradientLayer *halo = [CAGradientLayer layer];
    halo.frame = CGRectInset(btn.bounds, -12, -12);
    halo.cornerRadius = halo.frame.size.width / 2.0;
    halo.colors = @[
        (__bridge id)[UIColor colorWithRed:1   green:0.5  blue:0.8  alpha:0.7].CGColor,
        (__bridge id)[UIColor colorWithRed:0.4 green:0.8  blue:1    alpha:0.7].CGColor,
        (__bridge id)[UIColor colorWithRed:0.6 green:1    blue:0.6  alpha:0.7].CGColor
    ];
    halo.startPoint = CGPointMake(0, 0);
    halo.endPoint   = CGPointMake(1, 1);
    [btn.layer insertSublayer:halo atIndex:0];
    
    // 光晕旋转
    CABasicAnimation *haloSpin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    haloSpin.fromValue    = @(0);
    haloSpin.toValue      = @(M_PI * 2);
    haloSpin.duration     = 10.0;
    haloSpin.repeatCount  = HUGE_VALF;
    [halo addAnimation:haloSpin forKey:@"spinHalo"];
    
    // 呼吸光（透明度轻微变化）
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue     = @0.55;
    pulse.toValue       = @1.0;
    pulse.duration      = 2.4;
    pulse.autoreverses  = YES;
    pulse.repeatCount   = HUGE_VALF;
    [halo addAnimation:pulse forKey:@"haloPulse"];
    
    // 按钮轻微漂浮（additive = YES，不改真实 frame）
    CAKeyframeAnimation *floatAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    floatAnim.duration      = 5.0;
    floatAnim.repeatCount   = HUGE_VALF;
    floatAnim.additive      = YES;
    floatAnim.values = @[
        [NSValue valueWithCGPoint:CGPointMake(0, -3)],
        [NSValue valueWithCGPoint:CGPointMake(2,  2)],
        [NSValue valueWithCGPoint:CGPointMake(-2, 1)],
        [NSValue valueWithCGPoint:CGPointZero]
    ];
    [btn.layer addAnimation:floatAnim forKey:@"floatAnim"];
    
    return btn;
}

#pragma mark - 注册按钮 & 点击处理（特效 + 原逻辑）

- (void)registerMenuButton:(UIButton *)btn action:(SEL)sel {
    if (sel) {
        [self.originalActions setObject:[NSValue valueWithPointer:sel] forKey:btn];
    }
    [btn addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)menuButtonTapped:(UIButton *)sender {
    // 轻触觉反馈
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [gen impactOccurred];
    
    // 轻微按压缩放
    [UIView animateWithDuration:0.08 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 粒子爆炸（轻量）
    [self playParticleExplosionAt:sender];
    
    // 调用原来的点击方法（略微延迟以配合动画）
    SEL sel = [[self.originalActions objectForKey:sender] pointerValue];
    if (sel) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:sel withObject:nil];
#pragma clang diagnostic pop
        });
    }
}

#pragma mark - 粒子爆炸（轻量版）

- (void)playParticleExplosionAt:(UIView *)target {
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = target.center;
    emitter.emitterShape    = kCAEmitterLayerCircle;
    emitter.emitterSize     = CGSizeMake(20, 20);
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents      = (id)[[UIImage imageNamed:@"spark_blue"] CGImage];
    cell.birthRate     = 80;
    cell.lifetime      = 0.5;
    cell.velocity      = 160;
    cell.velocityRange = 60;
    cell.scale         = 0.06;
    cell.scaleRange    = 0.03;
    cell.alphaSpeed    = -1.5;
    
    emitter.emitterCells = @[cell];
    [self.view.layer addSublayer:emitter];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [emitter removeFromSuperlayer];
    });
}

#pragma mark - 随机打乱（每 5 秒一次，按钮不重叠）

- (void)startShuffleTimer {
    [self.shuffleTimer invalidate];
    self.shuffleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                         target:self
                                                       selector:@selector(shuffleAllMenuBalls)
                                                       userInfo:nil
                                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.shuffleTimer forMode:NSRunLoopCommonModes];
}

// 生成一个不与已有 center 重叠的新点
- (CGPoint)randomNonOverlappingPositionAvoiding:(NSArray<NSValue *> *)usedCenters {
    CGRect bounds = self.view.bounds;
    CGFloat r = self.menuBallDiameter * 0.5;
    
    CGFloat minX = bounds.origin.x + self.playSafeInsets.left  + r;
    CGFloat maxX = CGRectGetMaxX(bounds) - self.playSafeInsets.right - r;
    CGFloat minY = bounds.origin.y + self.playSafeInsets.top   + r;
    CGFloat maxY = CGRectGetMaxY(bounds) - self.playSafeInsets.bottom - r;
    
    NSInteger tries = 0;
    while (tries < 200) {
        tries++;
        CGFloat x = ((CGFloat)arc4random() / UINT32_MAX) * (maxX - minX) + minX;
        CGFloat y = ((CGFloat)arc4random() / UINT32_MAX) * (maxY - minY) + minY;
        CGPoint p = CGPointMake(x, y);
        
        BOOL overlap = NO;
        for (NSValue *val in usedCenters) {
            CGPoint c = [val CGPointValue];
            CGFloat dx = p.x - c.x;
            CGFloat dy = p.y - c.y;
            CGFloat dist = sqrt(dx*dx + dy*dy);
            if (dist < self.menuBallDiameter + 4.0) { // 留一点空隙
                overlap = YES;
                break;
            }
        }
        if (!overlap) {
            return p;
        }
    }
    // 兜底：回中心
    return CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

- (void)shuffleAllMenuBalls {
    if (self.menuBalls.count == 0) return;
    
    NSMutableArray<NSValue *> *usedCenters = [NSMutableArray array];
    
    [UIView animateWithDuration:0.45
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        for (UIButton *btn in self.menuBalls) {
            CGPoint target = [self randomNonOverlappingPositionAvoiding:usedCenters];
            [usedCenters addObject:[NSValue valueWithCGPoint:target]];
            btn.center = target;
        }
    } completion:nil];
}

#pragma mark - 入口按钮对应跳转

- (void)showTruth {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    StarDrawingViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"778"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showDare {
    EntangleMergeViewController *vc = [[EntangleMergeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showDareNoaml {
    CubeViewController *vc = [[CubeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpFive {
    FiveQiVc *vc = [[FiveQiVc alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpUnder {
    UndercoverViewController *vc = [[UndercoverViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpKing {
    KingGameViewController *vc = [[KingGameViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpcard {
    CardsGameViewController *vc = [[CardsGameViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpGest {
    GestureBombViewController *vc = [[GestureBombViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
