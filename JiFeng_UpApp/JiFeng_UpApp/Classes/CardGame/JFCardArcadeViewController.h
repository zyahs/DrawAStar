//
//  JFCardArcadeViewController.h
//  JiFeng_UpApp
//

#import "rootVcViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFCardArcadeMode) {
    JFCardArcadeModeHighLow = 0,
    JFCardArcadeModeBlackjack,
    JFCardArcadeModePyramid,
    JFCardArcadeModeWar,
};

@interface JFCardArcadeViewController : rootVcViewController
- (instancetype)initWithMode:(JFCardArcadeMode)mode;
@end

NS_ASSUME_NONNULL_END
