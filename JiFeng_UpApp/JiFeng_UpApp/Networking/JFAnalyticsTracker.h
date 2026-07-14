//
//  JFAnalyticsTracker.h
//  JiFeng_UpApp
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

@class JFGameResult;

NS_ASSUME_NONNULL_BEGIN

/// 轻量产品分析：统一维护 App/游戏会话，并将事件离线排队后批量上传。
@interface JFAnalyticsTracker : NSObject

+ (instancetype)shared;

- (void)sceneDidBecomeActive;
- (void)sceneWillResignActive;
- (void)flush;

- (void)trackGameCardClick:(JFGameKind)kind source:(NSString *)source;
- (void)beginGameSession:(JFGameKind)kind source:(NSString *)source;
- (void)finishGameWithResult:(JFGameResult *)result;
- (void)endCurrentGameSessionWithReason:(NSString *)reason;

- (void)trackEvent:(NSString *)name properties:(nullable NSDictionary<NSString *, id> *)properties;
- (void)trackEvent:(NSString *)name
          gameKind:(JFGameKind)kind
        properties:(nullable NSDictionary<NSString *, id> *)properties;

@end

NS_ASSUME_NONNULL_END
