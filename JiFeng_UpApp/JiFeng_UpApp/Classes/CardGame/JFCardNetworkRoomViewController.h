//
//  JFCardNetworkRoomViewController.h
//  JiFeng_UpApp
//

#import "rootVcViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 所有纸牌玩法共用的线上牌桌：单房主发牌，玩家私收手牌，统一亮牌结算。
@interface JFCardNetworkRoomViewController : rootVcViewController

- (instancetype)initWithGameTitle:(NSString *)gameTitle
                       serviceType:(NSString *)serviceType
                    modeIdentifier:(NSString *)modeIdentifier
                         ruleGuide:(NSString *)ruleGuide
              recommendedDealCount:(NSInteger)recommendedDealCount
                         partyMode:(NSInteger)partyMode
                            asHost:(BOOL)asHost
                          roomCode:(nullable NSString *)roomCode;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
