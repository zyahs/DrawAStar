//
//  JFTheme.h
//  JiFeng_UpApp
//
//  统一设计 token —— 颜色、间距、圆角、字体、阴影。
//  所有页面应该引用这里的常量,避免硬编码魔法值。
//  风格基线:iOS 17+ 现代化卡片 + 渐变。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 间距 / 圆角

extern const CGFloat JFSpacing4;     // 4
extern const CGFloat JFSpacing8;     // 8
extern const CGFloat JFSpacing12;    // 12
extern const CGFloat JFSpacing16;    // 16
extern const CGFloat JFSpacing20;    // 20
extern const CGFloat JFSpacing24;    // 24
extern const CGFloat JFSpacing32;    // 32

extern const CGFloat JFRadiusSmall;  // 10
extern const CGFloat JFRadiusMedium; // 16
extern const CGFloat JFRadiusLarge;  // 24
extern const CGFloat JFRadiusPill;   // 999 —— 胶囊

#pragma mark - JFTheme

@interface JFTheme : NSObject

#pragma mark 主色 / 文字

+ (UIColor *)brandPrimary;     // 主品牌色,按钮、强调
+ (UIColor *)brandSecondary;   // 次品牌色
+ (UIColor *)accent;           // 强调亮色

+ (UIColor *)backgroundPrimary;     // 一级背景(深色)
+ (UIColor *)backgroundSecondary;   // 卡片底
+ (UIColor *)backgroundElevated;    // 浮层 / 弹窗
+ (NSArray<UIColor *> *)appBackgroundColors;
+ (NSString *)themePatternStyle;
+ (NSString *)themeSymbolName;

+ (UIColor *)textPrimary;      // 一级文本(白)
+ (UIColor *)textSecondary;    // 二级文本(灰)
+ (UIColor *)textTertiary;     // 占位
+ (UIColor *)textOnAccent;     // 在主色上的文字(白)

+ (UIColor *)separator;        // 分割线
+ (UIColor *)cardBorder;       // 卡片描边

+ (UIColor *)success;
+ (UIColor *)danger;
+ (UIColor *)warning;

#pragma mark 字体

+ (UIFont *)fontTitleXL;       // 32 bold 主页 hero
+ (UIFont *)fontTitle;         // 24 bold 页面标题
+ (UIFont *)fontHeadline;      // 18 semibold 卡片标题
+ (UIFont *)fontBody;          // 16 regular 正文
+ (UIFont *)fontCallout;       // 15 medium 按钮
+ (UIFont *)fontCaption;       // 12 regular 辅助文字

#pragma mark 阴影 / 渐变 / 卡片

/// 给 view 上一层标准卡片阴影
+ (void)applyCardShadow:(UIView *)view;

/// 把 layer 装饰为标准卡片样式(圆角 + 描边 + 背景色)
+ (void)decorateCardLayer:(CALayer *)layer;

/// 标准模糊效果(暗色玻璃)
+ (UIVisualEffectView *)glassBlurView;

/// 全局主题背景:渐变 + 图案层。返回添加的容器 view,调用方可保留并置底。
+ (UIView *)installThemedBackgroundInView:(UIView *)view;

/// 统一玻璃卡片质感
+ (void)decorateGlassPanel:(UIView *)view;

/// 标准返回按钮 —— 玻璃模糊胶囊 + chevron。
/// target/action 由调用方决定;按钮已设好 translatesAutoresizingMaskIntoConstraints=NO,
/// 推荐尺寸 40~44 高度,加 leading/top 安全区约束即可。
+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action;

#pragma mark 渐变工具

/// 主页/卡片用的渐变(根据 index 取一组,共 8 组,色调互不重复)
+ (NSArray<UIColor *> *)gradientColorsForIndex:(NSInteger)index;

/// 触觉反馈 —— 轻击
+ (void)hapticImpactLight;
/// 触觉反馈 —— 中击
+ (void)hapticImpactMedium;
/// 触觉反馈 —— 选择
+ (void)hapticSelection;
/// 触觉反馈 —— 通知(成功/失败)
+ (void)hapticNotification:(UINotificationFeedbackType)type;

@end

NS_ASSUME_NONNULL_END
