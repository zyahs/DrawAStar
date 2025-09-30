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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupLabelAnimations];
    [self startMenuAnimation];
    [self startTeleportTimer];
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
    
    // 添加到两行
    [row1 addArrangedSubview:tileDraw];
    [row1 addArrangedSubview:tileTD];
    [row1 addArrangedSubview:tileDice];
    
    [row2 addArrangedSubview:tileFive];
    [row2 addArrangedSubview:tileUnder];
    [row2 addArrangedSubview:tileKing];
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
            (__bridge id)[UIColor colorWithRed:0.95 green:0.45 blue:1 alpha:1].CGColor,
            (__bridge id)[UIColor colorWithRed:0.35 green:0.75 blue:1 alpha:1].CGColor,
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
    btn.layer.shadowColor = [UIColor colorWithRed:0.5 green:0.9 blue:1 alpha:1].CGColor;
    btn.layer.shadowOpacity = 0.6;
    btn.layer.shadowRadius = 12;
    btn.layer.shadowOffset = CGSizeZero;
    
    // 标题（可叠在图片上）
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.numberOfLines = 2;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    btn.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    
    // 脉冲发光
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @(0.98);
    pulse.toValue   = @(1.04);
    pulse.duration  = 1.4;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [btn.layer addAnimation:pulse forKey:@"pulse"];
    
    //    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [self registerMenuButton:btn action:sel];
    // 栅格化优化
    btn.layer.shouldRasterize = YES;
    btn.layer.rasterizationScale = UIScreen.mainScreen.scale;
    btn.userInteractionEnabled = YES;
    
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



-(void)jumpFive{
        FiveQiVc *five = [[FiveQiVc alloc]init];
//    EntangleMergeViewController *five = [[EntangleMergeViewController alloc]init];
    
    [self.navigationController pushViewController:five animated:YES];
    
    
    
    
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
    // 按钮标题与入口
    NSArray *titles  = @[@"画板", @"真心话\n大冒险", @"骰子游戏", @"五子棋", @"谁是卧底", @"国王游戏"];
    NSArray *actions = @[
        NSStringFromSelector(@selector(showTruth)),
        NSStringFromSelector(@selector(showDare)),
        NSStringFromSelector(@selector(showDareNoaml)),
        NSStringFromSelector(@selector(jumpFive)),
        NSStringFromSelector(@selector(jumpUnder)),
        NSStringFromSelector(@selector(jumpKing))
    ];
    
    self.menuBallDiameter = 86.0;
    self.menuBalls = [NSMutableArray array];
    self.menuVelocities = [NSMutableArray array];
    
    // 可活动区域（避开安全区）
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
    }
    self.playSafeInsets = insets;
    
    // 加载图片数组
    NSArray *images = @[
        [UIImage imageNamed:@"x1"],
        [UIImage imageNamed:@"x2"],
        [UIImage imageNamed:@"x3"],
        [UIImage imageNamed:@"x4"],
        [UIImage imageNamed:@"x5"],
        [UIImage imageNamed:@"x6"]
    ];
    
    // 预先放置不重叠的初始位置
    for (NSInteger i = 0; i < titles.count; i++) {
        SEL sel = NSSelectorFromString(actions[i]);
        UIButton *ball = [self planetButtonWithTitle:titles[i] action:sel image:images[i]];
        ball.bounds = CGRectMake(0, 0, self.menuBallDiameter, self.menuBallDiameter);
        
        CGPoint pos = [self randomNonOverlappingPositionForIndex:i existing:self.menuBalls];
        ball.center = pos;
        [self.view addSubview:ball];
        [self.menuBalls addObject:ball];
        
        // 初速：随机方向/速度（保证不会太慢）
        CGFloat speed = 90 + arc4random_uniform(80); // 90~170 pt/s
        CGFloat ang = ((CGFloat)arc4random_uniform(628)) / 100.0f; // 0~6.28
        CGPoint v = CGPointMake(cos(ang) * speed, sin(ang) * speed);
        [self.menuVelocities addObject:[NSValue valueWithCGPoint:v]];
    }
    
    [self.view bringSubviewToFront:[self.view viewWithTag:999]]; // 保持标题在上（若需要）
    
    // 启动显示同步
    [self startMenuAnimation];
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

// 离开页面时停止动画
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopMenuAnimation];
    [self stopTeleportTimer];
}


#pragma mark - App Lifecycle Pause/Resume for Menu Animation

- (void)appDidBecomeActive {
    [self startMenuAnimation];
}

