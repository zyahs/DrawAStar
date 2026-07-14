//
//  JFRemoteGameSession.h
//  JiFeng_UpApp
//
//  线上联机会话(WebSocket / 自建服务)。
//
//  ⚠️ 当前是 PLACEHOLDER —— 端点 URL、鉴权、房间号生成都没接入。
//  本类已经把所有 hook 留好,等线上接口确定后只需要:
//
//      1. 在 JFRemoteEndpoint.h 填入正式的服务器地址
//      2. 替换 _connectWebSocket 里的 URLSessionWebSocketTask 实现
//      3. 在 -startAsHost / -startAsClient 里发握手包(房间创建/加入)
//      4. 收到 server frame 后按 JFGameMessage 解码
//
//  在线上联调好之前,可以把它当 Mock(看 _kMockMode 开关)。
//

#import <Foundation/Foundation.h>
#import "JFGameSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFRemoteGameSession : NSObject <JFGameSession>

@property (nonatomic, copy, readonly, nullable) NSString *roomCode;

- (instancetype)initWithServiceType:(NSString *)serviceType NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startAsClientWithRoomCode:(NSString *)roomCode;

@end

NS_ASSUME_NONNULL_END
