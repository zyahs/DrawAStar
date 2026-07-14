//
//  CardsGameViewController.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import "rootVcViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFCardPartyMode) {
    JFCardPartyModeMiss = 0,
    JFCardPartyModeBigSister,
    JFCardPartyModeYoungMaster,
    JFCardPartyModeKingsOrder,
    JFCardPartyModeTruthDare,
    JFCardPartyModeChemistry,
    JFCardPartyModeReaction,
    JFCardPartyModeLuckyDraw,
};

@interface CardsGameViewController : rootVcViewController

- (instancetype)initWithPartyMode:(JFCardPartyMode)mode;

+ (NSString *)titleForPartyMode:(JFCardPartyMode)mode;
+ (NSString *)guideForPartyMode:(JFCardPartyMode)mode;
+ (NSDictionary<NSString *, NSString *> *)ruleForRank:(NSString *)rank
                                                  suit:(NSString *)suit
                                             partyMode:(JFCardPartyMode)mode;

@end

NS_ASSUME_NONNULL_END
