//
//  JFDiceGameViewController.h
//  JiFeng_UpApp
//

#import "rootVcViewController.h"
#import "JFDiceGameDefinition.h"

NS_ASSUME_NONNULL_BEGIN

/// 单机或传手机多人骰局。
@interface JFDiceGameViewController : rootVcViewController

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition
                          diceCount:(NSInteger)diceCount
                        playerCount:(NSInteger)playerCount;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
