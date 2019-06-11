//
//  ProtopiaWebViewController.h
//  Protopia
//
//  Created by 飞奔的羊 on 16/12/7.
//  Copyright © 2016年 Beijing Zhianyi Co, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProtopiaWebViewController : UIViewController
@property (strong, nonatomic)UIWebView * webView;
@property (strong, nonatomic)UILabel * labUrl;
/**
 *  网址
 */
@property (nonatomic,copy) NSString * WebUrlStr;
/**
 *  标题
 */
@property (nonatomic,copy) NSString * TitleStr;
//-(void)getParam1:(NSString*)str1 withParam2:(NSString*)str2;

@end
