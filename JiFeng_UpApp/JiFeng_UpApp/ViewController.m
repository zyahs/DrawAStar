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
@interface ViewController ()
@property (nonatomic, strong) StarDrawingView *drawingView;


@property (nonatomic, strong) UIView *centerCircle;
@property (nonatomic, strong) UIView *topCircle;
@property (nonatomic, strong) UIView *bottomCircle;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupLabelAnimations];
    
}

- (UIColor *)randomColor {
    return [UIColor colorWithRed:arc4random_uniform(256)/255.0
                           green:arc4random_uniform(256)/255.0
                            blue:arc4random_uniform(256)/255.0
                           alpha:1.0];
}

- (UIColor *)randomColorWithAlpha:(CGFloat)alpha {
    return [UIColor colorWithRed:arc4random_uniform(256)/255.0
                           green:arc4random_uniform(256)/255.0
                            blue:arc4random_uniform(256)/255.0
                           alpha:alpha];
}
- (UIButton *)createAnimatedButtonWithText:(NSString *)title
                                    action:(SEL)selector
                                  position:(CGPoint)position {
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(position.x, position.y, 100, 50)];
    [button setBackgroundColor:[UIColor redColor]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Heavy" size:16];
    button.layer.cornerRadius = 12;
    button.clipsToBounds = YES;
    
    // 阴影
    button.layer.shadowColor = [self randomColor].CGColor;
    button.layer.shadowRadius = 16;
    button.layer.shadowOpacity = 0.9;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    
    // 渐变背景
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = button.bounds;
    NSMutableArray *colors = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        [colors addObject:(__bridge id)[self randomColor].CGColor];
    }
    gradient.colors = colors;
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    gradient.cornerRadius = 12;
    [button.layer insertSublayer:gradient atIndex:0];
    
    // 点击事件
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    // 脉冲动画
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @0.97;
    pulse.toValue = @1.05;
    pulse.duration = 1.2;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [button.layer addAnimation:pulse forKey:@"pulse"];
    
    // 粒子动画
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = CGPointMake(button.bounds.size.width / 2, button.bounds.size.height / 2);
    emitter.emitterShape = kCAEmitterLayerCircle;
    emitter.emitterSize = CGSizeMake(button.bounds.size.width * 0.9, button.bounds.size.height * 0.9);
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 1.2;
    cell.lifetime = 1.2;
    cell.velocity = 30;
    cell.velocityRange = 15;
    cell.scale = 0.03;
    cell.scaleRange = 0.02;
    cell.emissionRange = M_PI * 2;
    cell.contents = (id)[[UIImage systemImageNamed:@"sparkle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].CGImage;
    cell.color = [self randomColorWithAlpha:0.8].CGColor;
    
    emitter.emitterCells = @[cell];
    [button.layer addSublayer:emitter];
    
    [self.view addSubview:button];
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    self.view.backgroundColor = [UIColor blackColor];

    self.drawingView = [[StarDrawingView alloc] init];
    self.drawingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.drawingView.imageArray = @[
        [UIImage imageNamed:@"spark_red"],
        [UIImage imageNamed:@"spark_green"],
        [UIImage imageNamed:@"spark_blue"]
    ];
    [self.view addSubview:self.drawingView];

    // 位置自适应，填满父视图
    [NSLayoutConstraint activateConstraints:@[
        [self.drawingView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.drawingView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.drawingView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.drawingView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

    [self.drawingView startDrawing];
    
    
    [self createAnimatedButtonWithText:@"画板"
                                action:@selector(showTruth)
                              position:CGPointMake(50, 700)];
    
    [self createAnimatedButtonWithText:@"真心话大冒险"
                                action:@selector(showDare)
                              position:CGPointMake(175, 700)];
    
    [self createAnimatedButtonWithText:@"骰子游戏"
                                action:@selector(showDareNoaml)
                              position:CGPointMake(300, 700)];
    
    [self createAnimatedButtonWithText:@" 五子棋"
                                action:@selector(jumpFive)
                              position:CGPointMake(50, 300)];
    
    // Do any additional setup after loading the view.
    UILabel *animatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 200)];
    animatedLabel.text = @"继风的小游戏";
    animatedLabel.textAlignment = NSTextAlignmentCenter;
    animatedLabel.font = [UIFont boldSystemFontOfSize:36];
//    animatedLabel.textColor = [UIColor whiteColor];
    animatedLabel.numberOfLines = 0;
    animatedLabel.tag = 999;
    [self.view addSubview:animatedLabel];
//    [self setupLabelAnimations];
    
    // 背景渐变动画
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = @[(__bridge id)[UIColor systemPinkColor].CGColor,
                        (__bridge id)[UIColor systemPurpleColor].CGColor,
                        (__bridge id)[UIColor systemBlueColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    CABasicAnimation *bgAnim = [CABasicAnimation animationWithKeyPath:@"colors"];
    bgAnim.fromValue = gradient.colors;
    bgAnim.toValue = @[(__bridge id)[UIColor systemTealColor].CGColor,
                       (__bridge id)[UIColor systemOrangeColor].CGColor,
                       (__bridge id)[UIColor systemGreenColor].CGColor];
    bgAnim.duration = 4.0;
    bgAnim.autoreverses = YES;
    bgAnim.repeatCount = HUGE_VALF;
    [gradient addAnimation:bgAnim forKey:@"colorChange"];
    
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
    
    [self.navigationController pushViewController:five animated:YES];


}




// 动画展示真心话/大冒险公共方法
- (void)showRandomPromptFrom:(NSArray<NSString *> *)prompts title:(NSString *)title {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.title = title;
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = prompts[arc4random_uniform((uint32_t)prompts.count)];
    label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:18];
    label.alpha = 0.0;
    label.transform = CGAffineTransformMakeScale(0.8, 0.8);
    label.textColor = [UIColor redColor];
    [vc.view addSubview:label];
    
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:vc.view.leadingAnchor constant:20],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:vc.view.trailingAnchor constant:-20]
    ]];
    
    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        label.alpha = 1.0;
        label.transform = CGAffineTransformIdentity;
    } completion:nil];
    
    if (self.navigationController) {
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

// 新 showTruth 方法，带渐变动画和 label 漂浮
- (void)showTruth {
   
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    StarDrawingViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"778"];
    [self.navigationController pushViewController:vc animated:YES];
}
// 新 showDare 方法，带粒子特效和 label 漂浮
- (void)showDare {
    
    TDSwitchViewController *vc = [[TDSwitchViewController alloc] init];
    
    
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
@end
