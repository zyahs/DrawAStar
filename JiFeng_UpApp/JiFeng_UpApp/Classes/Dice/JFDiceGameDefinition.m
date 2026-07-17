//
//  JFDiceGameDefinition.m
//  JiFeng_UpApp
//

#import "JFDiceGameDefinition.h"

@implementation JFDiceGameDefinition

+ (instancetype)definitionWithMode:(JFDiceGameMode)mode
                              group:(JFDiceGameGroup)group
                              title:(NSString *)title
                           subtitle:(NSString *)subtitle
                             symbol:(NSString *)symbol
                        serviceType:(NSString *)serviceType
                               dice:(NSInteger)dice
                             custom:(BOOL)custom
                               rule:(NSString *)rule {
    JFDiceGameDefinition *definition = [[self alloc] init];
    definition.mode = mode;
    definition.group = group;
    definition.title = title;
    definition.subtitle = subtitle;
    definition.symbolName = symbol;
    definition.serviceType = serviceType;
    definition.recommendedDiceCount = dice;
    definition.customDiceCount = custom;
    definition.ruleGuide = rule;
    return definition;
}

+ (NSArray<JFDiceGameDefinition *> *)allDefinitions {
    static NSArray<JFDiceGameDefinition *> *definitions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        definitions = @[
            [self definitionWithMode:JFDiceGameModeFree group:JFDiceGameGroupQuick title:@"自由摇骰" subtitle:@"纯粹摇骰，快速统计点数" symbol:@"die.face.5.fill" serviceType:@"dice-free" dice:5 custom:NO rule:@"每人摇 5 颗骰子。停止摇动 2 秒后封盘，所有玩家完成后统一展示每位玩家的骰面和全场 1-6 点数量。"],
            [self definitionWithMode:JFDiceGameModeHigh group:JFDiceGameGroupQuick title:@"多人比大小" subtitle:@"总点最高者赢下本轮" symbol:@"arrow.up.circle.fill" serviceType:@"dice-high" dice:3 custom:NO rule:@"每人 3 颗骰子，总点数最高者获胜；同点并列。结果统一公布前不会展示其他玩家的点数。"],
            [self definitionWithMode:JFDiceGameModeLow group:JFDiceGameGroupQuick title:@"小点为王" subtitle:@"控制风险，最低总点获胜" symbol:@"arrow.down.circle.fill" serviceType:@"dice-low" dice:3 custom:NO rule:@"每人 3 颗骰子，总点数最低者获胜；同点并列。适合作为反向比大小或轻量惩罚轮。"],
            [self definitionWithMode:JFDiceGameModeClosestTen group:JFDiceGameGroupQuick title:@"贴近十点" subtitle:@"三骰总点最接近 10" symbol:@"scope" serviceType:@"dice-ten" dice:3 custom:NO rule:@"每人 3 颗骰子，比较总点与 10 的距离；距离最小者获胜，正好 10 点优先。"],
            [self definitionWithMode:JFDiceGameModeStraight group:JFDiceGameGroupQuick title:@"顺子挑战" subtitle:@"五骰凑连续点数" symbol:@"chart.bar.fill" serviceType:@"dice-straight" dice:5 custom:NO rule:@"每人 5 颗骰子。出现 1-5 或 2-6 为大顺；否则按连续点数长度和不同点数数量比较。"],
            [self definitionWithMode:JFDiceGameModeCustom group:JFDiceGameGroupQuick title:@"自定义骰池" subtitle:@"每人 1-100 颗，封盘后统计" symbol:@"slider.horizontal.3" serviceType:@"dice-custom" dice:12 custom:YES rule:@"可设置每人 1-100 颗骰子。滚动时预览前 12 颗，封盘后展示完整骰面，并统计 1-6 点分别出现多少次。"],
            [self definitionWithMode:JFDiceGameModeLiar group:JFDiceGameGroupParty title:@"吹牛骰子" subtitle:@"先叫点，统一开盅核验" symbol:@"bubble.left.and.exclamationmark.bubble.right.fill" serviceType:@"dice-liar" dice:5 custom:NO rule:@"每人 5 颗骰子，摇定后先按酒桌规则依次叫“数量 + 点数”，可加数量或提高点数。有人质疑后等待全员封盘，再统一开盅核对全场点数分布。"],
            [self definitionWithMode:JFDiceGameModeSevenEightNine group:JFDiceGameGroupParty title:@"七八九" subtitle:@"经典双骰酒桌局" symbol:@"7.circle.fill" serviceType:@"dice-789" dice:2 custom:NO rule:@"每人 2 颗骰子：总点 7 为加码，8 为自选一半，9 为接受本轮；豹子可指定一位玩家，其余点数安全。饮品或替代惩罚由现场自行约定。"],
            [self definitionWithMode:JFDiceGameModeOddEven group:JFDiceGameGroupParty title:@"单双阵营" subtitle:@"开摇前押奇数或偶数" symbol:@"circle.grid.cross.fill" serviceType:@"dice-oddeven" dice:3 custom:NO rule:@"每人 3 颗骰子，开摇前口头选择奇数或偶数。统一公布后按个人总点单双核验，猜错者执行桌面约定。"],
            [self definitionWithMode:JFDiceGameModeLuckySix group:JFDiceGameGroupParty title:@"幸运六" subtitle:@"六点越多，话语权越大" symbol:@"6.circle.fill" serviceType:@"dice-six" dice:6 custom:NO rule:@"每人 6 颗骰子，比较六点的数量；六点最多者获胜，同数时比较总点。可由胜者指定下一轮规则。"],
            [self definitionWithMode:JFDiceGameModePairs group:JFDiceGameGroupParty title:@"对子通吃" subtitle:@"相同点数组合越大越强" symbol:@"square.grid.2x2.fill" serviceType:@"dice-pairs" dice:5 custom:NO rule:@"每人 5 颗骰子，先比较同点骰子的最大数量，再比较该组点数。五同、四同、三同、对子依次递减。"],
            [self definitionWithMode:JFDiceGameModeNiuNiu group:JFDiceGameGroupParty title:@"骰子牛牛" subtitle:@"五骰组牛，牛牛最大" symbol:@"circle.grid.3x3.fill" serviceType:@"dice-niuniu" dice:5 custom:NO rule:@"每人 5 颗骰子。任取 3 颗点数之和为 10 的倍数即有牛，剩余 2 颗之和的个位数为牛几，整十为牛牛；无法凑整十则为无牛。"],
            [self definitionWithMode:JFDiceGameModePoker group:JFDiceGameGroupParty title:@"骰子梭哈" subtitle:@"五骰成牌，比较组合牌型" symbol:@"suit.spade.fill" serviceType:@"dice-poker" dice:5 custom:NO rule:@"每人 5 颗骰子。牌型从大到小为五同、四同、葫芦、顺子、三条、两对、对子、散牌；同牌型按组合点数比较。"],
            [self definitionWithMode:JFDiceGameModeTotalGuess group:JFDiceGameGroupParty title:@"总点竞猜" subtitle:@"先猜全场总点，再一起开盅" symbol:@"questionmark.bubble.fill" serviceType:@"dice-guess" dice:5 custom:NO rule:@"每人 5 颗骰子，封盘后先轮流猜全场总点。所有人完成再统一公布总和，最接近者获胜；猜测过程由现场口头记录。"],
        ];
    });
    return definitions;
}

