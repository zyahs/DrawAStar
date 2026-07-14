//
//  CubeViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/6.
//

#import "CubeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "JFProfileStore.h"
#import "JFDailyChallengeStore.h"
#import "JFTheme.h"

@interface CubeViewController ()
@property (nonatomic, strong) NSArray<UIView *> *cubes;
@property (nonatomic, strong) NSArray<UILabel *> *resultLabels;
@property (nonatomic, strong) UILabel *resultLabel1;
@property (nonatomic, strong) CAGradientLayer *resultGradientLayer;
@end

@implementation CubeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    
    [self setupCubes];

    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat labelSize = 60;

    CGFloat spacing = 20;
    CGFloat totalWidth = labelSize * 5 + spacing * 4;
    CGFloat startX = (screenWidth - totalWidth) / 2;
    CGFloat y = screenHeight - labelSize - 40;
    NSMutableArray *positions = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        CGFloat x = startX + i * (labelSize + spacing);
        [positions addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }

    NSMutableArray *labels = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        CGPoint pos = [positions[i] CGPointValue];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(pos.x,300, labelSize, labelSize)];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        label.layer.cornerRadius = labelSize / 2;
        label.layer.masksToBounds = YES;
        label.textColor = [UIColor redColor];
        label.font = [UIFont boldSystemFontOfSize:48];
        label.text = @"";
        [self.view addSubview:label];
        [labels addObject:label];
    }
    self.resultLabels = labels;

    UIButton *rollButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGFloat rollButtonWidth = 100;
    CGFloat rollButtonHeight = 44;
    CGFloat rollButtonX = (screenWidth - rollButtonWidth) / 2;
    CGFloat rollButtonY = y - rollButtonHeight - 20;
    rollButton.frame = CGRectMake(rollButtonX, rollButtonY, rollButtonWidth, rollButtonHeight);
    rollButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    rollButton.backgroundColor = [JFTheme brandPrimary];
    [rollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    rollButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    rollButton.layer.cornerRadius = 22;
    rollButton.layer.shadowColor = [UIColor blackColor].CGColor;
    rollButton.layer.shadowOpacity = 0.3;
    rollButton.layer.shadowOffset = CGSizeMake(0, 4);
    rollButton.layer.shadowRadius = 6;
    [rollButton setTitle:@"Roll" forState:UIControlStateNormal];
    [rollButton addTarget:self action:@selector(rollDice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rollButton];
    [self setupResultLabel];
}

- (void)setupCubes {
    NSMutableArray *cubes = [NSMutableArray array];
    CGFloat size = 100;
    for (int i = 0; i < 5; i++) {
        CGPoint point = [self randomSafePointWithinBoundsWithSize:CGSizeMake(size, size)];
        UIView *cube = [self createCubeAtPosition:point];
        [self.view addSubview:cube];
        [cubes addObject:cube];
    }
    
    self.cubes = cubes;
}

- (CGPoint)randomSafePointWithinBoundsWithSize:(CGSize)size {
    CGFloat padding = 20;
    CGFloat xMax = MAX(0, self.view.bounds.size.width - size.width - padding * 2);
    CGFloat yMax = MAX(0, self.view.bounds.size.height - size.height - padding * 2);
    CGFloat x = arc4random_uniform((uint32_t)xMax) + padding;
    CGFloat y = arc4random_uniform((uint32_t)yMax) + padding;
    x += size.width / 2;
    y += size.height / 2;
    return CGPointMake(x, y);
}

- (UIView *)createCubeAtPosition:(CGPoint)center {
    CGFloat size = 100;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(center.x - size/2, center.y - size/2, size, size)];
    container.layer.sublayerTransform = [self perspectiveTransform];

    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOpacity = 0.4;
    container.layer.shadowOffset = CGSizeMake(0, 5);
    container.layer.shadowRadius = 10;

    NSArray *texts = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    NSArray *transforms = @[
        [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 0, size / 2)], // front
        [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 0, -size / 2)], // back
        [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeRotation(M_PI_2, 0, 1, 0), CATransform3DMakeTranslation(0, 0, size / 2))], // right
        [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeRotation(-M_PI_2, 0, 1, 0), CATransform3DMakeTranslation(0, 0, size / 2))], // left
        [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeRotation(M_PI_2, 1, 0, 0), CATransform3DMakeTranslation(0, 0, size / 2))], // top
        [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeRotation(-M_PI_2, 1, 0, 0), CATransform3DMakeTranslation(0, 0, size / 2))]  // bottom
    ];

    for (int i = 0; i < 6; i++) {
        CATextLayer *face = [CATextLayer layer];
        face.frame = container.bounds;
        face.string = texts[i];
        face.alignmentMode = kCAAlignmentCenter;
        face.foregroundColor = [UIColor whiteColor].CGColor;
        face.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:36]);
        face.fontSize = 36;
        face.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:0.6].CGColor;
        face.borderColor = [UIColor yellowColor].CGColor;
        face.borderWidth = 1;
        face.cornerRadius = 8;
        face.masksToBounds = YES;
        face.contentsScale = [UIScreen mainScreen].scale;
        face.transform = [transforms[i] CATransform3DValue];
        [container.layer addSublayer:face];
    }

    return container;
}

- (CATransform3D)perspectiveTransform {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / 500.0;
    return transform;
}


// 新增 rollDice 方法
- (void)rollDice {
    JFGameResult *r = [JFGameResult resultWithKind:JFGameKindDice score:5 win:YES];
    [[JFProfileStore shared] reportResult:r];
    [[JFDailyChallengeStore shared] recordResultForToday:JFGameKindDice difficulty:0 score:5 win:YES];
    for (int i = 0; i < self.cubes.count; i++) {
        UIView *cube = self.cubes[i];
        UILabel *label = self.resultLabels[i];

        int repeatCount = arc4random_uniform(4) + 2;
        __block int current = 0;

        __block dispatch_block_t changeBlock = ^{
            int number = arc4random_uniform(6) + 1;
            [self updateCube:cube withNumber:number];
            label.text = [NSString stringWithFormat:@"%d", number];
            cube.center = [self randomSafePointWithinBoundsWithSize:CGSizeMake(100, 100)];

            current++;
            if (current < repeatCount) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), changeBlock);
            }
        };
        changeBlock();
    }
}
- (void)setupResultLabel {
    CGFloat labelWidth = self.view.bounds.size.width;
    CGFloat labelHeight = 500;
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
    self.resultLabel1.numberOfLines = 0;
    // 创建文字图层
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.frame = gradientLayer.bounds;
    textLayer.string = @"骰子游戏";
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
- (void)updateCube:(UIView *)cube withNumber:(int)number {
    NSArray *texts = @[@"1", @"2", @"3", @"4", @"5", @"6"];
    NSArray *layers = cube.layer.sublayers;
    for (CALayer *layer in layers) {
        if ([layer isKindOfClass:[CATextLayer class]]) {
            ((CATextLayer *)layer).string = texts[number - 1];
        }
    }
}

@end
