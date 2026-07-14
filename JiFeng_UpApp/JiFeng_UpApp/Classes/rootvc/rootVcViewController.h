//
//  rootVcViewController.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface rootVcViewController : UIViewController

@property (nonatomic, strong, nullable, readonly) UIView *jfThemeBackgroundView;
@property (nonatomic, assign) BOOL jfSuppressBackButton;

/// 子类可覆盖。画板这类页面需要纯黑/自定义背景时返回 NO。
- (BOOL)jf_prefersThemedBackground;

@end

NS_ASSUME_NONNULL_END
