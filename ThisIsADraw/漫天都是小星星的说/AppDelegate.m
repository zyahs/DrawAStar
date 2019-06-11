//
//  AppDelegate.m
//  漫天都是小星星的说
//
//  Created by 飞奔的羊 on 16/3/21.
//  Copyright © 2016年 itcast. All rights reserved.
//

#import "AppDelegate.h"
#import <AVOSCloud/AVOSCloud.h>
#import "FiveQiVc.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [AVOSCloud setApplicationId:@"lfndsiRdOHdqJ0lFfsH9Rv1v-gzGzoHsz" clientKey:@"sNQGOzYovMIOUnICNycgoWpn"];
    [AVCloud setProductionMode:YES];
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [self creatShortcutItem];  //动态创建应用图标上的3D touch快捷选项
    
    UIApplicationShortcutItem *shortcutItem = [launchOptions valueForKey:UIApplicationLaunchOptionsShortcutItemKey];
    //如果是从快捷选项标签启动app，则根据不同标识执行不同操作，然后返回NO，防止调用- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
    if (shortcutItem) {
        //判断设置的快捷选项标签唯一标识，根据不同标识执行不同操作
        if([shortcutItem.type isEqualToString:@"com.yang.one"]){
            NSLog(@"新启动APP-- 第一个按钮");
        } else if ([shortcutItem.type isEqualToString:@"com.yang.search"]) {
            //进入搜索界面
            NSLog(@"新启动APP-- 搜索");
        } else if ([shortcutItem.type isEqualToString:@"com.yang.add"]) {
            //进入分享界面
            NSLog(@"新启动APP-- 添加联系人");
        }else if ([shortcutItem.type isEqualToString:@"com.yang.share"]) {
            //进入分享页面
            FiveQiVc *five = [[FiveQiVc alloc]init];
            
            
            UINavigationController *nav = (UINavigationController*) (self.window.rootViewController);
            
            //    nav.selectedIndex = 2;
            
            
            
            
            
            [nav popToRootViewControllerAnimated:YES];
            
            
            [nav pushViewController:five animated:NO];
            NSLog(@"新启动APP-- 分享");
        }
        
        return NO;
    }
    
    
    return YES;
}


- (void)creatShortcutItem {
    //创建系统风格的icon
    UIApplicationShortcutIcon *icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeShare];
    //创建快捷选项
    UIApplicationShortcutItem * item = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"分享" localizedSubtitle:@"分享副标题" icon:icon userInfo:nil];
    UIApplicationShortcutIcon *icon1 = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCompose];
        UIApplicationShortcutItem * item1 = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"发文" localizedSubtitle:@"发表心情" icon:icon1 userInfo:nil];
        UIApplicationShortcutItem * item2 = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"分享" localizedSubtitle:@"分享副标题" icon:icon userInfo:nil];
        UIApplicationShortcutItem * item3 = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"分享" localizedSubtitle:@"分享副标题" icon:icon userInfo:nil];
        UIApplicationShortcutItem * item4 = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"分享" localizedSubtitle:@"分享副标题" icon:icon userInfo:nil];
//        UIApplicationShortcutItem * item5 = [[UIApplicationShortcutItem alloc]initWithType:@"com.yang.share" localizedTitle:@"分享" localizedSubtitle:@"分享副标题" icon:icon userInfo:nil];
    
    //添加到快捷选项数组
    [UIApplication sharedApplication].shortcutItems = @[item,item1,item2,item3,item4];
}
//如果APP没被杀死，还存在后台，点开Touch会调用该代理方法
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (shortcutItem) {
        //判断设置的快捷选项标签唯一标识，根据不同标识执行不同操作
        if([shortcutItem.type isEqualToString:@"com.yang.one"]){
            NSLog(@"APP没被杀死-- 第一个按钮");
            
          
          
        } else if ([shortcutItem.type isEqualToString:@"com.yang.search"]) {
            //进入搜索界面
            NSLog(@"APP没被杀死-- 搜索");
        } else if ([shortcutItem.type isEqualToString:@"com.yang.add"]) {
            //进入分享界面吃
            NSLog(@"APP没被杀死-- 添加联系人");
            
        }else if ([shortcutItem.type isEqualToString:@"com.yang.share"]) {
            //进入分享页面
            FiveQiVc *five = [[FiveQiVc alloc]init];
            
            
            UINavigationController *nav = (UINavigationController*) (self.window.rootViewController);
            
            //    nav.selectedIndex = 2;
            
            
            
            
            
            [nav popToRootViewControllerAnimated:YES];
            
            
            [nav pushViewController:five animated:NO];
            NSLog(@"APP没被杀死-- 分享");
        }
    }else{
        
        
    }
    
    if (completionHandler) {
        completionHandler(YES);
    }
    
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
