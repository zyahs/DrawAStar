//
//  JFRemoteEndpoint.h
//  JiFeng_UpApp
//
//  线上服务的端点配置。等正式服务器上线后,把 URL 填进 .m 即可,
//  其它代码无需改动。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFRemoteEndpoint : NSObject

/// 当前是否启用线上联机(默认 NO,所有联机走本地 MultipeerConnectivity)
+ (BOOL)remoteEnabled;

/// WebSocket 地址(eg. wss://api.example.com/jfgame/ws)。未配置时为空串。
+ (NSString *)webSocketURLString;

/// REST 基址(房间创建、心跳上报等),未配置时为空串
+ (NSString *)apiBaseURLString;

/// 客户端版本号(随消息上报,服务端可做兼容路由)
+ (NSString *)clientVersion;

@end

NS_ASSUME_NONNULL_END
