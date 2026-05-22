//
//  JFGameTileCell.h
//  JiFeng_UpApp
//
//  主页 collection cell —— 渐变卡片 + SF Symbol + 标题副标题。
//

#import <UIKit/UIKit.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFGameTileCell : UICollectionViewCell

+ (NSString *)reuseId;

- (void)configureWithEntry:(JFGameEntry *)entry index:(NSInteger)index;

/// 在 configureWithEntry: 之后调用,刷新右下角"已玩 X 次 · 最佳 Y"。
/// 没有数据(playCount=0)时角标隐藏。
- (void)setStatsPlayCount:(NSInteger)playCount bestScore:(NSInteger)bestScore;

@end

NS_ASSUME_NONNULL_END
