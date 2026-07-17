#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 成人酒桌题库。所有挑战都应以双方自愿、可随时跳过为前提。
@interface JFTruthOrDarePrompts : NSObject
+ (NSArray<NSString *> *)normalTruths;
+ (NSArray<NSString *> *)normalDares;
+ (NSArray<NSString *> *)advancedTruths;
+ (NSArray<NSString *> *)advancedDares;
@end

NS_ASSUME_NONNULL_END
