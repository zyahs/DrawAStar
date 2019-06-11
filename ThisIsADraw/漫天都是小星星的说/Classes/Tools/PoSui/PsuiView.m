//
//  PsuiView.m
//  Protopia
//
//  Created by 飞奔的羊 on 2017/8/22.
//  Copyright © 2017年 Beijing Zhianyi Co, Ltd. All rights reserved.
//

#import "PsuiView.h"

@interface PsuiView ()

@end

@implementation PsuiView

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.layer.contents = (__bridge id _Nullable)(_image.CGImage);
//    self.view.frame = CGRectMake(-64, 0, WIDTH, HEIGHT);

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"2"] forBarMetrics:UIBarMetricsCompact];
    if ([self.navigationController.navigationBar respondsToSelector:@selector( setBackgroundImage:forBarMetrics:)]){
        NSArray *list=self.navigationController.navigationBar.subviews;
        
        for (id obj in list) {
            if ([obj isKindOfClass:[UIView class]]) {
                UIView *imageView1=(UIView *)obj;
                imageView1.hidden=YES;
            }
            
        }
        
    }
    for (UIImageView *im in self.navigationController.navigationBar.subviews) {
        if (im.tag == 100001) {
            im.hidden = YES;
        }
    }
    
    UIImageView *imae = [[UIImageView alloc]initWithFrame:CGRectMake(0, -64, WIDTH, HEIGHT)];
    imae.image = self.image;
    ZYLog(@"%@------%@",_image,_imaStr);
    [self.view addSubview:imae];
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"2"] forBarMetrics:UIBarMetricsCompact];
    if ([self.navigationController.navigationBar respondsToSelector:@selector( setBackgroundImage:forBarMetrics:)]){
        NSArray *list=self.navigationController.navigationBar.subviews;
        
        for (id obj in list) {
            if ([obj isKindOfClass:[UIView class]]) {
                UIView *imageView1=(UIView *)obj;
                imageView1.hidden=NO;
            }
            
        }
        
    }
    for (UIImageView *im in self.navigationController.navigationBar.subviews) {
        if (im.tag == 100001) {
            im.hidden = NO;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
