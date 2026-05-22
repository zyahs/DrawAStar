//
//  AppDelegate.m
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/8/5.
//

#import "AppDelegate.h"
#import "JFNotificationScheduler.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 申请通知权限并安排周报(每周日 20:00 推送本周战绩)
    [[JFNotificationScheduler shared] setupOnLaunch];
    return YES;
}

#pragma mark - 屏幕方向

/// 把方向控制下沉到当前 keyWindow 的 rootVC,这样具体页面通过
/// supportedInterfaceOrientations 即可独立决定支持的方向(默认竖屏,
/// 五子棋页面强制横屏)。
- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    UIViewController *root = window.rootViewController;
    UIViewController *top = [self jf_topMostFor:root];
    if (top) {
        return top.supportedInterfaceOrientations;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (UIViewController *)jf_topMostFor:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self jf_topMostFor:[(UINavigationController *)vc topViewController]];
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self jf_topMostFor:[(UITabBarController *)vc selectedViewController]];
    }
    if (vc.presentedViewController) {
        return [self jf_topMostFor:vc.presentedViewController];
    }
    return vc;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
