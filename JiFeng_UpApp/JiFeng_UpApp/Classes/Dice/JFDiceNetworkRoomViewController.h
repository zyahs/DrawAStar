//
//  JFDiceNetworkRoomViewController.h
//  JiFeng_UpApp
//

#import "rootVcViewController.h"
#import "JFDiceGameDefinition.h"

NS_ASSUME_NONNULL_BEGIN

/// 线上骰桌：各设备独立摇骰，全部封盘后由房主统一公布。
@interface JFDiceNetworkRoomViewController : rootVcViewController

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition
                          diceCount:(NSInteger)diceCount
                             asHost:(BOOL)asHost
                           roomCode:(nullable NSString *)roomCode;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
