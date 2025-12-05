//
//  JFCard.h
//  JiFeng_UpApp
//
//  Created by 继风(周毅) on 2025/9/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JFCard : NSObject
@property (nonatomic, copy) NSString *rank;   // A 2..10 J Q K
@property (nonatomic, copy) NSString *suit;   // ♠ ♥ ♦ ♣
@end

NS_ASSUME_NONNULL_END
