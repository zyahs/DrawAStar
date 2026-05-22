//
//  JFNotificationScheduler.m
//  JiFeng_UpApp
//

#import "JFNotificationScheduler.h"
#import "JFProfileStore.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kWeeklyDigestId = @"jf_weekly_digest";

@implementation JFNotificationScheduler

+ (instancetype)shared {
    static JFNotificationScheduler *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)setupOnLaunch {
    UNUserNotificationCenter *c = [UNUserNotificationCenter currentNotificationCenter];
    [c requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                     completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self rescheduleWeeklyDigest];
            });
        }
    }];
}

- (void)rescheduleWeeklyDigest {
    UNUserNotificationCenter *c = [UNUserNotificationCenter currentNotificationCenter];
    [c removePendingNotificationRequestsWithIdentifiers:@[kWeeklyDigestId]];

    JFProfileStore *p = [JFProfileStore shared];
    NSString *title = @"继风周报";
    NSString *body = [NSString stringWithFormat:@"本周累计 %ld 局,等级 %ld,连续登录 %ld 天。打开看看本周战绩吧!",
                      (long)p.totalGamesPlayed, (long)p.level, (long)p.currentStreakDays];

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body  = body;
    content.sound = [UNNotificationSound defaultSound];

    // 每周日 20:00
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.weekday = 1;   // 1 = Sunday in Gregorian
    comp.hour    = 20;
    comp.minute  = 0;

    UNCalendarNotificationTrigger *trigger =
        [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:comp repeats:YES];

    UNNotificationRequest *req =
        [UNNotificationRequest requestWithIdentifier:kWeeklyDigestId content:content trigger:trigger];

    [c addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"[JFNotification] schedule weekly digest failed: %@", error);
        }
    }];
}

- (void)cancelAll {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

@end
