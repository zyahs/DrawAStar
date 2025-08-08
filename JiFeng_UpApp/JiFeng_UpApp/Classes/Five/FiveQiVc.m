//
//  FiveQiVc.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/9/2.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "FiveQiVc.h"
#import "CheckerboardView.h"
#define ScreenW [UIScreen mainScreen].bounds.size.width

@interface FiveQiVc ()
@property (nonatomic, strong) CheckerboardView * boardView;
@property (nonatomic,weak) UIButton * backButton;
@property (nonatomic,weak) UIButton * reStartBtn;
@property (nonatomic,weak) UIButton * changeBoardButton;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) CAGradientLayer *resultGradientLayer;

@end
@implementation FiveQiVc



- (void)viewDidLoad {
    [super viewDidLoad];

    for (UIView *subview in self.view.subviews) {
        [subview removeFromSuperview];
    }

    [self setUp];
//    self.title = @"这是五子棋";
    [self setupResultLabel];
}


- (void)setupResultLabel {
    CGFloat labelWidth = self.view.bounds.size.width;
    CGFloat labelHeight = 1000;
    CGRect labelFrame = CGRectMake((self.view.bounds.size.width - labelWidth) / 2, 100, labelWidth, labelHeight);

    // 创建渐变图层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = labelFrame;
    gradientLayer.colors = @[(__bridge id)[UIColor redColor].CGColor,
                             (__bridge id)[UIColor blueColor].CGColor,
                             (__bridge id)[UIColor purpleColor].CGColor];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    [self.view.layer addSublayer:gradientLayer];
    self.resultGradientLayer = gradientLayer;
    self.resultLabel.numberOfLines = 0;
    // 创建文字图层
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.frame = gradientLayer.bounds;
    textLayer.string = @"五子棋";
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:28].fontName);
    textLayer.fontSize = 32;
    textLayer.wrapped = YES;
    textLayer.truncationMode = kCATruncationEnd;
//    self.resultTextLayer = textLayer;

    // 使用文字图层作为渐变图层的遮罩
    gradientLayer.mask = textLayer;

    // 添加颜色动画
    CABasicAnimation *colorShift = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorShift.toValue = @[(__bridge id)[UIColor blueColor].CGColor,
                           (__bridge id)[UIColor greenColor].CGColor,
                           (__bridge id)[UIColor redColor].CGColor];
    colorShift.duration = 3.0;
    colorShift.autoreverses = YES;
    colorShift.repeatCount = HUGE_VALF;
    [gradientLayer addAnimation:colorShift forKey:@"colorShift"];

    // 添加轻微抖动动画
    CAKeyframeAnimation *shakeAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shakeAnim.values = @[@0, @-4, @4, @-4, @4, @0];
    shakeAnim.keyTimes = @[@0, @0.2, @0.4, @0.6, @0.8, @1];
    shakeAnim.duration = 1.2;
    shakeAnim.repeatCount = HUGE_VALF;
    [gradientLayer addAnimation:shakeAnim forKey:@"shake"];

    // 添加呼吸光动画（透明度闪烁）
    CABasicAnimation *breathAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    breathAnim.fromValue = @0.8;
    breathAnim.toValue = @1.0;
    breathAnim.duration = 2.0;
    breathAnim.autoreverses = YES;
    breathAnim.repeatCount = HUGE_VALF;
    [gradientLayer addAnimation:breathAnim forKey:@"breath"];

    // 添加缩放脉动动画
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @1.0;
    scaleAnim.toValue = @1.08;
    scaleAnim.duration = 1.5;
    scaleAnim.autoreverses = YES;
    scaleAnim.repeatCount = HUGE_VALF;
    [gradientLayer addAnimation:scaleAnim forKey:@"pulse"];

    // 添加拖尾（发光拖尾）动画
    CABasicAnimation *shadowAnim = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    shadowAnim.fromValue = @2;
    shadowAnim.toValue = @10;
    shadowAnim.duration = 1.5;
    shadowAnim.autoreverses = YES;
    shadowAnim.repeatCount = HUGE_VALF;
    gradientLayer.shadowColor = [UIColor whiteColor].CGColor;
    gradientLayer.shadowOpacity = 0.8;
    gradientLayer.shadowOffset = CGSizeZero;
    [gradientLayer addAnimation:shadowAnim forKey:@"trail"];

    // 添加粒子光点围绕 label 飘动的动画
    CAEmitterLayer *orbitEmitter = [CAEmitterLayer layer];
    orbitEmitter.emitterPosition = CGPointMake(CGRectGetMidX(gradientLayer.frame), CGRectGetMidY(gradientLayer.frame));
    orbitEmitter.emitterSize = CGSizeMake(gradientLayer.bounds.size.width, gradientLayer.bounds.size.height);
    orbitEmitter.emitterShape = kCAEmitterLayerCircle;
    orbitEmitter.renderMode = kCAEmitterLayerAdditive;

    CAEmitterCell *orbitCell = [CAEmitterCell emitterCell];
    orbitCell.contents = (__bridge id)[[UIImage imageNamed:@"spark.png"] CGImage];
    orbitCell.birthRate = 5;
    orbitCell.lifetime = 5;
    orbitCell.velocity = 50;
    orbitCell.scale = 0.05;
    orbitCell.alphaSpeed = -0.4;
    orbitCell.emissionRange = 2 * M_PI;
    orbitCell.spin = 4;

    orbitEmitter.emitterCells = @[orbitCell];
    [self.resultGradientLayer removeAllAnimations];
    [self.resultGradientLayer addAnimation:colorShift forKey:@"colorShift"];
    [self.resultGradientLayer addAnimation:shakeAnim forKey:@"shake"];
    [self.resultGradientLayer addAnimation:breathAnim forKey:@"breath"];
    [self.resultGradientLayer addAnimation:scaleAnim forKey:@"pulse"];
    [self.resultGradientLayer addAnimation:shadowAnim forKey:@"trail"];
    self.resultGradientLayer.masksToBounds = NO;
    // 注意：粒子层添加在 self.view.layer，确保不会被 gradientLayer.mask 遮住
    [self.view.layer insertSublayer:orbitEmitter above:self.resultGradientLayer];
}


- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self.boardView isKindOfClass:[CheckerboardView class]]) {
        NSLog(@"[JFTD] 是正确的 CheckerboardView，尝试刷新");
        [self.boardView setNeedsDisplay];
    } else {
        NSLog(@"[JFTD] 错误！boardView 不是 CheckerboardView 类型：%@", self.boardView);
    }
}

- (void)setUp{
    
    self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    
    //添加棋盘
    CheckerboardView * boardView = [[CheckerboardView alloc]initWithFrame:CGRectMake(20, 30, ScreenW * 0.95, ScreenW * 0.95)];
    boardView.center = self.view.center;
    [self.view addSubview:boardView];
    self.boardView = boardView;
    
    
    //悔棋
    UIButton * changeBoardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [changeBoardButton setTitle:@"初级棋盘" forState:UIControlStateNormal];
    [changeBoardButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    changeBoardButton.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
    changeBoardButton.frame = CGRectMake(CGRectGetMidX(boardView.frame) - CGRectGetWidth(boardView.frame) * 0.3, CGRectGetMinY(boardView.frame) - 50, CGRectGetWidth(boardView.frame) * 0.6, 35);
    changeBoardButton.layer.cornerRadius = 4;
    [self.view addSubview:changeBoardButton];
    self.changeBoardButton = changeBoardButton;
    [changeBoardButton addTarget:self action:@selector(changeBoard:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //悔棋
    UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setTitle:@"悔棋" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    backButton.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
    backButton.frame = CGRectMake(CGRectGetMinX(boardView.frame), CGRectGetMaxY(boardView.frame) + 15, CGRectGetWidth(boardView.frame) * 0.45, 30);
    backButton.layer.cornerRadius = 4;
    [self.view addSubview:backButton];
    self.backButton = backButton;
    [backButton addTarget:self action:@selector(backOneStep:) forControlEvents:UIControlEventTouchUpInside];
    
    //新游戏
    UIButton * reStartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [reStartBtn setTitle:@"新游戏" forState:UIControlStateNormal];
    reStartBtn.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
    reStartBtn.frame = CGRectMake(CGRectGetMaxX(boardView.frame) - CGRectGetWidth(boardView.frame) * 0.45, CGRectGetMaxY(boardView.frame) + 15, CGRectGetWidth(boardView.frame) * 0.45, 30);
    reStartBtn.layer.cornerRadius = 4;
    [self.view addSubview:reStartBtn];
    self.reStartBtn = reStartBtn;
    [reStartBtn addTarget:self action:@selector(newGame) forControlEvents:UIControlEventTouchUpInside];
}

- (void)backOneStep:(UIButton *)sender{
    [self.boardView backOneStep:(UIButton *)sender];
}

- (void)newGame{
    
    [self.boardView newGame];
}

- (void)changeBoard:(UIButton *)btn{
    
    [self.boardView changeBoardLevel];
    [_changeBoardButton setTitle:[btn.currentTitle isEqualToString:@"高级棋盘"]?@"初级棋盘":@"高级棋盘" forState:UIControlStateNormal];
}
@end
