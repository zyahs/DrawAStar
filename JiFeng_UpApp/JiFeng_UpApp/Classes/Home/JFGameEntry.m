//
//  JFGameEntry.m
//

#import "JFGameEntry.h"

@implementation JFGameEntry

+ (instancetype)entryWithKind:(JFGameKind)kind
                        title:(NSString *)title
                     subtitle:(NSString *)subtitle
                       symbol:(NSString *)symbol
                     multipeer:(BOOL)mp {
    JFGameEntry *e = [[self alloc] init];
    e.kind = kind;
    e.title = title;
    e.subtitle = subtitle;
    e.symbolName = symbol;
    e.supportsMultipeer = mp;
    return e;
}

+ (NSArray<JFGameEntry *> *)allEntries {
    return @[
        [self entryWithKind:JFGameKindDrawBoard
                      title:@"画板"
                   subtitle:@"自由作画"
                     symbol:@"paintbrush.pointed.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindTruthOrDare
                      title:@"真心话大冒险"
                   subtitle:@"双色球抽签"
                     symbol:@"heart.circle.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindDice
                      title:@"骰子游戏"
                   subtitle:@"随机点数"
                     symbol:@"die.face.5.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindFiveInRow
                      title:@"五子棋"
                   subtitle:@"双人对弈"
                     symbol:@"square.grid.4x3.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindUndercover
                      title:@"谁是卧底"
                   subtitle:@"联机 · 找卧底"
                     symbol:@"person.3.sequence.fill"
                  multipeer:YES],
        [self entryWithKind:JFGameKindKing
                      title:@"国王游戏"
                   subtitle:@"联机 · 抽 K 牌"
                     symbol:@"crown.fill"
                  multipeer:YES],
        [self entryWithKind:JFGameKindCard
                      title:@"小姐牌"
                   subtitle:@"卡牌玩法"
                     symbol:@"rectangle.stack.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindGesture
                      title:@"手势炸弹"
                   subtitle:@"快手反应"
                     symbol:@"hand.raised.fingers.spread.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindPuzzle
                      title:@"拼图"
                   subtitle:@"相册照片 · 三档难度"
                     symbol:@"square.grid.3x3.square"
                  multipeer:NO],
        [self entryWithKind:JFGameKindSnake
                      title:@"贪吃蛇"
                   subtitle:@"经典单机"
                     symbol:@"scribble.variable"
                  multipeer:NO],
        [self entryWithKind:JFGameKind2048
                      title:@"2048"
                   subtitle:@"滑动合并 · 冲击高分"
                     symbol:@"square.fill.on.square.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindSudoku
                      title:@"数独"
                   subtitle:@"九宫格 · 三档"
                     symbol:@"square.grid.3x3.square"
                  multipeer:NO],
        [self entryWithKind:JFGameKindMemory
                      title:@"记忆翻牌"
                   subtitle:@"找对子 · 三档难度"
                     symbol:@"rectangle.on.rectangle"
                  multipeer:NO],
        [self entryWithKind:JFGameKindReaction
                      title:@"反应力测试"
                   subtitle:@"30 秒挑战手速"
                     symbol:@"hand.tap.fill"
                  multipeer:NO],
        [self entryWithKind:JFGameKindRhythm
                      title:@"节奏点点"
                   subtitle:@"踩点 · 上头"
                     symbol:@"music.note"
                  multipeer:NO],
    ];
}

@end
