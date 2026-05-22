//
//  JFGameSession.h
//  JiFeng_UpApp
//
//  联机会话抽象。
//
//  本地实现:JFLocalGameSession(MultipeerConnectivity,蓝牙+局域网 P2P)
//  线上实现:JFRemoteGameSession(WebSocket,目前是骨架/Mock,等线上接口接入)
//
//  接入方式:
//      id<JFGameSession> session =
//          [JFGameSessionFactory sessionForServiceType:@"undercover" mode:JFSessionModeLocal];
//      session.delegate = self;
//      [session startAsHost];
//      [session sendMessage:msg toPeer:nil];   // nil = 广播
//
//  业务侧只关心 type=identity / vote / ... 等 JFGameMessage,不再直接接触 MC*。
//

#import <Foundation/Foundation.h>
#import "JFGameMessage.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Mode / State

typedef NS_ENUM(NSInteger, JFSessionMode) {
    JFSessionModeLocal = 0,    // MultipeerConnectivity
    JFSessionModeRemote        // 线上(WebSocket / 自建服务,暂未接入)
};

typedef NS_ENUM(NSInteger, JFSessionPeerState) {
    JFSessionPeerStateNotConnected = 0,
    JFSessionPeerStateConnecting,
    JFSessionPeerStateConnected,
};

typedef NS_ENUM(NSInteger, JFSessionRole) {
    JFSessionRoleNone = 0,
    JFSessionRoleHost,
    JFSessionRoleClient,
};

#pragma mark - Peer

@interface JFGamePeer : NSObject
@property (nonatomic, copy) NSString *peerId;       // 唯一标识(本地用 peerID hash,线上用 uid)
@property (nonatomic, copy) NSString *displayName;  // 展示名
@end

#pragma mark - Delegate

@protocol JFGameSession;

@protocol JFGameSessionDelegate <NSObject>
@optional

/// 某个对端状态变化
- (void)gameSession:(id<JFGameSession>)session
               peer:(JFGamePeer *)peer
       didChangeState:(JFSessionPeerState)state;

/// 收到一条业务消息
- (void)gameSession:(id<JFGameSession>)session
   didReceiveMessage:(JFGameMessage *)message
            fromPeer:(JFGamePeer *)peer;

/// 会话级错误(广告/浏览启动失败等)
- (void)gameSession:(id<JFGameSession>)session didFailWithError:(NSError *)error;

@end

#pragma mark - Session

@protocol JFGameSession <NSObject>

@property (nonatomic, weak, nullable) id<JFGameSessionDelegate> delegate;

/// 服务类型,如 "undercover" / "kinggame",同一服务的设备才能互相发现
@property (nonatomic, copy, readonly) NSString *serviceType;

/// 当前角色
@property (nonatomic, assign, readonly) JFSessionRole role;

/// 自己
@property (nonatomic, strong, readonly) JFGamePeer *localPeer;

/// 已连接的对端
@property (nonatomic, copy, readonly) NSArray<JFGamePeer *> *connectedPeers;

/// 启动为房主(开始广告)
- (void)startAsHost;

/// 启动为玩家(开始浏览并自动加入第一个房主)
- (void)startAsClient;

/// 完整断开
- (void)stop;

/// 发送消息。peer = nil 时广播给所有连接的对端
- (BOOL)sendMessage:(JFGameMessage *)message toPeer:(nullable JFGamePeer *)peer;

@end

#pragma mark - Factory

@interface JFGameSessionFactory : NSObject

/// 按 mode 创建 session。serviceType 必须是合法 Bonjour 服务类型(全小写、字母数字、长度 1-15)。
+ (id<JFGameSession>)sessionForServiceType:(NSString *)serviceType
                                      mode:(JFSessionMode)mode;

/// 默认本地实现
+ (id<JFGameSession>)localSessionForServiceType:(NSString *)serviceType;

@end

NS_ASSUME_NONNULL_END