- (NSArray<NSNumber *> *)faceCountsForValues:(NSArray<NSNumber *> *)values {
    NSInteger counts[7] = {0};
    for (NSNumber *value in values) {
        NSInteger face = value.integerValue;
        if (face >= 1 && face <= 6) counts[face] += 1;
    }
    NSMutableArray<NSNumber *> *histogram = [NSMutableArray arrayWithCapacity:6];
    for (NSInteger face = 1; face <= 6; face++) [histogram addObject:@(counts[face])];
    return histogram;
}

- (NSInteger)sumForValues:(NSArray<NSNumber *> *)values {
    NSInteger sum = 0;
    for (NSNumber *value in values) sum += value.integerValue;
    return sum;
}

- (NSInteger)longestStraightForValues:(NSArray<NSNumber *> *)values {
    NSArray<NSNumber *> *histogram = [self faceCountsForValues:values];
    NSInteger longest = 0;
    NSInteger current = 0;
    for (NSNumber *count in histogram) {
        if (count.integerValue > 0) {
            current += 1;
            longest = MAX(longest, current);
        } else {
            current = 0;
        }
    }
    return longest;
}

- (NSInteger)descendingTieScoreForValues:(NSArray<NSNumber *> *)values {
    NSArray<NSNumber *> *sorted = [values sortedArrayUsingComparator:^NSComparisonResult(NSNumber *left, NSNumber *right) {
        return [right compare:left];
    }];
    NSInteger score = 0;
    for (NSNumber *value in sorted) score = score * 7 + value.integerValue;
    return score;
}

