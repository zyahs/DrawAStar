//
//  rootVcViewController.m
//  JiFeng_UpApp
//
//  所有子页面都从这里继承,自动获得统一的玻璃胶囊返回按钮 + 侧滑返回手势支持。
//

#import "rootVcViewController.h"
#import "JFTheme.h"

@interface rootVcViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong, nullable) UIButton *jfBackButton;
@end

@implementation rootVcViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

#pragma mark - 默认仅支持竖屏(子类可覆盖,例如五子棋强制横屏)

- (BOOL)shouldAutorotate { return YES; }

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self jf_installBackIfNeeded];
}

#pragma mark - 返回按钮

- (void)jf_installBackIfNeeded {
    if (!self.navigationController) { return; }
    if (self.navigationController.viewControllers.firstObject == self) {
        // 根控制器不显示返回按钮
        [self.jfBackButton removeFromSuperview];
        self.jfBackButton = nil;
        return;
    }

    if (!self.jfBackButton) {
        UIButton *btn = [JFTheme backButtonWithTarget:self action:@selector(jf_goBack)];
        [self.view addSubview:btn];
        // 持续置顶,避免被子页面后续 addSubview 盖掉
        [self.view bringSubviewToFront:btn];
        self.jfBackButton = btn;

        UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [btn.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
            [btn.topAnchor     constraintEqualToAnchor:safe.topAnchor constant:JFSpacing8],
            [btn.widthAnchor   constraintEqualToConstant:40],
            [btn.heightAnchor  constraintEqualToConstant:40],
        ]];
    } else {
        [self.view bringSubviewToFront:self.jfBackButton];
    }

    // 保证侧滑返回手势可用
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)jf_goBack {
    [JFTheme hapticImpactLight];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 侧滑返回

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}

@end
