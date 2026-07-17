//
//  JFGamePieceSkin.h
//  JiFeng_UpApp
//
//  纸牌与骰子的统一主题绘制。支持原生矢量牌面与本地 CC0 牌面素材。
//

#import <UIKit/UIKit.h>

@class JFSkin;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFGamePieceSurfaceStyle) {
    JFGamePieceSurfaceStyleCardFace,
    JFGamePieceSurfaceStyleCardBack,
    JFGamePieceSurfaceStyleDiceTray,
};

@interface JFGamePieceSkin : NSObject

+ (JFSkin *)currentSkin;
+ (UIColor *)cardFaceColorForSkin:(JFSkin *)skin;
+ (UIColor *)cardBorderColorForSkin:(JFSkin *)skin;
+ (UIColor *)cardRedInkColorForSkin:(JFSkin *)skin;
+ (UIColor *)cardBlackInkColorForSkin:(JFSkin *)skin;
+ (UIColor *)cardBackDetailColorForSkin:(JFSkin *)skin;
+ (UIColor *)diceBodyColorForSkin:(JFSkin *)skin;
+ (UIColor *)dicePipColorForSkin:(JFSkin *)skin highlighted:(BOOL)highlighted;
+ (UIColor *)diceBorderColorForSkin:(JFSkin *)skin highlighted:(BOOL)highlighted;

@end

@interface JFGamePieceSkinView : UIView

@property (nonatomic, assign) JFGamePieceSurfaceStyle surfaceStyle;
@property (nonatomic, strong, nullable) JFSkin *skin;
@property (nonatomic, assign) BOOL showsCenterEmblem;

- (void)refreshSkin;

@end

@interface JFCardFaceArtworkView : UIView

@property (nonatomic, strong, nullable) JFSkin *skin;
@property (nonatomic, copy, nullable) NSString *presetId;
@property (nonatomic, readonly) BOOL usesFullCardArtwork;

- (void)configureWithRank:(NSString *)rank suit:(NSString *)suit compact:(BOOL)compact;
- (void)refreshArtwork;

@end

@interface JFSkinnedDieView : UIView

@property (nonatomic, assign) NSInteger face;
@property (nonatomic, assign, getter=isLocked) BOOL locked;
@property (nonatomic, assign, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, strong, nullable) JFSkin *skin;

- (void)configureWithFace:(NSInteger)face locked:(BOOL)locked;

+ (void)drawFace:(NSInteger)face
          inRect:(CGRect)rect
            skin:(JFSkin *)skin
     highlighted:(BOOL)highlighted
          locked:(BOOL)locked;

@end

NS_ASSUME_NONNULL_END
