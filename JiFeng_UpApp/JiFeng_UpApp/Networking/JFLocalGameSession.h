//
//  JFLocalGameSession.h
//  JiFeng_UpApp
//
//  基于 MultipeerConnectivity 的本地联机实现。
//

#import <Foundation/Foundation.h>
#import "JFGameSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFLocalGameSession : NSObject <JFGameSession>

- (instancetype)initWithServiceType:(NSString *)serviceType NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
