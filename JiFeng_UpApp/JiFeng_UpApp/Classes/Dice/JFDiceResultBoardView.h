//
//  JFDiceResultBoardView.h
//  JiFeng_UpApp
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class JFDiceGameDefinition;

/// 开盅结果：顶部汇总 1-6 点数量，下面逐人展示完整骰面。
@interface JFDiceResultBoardView : UIView

- (instancetype)initWithDefinition:(JFDiceGameDefinition *)definition;
- (void)showResults:(NSArray<NSDictionary *> *)results
             summary:(NSString *)summary
       localPlayerId:(nullable NSString *)localPlayerId;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
