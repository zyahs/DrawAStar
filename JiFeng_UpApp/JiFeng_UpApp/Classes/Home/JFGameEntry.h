//
//  JFGameEntry.h
//  JiFeng_UpApp
//
//  主页一个游戏入口的数据模型。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFGameKind) {
    JFGameKindDrawBoard = 0,   // 画板
    JFGameKindTruthOrDare,     // 真心话大冒险
    JFGameKindDice,            // 骰子游戏
    JFGameKindFiveInRow,       // 五子棋
    JFGameKindUndercover,      // 谁是卧底(联机)
    JFGameKindKing,            // 国王游戏(联机)
    JFGameKindCard,            // 小姐牌
    JFGameKindGesture,         // 手势炸弹
    JFGameKindPuzzle,          // 拼图(相册照片+难度三档)
    JFGameKindSnake,           // 贪吃蛇
    JFGameKind2048,            // 2048
    JFGameKindSudoku,          // 数独
    JFGameKindMemory,          // 记忆翻牌
    JFGameKindReaction,        // 反应力测试
    JFGameKindRhythm,          // 节奏点点
};

@interface JFGameEntry : NSObject

@property (nonatomic, assign) JFGameKind kind;
@property (nonatomic, copy)   NSString  *title;
@property (nonatomic, copy)   NSString  *subtitle;     // 副标题(类型/玩法说明)
@property (nonatomic, copy)   NSString  *symbolName;   // SF Symbol 名,主图标
@property (nonatomic, assign) BOOL      supportsMultipeer; // 是否支持联机

+ (NSArray<JFGameEntry *> *)allEntries;

@end

NS_ASSUME_NONNULL_END
