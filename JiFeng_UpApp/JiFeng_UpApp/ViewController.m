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
    
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat buttonWidth = 100.0; // 假设每个按钮宽度为 100
    CGFloat spacing = (screenWidth - buttonWidth * 3) / 4.0;
    CGFloat yPosition = 700;

    UIButton *drawBtn = [ColorButton createAnimatedButtonWithText:@"画板"
                                                            target:self
                                                            action:@selector(showTruth)
                                                          position:CGPointMake(spacing, yPosition)];
    [self.view addSubview:drawBtn];

    UIButton *dareBtn = [ColorButton createAnimatedButtonWithText:@"真心话大冒险"
                                                            target:self
                                                            action:@selector(showDare)
                                                          position:CGPointMake(spacing * 2 + buttonWidth, yPosition)];
    [self.view addSubview:dareBtn];

    UIButton *numBtn = [ColorButton createAnimatedButtonWithText:@"骰子游戏"
                                                           target:self
                                                           action:@selector(showDareNoaml)
                                                         position:CGPointMake(spacing * 3 + buttonWidth * 2, yPosition)];
    [self.view addSubview:numBtn];
    UIButton *fiveBtn = [ColorButton createAnimatedButtonWithText:@"五子棋" target:self
                                action:@selector(jumpFive)
                              position:CGPointMake(spacing, 300)];
    [self.view addSubview:fiveBtn];
    
    UIButton *unBtn = [ColorButton createAnimatedButtonWithText:@"谁是卧底" target:self
                                action:@selector(jumpUnder)
                              position:CGPointMake(spacing*2 +buttonWidth, 300)];
    
    [self.view addSubview:unBtn];
    UIButton *kingBtn = [ColorButton createAnimatedButtonWithText:@"国王游戏" target:self
                                action:@selector(jumpKing)
                              position:CGPointMake(spacing*3+buttonWidth*2, 300)];
    [self.view addSubview:kingBtn];
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
