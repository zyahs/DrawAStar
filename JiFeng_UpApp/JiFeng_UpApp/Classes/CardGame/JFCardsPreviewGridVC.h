//
//  JFCardsPreviewGridVC.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import <UIKit/UIKit.h>

#import "JFCard.h"

NS_ASSUME_NONNULL_BEGIN
@interface JFCardsPreviewGridVC : UIViewController
@property (nonatomic, copy) NSArray<JFCard *> *allCards; // 展示的牌（不要求顺序）
@end

NS_ASSUME_NONNULL_END
