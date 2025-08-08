//
//  TruthOrDareViewController.m
//  JiFeng_test
//
//  Created by 继风(周毅) on 2025/8/4.
//

#import "TruthOrDareViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TruthOrDareViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) NSArray<NSString *> *items;
@property (nonatomic, assign) NSInteger selectedRow;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) CAGradientLayer *resultGradientLayer;
@property (nonatomic, strong) CAGradientLayer *resultGradientLayer1;
@property (nonatomic, strong) CATextLayer *resultTextLayer;
@property (nonatomic, strong) CATextLayer *resultTextLayer1;
@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) UILabel *resultLabel1;
@end

@implementation TruthOrDareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    
   
    
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap)];
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tripleTap];
    [self setupBackgroundGlow];
    self.items = self.item;
    self.selectedRow = 0;
    [self setupPickerView];
    [self setupStartButton];
    [self setupResultLabel];
    [self setupResultLabel1];
    [self setupParticles];
    self.hudView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.center.y - 100, self.view.bounds.size.width, 200)];
    self.hudView.userInteractionEnabled = YES;
    self.hudView.backgroundColor = [UIColor redColor];
    self.hudView.alpha = 0.2;
    [self.view addSubview:self.hudView];
}

- (void)handleTripleTap {
    NSLog(@"检测到三连击！");
    [self.hudView removeFromSuperview];
    // 在这里添加你需要的逻辑
}

- (void)setupResultLabel {
    CGFloat labelWidth = self.view.bounds.size.width;
    CGFloat labelHeight = 1000;
    CGRect labelFrame = CGRectMake((self.view.bounds.size.width - labelWidth) / 2, 200, labelWidth, labelHeight);

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
    textLayer.string = @"准备好了吗？";
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:28].fontName);
    textLayer.fontSize = 32;
    textLayer.wrapped = YES;
    textLayer.truncationMode = kCATruncationEnd;
    self.resultTextLayer = textLayer;

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

#pragma mark - UIPickerView Setup

-(void)setupPickerView {
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.center.y - 100, self.view.bounds.size.width, 200)];
    self.pickerView.dataSource = (id)self;
    self.pickerView.delegate = (id)self;
    self.pickerView.showsSelectionIndicator = YES;
    [self.pickerView selectRow:self.items.count * 500 inComponent:0 animated:NO];
  
    [self.view addSubview:self.pickerView];
}

- (void)setupStartButton {
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.frame = CGRectMake((self.view.bounds.size.width - 120) / 2, CGRectGetMaxY(self.pickerView.frame) + 40, 120, 50);
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    self.startButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.startButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startRolling) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
}

// 实现流畅滚动效果并在末尾自然停下
- (void)startRolling {
    [self.startButton setEnabled:NO];
    
    NSInteger currentRow = [self.pickerView selectedRowInComponent:0];
//    NSInteger totalRows = self.items.count * 1000;
    NSInteger randomIndex = arc4random_uniform((uint32_t)self.items.count);
    NSInteger finalRow = currentRow + 30 + randomIndex;

    self.selectedRow = finalRow % self.items.count;
    
    // 模拟丝滑滚动
    [self animateRollingFromRow:currentRow toRow:finalRow duration:2.0];
}

- (void)animateRollingFromRow:(NSInteger)startRow toRow:(NSInteger)endRow duration:(NSTimeInterval)duration {
    NSInteger steps = 60;
    NSTimeInterval interval = duration / steps;
    NSInteger diff = endRow - startRow;

    for (int i = 1; i <= steps; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSInteger intermediateRow = startRow + diff * i / steps;
            [self.pickerView selectRow:intermediateRow inComponent:0 animated:NO];
        });
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self highlightSelectedRow];
        [self.startButton setEnabled:YES];
        // 更新文字内容
        self.resultTextLayer.string = [NSString stringWithFormat:@"你抽到的是：%@", self.items[self.selectedRow]];
    });
}

- (void)highlightSelectedRow {
    NSInteger actualRow = [self.pickerView selectedRowInComponent:0] % self.items.count;
    self.selectedRow = actualRow;
    [self.pickerView reloadAllComponents];
}