- (NSInteger)niuPointForValues:(NSArray<NSNumber *> *)values {
    if (values.count != 5) return 0;
    NSInteger total = [self sumForValues:values];
    for (NSInteger first = 0; first < 3; first++) {
        for (NSInteger second = first + 1; second < 4; second++) {
            for (NSInteger third = second + 1; third < 5; third++) {
                NSInteger trio = values[first].integerValue + values[second].integerValue + values[third].integerValue;
                if (trio % 10 == 0) {
                    NSInteger point = total % 10;
                    return point == 0 ? 10 : point;
                }
            }
        }
    }
    return 0;
}

- (NSInteger)pokerCategoryForValues:(NSArray<NSNumber *> *)values {
    if (values.count != 5) return 0;
    NSArray<NSNumber *> *counts = [self faceCountsForValues:values];
    NSInteger pairCount = 0;
    NSInteger maxCount = 0;
    NSInteger distinct = 0;
    BOOL hasThree = NO;
    for (NSNumber *count in counts) {
        NSInteger value = count.integerValue;
        if (value > 0) distinct += 1;
        if (value == 2) pairCount += 1;
        if (value == 3) hasThree = YES;
        maxCount = MAX(maxCount, value);
    }
    BOOL lowStraight = YES;
    BOOL highStraight = YES;
    for (NSInteger index = 0; index < 5; index++) lowStraight = lowStraight && counts[index].integerValue > 0;
    for (NSInteger index = 1; index < 6; index++) highStraight = highStraight && counts[index].integerValue > 0;
    BOOL straight = distinct == 5 && (lowStraight || highStraight);
    if (maxCount == 5) return 8;
    if (maxCount == 4) return 7;
    if (hasThree && pairCount == 1) return 6;
    if (straight) return 5;
    if (hasThree) return 4;
    if (pairCount == 2) return 3;
    if (pairCount == 1) return 2;
    return 1;
}

- (NSInteger)pokerTieScoreForValues:(NSArray<NSNumber *> *)values {
    NSArray<NSNumber *> *counts = [self faceCountsForValues:values];
    NSMutableArray<NSDictionary *> *groups = [NSMutableArray array];
    for (NSInteger face = 1; face <= 6; face++) {
        NSInteger count = counts[face - 1].integerValue;
        if (count > 0) [groups addObject:@{@"face": @(face), @"count": @(count)}];
    }
    [groups sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        NSComparisonResult countOrder = [right[@"count"] compare:left[@"count"]];
        return countOrder == NSOrderedSame ? [right[@"face"] compare:left[@"face"]] : countOrder;
    }];
    NSInteger score = 0;
    for (NSDictionary *group in groups) score = score * 7 + [group[@"face"] integerValue];
    return score;
}

- (NSInteger)scoreForValues:(NSArray<NSNumber *> *)values {
    NSInteger sum = [self sumForValues:values];
    NSArray<NSNumber *> *histogram = [self faceCountsForValues:values];
    switch (self.mode) {
        case JFDiceGameModeLow:
            return -sum;
        case JFDiceGameModeClosestTen:
            return 100 - labs(sum - 10);
        case JFDiceGameModeLuckySix:
            return histogram[5].integerValue * 100 + sum;
        case JFDiceGameModePairs: {
            NSInteger bestCount = 0;
            NSInteger bestFace = 0;
            for (NSUInteger idx = 0; idx < histogram.count; idx++) {
                NSNumber *count = histogram[idx];
                if (count.integerValue > bestCount || (count.integerValue == bestCount && (NSInteger)idx + 1 > bestFace)) {
                    bestCount = count.integerValue;
                    bestFace = idx + 1;
                }
            }
            return bestCount * 100 + bestFace;
        }
        case JFDiceGameModeStraight:
            return [self longestStraightForValues:values] * 100 + sum;
        case JFDiceGameModeNiuNiu:
            return [self niuPointForValues:values] * 100000 + [self descendingTieScoreForValues:values];
        case JFDiceGameModePoker:
            return [self pokerCategoryForValues:values] * 100000 + [self pokerTieScoreForValues:values];
        default:
            return sum;
    }
}

