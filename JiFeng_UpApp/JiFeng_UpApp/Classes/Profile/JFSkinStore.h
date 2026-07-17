//
//  JFSkinStore.h
//  JiFeng_UpApp
//
//  皮肤(主题色)系统 —— 管理皮肤定义、解锁、当前选中。
//  默认皮肤永远解锁;其他皮肤需金币购买。
//  落盘:NSUserDefaults。
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const JFSkinDidChangeNotification;

@interface JFSkin : NSObject
@property (nonatomic, copy)   NSString *skinId;        // 唯一 id
@property (nonatomic, copy)   NSString *displayName;   // "极光紫" 等
@property (nonatomic, copy)   NSString *desc;          // 简短描述
@property (nonatomic, strong) UIColor  *brandPrimary;
@property (nonatomic, strong) UIColor  *brandSecondary;
@property (nonatomic, strong) UIColor  *accent;
@property (nonatomic, strong) UIColor  *backgroundTop;
@property (nonatomic, strong) UIColor  *backgroundBottom;
@property (nonatomic, copy)   NSString *patternStyle;   // stars / bows / monsters / clouds / dots ...
@property (nonatomic, copy)   NSString *symbolName;     // 主题符号
@property (nonatomic, copy)   NSString *pieceStyle;     // 纸牌与骰子的材质语言
@property (nonatomic, assign) NSInteger price;         // 0 = 免费
@end

@interface JFCardFacePreset : NSObject
@property (nonatomic, copy) NSString *presetId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *symbolName;
@end

@interface JFSkinStore : NSObject

+ (instancetype)shared;

/// 全部可用皮肤定义(从内置静态表读取)
@property (nonatomic, readonly) NSArray<JFSkin *> *allSkins;

/// 纸牌正面预设，独立于全局皮肤切换。
@property (nonatomic, readonly) NSArray<JFCardFacePreset *> *allCardFacePresets;

/// 当前选中的皮肤 id
@property (nonatomic, copy, readonly) NSString *currentSkinId;
@property (nonatomic, copy, readonly) NSString *currentCardFacePresetId;

/// 当前选中皮肤(便捷取)
- (JFSkin *)currentSkin;
- (JFCardFacePreset *)currentCardFacePreset;

/// 通过 id 找皮肤
- (nullable JFSkin *)skinById:(NSString *)skinId;

/// 是否已解锁
- (BOOL)isUnlocked:(NSString *)skinId;

/// 解锁某皮肤(扣金币)。成功返回 YES。
/// 若已解锁直接返回 YES;若金币不足返回 NO。
- (BOOL)purchaseSkin:(NSString *)skinId;

/// 切换当前皮肤(必须已解锁)
- (BOOL)applySkin:(NSString *)skinId;

/// 切换纸牌正面预设，所有预设当前均免费开放。
- (BOOL)applyCardFacePreset:(NSString *)presetId;

@end

NS_ASSUME_NONNULL_END
