//
//  FiveQiVc.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/9/2.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "FiveQiVc.h"
#import "CheckerboardView.h"
#define ScreenW [UIScreen mainScreen].bounds.size.width

@interface FiveQiVc ()
@property (nonatomic,weak) CheckerboardView * boardView;
@property (nonatomic,weak) UIButton * backButton;
@property (nonatomic,weak) UIButton * reStartBtn;
@property (nonatomic,weak) UIButton * changeBoardButton;


@end
@implementation FiveQiVc



- (void)viewDidLoad {
	[super viewDidLoad];
	[self setUp];
	self.title = @"这是五子棋";
//	UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 30, 100, 100)];
	UIBarButtonItem *butt = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"FFTspark"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
	
	self.navigationController.navigationItem.leftBarButtonItem = butt;
//	[btn setTitle:@"back" forState:UIControlStateNormal];
//	[btn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
//	[self.view addSubview:btn];
}
- (void)back
{
	[self.navigationController popViewControllerAnimated:YES];
	
}

- (void)setUp{
	
	self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
	
	//添加棋盘
	CheckerboardView * boardView = [[CheckerboardView alloc]initWithFrame:CGRectMake(20, 30, ScreenW * 0.95, CGFLOAT_MAX)];
	boardView.center = self.view.center;
	[self.view addSubview:boardView];
	self.boardView = boardView;
	
	
	//悔棋
	UIButton * changeBoardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[changeBoardButton setTitle:@"初级棋盘" forState:UIControlStateNormal];
	[changeBoardButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	changeBoardButton.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
	changeBoardButton.frame = CGRectMake(CGRectGetMidX(boardView.frame) - CGRectGetWidth(boardView.frame) * 0.3, CGRectGetMinY(boardView.frame) - 50, CGRectGetWidth(boardView.frame) * 0.6, 35);
	changeBoardButton.layer.cornerRadius = 4;
	[self.view addSubview:changeBoardButton];
	self.changeBoardButton = changeBoardButton;
	[changeBoardButton addTarget:self action:@selector(changeBoard:) forControlEvents:UIControlEventTouchUpInside];
	
	
	//悔棋
	UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backButton setTitle:@"悔棋" forState:UIControlStateNormal];
	[backButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	backButton.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
	backButton.frame = CGRectMake(CGRectGetMinX(boardView.frame), CGRectGetMaxY(boardView.frame) + 15, CGRectGetWidth(boardView.frame) * 0.45, 30);
	backButton.layer.cornerRadius = 4;
	[self.view addSubview:backButton];
	self.backButton = backButton;
	[backButton addTarget:self action:@selector(backOneStep:) forControlEvents:UIControlEventTouchUpInside];
	
	//新游戏
	UIButton * reStartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[reStartBtn setTitle:@"新游戏" forState:UIControlStateNormal];
	reStartBtn.backgroundColor = [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
	reStartBtn.frame = CGRectMake(CGRectGetMaxX(boardView.frame) - CGRectGetWidth(boardView.frame) * 0.45, CGRectGetMaxY(boardView.frame) + 15, CGRectGetWidth(boardView.frame) * 0.45, 30);
	reStartBtn.layer.cornerRadius = 4;
	[self.view addSubview:reStartBtn];
	self.reStartBtn = reStartBtn;
	[reStartBtn addTarget:self action:@selector(newGame) forControlEvents:UIControlEventTouchUpInside];
}

- (void)backOneStep:(UIButton *)sender{
	[self.boardView backOneStep:(UIButton *)sender];
}

- (void)newGame{
	
	[self.boardView newGame];
}

- (void)changeBoard:(UIButton *)btn{
	
	[self.boardView changeBoardLevel];
	[_changeBoardButton setTitle:[btn.currentTitle isEqualToString:@"高级棋盘"]?@"初级棋盘":@"高级棋盘" forState:UIControlStateNormal];
}
@end
