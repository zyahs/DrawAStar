//
//  ColorButton.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import "ColorButton.h"



@implementation ColorButton
+ (UIButton *)createAnimatedButtonWithText:(NSString *)title
                                     target:(id)target
                                     action:(SEL)selector
                                   position:(CGPoint)position; {
    
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
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
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
    
    
    return button;
}
+ (UIColor *)randomColor {
    return [UIColor colorWithRed:arc4random_uniform(256)/255.0
                           green:arc4random_uniform(256)/255.0
                            blue:arc4random_uniform(256)/255.0
                           alpha:1.0];
}

+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha {
    return [UIColor colorWithRed:arc4random_uniform(256)/255.0
                           green:arc4random_uniform(256)/255.0
                            blue:arc4random_uniform(256)/255.0
                           alpha:alpha];
}
+ (CAGradientLayer *)createFancyAnimatedGradientForView:(UIView *)view {
    CAGradientLayer *gradient = [CAGradientLayer layer];

       // 扩大尺寸以防旋转时露出黑边
       CGFloat extra = MAX(view.bounds.size.width, view.bounds.size.height);
       CGRect expandedFrame = CGRectInset(view.bounds, -extra * 0.3, -extra * 0.3);
       gradient.frame = expandedFrame;
       gradient.position = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    // 随机生成 6~10 个炫彩颜色
    NSMutableArray *colors = [NSMutableArray array];
    for (int i = 0; i < 8; i++) {
        UIColor *randomColor = [UIColor colorWithHue:(arc4random_uniform(256) / 255.0)
                                           saturation:0.7 + (arc4random_uniform(30) / 100.0)
                                           brightness:0.8 + (arc4random_uniform(20) / 100.0)
                                                alpha:1.0];
        [colors addObject:(__bridge id)randomColor.CGColor];
    }
    gradient.colors = colors;
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [view.layer insertSublayer:gradient atIndex:0];

    // 🔁 颜色自动切换动画
    CABasicAnimation *colorShift = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorShift.duration = 6.0;
    colorShift.toValue = ({
        NSMutableArray *newColors = [NSMutableArray array];
        for (int i = 0; i < 8; i++) {
            UIColor *color = [UIColor colorWithHue:(arc4random_uniform(256) / 255.0)
                                         saturation:0.6 + (arc4random_uniform(40) / 100.0)
                                         brightness:0.8 + (arc4random_uniform(20) / 100.0)
                                              alpha:1.0];
            [newColors addObject:(__bridge id)color.CGColor];
        }
        newColors;
    });
    colorShift.autoreverses = YES;
    colorShift.repeatCount = HUGE_VALF;
    [gradient addAnimation:colorShift forKey:@"randomColorPulse"];

    // 🔁 渐变方向变化动画（旋转感）
    CAKeyframeAnimation *rotateDirection = [CAKeyframeAnimation animationWithKeyPath:@"startPoint"];
    rotateDirection.values = @[
        [NSValue valueWithCGPoint:CGPointMake(0, 0)],
        [NSValue valueWithCGPoint:CGPointMake(1, 0)],
        [NSValue valueWithCGPoint:CGPointMake(1, 1)],
        [NSValue valueWithCGPoint:CGPointMake(0, 1)],
        [NSValue valueWithCGPoint:CGPointMake(0, 0)]
    ];
    rotateDirection.duration = 20.0;
    rotateDirection.repeatCount = HUGE_VALF;
    [gradient addAnimation:rotateDirection forKey:@"gradientRotation"];

    // 🔁 transform 缩放和旋转动画（制造背景波动感）
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @1.0;
    scaleAnim.toValue = @1.2;
    scaleAnim.duration = 10.0;
    scaleAnim.autoreverses = YES;
    scaleAnim.repeatCount = HUGE_VALF;
    [gradient addAnimation:scaleAnim forKey:@"scaleWave"];

    CABasicAnimation *spinAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spinAnim.fromValue = @(0);
    spinAnim.toValue = @(M_PI * 2);
    spinAnim.duration = 30.0;
    spinAnim.repeatCount = HUGE_VALF;
    [gradient addAnimation:spinAnim forKey:@"spinBackground"];

    return gradient;
}
+ (void)addAnimationsToGradientLayer:(CAGradientLayer *)gradient {
    // 颜色渐变动画
    CABasicAnimation *colorShift = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorShift.duration = 6.0;
    colorShift.toValue = ({
        NSMutableArray *newColors = [NSMutableArray array];
        for (int i = 0; i < 8; i++) {
            UIColor *color = [UIColor colorWithHue:(arc4random_uniform(256) / 255.0)
                                         saturation:0.6 + (arc4random_uniform(40) / 100.0)
                                         brightness:0.8 + (arc4random_uniform(20) / 100.0)
                                              alpha:1.0];
            [newColors addObject:(__bridge id)color.CGColor];
        }
        newColors;
    });
    colorShift.autoreverses = YES;
    colorShift.repeatCount = HUGE_VALF;
    [gradient addAnimation:colorShift forKey:@"randomColorPulse"];

    // 旋转方向变化动画
    CAKeyframeAnimation *rotateDirection = [CAKeyframeAnimation animationWithKeyPath:@"startPoint"];
    rotateDirection.values = @[
        [NSValue valueWithCGPoint:CGPointMake(0, 0)],
        [NSValue valueWithCGPoint:CGPointMake(1, 0)],
        [NSValue valueWithCGPoint:CGPointMake(1, 1)],
        [NSValue valueWithCGPoint:CGPointMake(0, 1)],
        [NSValue valueWithCGPoint:CGPointMake(0, 0)]
    ];
    rotateDirection.duration = 20.0;
    rotateDirection.repeatCount = HUGE_VALF;
    [gradient addAnimation:rotateDirection forKey:@"gradientRotation"];

    // 缩放动画
    CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.fromValue = @1.0;
    scaleAnim.toValue = @1.2;
    scaleAnim.duration = 10.0;
    scaleAnim.autoreverses = YES;
    scaleAnim.repeatCount = HUGE_VALF;
    [gradient addAnimation:scaleAnim forKey:@"scaleWave"];

    // 旋转动画
    CABasicAnimation *spinAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spinAnim.fromValue = @(0);
    spinAnim.toValue = @(M_PI * 2);
    spinAnim.duration = 30.0;
    spinAnim.repeatCount = HUGE_VALF;
    [gradient addAnimation:spinAnim forKey:@"spinBackground"];
}

+ (void)removeAnimationsFromLayer:(CALayer *)layer {
    [layer removeAllAnimations];
}
@end
