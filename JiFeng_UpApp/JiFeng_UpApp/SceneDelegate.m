//
//  SceneDelegate.m
//  JiFeng_UpApp
//

#import "SceneDelegate.h"
#import "HomeViewController.h"
#import "JFAnalyticsTracker.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    HomeViewController *home = [[HomeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:home];
    nav.navigationBar.prefersLargeTitles = NO;
    [nav setNavigationBarHidden:YES animated:NO];

    self.window.rootViewController = nav;
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    [[JFAnalyticsTracker shared] flush];
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    [[JFAnalyticsTracker shared] sceneDidBecomeActive];
}
- (void)sceneWillResignActive:(UIScene *)scene {
    [[JFAnalyticsTracker shared] sceneWillResignActive];
}
- (void)sceneWillEnterForeground:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {
    [[JFAnalyticsTracker shared] flush];
}

@end
