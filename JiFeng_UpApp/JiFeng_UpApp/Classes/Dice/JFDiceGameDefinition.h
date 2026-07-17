//
//  JFDiceGameDefinition.h
//  JiFeng_UpApp
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFDiceGameGroup) {
    JFDiceGameGroupQuick = 0,
    JFDiceGameGroupParty,
};

typedef NS_ENUM(NSInteger, JFDiceGameMode) {
    JFDiceGameModeFree = 0,
    JFDiceGameModeHigh,
    JFDiceGameModeLow,
    JFDiceGameModeLiar,
    JFDiceGameModeSevenEightNine,
    JFDiceGameModeOddEven,
    JFDiceGameModeLuckySix,
    JFDiceGameModePairs,
    JFDiceGameModeStraight,
    JFDiceGameModeClosestTen,
    JFDiceGameModeTotalGuess,
    JFDiceGameModeCustom,
    JFDiceGameModeNiuNiu,
    JFDiceGameModePoker,
};

@interface JFDiceGameDefinition : NSObject

@property (nonatomic, assign) JFDiceGameMode mode;
@property (nonatomic, assign) JFDiceGameGroup group;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbolName;
@property (nonatomic, copy) NSString *serviceType;
@property (nonatomic, copy) NSString *ruleGuide;
@property (nonatomic, assign) NSInteger recommendedDiceCount;
@property (nonatomic, assign, getter=isCustomDiceCount) BOOL customDiceCount;

+ (NSArray<JFDiceGameDefinition *> *)allDefinitions;

- (NSInteger)scoreForValues:(NSArray<NSNumber *> *)values;
- (NSArray<NSNumber *> *)faceCountsForValues:(NSArray<NSNumber *> *)values;
- (NSString *)shortTextForValues:(NSArray<NSNumber *> *)values;
- (NSString *)statisticsTextForValues:(NSArray<NSNumber *> *)values;
- (NSString *)resultDetailForValues:(NSArray<NSNumber *> *)values;
- (NSString *)resultSummaryForResults:(NSArray<NSDictionary *> *)results;

@end

NS_ASSUME_NONNULL_END
