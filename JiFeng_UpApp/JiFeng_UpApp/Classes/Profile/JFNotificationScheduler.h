//
//  JFNotificationScheduler.h
//  JiFeng_UpApp
//
//  本地通知调度 —— 每周日晚 20:00 推送本周战报。
//  统一管理通知权限申请 + 重复通知排期。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFNotificationScheduler : NSObject

+ (instancetype)shared;

/// App 启动时调用 —— 申请通知权限并安排周报。
/// 内部已做幂等,可重复调用。
- (void)setupOnLaunch;

/// 立即重排周报(用于"重置"或调试)。
- (void)rescheduleWeeklyDigest;

/// 取消所有计划的本地通知。
- (void)cancelAll;

@end

NS_ASSUME_NONNULL_END
