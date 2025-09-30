//
//  rootVcViewController.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/8.
//

#import "rootVcViewController.h"
#import <UIKit/UIKit.h>

@interface rootVcViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *backButton;
@end

@implementation rootVcViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self jf_installBackIfNeeded];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 确保导航栏隐藏
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

#pragma mark - Back Button

- (void)jf_installBackIfNeeded {
    // 只有当当前控制器不是栈底（root）时才显示返回按钮
    if (!self.navigationController) { return; }
    if (self.navigationController.viewControllers.firstObject == self) {
        // 如果是根控制器，移除返回按钮
        [self.backButton removeFromSuperview];
        self.backButton = nil;
        return;
    }
    
    if (!self.backButton) {
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *img = [UIImage imageNamed:@"back"];
        [backButton setImage:img forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, 0, 30, 30);
        [backButton addTarget:self action:@selector(jf_goBack) forControlEvents:UIControlEventTouchUpInside];
        self.backButton = backButton;
        [self.view addSubview:backButton];
        
        backButton.translatesAutoresizingMaskIntoConstraints = NO;
        UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [backButton.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16],
            [backButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:10],
            [backButton.widthAnchor constraintEqualToConstant:30],
            [backButton.heightAnchor constraintEqualToConstant:30]
        ]];
    }
    
    // 修复自定义返回按钮导致侧滑返回手势失效的问题
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)jf_goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 仅当栈中有上一层时允许侧滑返回
    return self.navigationController.viewControllers.count > 1;
}

@end
