//
//  ProtopiaWebViewController.m
//  Protopia
//
//  Created by 飞奔的羊 on 16/12/7.
//  Copyright © 2016年 Beijing Zhianyi Co, Ltd. All rights reserved.
//

#import "ProtopiaWebViewController.h"

@interface ProtopiaWebViewController ()<UIWebViewDelegate>
@property (strong, nonatomic)UIBarButtonItem * leftItem;
@property (strong, nonatomic)UIButton * btnSure;
/**
 *  网页
 */

@end

@implementation ProtopiaWebViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
        self.title =@"桃源用户协议";
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0 , 100, 44)];
    titleLabel.backgroundColor = [UIColor clearColor];  //设置Label背景透明
    titleLabel.font = [UIFont boldSystemFontOfSize:20];  //设置文本字体与大小
    titleLabel.textColor = [UIColor redColor];  //设置文本颜色
    titleLabel.textAlignment = NSTextAlignmentCenter;
    if (!self.TitleStr) {
        self.TitleStr = @"桃源用户协议";
    }
//    titleLabel.text = self.TitleStr;  //设置标题
    self.navigationItem.titleView = titleLabel;
	self.navigationItem.leftBarButtonItem = self.leftItem;
//	self.navigationController.navigationBar.backgroundColor = [UIColor orangeColor];
//    NSArray *list=self.navigationController.navigationBar.subviews;
//    for (id obj in list) {
//        if ([obj isKindOfClass:[UIButton class]]) {
//            UIButton *imageView1=(UIButton *)obj;
//            if (imageView1.tag == 10009||imageView1.tag == 10008) {
//                imageView1.hidden = YES;
//            }
//        }
//    }
//
//
//
//        for (id obj in list) {
//            if ([obj isKindOfClass:[UIImageView class]]) {
//                UIImageView *imageView=(UIImageView *)obj;
//                imageView.hidden=YES;
//            }
//        }
	
//	self.navigationController.navigationBar.barTintColor = [UIColor orangeColor];
}



- (void)viewDidLoad {
    [super viewDidLoad];
	
	


	 
	 
	 
 
	
	NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.WebUrlStr]];
    
    
	[self.webView loadRequest:req];
	
    
    [self.view addSubview:self.webView];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UIWebView *)webView{
	if (!_webView) {
		_webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
		_webView.backgroundColor = [UIColor whiteColor];
	}
	return _webView;
}

- (UIBarButtonItem *)leftItem{
	if (!_leftItem) {
		_leftItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backMethod)];
		_leftItem.tintColor = [UIColor redColor];
	}
	return _leftItem;
}
- (void)backMethod{
	if ([self.navigationController.navigationBar respondsToSelector:@selector( setBackgroundImage:forBarMetrics:)]){
		NSArray *list=self.navigationController.navigationBar.subviews;
		
		for (id obj in list) {
			if ([obj isKindOfClass:[UIImageView class]]) {
				UIImageView *imageView=(UIImageView *)obj;
				imageView.hidden=YES;
			}
		}
	}
	[self.navigationController popViewControllerAnimated:YES];
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
