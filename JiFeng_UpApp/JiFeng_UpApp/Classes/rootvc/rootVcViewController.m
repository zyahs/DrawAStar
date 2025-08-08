//
//  rootVcViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import "rootVcViewController.h"

@interface GradientBackgroundView : UIView
- (void)startAnimating;
- (void)stopAnimating;
@end

@interface GradientBackgroundView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat hue;
@end

@implementation GradientBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.frame = self.bounds;
        self.gradientLayer.startPoint = CGPointMake(0, 0);
        self.gradientLayer.endPoint = CGPointMake(1, 1);
        [self.layer addSublayer:self.gradientLayer];
        
        self.hue = 0;
        [self updateGradientColors];
    }
    return self;
}
- (void)stopAnimating {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)startAnimating {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGradient)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)updateGradient {
    self.hue += 0.002;
    if (self.hue > 1.0) self.hue -= 1.0;
    [self updateGradientColors];
}

- (void)updateGradientColors {
    UIColor *color1 = [UIColor colorWithHue:self.hue saturation:0.8 brightness:1 alpha:1];
    UIColor *color2 = [UIColor colorWithHue:fmod(self.hue + 0.33, 1.0) saturation:0.8 brightness:1 alpha:1];
    UIColor *color3 = [UIColor colorWithHue:fmod(self.hue + 0.66, 1.0) saturation:0.8 brightness:1 alpha:1];
    
    self.gradientLayer.colors = @[
        (id)color1.CGColor,
        (id)color2.CGColor,
        (id)color3.CGColor
    ];
}

@end


@interface rootVcViewController ()
@property (nonatomic, strong) GradientBackgroundView *gradientView;
@end

@implementation rootVcViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.gradientView startAnimating];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.gradientView = [[GradientBackgroundView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.gradientView atIndex:0];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.gradientView stopAnimating];
}

- (void)dealloc {
    [self.gradientView removeFromSuperview];
    self.gradientView = nil;
}
@end