- (void)appWillResignActive {
    [self stopMenuAnimation];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"3333"]];
    self.bgImageView.frame = self.view.bounds;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.bgImageView];
    // 传送门高光圈（与背景图位置大致对应：左上吸入 & 左下弹出）
    self.portalInView  = [self buildPortalGlowWithDiameter:120.0];
    self.portalOutView = [self buildPortalGlowWithDiameter:120.0];
    
    // 下面两个点位可按你的背景图实际视觉再微调
    self.portalInView.center  = CGPointMake(self.view.bounds.size.width * 0.18, self.view.bounds.size.height * 0.22);
    self.portalOutView.center = CGPointMake(self.view.bounds.size.width * 0.22, self.view.bounds.size.height * 0.78);
    
    self.portalInView.autoresizingMask  = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.portalOutView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.portalInView];
    [self.view addSubview:self.portalOutView];
    
    // 计时器：每 4s 传送一个按钮（吸入0.6s + 等待3s + 弹出0.4s）
    [self startTeleportTimer];
    
    //    self.drawingView = [[StarDrawingView alloc] init];
    //    self.drawingView.translatesAutoresizingMaskIntoConstraints = NO;
    //    self.drawingView.imageArray = @[
    //        [UIImage imageNamed:@"spark_red"],
    //        [UIImage imageNamed:@"spark_green"],
    //        [UIImage imageNamed:@"spark_blue"]
    //    ];
    //    [self.view addSubview:self.drawingView];
    //
    //    // 位置自适应，填满父视图
    //    [NSLayoutConstraint activateConstraints:@[
    //        [self.drawingView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    //        [self.drawingView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    //        [self.drawingView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    //        [self.drawingView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    //    ]];
    //
    //    [self.drawingView startDrawing];
    
    [self setupBouncingMenu];
    
    // Do any additional setup after loading the view.
    UILabel *animatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 200)];
    animatedLabel.text = @"继风的小游戏";
    animatedLabel.textAlignment = NSTextAlignmentCenter;
    animatedLabel.font = [UIFont boldSystemFontOfSize:36];
    animatedLabel.numberOfLines = 0;
    animatedLabel.tag = 999;
    [self.view addSubview:animatedLabel];
    
    // label 漂浮动画
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
    
    // 文字颜色渐变（使用渐变蒙版实现真正的文字颜色渐变动画）
    // 1. 创建 CATextLayer
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = animatedLabel.text;
    textLayer.font = (__bridge CFTypeRef)(animatedLabel.font.fontName);
    textLayer.fontSize = animatedLabel.font.pointSize;
    textLayer.frame = animatedLabel.frame;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    
    // 2. 创建渐变层
    CAGradientLayer *textGradient = [CAGradientLayer layer];
    textGradient.frame = animatedLabel.frame;
    textGradient.colors = @[(__bridge id)[UIColor systemPinkColor].CGColor,
                            (__bridge id)[UIColor systemYellowColor].CGColor,
                            (__bridge id)[UIColor systemCyanColor].CGColor];
    textGradient.startPoint = CGPointMake(0, 0);
    textGradient.endPoint = CGPointMake(1, 1);
    textGradient.mask = textLayer;
    [self.view.layer addSublayer:textGradient];
    [animatedLabel.layer addSublayer:textGradient];
    
    // 3. 渐变动画
    CABasicAnimation *colorAnim = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorAnim.toValue = @[(__bridge id)[UIColor systemGreenColor].CGColor,
                          (__bridge id)[UIColor systemOrangeColor].CGColor,
                          (__bridge id)[UIColor systemPurpleColor].CGColor];
    colorAnim.duration = 3.0;
    colorAnim.autoreverses = YES;
    colorAnim.repeatCount = HUGE_VALF;
    [textGradient addAnimation:colorAnim forKey:@"gradientColorChange"];
    [animatedLabel.layer addAnimation:colorAnim forKey:@"gradientColorChange"];
    
    // App lifecycle observers for display link auto pause/resume
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
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
    // 黑洞视觉扭曲（0.3s）
    [self runBlackHoleEffectAroundView:sender duration:0.3];
    
    // 轻微延迟后继续原逻辑
    SEL sel = [[self.originalActions objectForKey:sender] pointerValue];
    if (sel && [self respondsToSelector:sel]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:sel withObject:nil];
