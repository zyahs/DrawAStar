//
//  JFTheme.m
//  JiFeng_UpApp
//

#import "JFTheme.h"
#import "JFSkinStore.h"

const CGFloat JFSpacing4  = 4;
const CGFloat JFSpacing8  = 8;
const CGFloat JFSpacing12 = 12;
const CGFloat JFSpacing16 = 16;
const CGFloat JFSpacing20 = 20;
const CGFloat JFSpacing24 = 24;
const CGFloat JFSpacing32 = 32;

const CGFloat JFRadiusSmall  = 10;
const CGFloat JFRadiusMedium = 16;
const CGFloat JFRadiusLarge  = 24;
const CGFloat JFRadiusPill   = 999;

@implementation JFTheme

#pragma mark - 颜色

+ (UIColor *)brandPrimary {
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    return s.brandPrimary ?: [UIColor colorWithRed:0.46 green:0.42 blue:0.95 alpha:1.0];
}
+ (UIColor *)brandSecondary {
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    return s.brandSecondary ?: [UIColor colorWithRed:0.96 green:0.45 blue:0.78 alpha:1.0];
}
+ (UIColor *)accent {
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    return s.accent ?: [UIColor colorWithRed:0.20 green:0.85 blue:0.78 alpha:1.0];
}

+ (UIColor *)backgroundPrimary {
    return [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:1.0];
}
+ (UIColor *)backgroundSecondary {
    return [UIColor colorWithRed:0.10 green:0.10 blue:0.16 alpha:1.0];
}
+ (UIColor *)backgroundElevated {
    return [UIColor colorWithRed:0.14 green:0.14 blue:0.20 alpha:1.0];
}

+ (UIColor *)textPrimary   { return [UIColor whiteColor]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:1.0 alpha:0.72]; }
+ (UIColor *)textTertiary  { return [UIColor colorWithWhite:1.0 alpha:0.45]; }
+ (UIColor *)textOnAccent  { return [UIColor whiteColor]; }

+ (UIColor *)separator     { return [UIColor colorWithWhite:1.0 alpha:0.10]; }
+ (UIColor *)cardBorder    { return [UIColor colorWithWhite:1.0 alpha:0.14]; }

+ (UIColor *)success { return [UIColor colorWithRed:0.30 green:0.85 blue:0.55 alpha:1.0]; }
+ (UIColor *)danger  { return [UIColor colorWithRed:0.98 green:0.36 blue:0.42 alpha:1.0]; }
+ (UIColor *)warning { return [UIColor colorWithRed:0.99 green:0.78 blue:0.30 alpha:1.0]; }

#pragma mark - 字体

+ (UIFont *)fontTitleXL  { return [UIFont systemFontOfSize:32 weight:UIFontWeightBold]; }
+ (UIFont *)fontTitle    { return [UIFont systemFontOfSize:24 weight:UIFontWeightBold]; }
+ (UIFont *)fontHeadline { return [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]; }
+ (UIFont *)fontBody     { return [UIFont systemFontOfSize:16 weight:UIFontWeightRegular]; }
+ (UIFont *)fontCallout  { return [UIFont systemFontOfSize:15 weight:UIFontWeightMedium]; }
+ (UIFont *)fontCaption  { return [UIFont systemFontOfSize:12 weight:UIFontWeightRegular]; }

#pragma mark - 卡片 / 阴影

+ (void)applyCardShadow:(UIView *)view {
    view.layer.shadowColor   = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.25;
    view.layer.shadowRadius  = 14;
    view.layer.shadowOffset  = CGSizeMake(0, 6);
}

+ (void)decorateCardLayer:(CALayer *)layer {
    layer.cornerRadius   = JFRadiusMedium;
    layer.cornerCurve    = kCACornerCurveContinuous;
    layer.borderWidth    = 1.0;
    layer.borderColor    = [self cardBorder].CGColor;
    layer.backgroundColor = [self backgroundSecondary].CGColor;
    layer.masksToBounds  = NO;
}

