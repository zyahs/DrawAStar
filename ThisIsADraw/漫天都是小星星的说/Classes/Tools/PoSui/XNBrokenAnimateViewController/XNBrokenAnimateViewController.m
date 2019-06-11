//
//  XNBrokenAnimateViewController.m
//  OC
//
//  Created by codeIsMyGirl on 16/8/2.
//  Copyright © 2016年 codeIsMyGirl. All rights reserved.
//
 

#import "XNBrokenAnimateViewController.h"

#import "ZBFallenBricksAnimator.h"
#import "UIView_extra.h"

@interface XNBrokenAnimateViewController ()<UINavigationControllerDelegate>

@end

@implementation XNBrokenAnimateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.delegate = self;
    
//    // 设置整个控制器的背景图片
//    self.view.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"leimu"].CGImage);

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UINavigationControllerDelegate

#pragma mark - pop结束前调用
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    NSObject <UIViewControllerAnimatedTransitioning> *animator;
    
    // create
    animator = [[ZBFallenBricksAnimator alloc] init];
    
    return animator;
}


// =============================================================================
#pragma mark - IBAction

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
 
    //判断代理方法是否实现
    if ([self.delegate respondsToSelector:@selector(delegateCallYouIClose:)]) {
        
        // 第三步:调用代理方法
        [self.delegate delegateCallYouIClose:self];
    }
 
    [self.navigationController popViewControllerAnimated:YES];
    
}
@end

