//
//  JFDiceRollSurface.h
//  JiFeng_UpApp
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class JFDiceRollSurface;

@protocol JFDiceRollSurfaceDelegate <NSObject>
- (void)diceRollSurface:(JFDiceRollSurface *)surface didFinishValues:(NSArray<NSNumber *> *)values;
@end

/// 统一处理按住/摇动、震感、静止倒计时和最多 100 颗骰子的统计预览。
@interface JFDiceRollSurface : UIView

@property (nonatomic, weak) id<JFDiceRollSurfaceDelegate> delegate;
@property (nonatomic, assign) NSInteger diceCount;
@property (nonatomic, assign, getter=isRollEnabled) BOOL rollEnabled;
@property (nonatomic, assign) BOOL concealsFinalResult;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *finalValues;
@property (nonatomic, assign, readonly, getter=isRolling) BOOL rolling;

- (instancetype)initWithDiceCount:(NSInteger)diceCount;
- (void)beginRolling;
- (void)beginSettlementCountdown;
- (void)resetForNextRoll;
- (void)revealFinalValues;

@end

NS_ASSUME_NONNULL_END
