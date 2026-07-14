//
//  JFPlayerSetup.h
//  JiFeng_UpApp
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 首次联机前的轻量玩家账号引导。账号由后端访客身份承载，昵称由个人资料统一维护。
@interface JFPlayerSetup : NSObject

+ (BOOL)isComplete;
+ (NSString *)currentDisplayName;

/// 尚未创建昵称时展示不可跳过的创建弹窗；已创建时直接回调。
+ (void)ensureFromViewController:(UIViewController *)viewController
                      completion:(void (^ _Nullable)(BOOL complete))completion;

@end

NS_ASSUME_NONNULL_END
