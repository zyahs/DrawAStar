//
//  JFGameMessage.h
//  JiFeng_UpApp
//
//  统一的游戏内消息结构,用 JSON 编码。替换原工程混用的
//  NSKeyedArchiver(归档) + 裸 JSON + 裸 UTF8 字符串三种方式。
//
//  消息形态:
//      { "type": "identity", "from": 0, "to": 1, "ts": 173xxx,
//        "payload": { ... 任意业务字段 ... } }
//
//  type 是字符串,业务自定义。建议使用本文件提供的常量。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 通用消息类型(可扩展)

/// 系统消息 —— 用于会话握手、心跳、踢人等
extern NSString * const JFMessageTypeHello;       // 客户端连上后报告昵称
extern NSString * const JFMessageTypePing;        // 心跳
extern NSString * const JFMessageTypePong;

/// 卧底
extern NSString * const JFMessageTypeIdentity;    // 房主分发身份
extern NSString * const JFMessageTypeVoteList;    // 房主广播可投编号
extern NSString * const JFMessageTypeVote;        // 客户端提交投票
extern NSString * const JFMessageTypeVoteResult;  // 房主公布结果

/// 国王
extern NSString * const JFMessageTypeKingDeal;    // 房主分发牌

/// 通用联机牌桌
extern NSString * const JFMessageTypeCardRound;   // 房主广播新回合
extern NSString * const JFMessageTypeCardDeal;    // 房主定向发手牌
extern NSString * const JFMessageTypeCardReveal;  // 玩家公开亮牌
extern NSString * const JFMessageTypeCardResult;  // 房主广播结算

/// 通用联机骰桌
extern NSString * const JFMessageTypeDiceRound;   // 房主广播新回合与参与者
extern NSString * const JFMessageTypeDiceSubmit;  // 玩家向房主提交封盘点数
extern NSString * const JFMessageTypeDiceResult;  // 房主统一公布本轮结果

/// 你画我猜
extern NSString * const JFMessageTypeDrawGuessState;   // 房主广播玩家顺序/回合
extern NSString * const JFMessageTypeDrawGuessSecret;  // 房主定向发送题目给画手
extern NSString * const JFMessageTypeDrawGuessStroke;  // 画手广播实时笔画
extern NSString * const JFMessageTypeDrawGuessClear;   // 画手清空画板
extern NSString * const JFMessageTypeDrawGuessAnswer;  // 猜题者向房主提交答案
extern NSString * const JFMessageTypeDrawGuessResult;  // 房主广播猜中结果

/// 我有你没有
extern NSString * const JFMessageTypeHaveYouNotState;      // 房主广播完整回合状态
extern NSString * const JFMessageTypeHaveYouNotStatement;  // 当前玩家提交发言
extern NSString * const JFMessageTypeHaveYouNotVote;       // 其他玩家提交“我有/我没有”

#pragma mark - JFGameMessage

@interface JFGameMessage : NSObject

@property (nonatomic, copy)   NSString *type;            // 必填
@property (nonatomic, copy, nullable) NSString *from;    // 发送方标识(peerID 或服务器 uid)
@property (nonatomic, copy, nullable) NSString *to;      // 目标(可空 = 广播)
@property (nonatomic, assign) NSTimeInterval timestamp;  // 发送时间(秒)
@property (nonatomic, copy)   NSDictionary<NSString *, id> *payload; // 业务字段

+ (instancetype)messageWithType:(NSString *)type payload:(nullable NSDictionary *)payload;

/// 编码为 NSData(JSON)。失败返回 nil
- (nullable NSData *)dataRepresentation;

/// 反序列化 —— 失败返回 nil
+ (nullable instancetype)messageFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