#pragma mark - UIPickerView DataSource & Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.items.count * 1000; // 支持无限滚动
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.bounds.size.width, 44)];
    label.text = self.items[row % self.items.count];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.font = ((row % self.items.count) == self.selectedRow) ? [UIFont boldSystemFontOfSize:30] : [UIFont systemFontOfSize:22];
    
    return label;
}

- (void)setupParticles {
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterPosition = CGPointMake(self.view.center.x, -10);
    emitter.emitterShape = kCAEmitterLayerLine;
    emitter.emitterSize = CGSizeMake(self.view.bounds.size.width, 1.0);

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 5;
    cell.lifetime = 5.0;
    cell.velocity = 80;
    cell.velocityRange = 50;
    cell.scale = 0.04;
    cell.scaleRange = 0.02;
    cell.contents = (__bridge id)[[UIImage imageNamed:@"spark.png"] CGImage];
    cell.color = nil;
    cell.redRange = 1.0;
    cell.greenRange = 1.0;
    cell.blueRange = 1.0;
    cell.alphaRange = 0.5;
    cell.spin = 2;
    cell.emissionRange = M_PI;

    emitter.emitterCells = @[cell];
    [self.view.layer addSublayer:emitter];
}

- (void)setupBackgroundGlow {
    UILabel *animatedLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    animatedLabel.text = self.displayText ?: @"默认显示内容";;
    animatedLabel.textAlignment = NSTextAlignmentCenter;
    animatedLabel.font = [UIFont boldSystemFontOfSize:36];
    animatedLabel.textColor = [UIColor whiteColor];
    animatedLabel.numberOfLines = 0;
//    [self.view addSubview:animatedLabel];

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

    // 文字颜色渐变
    CABasicAnimation *textColorAnim = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
    textColorAnim.duration = 2.0;
    textColorAnim.toValue = (__bridge id)[UIColor systemYellowColor].CGColor;
    textColorAnim.autoreverses = YES;
    textColorAnim.repeatCount = HUGE_VALF;
    [animatedLabel.layer addAnimation:textColorAnim forKey:@"textColorFlash"];
}


- (void)setupResultLabel1 {
    CGFloat labelWidth = self.view.bounds.size.width;
    CGFloat labelHeight = 1000;
    CGRect labelFrame = CGRectMake((self.view.bounds.size.width - labelWidth) / 2, 800, labelWidth, labelHeight);

    // 创建渐变图层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = labelFrame;
    gradientLayer.colors = @[(__bridge id)[UIColor redColor].CGColor,
                             (__bridge id)[UIColor blueColor].CGColor,
                             (__bridge id)[UIColor purpleColor].CGColor];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    [self.view.layer addSublayer:gradientLayer];
    self.resultGradientLayer1 = gradientLayer;
    self.resultLabel1.numberOfLines = 0;
    // 创建文字图层
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.frame = gradientLayer.bounds;
    textLayer.string = self.displayText?:@"GoGoGo";
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:28].fontName);
    textLayer.fontSize = 32;
    textLayer.wrapped = YES;
    textLayer.truncationMode = kCATruncationEnd;
    self.resultTextLayer1 = textLayer;

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
    [self.resultGradientLayer1 removeAllAnimations];
    [self.resultGradientLayer1 addAnimation:colorShift forKey:@"colorShift"];
    [self.resultGradientLayer1 addAnimation:shakeAnim forKey:@"shake"];
    [self.resultGradientLayer1 addAnimation:breathAnim forKey:@"breath"];
    [self.resultGradientLayer1 addAnimation:scaleAnim forKey:@"pulse"];
    [self.resultGradientLayer1 addAnimation:shadowAnim forKey:@"trail"];
    self.resultGradientLayer1.masksToBounds = NO;
    // 注意：粒子层添加在 self.view.layer，确保不会被 gradientLayer.mask 遮住
    [self.view.layer insertSublayer:orbitEmitter above:self.resultGradientLayer1];
}



@end
