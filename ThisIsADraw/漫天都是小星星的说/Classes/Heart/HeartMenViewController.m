//
//  HeartMenViewController.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/11/26.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "HeartMenViewController.h"

@interface HeartMenViewController ()

/**
 *  返回
 */
@property (nonatomic,strong) UIButton *backButton;
@end

@implementation HeartMenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
//	self.view.backgroundColor = [UIColor blueColor];
	self.navigationController.navigationBar.hidden = YES;
	
	if ([self.navigationController.navigationBar respondsToSelector:@selector( setBackgroundImage:forBarMetrics:)]){
		NSArray *list=self.navigationController.navigationBar.subviews;
		
		for (id obj in list) {
			if ([obj isKindOfClass:[UIImageView class]]) {
				UIImageView *imageView=(UIImageView *)obj;
				imageView.hidden=YES;
			}
		}
	}
	[self.view addSubview:self.backButton];
}

- (UIButton *)backButton
{
	if (!_backButton) {
		_backButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 20, 20)];
		[_backButton setBackgroundColor:[UIColor purpleColor]];
		_backButton.titleLabel.text = @"返回" ;
		[_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
	}
	return _backButton;
}

- (void)back
{
	[self.navigationController popViewControllerAnimated:YES];


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