#pragma clang diagnostic pop
        });
    }
}
- (UIView *)buildPortalGlowWithDiameter:(CGFloat)diameter {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    v.layer.cornerRadius = diameter/2.0;
    v.userInteractionEnabled = NO;
    
    // 径向渐变光圈
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = v.bounds;
    g.type = kCAGradientLayerRadial;
    g.colors = @[(__bridge id)[UIColor colorWithWhite:1 alpha:0.85].CGColor,
                 (__bridge id)[UIColor colorWithWhite:1 alpha:0.25].CGColor,
                 (__bridge id)[UIColor colorWithWhite:1 alpha:0.0].CGColor];
    g.locations = @[@0.0, @0.5, @1.0];
    g.startPoint = CGPointMake(0.5, 0.5);
    g.endPoint   = CGPointMake(1.0, 1.0);
    g.cornerRadius = v.layer.cornerRadius;
    [v.layer addSublayer:g];
    
    v.layer.shadowColor = [UIColor whiteColor].CGColor;
    v.layer.shadowOpacity = 0.7;
    v.layer.shadowRadius = 16;
    v.layer.shadowOffset = CGSizeZero;
    
    // 轻微脉冲动画
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @0.98; pulse.toValue = @1.03;
    pulse.duration = 2.2; pulse.autoreverses = YES; pulse.repeatCount = HUGE_VALF;
    [v.layer addAnimation:pulse forKey:@"portal.pulse"];
    return v;
}

- (void)startTeleportTimer {
    [self.teleportTimer invalidate];
    self.teleportTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                          target:self
                                                        selector:@selector(performTeleportOnce)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)stopTeleportTimer {
    [self.teleportTimer invalidate];
    self.teleportTimer = nil;
}

- (void)performTeleportOnce {
    if (self.menuBalls.count == 0) return;
    
    // 选择可见候选
    NSMutableArray<UIButton*> *candidates = [NSMutableArray array];
    for (UIButton *b in self.menuBalls) {
        if (!b.hidden && b.alpha > 0.9 && b.window) [candidates addObject:b];
    }
    if (candidates.count == 0) return;
    
    UIButton *btn = candidates[arc4random_uniform((uint32_t)candidates.count)];
    CGPoint inC  = [self.portalInView.superview convertPoint:self.portalInView.center toView:self.view];
    
    // 吸入
    [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        btn.center = inC;
        btn.transform = CGAffineTransformMakeScale(0.15, 0.15);
        btn.alpha = 0.15;
    } completion:^(BOOL finished) {
        btn.hidden = YES;
        btn.transform = CGAffineTransformIdentity;
        btn.alpha = 1.0;
        
        // 3 秒后从另一传送门弹出
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CGPoint outC = [self.portalOutView.superview convertPoint:self.portalOutView.center toView:self.view];
            btn.center = outC;
            btn.transform = CGAffineTransformMakeScale(0.2, 0.2);
            btn.hidden = NO;
            btn.alpha = 0.0;
            
            CGPoint target = [self randomNonOverlappingPositionForIndex:[self.menuBalls indexOfObject:btn]
                                                               existing:self.menuBalls];
            
            [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.4
                                options:UIViewAnimationOptionCurveEaseOut animations:^{
                btn.center = target;
                btn.transform = CGAffineTransformIdentity;
                btn.alpha = 1.0;
            } completion:nil];
        });
    }];
}

- (void)runBlackHoleEffectAroundView:(UIView *)view duration:(NSTimeInterval)duration {
    // 抓屏
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, UIScreen.mainScreen.scale);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // CoreImage 扭曲（更像黑洞）
    CIImage *ci = [[CIImage alloc] initWithImage:snap];
    CIFilter *twirl = [CIFilter filterWithName:@"CITwirlDistortion"];
    [twirl setValue:ci forKey:kCIInputImageKey];

    CGPoint center = [view.superview convertPoint:view.center toView:self.view];
    // 注意 CoreImage y 轴翻转
    [twirl setValue:[CIVector vectorWithX:center.x Y:self.view.bounds.size.height - center.y] forKey:kCIInputCenterKey];
    [twirl setValue:@(MIN(view.bounds.size.width, view.bounds.size.height) * 1.6) forKey:kCIInputRadiusKey];
    [twirl setValue:@(2.8) forKey:kCIInputAngleKey];

    CIContext *ctx = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [ctx createCGImage:twirl.outputImage fromRect:ci.extent];
    UIImage *distorted = [UIImage imageWithCGImage:cgimg scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp];
    CGImageRelease(cgimg);

    UIImageView *overlay = [[UIImageView alloc] initWithFrame:self.view.bounds];
    overlay.image = distorted;
    overlay.alpha = 0.0;
    overlay.userInteractionEnabled = NO;
    [self.view addSubview:overlay];

    [UIView animateWithDuration:duration/2.0 animations:^{ overlay.alpha = 1.0; } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration/2.0 animations:^{ overlay.alpha = 0.0; } completion:^(BOOL fin){ [overlay removeFromSuperview]; }];
    }];
}

@end
