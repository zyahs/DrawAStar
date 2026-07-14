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

@interface JFThemeBackgroundView : UIView
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation JFThemeBackgroundView

- (instancetype)init {
    if (self = [super init]) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0.08, 0.0);
        _gradientLayer.endPoint = CGPointMake(0.92, 1.0);
        [self.layer addSublayer:_gradientLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

@end

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
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    return s.backgroundTop ?: [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:1.0];
}
+ (UIColor *)backgroundSecondary {
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    UIColor *bottom = s.backgroundBottom ?: [UIColor colorWithRed:0.10 green:0.10 blue:0.16 alpha:1.0];
    return [bottom colorWithAlphaComponent:0.84];
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

+ (NSArray<UIColor *> *)appBackgroundColors {
    JFSkin *s = [[JFSkinStore shared] currentSkin];
    UIColor *top = s.backgroundTop ?: [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:1.0];
    UIColor *bottom = s.backgroundBottom ?: [UIColor colorWithRed:0.12 green:0.06 blue:0.22 alpha:1.0];
    return @[top, [self brandPrimary], bottom];
}

+ (NSString *)themePatternStyle {
    return [[JFSkinStore shared] currentSkin].patternStyle ?: @"stars";
}

+ (NSString *)themeSymbolName {
    return [[JFSkinStore shared] currentSkin].symbolName ?: @"sparkles";
}

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

+ (void)decorateGlassPanel:(UIView *)view {
    view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.075];
    view.layer.cornerRadius = JFRadiusLarge;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14].CGColor;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.28;
    view.layer.shadowRadius = 18;
    view.layer.shadowOffset = CGSizeMake(0, 10);
}

+ (UIView *)installThemedBackgroundInView:(UIView *)view {
    JFThemeBackgroundView *container = [[JFThemeBackgroundView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.userInteractionEnabled = NO;
    [view insertSubview:container atIndex:0];

    NSArray<UIColor *> *colors = [self appBackgroundColors];
    container.gradientLayer.colors = @[(__bridge id)colors[0].CGColor,
                                       (__bridge id)colors[1].CGColor,
                                       (__bridge id)colors[2].CGColor];

    UIView *pattern = [self patternViewWithStyle:[self themePatternStyle] symbol:[self themeSymbolName]];
    pattern.translatesAutoresizingMaskIntoConstraints = NO;
    pattern.alpha = 0.18;
    [container addSubview:pattern];

    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:view.topAnchor],
        [container.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [container.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [container.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],

        [pattern.topAnchor constraintEqualToAnchor:container.topAnchor],
        [pattern.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [pattern.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [pattern.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];

    return container;
}

+ (UIView *)patternViewWithStyle:(NSString *)style symbol:(NSString *)symbol {
    UIView *view = [[UIView alloc] init];
    NSArray<NSString *> *symbols = [self symbolsForPattern:style fallback:symbol];
    NSInteger columns = 5;
    NSInteger rows = 9;
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < columns; col++) {
            NSString *name = symbols[(row + col) % symbols.count];
            UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:name]];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            iv.tintColor = [UIColor whiteColor];
            iv.alpha = 0.24 + ((row + col) % 3) * 0.08;
            iv.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:18 + ((row + col) % 3) * 5 weight:UIImageSymbolWeightBold];
            [view addSubview:iv];
            [NSLayoutConstraint activateConstraints:@[
                [iv.centerXAnchor constraintEqualToAnchor:view.leadingAnchor constant:42 + col * 76 + (row % 2) * 28],
                [iv.centerYAnchor constraintEqualToAnchor:view.topAnchor constant:56 + row * 92],
            ]];
        }
    }
    return view;
}

+ (NSArray<NSString *> *)symbolsForPattern:(NSString *)style fallback:(NSString *)fallback {
    if ([style isEqualToString:@"bows"]) return @[@"gift.fill", @"heart.fill", @"sparkle"];
    if ([style isEqualToString:@"monsters"]) return @[@"bolt.fill", @"circle.hexagongrid.fill", @"leaf.fill"];
    if ([style isEqualToString:@"bubbles"]) return @[@"drop.fill", @"circle.fill", @"sparkles"];
    if ([style isEqualToString:@"leaves"]) return @[@"leaf.fill", @"tree.fill", @"sparkle"];
    if ([style isEqualToString:@"petals"]) return @[@"camera.macro", @"heart.fill", @"circle.fill"];
    if ([style isEqualToString:@"neon"]) return @[@"waveform.path.ecg", @"bolt.fill", @"sparkles"];
    if ([style isEqualToString:@"medals"]) return @[@"crown.fill", @"medal.fill", @"star.fill"];
    if ([style isEqualToString:@"sunset"]) return @[@"sun.max.fill", @"sparkles", @"circle.fill"];
    if ([style isEqualToString:@"custom"]) return @[@"slider.horizontal.3", @"paintpalette.fill", @"sparkles"];
    return @[fallback ?: @"sparkles", @"star.fill", @"circle.fill"];
}

+ (UIVisualEffectView *)glassBlurView {
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    return [[UIVisualEffectView alloc] initWithEffect:blur];
}

+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;

    // 统一返回按钮:主题色描边 + 玻璃底
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
    btn.layer.borderWidth = 1.0;
    btn.layer.borderColor = [[self accent] colorWithAlphaComponent:0.55].CGColor;
    btn.layer.shadowColor = [self accent].CGColor;
    btn.layer.shadowOpacity = 0.22;
    btn.layer.shadowRadius = 10;
    btn.layer.shadowOffset = CGSizeZero;
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
