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
@end


@implementation ViewController

// MARK: - Menu Animation Helpers

- (void)startMenuAnimation {
    if (!self.menuDisplayLink) {
        self.menuDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(stepBouncingMenu:)];
        [self.menuDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        self.menuDisplayLink.paused = NO;
    }
}

- (void)stopMenuAnimation {
    if (self.menuDisplayLink) {
        self.menuDisplayLink.paused = YES;
    }
}


- (void)playParticleExplosionAt:(UIView *)target {
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = target.center;
    emitter.emitterShape = kCAEmitterLayerCircle;
    emitter.emitterSize = CGSizeMake(20, 20);

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"spark_blue"] CGImage];
    cell.birthRate = 120;
    cell.lifetime = 0.6;
    cell.velocity = 180;
    cell.velocityRange = 80;
    cell.scale = 0.06;
    cell.scaleRange = 0.03;
    cell.alphaSpeed = -1.5;

    emitter.emitterCells = @[cell];
    [self.view.layer addSublayer:emitter];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [emitter removeFromSuperlayer];
    });
}
- (void)setBtn{
    UIStackView *grid = [[UIStackView alloc] init];
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = 14;
    grid.alignment = UIStackViewAlignmentFill;
    grid.distribution = UIStackViewDistributionFillEqually;
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:grid];
    
    // 两行
    UIStackView *row1 = [[UIStackView alloc] init];
    row1.axis = UILayoutConstraintAxisHorizontal;
    row1.spacing = 14;
    row1.alignment = UIStackViewAlignmentFill;
    row1.distribution = UIStackViewDistributionFillEqually;
    
    UIStackView *row2 = [[UIStackView alloc] init];
    row2.axis = UILayoutConstraintAxisHorizontal;
    row2.spacing = 14;
    row2.alignment = UIStackViewAlignmentFill;
    row2.distribution = UIStackViewDistributionFillEqually;
    
    [grid addArrangedSubview:row1];
    [grid addArrangedSubview:row2];
    
    // 约束：底部安全区域上方，左右各 20
    [NSLayoutConstraint activateConstraints:@[
        [grid.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [grid.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [grid.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24],
        [grid.heightAnchor constraintEqualToConstant:220] // 两行卡片总高（可调）
    ]];
    
    // 构建 6 张卡
    JGMenuTileView *tileDraw = [[JGMenuTileView alloc] initWithTitle:@"画板"
                                                                icon:[UIImage imageNamed:@"PS3"]];
    [tileDraw addTarget:self action:@selector(showTruth) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileTD = [[JGMenuTileView alloc] initWithTitle:@"真心话大冒险"
                                                              icon:[UIImage imageNamed:@"snow"]];
    [tileTD addTarget:self action:@selector(showDare) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileDice = [[JGMenuTileView alloc] initWithTitle:@"骰子游戏"
                                                                icon:[UIImage imageNamed:@"ic_dice"]];
    [tileDice addTarget:self action:@selector(showDareNoaml) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileFive = [[JGMenuTileView alloc] initWithTitle:@"五子棋"
                                                                icon:[UIImage imageNamed:@"ic_board"]];
    [tileFive addTarget:self action:@selector(jumpFive) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileUnder = [[JGMenuTileView alloc] initWithTitle:@"谁是卧底"
                                                                 icon:[UIImage imageNamed:@"ic_spy"]];
    [tileUnder addTarget:self action:@selector(jumpUnder) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileKing = [[JGMenuTileView alloc] initWithTitle:@"国王游戏"
                                                                icon:[UIImage imageNamed:@"ic_crown"]];
    [tileKing addTarget:self action:@selector(jumpKing) forControlEvents:UIControlEventTouchUpInside];
    
    JGMenuTileView *tileGest = [[JGMenuTileView alloc] initWithTitle:@"手势游戏"
                                                                icon:[UIImage imageNamed:@"ic_crown"]];
    [tileKing addTarget:self action:@selector(jumpGest) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加到两行
    [row1 addArrangedSubview:tileDraw];
    [row1 addArrangedSubview:tileTD];
    [row1 addArrangedSubview:tileDice];
    
    [row2 addArrangedSubview:tileFive];
    [row2 addArrangedSubview:tileUnder];
    [row2 addArrangedSubview:tileKing];
    [row2 addArrangedSubview:tileGest];
}
- (UIButton *)makePlanetButton:(NSString *)title action:(SEL)sel {
    UIButton *btn = [self planetButtonWithTitle:title action:sel];
    // 防止子图层影响点击
    for (CALayer *subl in btn.layer.sublayers) {
        subl.allowsGroupOpacity = YES;
        subl.masksToBounds = NO;
    }
    btn.layer.shouldRasterize = YES;
    btn.layer.rasterizationScale = UIScreen.mainScreen.scale;
    btn.userInteractionEnabled = YES;
    return btn;
}
// 创建星球按钮
- (UIButton *)planetButtonWithTitle:(NSString *)title action:(SEL)sel {
    return [self planetButtonWithTitle:title action:sel image:nil];
}

- (UIButton *)planetButtonWithTitle:(NSString *)title action:(SEL)sel image:(UIImage *)fillImage {
    CGFloat diameter = 86.0;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, diameter, diameter);
    btn.layer.cornerRadius = diameter/2.0;
    btn.clipsToBounds = YES; // 关键：裁剪成圆形
    btn.adjustsImageWhenHighlighted = NO;
    
    if (fillImage) {
        // 使用图片填充
        [btn setBackgroundImage:fillImage forState:UIControlStateNormal];
        btn.imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        // 旧的炫彩渐变球体
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
        
        // 光圈描边
        CALayer *ring = [CALayer layer];
        ring.frame = CGRectInset(btn.bounds, -2.0, -2.0);
        ring.cornerRadius = ring.frame.size.width/2.0;
        ring.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
        ring.borderWidth = 1.0;
        ring.shadowColor = [UIColor colorWithRed:0.4 green:0.7 blue:1 alpha:1].CGColor;
        ring.shadowRadius = 10;
        ring.shadowOpacity = 0.8;
        ring.shadowOffset = CGSizeZero;
        [btn.layer addSublayer:ring];
        
        // 渐变旋转动画
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @(0);
        spin.toValue   = @(M_PI * 2);
        spin.duration  = 8.0;
        spin.repeatCount = HUGE_VALF;
        [grad addAnimation:spin forKey:@"grad.spin"];
    }
    
    // 外发光（保留）
    btn.layer.shadowColor = [UIColor colorWithRed:0.6 green:0.9 blue:1 alpha:1].CGColor;
    btn.layer.shadowOpacity = 0.9;
    btn.layer.shadowRadius = 18;
    btn.layer.shadowOffset = CGSizeZero;
    
    // 标题（可叠在图片上）
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.numberOfLines = 2;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    
    // 脉冲发光
    CAGradientLayer *halo = [CAGradientLayer layer];
    halo.frame = CGRectInset(btn.bounds, -12, -12);
    halo.cornerRadius = halo.frame.size.width/2.0;
    halo.colors = @[
        (__bridge id)[UIColor colorWithRed:1 green:0.5 blue:0.8 alpha:0.8].CGColor,
        (__bridge id)[UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:0.8].CGColor,
        (__bridge id)[UIColor colorWithRed:0.6 green:1 blue:0.6 alpha:0.8].CGColor
    ];
    halo.startPoint = CGPointMake(0,0);
    halo.endPoint = CGPointMake(1,1);
    [btn.layer insertSublayer:halo below:btn.layer.sublayers.firstObject];

    // 光晕旋转
    CABasicAnimation *haloSpin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    haloSpin.duration = 10.0;
    haloSpin.toValue = @(M_PI*2);
    haloSpin.repeatCount = HUGE_VALF;
    [halo addAnimation:haloSpin forKey:@"spinHalo"];

    // 呼吸光
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue = @0.55;
    pulse.toValue = @1;
    pulse.duration = 2.4;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [halo addAnimation:pulse forKey:@"haloPulse"];

    // 微浮动（左右上下随机漂移）
    CAKeyframeAnimation *floatAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    floatAnim.duration = 5.0;
    floatAnim.repeatCount = HUGE_VALF;
    floatAnim.additive = YES;
    floatAnim.values = @[
        [NSValue valueWithCGPoint:CGPointMake(0, -3)],
        [NSValue valueWithCGPoint:CGPointMake(2, 2)],
        [NSValue valueWithCGPoint:CGPointMake(-2, 1)],
        [NSValue valueWithCGPoint:CGPointZero]
    ];
    [btn.layer addAnimation:floatAnim forKey:@"floatAnim"];
    return btn;
}



// 粒子拖尾动态跟随 label
- (void)updateEmitterPosition:(CADisplayLink *)link {
    UILabel *label = objc_getAssociatedObject(link, "targetLabel");
    CAEmitterLayer *emitter = objc_getAssociatedObject(link, "emitterLayer");
    if (label && emitter) {
        emitter.emitterPosition = label.center;
    }
}

- (void)jumpGest{
    GestureBombViewController *five = [[GestureBombViewController alloc]init];
       
       [self.navigationController pushViewController:five animated:YES];
}

-(void)jumpFive{
        FiveQiVc *five = [[FiveQiVc alloc]init];
//    GestureBombViewController *five = [[GestureBombViewController alloc]init];
    
    [self.navigationController pushViewController:five animated:YES];
    
}

-(void)jumpcard{
    CardsGameViewController *cc = [CardsGameViewController new];
    [self.navigationController pushViewController:cc animated:YES];
}

-(void)jumpUnder{
    UndercoverViewController *five = [[UndercoverViewController alloc]init];
    
    [self.navigationController pushViewController:five animated:YES];
    
    
}
-(void)jumpKing{
    KingGameViewController *five = [[KingGameViewController alloc]init];
    
    [self.navigationController pushViewController:five animated:YES];
    
    
}


// 新 showTruth 方法，带渐变动画和 label 漂浮
- (void)showTruth {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    StarDrawingViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"778"];
    [self.navigationController pushViewController:vc animated:YES];
}
// 新 showDare 方法，带粒子特效和 label 漂浮
- (void)showDare {
    
//    TDSwitchViewController *vc = [[TDSwitchViewController alloc] init];
        EntangleMergeViewController *vc = [[EntangleMergeViewController alloc]init];
    
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)showDareNoaml {
    
    CubeViewController *five = [[CubeViewController alloc]init];
    
    [self.navigationController pushViewController:five animated:YES];
}


// 将所有 label 动画相关逻辑集中到此方法
- (void)setupLabelAnimations {
    UILabel *animatedLabel = [self.view viewWithTag:999];
    if (!animatedLabel) return;
    
    // 呼吸缩放动画
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @0.98;
    pulse.toValue = @1.05;
    pulse.duration = 1.2;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [animatedLabel.layer addAnimation:pulse forKey:@"pulse"];
    
    // 抖动动画
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.values = @[@(-2), @(2), @(-2)];
    shake.duration = 0.3;
    shake.repeatCount = HUGE_VALF;
    [animatedLabel.layer addAnimation:shake forKey:@"shake"];
    
    // 发光阴影
    animatedLabel.layer.shadowColor = [UIColor colorWithRed:1 green:0.6 blue:0.9 alpha:1].CGColor;
    animatedLabel.layer.shadowOffset = CGSizeMake(0, 0);
    animatedLabel.layer.shadowOpacity = 0.9;
    animatedLabel.layer.shadowRadius = 16;
    animatedLabel.layer.masksToBounds = NO;
    
    // 自身旋转
    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(M_PI * 2);
    rotateAnim.duration = 8.0;
    rotateAnim.repeatCount = HUGE_VALF;
    [animatedLabel.layer addAnimation:rotateAnim forKey:@"rotate"];
    
    // 漂浮路径
    CAKeyframeAnimation *move = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    move.path = ({
        CGMutablePathRef path = CGPathCreateMutable();
        CGRect bounds = self.view.bounds;
        CGPathMoveToPoint(path, NULL, bounds.size.width/2, bounds.size.height/2);
        CGPathAddCurveToPoint(path, NULL,
                              bounds.size.width * 0.8, bounds.size.height * 0.3,
                              bounds.size.width * 0.2, bounds.size.height * 0.7,
                              bounds.size.width/2, bounds.size.height/2);
        path;
    });
    move.duration = 6.0;
    move.repeatCount = HUGE_VALF;
    move.autoreverses = YES;
    [animatedLabel.layer addAnimation:move forKey:@"floatAround"];
    
    // 文字颜色渐变
    CABasicAnimation *textColorAnim = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
    textColorAnim.duration = 2.0;
    textColorAnim.toValue = (__bridge id)[UIColor systemYellowColor].CGColor;
    textColorAnim.autoreverses = YES;
    textColorAnim.repeatCount = HUGE_VALF;
    [animatedLabel.layer addAnimation:textColorAnim forKey:@"textColorFlash"];
}


// MARK: - Bouncing Menu (non-overlapping, full-screen, clickable)

#pragma mark - Bouncing Menu (non-overlapping, full-screen, clickable)

- (void)setupBouncingMenu {

    NSArray *titles  = @[@"画板", @"真心话\n大冒险", @"骰子游戏", @"五子棋",
                         @"谁是卧底", @"国王游戏", @"小姐牌", @"手势游戏"];

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

    self.menuBalls = [NSMutableArray array];
    CGFloat diameter = self.menuBallDiameter = 86.0;
    CGFloat spacing = 22.0;

    // 总宽度：4 个按钮 + 3 个间距
    CGFloat totalWidth = 4 * diameter + 3 * spacing;
    CGFloat startX = (self.view.bounds.size.width - totalWidth) / 2.0;

    // 两排的位置（可调整）
    CGFloat rowY1 = self.view.bounds.size.height * 0.42;
    CGFloat rowY2 = rowY1 + diameter + 30.0;

    for (NSInteger i = 0; i < titles.count; i++) {

        SEL sel = NSSelectorFromString(actions[i]);
        UIButton *ball = [self planetButtonWithTitle:titles[i]
                                              action:sel
                                               image:images[i]];

        NSInteger row = i / 4;
        NSInteger col = i % 4;

        CGFloat x = startX + col * (diameter + spacing);
        CGFloat y = (row == 0) ? rowY1 : rowY2;

        ball.frame = CGRectMake(x, y, diameter, diameter);
        [self.view addSubview:ball];
        [self.menuBalls addObject:ball];

        // 呼吸光动画（按钮周期性放大缩小）
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        pulse.fromValue = @0.95;
        pulse.toValue   = @1.05;
        pulse.duration  = 1.6;
        pulse.autoreverses = YES;
        pulse.repeatCount  = HUGE_VALF;
        [ball.layer addAnimation:pulse forKey:@"breathPulse"];
    }
}
- (CGPoint)randomNonOverlappingPositionForIndex:(NSInteger)idx existing:(NSArray<UIButton *> *)balls {
    CGRect bounds = self.view.bounds;
    CGFloat r = self.menuBallDiameter * 0.5;
    CGFloat minX = bounds.origin.x + self.playSafeInsets.left + r;
    CGFloat maxX = CGRectGetMaxX(bounds) - self.playSafeInsets.right - r;
    CGFloat minY = bounds.origin.y + self.playSafeInsets.top + r;
    CGFloat maxY = CGRectGetMaxY(bounds) - self.playSafeInsets.bottom - r;
    
    NSInteger tries = 0;
    while (tries < 500) {
        tries++;
        CGFloat x = ((CGFloat)arc4random() / UINT32_MAX) * (maxX - minX) + minX;
        CGFloat y = ((CGFloat)arc4random() / UINT32_MAX) * (maxY - minY) + minY;
        CGPoint p = CGPointMake(x, y);
        BOOL overlap = NO;
        for (UIButton *b in balls) {
            CGFloat dx = p.x - b.center.x;
            CGFloat dy = p.y - b.center.y;
            CGFloat dist = sqrt(dx*dx + dy*dy);
            if (dist < self.menuBallDiameter + 4) { // 稍留 4pt 缓冲
                overlap = YES; break;
            }
        }
        if (!overlap) return p;
    }
    // 兜底：按网格粗放摆放
    CGFloat col = (idx % 3);
    CGFloat row = (idx / 3);
    CGFloat w = (CGRectGetWidth(bounds) - self.playSafeInsets.left - self.playSafeInsets.right) / 3.0;
    CGFloat h = (CGRectGetHeight(bounds) - self.playSafeInsets.top - self.playSafeInsets.bottom) / 2.0;
    return CGPointMake(minX + w*0.5 + w*col, minY + h*0.5 + h*row);
}

- (void)stepBouncingMenu:(CADisplayLink *)link {
    CFTimeInterval dt = link.targetTimestamp - link.timestamp;
    if (dt <= 0) dt = 1.0/60.0;
    
    CGRect bounds = self.view.bounds;
    CGFloat r = self.menuBallDiameter * 0.5;
    
    CGFloat minX = bounds.origin.x + self.playSafeInsets.left + r;
    CGFloat maxX = CGRectGetMaxX(bounds) - self.playSafeInsets.right - r;
    CGFloat minY = bounds.origin.y + self.playSafeInsets.top + r;
    CGFloat maxY = CGRectGetMaxY(bounds) - self.playSafeInsets.bottom - r;
    
    // 1) 位置积分 + 边界碰撞
    for (NSInteger i = 0; i < self.menuBalls.count; i++) {
        UIButton *b = self.menuBalls[i];
        CGPoint v = [self.menuVelocities[i] CGPointValue];
        CGPoint p = b.center;
        p.x += v.x * dt;
        p.y += v.y * dt;
        
        // 撞墙反弹
        if (p.x < minX) { p.x = minX; v.x = fabs(v.x); }
        else if (p.x > maxX) { p.x = maxX; v.x = -fabs(v.x); }
        if (p.y < minY) { p.y = minY; v.y = fabs(v.y); }
        else if (p.y > maxY) { p.y = maxY; v.y = -fabs(v.y); }
        
        b.center = p;
        self.menuVelocities[i] = [NSValue valueWithCGPoint:v];
    }
    
    // 2) 球-球碰撞（等质量弹性）
    for (NSInteger i = 0; i < self.menuBalls.count; i++) {
        for (NSInteger j = i+1; j < self.menuBalls.count; j++) {
            [self resolveCollisionBetween:i and:j];
        }
    }
}

- (void)resolveCollisionBetween:(NSInteger)i and:(NSInteger)j {
    UIButton *a = self.menuBalls[i];
    UIButton *b = self.menuBalls[j];
    CGPoint pa = a.center, pb = b.center;
    
    CGFloat dx = pb.x - pa.x;
    CGFloat dy = pb.y - pa.y;
    CGFloat dist = sqrt(dx*dx + dy*dy);
    CGFloat minDist = self.menuBallDiameter; // 半径相等
    
    if (dist < 1e-4) { // 防止除零
        dx = 1; dy = 0; dist = 1;
    }
    
    if (dist < minDist) {
        // 位置分离（各退一半）
        CGFloat overlap = (minDist - dist) * 0.5;
        CGFloat nx = dx / dist, ny = dy / dist; // 碰撞法线
        pa.x -= nx * overlap; pa.y -= ny * overlap;
        pb.x += nx * overlap; pb.y += ny * overlap;
        a.center = pa; b.center = pb;
        
        // 速度在法线方向的交换（等质量弹性碰撞）
        CGPoint va = [self.menuVelocities[i] CGPointValue];
        CGPoint vb = [self.menuVelocities[j] CGPointValue];
        
        CGFloat vaN = va.x*nx + va.y*ny;
        CGFloat vbN = vb.x*nx + vb.y*ny;
        
        CGFloat vaT_x = va.x - vaN*nx;
        CGFloat vaT_y = va.y - vaN*ny;
        CGFloat vbT_x = vb.x - vbN*nx;
        CGFloat vbT_y = vb.y - vbN*ny;
        
        // 交换法向分量
        CGFloat tmp = vaN; vaN = vbN; vbN = tmp;
        
        CGPoint vaNew = CGPointMake(vaT_x + vaN*nx, vaT_y + vaN*ny);
        CGPoint vbNew = CGPointMake(vbT_x + vbN*nx, vbT_y + vbN*ny);
        
        self.menuVelocities[i] = [NSValue valueWithCGPoint:vaNew];
        self.menuVelocities[j] = [NSValue valueWithCGPoint:vbNew];
    }
}


#pragma mark - App Lifecycle Pause/Resume for Menu Animation

- (void)appDidBecomeActive {
    [self startMenuAnimation];
}

- (void)appWillResignActive {
    [self stopMenuAnimation];
}
- (void)startShuffleTimer {
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(shuffleAllMenuBalls)
                                   userInfo:nil
                                    repeats:YES];
}

// 每隔 5s 调用：打乱所有按钮的位置 + 粒子爆炸 + 光线爆破 + 贝塞尔曲线移动
- (void)shuffleAllMenuBalls {

    // 停止弹跳动画
    if (self.menuDisplayLink) self.menuDisplayLink.paused = YES;

    if (self.menuBalls.count == 0) return;

    for (NSInteger i = 0; i < self.menuBalls.count; i++) {

        UIButton *btn = self.menuBalls[i];

        // 清理所有旧动画（避免叠加）
        [btn.layer removeAllAnimations];

        // 粒子效果（轻量版）
        [self playParticleExplosionAt:btn];

        // 目标位置（不重叠）
        CGPoint target = [self randomNonOverlappingPositionForIndex:i existing:self.menuBalls];

        // 贝塞尔路径（轻量）
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:btn.center];

        CGPoint mid = CGPointMake(
            (btn.center.x + target.x) / 2.0 + arc4random_uniform(20) - 10,
            (btn.center.y + target.y) / 2.0 + arc4random_uniform(20) - 10
        );
        [path addQuadCurveToPoint:target controlPoint:mid];

        // 关键动画（轻量）
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        anim.path = path.CGPath;
        anim.duration = 0.45;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.removedOnCompletion = YES;

        [btn.layer addAnimation:anim forKey:@"shuffleMove"];

        // 更新真实位置
        btn.center = target;
    }

    // 动画完成后恢复弹跳
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (self.menuDisplayLink) self.menuDisplayLink.paused = NO;
    });
}
-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"3333"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];
 
    

    

    
    [self setupBouncingMenu];
    
    // Do any additional setup after loading the view.
    
    
    // App lifecycle observers for display link auto pause/resume
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [self startShuffleTimer];
    [self addBackgroundRippleEffect];
}
- (void)addBackgroundRippleEffect {
    CAShapeLayer *ripple = [CAShapeLayer layer];
    CGFloat size = 200;
    ripple.frame = CGRectMake(self.view.center.x - size/2, self.view.center.y - size/2, size, size);
    ripple.cornerRadius = size/2;
    ripple.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    ripple.opacity = 0.0;

    [self.bgImageView.layer addSublayer:ripple];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.6;
    scale.toValue = @2.6;

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @0.45;
    fade.toValue = @0;

    CAAnimationGroup *grp = [CAAnimationGroup animation];
    grp.animations = @[scale, fade];
    grp.duration = 4.5;
    grp.repeatCount = HUGE_VALF;
    grp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [ripple addAnimation:grp forKey:@"rippleWave"];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startMenuAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.menuDisplayLink.paused = NO; // 强制恢复
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.menuDisplayLink.paused = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.menuDisplayLink.paused = YES;
}
#pragma mark - Safe Area Updates for Menu Bouncing

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (@available(iOS 11.0, *)) {
        self.playSafeInsets = self.view.safeAreaInsets;
    } else {
        self.playSafeInsets = UIEdgeInsetsZero;
    }
}

#pragma mark - Clean up

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.menuDisplayLink invalidate];
    self.menuDisplayLink = nil;
}

#pragma mark - Portal helpers
// 统一注册按钮 & 事件
- (void)registerMenuButton:(UIButton *)btn action:(SEL)sel {
    if (!self.originalActions) {
        self.originalActions = [NSMapTable weakToStrongObjectsMapTable];
    }
    [self.originalActions setObject:[NSValue valueWithPointer:sel] forKey:btn];
    [btn addTarget:self action:@selector(menuButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)menuButtonTapped:(UIButton *)sender {
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [gen impactOccurred];
    // 黑洞视觉扭曲（0.3s）
    [UIView animateWithDuration:0.08 animations:^{
            sender.transform = CGAffineTransformMakeScale(0.88, 0.88);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.12 animations:^{
                sender.transform = CGAffineTransformIdentity;
            }];
        }];

        // 粒子爆炸
        [self playParticleExplosionAt:sender];

        // 原来的事件
        SEL sel = [[self.originalActions objectForKey:sender] pointerValue];
        if (sel) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:sel withObject:nil];
    #pragma clang diagnostic pop
            });
        }
}





@end
