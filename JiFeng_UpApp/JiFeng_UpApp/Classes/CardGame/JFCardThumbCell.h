//
//  JFCardThumbCell.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import <UIKit/UIKit.h>
#import "JFCard.h"
NS_ASSUME_NONNULL_BEGIN

@interface JFCardThumbCell : UICollectionViewCell
- (void)configureWithCard:(JFCard *)card;
@end

NS_ASSUME_NONNULL_END
