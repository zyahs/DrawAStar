//
//  XNBrokenAnimateViewController.h
//  OC
//
//  Created by codeIsMyGirl on 16/8/2.
//  Copyright © 2016年 codeIsMyGirl. All rights reserved.
//


#import <UIKit/UIKit.h>

//第一步:声明自己 ClassName: 文件名(类名)

@class XNBrokenAnimateViewController;

@protocol XNBrokenAnimateViewControllerDelegate <NSObject>

// 可选 注释表示 必须实现
//@optional

/// 代理方法 告诉 别人 我关闭了
- (void)delegateCallYouIClose:(UIViewController *)vc;

@end


@interface XNBrokenAnimateViewController : UIViewController

// 第二步:定义属性
/// 代理方法属性,在指定场合调用 告诉别人我关闭了
@property (nonatomic,weak) id<XNBrokenAnimateViewControllerDelegate> delegate;

@end
