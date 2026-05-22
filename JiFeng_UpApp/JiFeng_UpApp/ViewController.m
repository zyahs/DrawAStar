//
//  ViewController.m
//  JiFeng_UpApp
//
//  注意:此类已弃用 —— 启动入口由 SceneDelegate 直接装配 HomeViewController。
//  保留这个空壳的原因:Main.storyboard 的初始场景仍然 customClass="ViewController",
//  storyboard 资源被打包后会引用此类名,直接删除会导致 storyboardWithName:@"Main"
//  加载失败(画板页 storyboardID = 778 仍走 storyboard 实例化)。
//
//  不要在这里再加业务代码;新功能请加到 HomeViewController。
//

#import "ViewController.h"
#import "HomeViewController.h"

@implementation ViewController

// 兜底:万一被外部实例化,也把它替换为新主页,避免显示空白。
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.navigationController.viewControllers.firstObject == self) {
        HomeViewController *home = [[HomeViewController alloc] init];
        [self.navigationController setViewControllers:@[home] animated:NO];
    }
}

@end