- (NSString *)shortTextForValues:(NSArray<NSNumber *> *)values {
    if (values.count <= 12) {
        NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:values.count];
        for (NSNumber *value in values) [parts addObject:value.stringValue];
        return [parts componentsJoinedByString:@" · "];
    }
    NSArray<NSNumber *> *histogram = [self faceCountsForValues:values];
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:6];
    [histogram enumerateObjectsUsingBlock:^(NSNumber *count, NSUInteger idx, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%lu×%@", (unsigned long)idx + 1, count]];
    }];
    return [parts componentsJoinedByString:@"  "];
}

- (NSString *)statisticsTextForValues:(NSArray<NSNumber *> *)values {
    NSInteger sum = [self sumForValues:values];
    NSArray<NSNumber *> *counts = [self faceCountsForValues:values];
    return [NSString stringWithFormat:@"%lu 颗 · 总点 %ld\n1点 %@  2点 %@  3点 %@  4点 %@  5点 %@  6点 %@",
            (unsigned long)values.count, (long)sum,
            counts[0], counts[1], counts[2], counts[3], counts[4], counts[5]];
}

- (NSString *)resultDetailForValues:(NSArray<NSNumber *> *)values {
    NSInteger sum = [self sumForValues:values];
    NSArray<NSNumber *> *counts = [self faceCountsForValues:values];
    switch (self.mode) {
        case JFDiceGameModeClosestTen:
            return [NSString stringWithFormat:@"总点 %ld · 距 10 点 %ld", (long)sum, (long)labs(sum - 10)];
        case JFDiceGameModeStraight:
            return [NSString stringWithFormat:@"最长 %ld 连 · 总点 %ld", (long)[self longestStraightForValues:values], (long)sum];
        case JFDiceGameModeLuckySix:
            return [NSString stringWithFormat:@"6 点 %@ 颗 · 总点 %ld", counts[5], (long)sum];
        case JFDiceGameModePairs: {
            NSInteger largestGroup = 0;
            for (NSNumber *count in counts) largestGroup = MAX(largestGroup, count.integerValue);
            return [NSString stringWithFormat:@"最大 %ld 同 · 总点 %ld", (long)largestGroup, (long)sum];
        }
        case JFDiceGameModeOddEven:
            return [NSString stringWithFormat:@"总点 %ld · %@", (long)sum, sum % 2 == 0 ? @"偶数" : @"奇数"];
        case JFDiceGameModeSevenEightNine: {
            BOOL pair = values.count >= 2 && [values.firstObject isEqualToNumber:values[1]];
            NSString *action = pair ? @"豹子" : (sum == 7 ? @"加码" : (sum == 8 ? @"自选一半" : (sum == 9 ? @"接受本轮" : @"安全")));
            return [NSString stringWithFormat:@"总点 %ld · %@", (long)sum, action];
        }
        case JFDiceGameModeNiuNiu: {
            NSInteger point = [self niuPointForValues:values];
            NSString *hand = point == 0 ? @"无牛" : (point == 10 ? @"牛牛" : [NSString stringWithFormat:@"牛%ld", (long)point]);
            return [NSString stringWithFormat:@"%@ · 总点 %ld", hand, (long)sum];
        }
        case JFDiceGameModePoker: {
            NSArray<NSString *> *names = @[@"", @"散牌", @"对子", @"两对", @"三条", @"顺子", @"葫芦", @"四同", @"五同"];
            NSInteger category = [self pokerCategoryForValues:values];
            return [NSString stringWithFormat:@"%@ · 总点 %ld", names[MAX(0, MIN(8, category))], (long)sum];
        }
        default:
            return [NSString stringWithFormat:@"%lu 颗 · 总点 %ld", (unsigned long)values.count, (long)sum];
    }
}

