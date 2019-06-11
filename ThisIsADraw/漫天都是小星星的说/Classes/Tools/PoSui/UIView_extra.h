//
//  UIView_extra.h
//  Woyoli
//
//  Created by jamie on 14-11-25.
//  Copyright (c) 2014年 Missionsky. All rights reserved.
//

#define vAlertTag    10086

#import <UIKit/UIKit.h>

@interface UIView (UIView)

@property (nonatomic, assign) CGFloat   x; 

@property (nonatomic, assign) CGFloat   y; 

@property (nonatomic, assign) CGFloat   width; 

@property (nonatomic, assign) CGFloat   height; 

@property (nonatomic, assign) CGPoint   origin; 

@property (nonatomic, assign) CGSize    size; 

@property (nonatomic, assign) CGFloat   bottom; 

@property (nonatomic, assign) CGFloat   right; 

@property (nonatomic, assign) CGFloat   centerX; 

@property (nonatomic, assign) CGFloat   centerY; 

@property (nonatomic, strong, readonly) UIView *lastSubviewOnX; 

@property (nonatomic, strong, readonly) UIView *lastSubviewOnY; 


/*
 
 //弹框使用:
 
 UIAlertViewDelegate
 
 [UIView showAlertView:@"111" andMessage:@"222" withDelegate:self];
 
 // 配合上面点击确定调用此方法
 - (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
 
 // actionsheet的监听  buttonIndex :从上往下 从0依次递增
 if (buttonIndex == 0) {
 
 NSLog(@"选择了");
 }
 
 
 }
 
 */

/**
 * @brief 移除此view上的所有子视图
 */
- (void)removeAllSubviews; 


/**
 @brief 弹窗
 @param title 弹窗标题
        message 弹窗信息
 */
+ (void) showAlertView: (NSString*) title andMessage: (NSString *) message; 


/**
 *  弹窗
 *
 *  @param title    弹窗标题
 *  @param message  弹窗信息
 *  @param delegate 弹窗代理
 */
+ (void) showAlertView: (NSString*) title
            andMessage: (NSString *) message
          withDelegate: (UIViewController<UIAlertViewDelegate> *) delegate; 


@end
