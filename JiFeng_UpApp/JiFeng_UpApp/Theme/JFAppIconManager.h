//
//  JFAppIconManager.h
//  JiFeng_UpApp
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const JFAppIconDidChangeNotification;

typedef void (^JFAppIconCompletion)(BOOL success, NSError * _Nullable error);

@interface JFAppIconManager : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL followsTheme;
@property (nonatomic, readonly) BOOL supportsAlternateIcons;
@property (nonatomic, copy, readonly, nullable) NSString *currentAlternateIconName;

- (nullable NSString *)alternateIconNameForSkinId:(NSString *)skinId;
- (nullable NSString *)skinIdForCurrentIcon;
- (void)applyIconForSkinId:(NSString *)skinId completion:(nullable JFAppIconCompletion)completion;

@end

NS_ASSUME_NONNULL_END