- (NSString *)namesForBestScoreInResults:(NSArray<NSDictionary *> *)results score:(NSInteger *)bestScore {
    NSInteger best = NSIntegerMin;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSDictionary *result in results) {
        NSArray<NSNumber *> *values = [result[@"values"] isKindOfClass:NSArray.class] ? result[@"values"] : @[];
        NSInteger score = [self scoreForValues:values];
        NSString *name = [result[@"displayName"] isKindOfClass:NSString.class] ? result[@"displayName"] : @"玩家";
        if (score > best) {
            best = score;
            [names removeAllObjects];
            [names addObject:name];
        } else if (score == best) {
            [names addObject:name];
        }
    }
    if (bestScore) *bestScore = best;
    return [names componentsJoinedByString:@"、"];
}

- (NSString *)resultSummaryForResults:(NSArray<NSDictionary *> *)results {
    if (results.count == 0) return @"本轮没有有效结果。";
    if (self.mode == JFDiceGameModeLiar || self.mode == JFDiceGameModeTotalGuess) {
        NSMutableArray<NSNumber *> *allValues = [NSMutableArray array];
        for (NSDictionary *result in results) {
            NSArray *values = [result[@"values"] isKindOfClass:NSArray.class] ? result[@"values"] : @[];
            [allValues addObjectsFromArray:values];
        }
        if (self.mode == JFDiceGameModeLiar) {
            return [NSString stringWithFormat:@"全场已开盅，%lu 名玩家共 %lu 颗骰子。",
                    (unsigned long)results.count, (unsigned long)allValues.count];
        }
        return [NSString stringWithFormat:@"全场总点为 %ld，可开始核对本轮猜测。",
                (long)[self sumForValues:allValues]];
    }
    if (self.mode == JFDiceGameModeOddEven) {
        NSMutableArray<NSString *> *odd = [NSMutableArray array];
        NSMutableArray<NSString *> *even = [NSMutableArray array];
        for (NSDictionary *result in results) {
            NSArray *values = [result[@"values"] isKindOfClass:NSArray.class] ? result[@"values"] : @[];
            NSString *name = result[@"displayName"] ?: @"玩家";
            NSMutableArray<NSString *> *bucket = [self sumForValues:values] % 2 == 0 ? even : odd;
            [bucket addObject:name];
        }
        return [NSString stringWithFormat:@"奇数：%@\n偶数：%@",
                odd.count ? [odd componentsJoinedByString:@"、"] : @"无",
                even.count ? [even componentsJoinedByString:@"、"] : @"无"];
    }
    if (self.mode == JFDiceGameModeSevenEightNine) {
        return @"本轮七八九判定已完成，每位玩家的结果见下方骰面。";
    }

    NSInteger bestScore = 0;
    NSString *winners = [self namesForBestScoreInResults:results score:&bestScore];
    switch (self.mode) {
        case JFDiceGameModeHigh:
            return [NSString stringWithFormat:@"%@ 以 %ld 点获得最高总点。", winners, (long)bestScore];
        case JFDiceGameModeLow:
            return [NSString stringWithFormat:@"%@ 以 %ld 点成为本轮最小点。", winners, (long)-bestScore];
        case JFDiceGameModeClosestTen:
            return [NSString stringWithFormat:@"%@ 的总点最接近 10。", winners];
        case JFDiceGameModeLuckySix:
            return [NSString stringWithFormat:@"%@ 摇出最多六点。", winners];
        case JFDiceGameModePairs:
            return [NSString stringWithFormat:@"%@ 的同点组合最强。", winners];
        case JFDiceGameModeStraight:
            return [NSString stringWithFormat:@"%@ 的连续点数组合最佳。", winners];
        case JFDiceGameModeNiuNiu:
            return [NSString stringWithFormat:@"%@ 的牛牛牌型最大。", winners];
        case JFDiceGameModePoker:
            return [NSString stringWithFormat:@"%@ 的梭哈组合最大。", winners];
        default:
            return [NSString stringWithFormat:@"%lu 名玩家已完成本轮，结果如下。", (unsigned long)results.count];
    }
}

@end