+ (UIVisualEffectView *)glassBlurView {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    return [[UIVisualEffectView alloc] initWithEffect:blur];
}

+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;

    // 玻璃胶囊
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    UIVisualEffectView *bg = [[UIVisualEffectView alloc] initWithEffect:blur];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.userInteractionEnabled = NO;
    bg.layer.cornerRadius = JFRadiusPill;
    bg.layer.cornerCurve = kCACornerCurveContinuous;
    bg.clipsToBounds = YES;
    [btn insertSubview:bg atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [bg.topAnchor      constraintEqualToAnchor:btn.topAnchor],
        [bg.leadingAnchor  constraintEqualToAnchor:btn.leadingAnchor],
        [bg.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor],
        [bg.bottomAnchor   constraintEqualToAnchor:btn.bottomAnchor],
    ]];

    btn.layer.cornerRadius = JFRadiusPill;
    btn.layer.cornerCurve = kCACornerCurveContinuous;
    btn.layer.borderWidth = 0.5;
    btn.layer.borderColor = [self cardBorder].CGColor;
    btn.tintColor = [self textPrimary];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightSemibold];
    UIImage *img = [UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg];
    [btn setImage:img forState:UIControlStateNormal];

    if (target && action) {
        [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return btn;
}

#pragma mark - 渐变

+ (NSArray<UIColor *> *)gradientColorsForIndex:(NSInteger)index {
    // 8 组渐变,色相分布均匀,饱和度/明度统一,保证视觉一致
    static NSArray<NSArray<UIColor *> *> *_palette;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _palette = @[
            // 紫 -> 蓝
            @[[UIColor colorWithRed:0.55 green:0.36 blue:0.96 alpha:1],
              [UIColor colorWithRed:0.30 green:0.50 blue:0.99 alpha:1]],
            // 粉 -> 橙
            @[[UIColor colorWithRed:0.99 green:0.40 blue:0.62 alpha:1],
              [UIColor colorWithRed:0.99 green:0.65 blue:0.36 alpha:1]],
            // 青 -> 绿
            @[[UIColor colorWithRed:0.20 green:0.78 blue:0.93 alpha:1],
              [UIColor colorWithRed:0.30 green:0.88 blue:0.62 alpha:1]],
            // 玫红 -> 紫
            @[[UIColor colorWithRed:0.95 green:0.32 blue:0.72 alpha:1],
              [UIColor colorWithRed:0.55 green:0.30 blue:0.95 alpha:1]],
            // 金 -> 红
            @[[UIColor colorWithRed:0.99 green:0.78 blue:0.30 alpha:1],
              [UIColor colorWithRed:0.99 green:0.40 blue:0.40 alpha:1]],
            // 蓝 -> 青
            @[[UIColor colorWithRed:0.32 green:0.50 blue:0.97 alpha:1],
              [UIColor colorWithRed:0.20 green:0.85 blue:0.92 alpha:1]],
            // 绿 -> 黄
            @[[UIColor colorWithRed:0.30 green:0.78 blue:0.55 alpha:1],
              [UIColor colorWithRed:0.95 green:0.85 blue:0.35 alpha:1]],
            // 红 -> 紫
            @[[UIColor colorWithRed:0.97 green:0.36 blue:0.45 alpha:1],
              [UIColor colorWithRed:0.62 green:0.34 blue:0.94 alpha:1]],
        ];
    });
    NSInteger i = ((index % _palette.count) + _palette.count) % _palette.count;
    return _palette[i];
}

#pragma mark - 触觉

+ (void)hapticImpactLight {
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [g impactOccurred];
}
+ (void)hapticImpactMedium {
    UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [g impactOccurred];
}
+ (void)hapticSelection {
    UISelectionFeedbackGenerator *g = [[UISelectionFeedbackGenerator alloc] init];
    [g selectionChanged];
}
+ (void)hapticNotification:(UINotificationFeedbackType)type {
    UINotificationFeedbackGenerator *g = [[UINotificationFeedbackGenerator alloc] init];
    [g notificationOccurred:type];
}

@end
