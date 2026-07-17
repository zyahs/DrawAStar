//
//  JFSkinStore.m
//  JiFeng_UpApp
//

#import "JFSkinStore.h"
#import "JFProfileStore.h"
#import "JFAnalyticsTracker.h"
#import "JFAppIconManager.h"

NSNotificationName const JFSkinDidChangeNotification = @"JFSkinDidChangeNotification";

static NSString * const kJFSkinKey      = @"jf_skin_v1";
static NSString * const kK_Current      = @"current";
static NSString * const kK_Unlocked     = @"unlocked";  // 数组,皮肤 id
static NSString * const kK_CardFace     = @"cardFace";

#pragma mark - JFSkin

@implementation JFSkin
@end

@implementation JFCardFacePreset
@end

static JFSkin *Sk(NSString *sid, NSString *name, NSString *desc,
                  CGFloat r1, CGFloat g1, CGFloat b1,
                  CGFloat r2, CGFloat g2, CGFloat b2,
                  CGFloat r3, CGFloat g3, CGFloat b3,
                  CGFloat rt, CGFloat gt, CGFloat bt,
                  CGFloat rb, CGFloat gb, CGFloat bb,
                  NSString *pattern,
                  NSString *symbol,
                  NSString *pieceStyle,
                  NSInteger price) {
    JFSkin *s = [JFSkin new];
    s.skinId = sid;
    s.displayName = name;
    s.desc = desc;
    s.brandPrimary   = [UIColor colorWithRed:r1 green:g1 blue:b1 alpha:1];
    s.brandSecondary = [UIColor colorWithRed:r2 green:g2 blue:b2 alpha:1];
    s.accent         = [UIColor colorWithRed:r3 green:g3 blue:b3 alpha:1];
    s.backgroundTop  = [UIColor colorWithRed:rt green:gt blue:bt alpha:1];
    s.backgroundBottom = [UIColor colorWithRed:rb green:gb blue:bb alpha:1];
    s.patternStyle = pattern;
    s.symbolName = symbol;
    s.pieceStyle = pieceStyle;
    s.price = price;
    return s;
}

static JFCardFacePreset *Face(NSString *presetId, NSString *name, NSString *desc, NSString *symbol) {
    JFCardFacePreset *preset = [JFCardFacePreset new];
    preset.presetId = presetId;
    preset.displayName = name;
    preset.desc = desc;
    preset.symbolName = symbol;
    return preset;
}

#pragma mark - JFSkinStore

@interface JFSkinStore ()
@property (nonatomic, strong) NSArray<JFSkin *> *allSkins;
@property (nonatomic, strong) NSArray<JFCardFacePreset *> *allCardFacePresets;
@property (nonatomic, copy) NSString *currentSkinId;
@property (nonatomic, copy) NSString *currentCardFacePresetId;
@property (nonatomic, strong) NSMutableSet<NSString *> *unlockedSet;
@end

@implementation JFSkinStore

+ (instancetype)shared {
    static JFSkinStore *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if (self = [super init]) {
        // 主题不只是颜色:每套带背景、图案、符号和卡片氛围。
        _allSkins = @[
            Sk(@"default", @"星夜游乐场", @"默认主题,轻霓虹与星尘",
               0.46, 0.42, 0.95,
               0.96, 0.45, 0.78,
               0.20, 0.85, 0.78,
               0.06, 0.06, 0.12,
               0.12, 0.06, 0.22,
               @"stars", @"sparkles", @"starlight", 0),
            Sk(@"monster", @"精灵冒险", @"草地、能量球和伙伴感",
               0.18, 0.68, 0.36,
               0.99, 0.78, 0.24,
               0.20, 0.55, 1.00,
               0.06, 0.18, 0.12,
               0.02, 0.34, 0.22,
               @"monsters", @"bolt.circle.fill", @"adventure", 360),
            Sk(@"kitty", @"蝴蝶结糖果屋", @"奶油粉、蝴蝶结和软糖光泽",
               1.00, 0.46, 0.66,
               1.00, 0.82, 0.90,
               0.98, 0.22, 0.42,
               0.18, 0.07, 0.14,
               0.48, 0.15, 0.28,
               @"bows", @"heart.circle.fill", @"ribbon", 360),
            Sk(@"sunset", @"落日电玩城", @"暖橙霓虹,复古街机",
               0.99, 0.45, 0.36,
               0.99, 0.72, 0.30,
               0.99, 0.38, 0.62,
               0.18, 0.08, 0.16,
               0.52, 0.16, 0.10,
               @"sunset", @"sun.max.fill", @"arcade", 260),
            Sk(@"ocean", @"深海水族馆", @"蓝绿流光,像夜潜海面",
               0.20, 0.55, 0.92,
               0.25, 0.78, 0.92,
               0.30, 0.88, 0.62,
               0.02, 0.10, 0.20,
               0.03, 0.28, 0.36,
               @"bubbles", @"drop.fill", @"pearl", 320),
            Sk(@"forest", @"森林露营", @"树影、萤火与自然绿",
               0.20, 0.70, 0.50,
               0.45, 0.85, 0.40,
               0.95, 0.85, 0.35,
               0.04, 0.12, 0.08,
               0.08, 0.28, 0.14,
               @"leaves", @"leaf.fill", @"woodland", 420),
            Sk(@"sakura", @"樱花祭", @"粉白纸灯,轻甜但不腻",
               0.96, 0.55, 0.78,
               0.99, 0.78, 0.85,
               0.62, 0.45, 0.95,
               0.16, 0.08, 0.14,
               0.38, 0.18, 0.30,
               @"petals", @"camera.macro", @"sakura", 520),
            Sk(@"midnight", @"赛博夜跑", @"黑紫底、青粉光轨",
               0.32, 0.18, 0.55,
               0.95, 0.20, 0.62,
               0.20, 0.95, 0.75,
               0.02, 0.02, 0.07,
               0.16, 0.05, 0.22,
               @"neon", @"waveform.path.ecg", @"circuit", 780),
            Sk(@"gold", @"皇室剧场", @"金色幕布和奖章感",
               0.85, 0.65, 0.20,
               0.95, 0.85, 0.40,
               0.65, 0.25, 0.20,
               0.12, 0.08, 0.04,
               0.34, 0.22, 0.08,
               @"medals", @"crown.fill", @"royal", 980),
            Sk(@"porcelain", @"青花月影", @"釉白牌面、钴蓝纹样与朱砂点睛",
               0.08, 0.30, 0.64,
               0.88, 0.18, 0.24,
               0.70, 0.88, 1.00,
               0.02, 0.08, 0.18,
               0.04, 0.24, 0.42,
               @"porcelain", @"moon.stars.fill", @"porcelain", 1180),
            Sk(@"celestial", @"星穹鎏光", @"深空蓝、香槟金与流星金属边",
               0.12, 0.34, 0.72,
               0.62, 0.30, 0.82,
               0.96, 0.78, 0.36,
               0.01, 0.03, 0.10,
               0.05, 0.12, 0.30,
               @"celestial", @"sparkles", @"celestial", 1380),
            Sk(@"noir", @"黑曜玫瑰", @"黑曜石骰体、酒红牌背与银色暗纹",
               0.10, 0.10, 0.13,
               0.66, 0.08, 0.24,
               0.82, 0.84, 0.90,
               0.015, 0.015, 0.025,
               0.16, 0.025, 0.07,
               @"noir", @"seal.fill", @"noir", 1580),
            Sk(@"prism", @"棱镜幻城", @"冰青、莓红与柠檬金的折射光泽",
               0.10, 0.78, 0.84,
               0.92, 0.20, 0.52,
               0.96, 0.84, 0.24,
               0.025, 0.08, 0.12,
               0.18, 0.06, 0.28,
               @"prism", @"diamond.fill", @"prism", 1780),
            Sk(@"custom", @"自定义工坊", @"用当前资料背景做轻定制",
               0.45, 0.45, 0.50,
               0.65, 0.65, 0.70,
               0.85, 0.85, 0.92,
               0.07, 0.08, 0.10,
               0.20, 0.22, 0.28,
               @"custom", @"slider.horizontal.3", @"atelier", 0),
        ];
        _allCardFacePresets = @[
            Face(@"themed", @"主题华彩", @"主题点阵与双头宫廷徽章", @"sparkles.rectangle.stack.fill"),
            Face(@"classic", @"经典宫廷", @"高细节双头宫廷人物", @"crown.fill"),
            Face(@"pixel", @"复古像素", @"清晰利落的像素牌组", @"square.grid.3x3.fill"),
            Face(@"fourColor", @"四彩竞技", @"四种花色快速识别", @"suit.club.fill"),
            Face(@"minimal", @"极简字牌", @"大字标记与单花色构图", @"textformat.size.larger"),
        ];
        [self load];
    }
    return self;
}

#pragma mark - 持久化

- (void)load {
    NSDictionary *root = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kJFSkinKey];
    NSString *cur = root[kK_Current];
    NSString *cardFace = root[kK_CardFace];
    NSArray *un  = root[kK_Unlocked];
    if (![cur isKindOfClass:[NSString class]] || cur.length == 0) cur = @"default";
    if (![un isKindOfClass:[NSArray class]]) un = @[];
    if (![cardFace isKindOfClass:NSString.class] || cardFace.length == 0) cardFace = @"themed";
    BOOL validCardFace = NO;
    for (JFCardFacePreset *preset in self.allCardFacePresets) {
        if ([preset.presetId isEqualToString:cardFace]) {
            validCardFace = YES;
            break;
        }
    }
    if (!validCardFace) cardFace = @"themed";
    self.unlockedSet = [NSMutableSet setWithArray:un];
    [self.unlockedSet addObject:@"default"]; // 默认皮肤永远解锁
    // 当前皮肤如果未解锁,回退到默认
    if (![self.unlockedSet containsObject:cur]) cur = @"default";
    self.currentSkinId = cur;
    self.currentCardFacePresetId = cardFace;
}

- (void)save {
    NSDictionary *root = @{
        kK_Current  : self.currentSkinId ?: @"default",
        kK_Unlocked : self.unlockedSet.allObjects ?: @[],
        kK_CardFace : self.currentCardFacePresetId ?: @"themed",
    };
    [[NSUserDefaults standardUserDefaults] setObject:root forKey:kJFSkinKey];
}

- (void)broadcast {
    [[NSNotificationCenter defaultCenter] postNotificationName:JFSkinDidChangeNotification object:self];
}

#pragma mark - API

- (JFSkin *)currentSkin {
    return [self skinById:self.currentSkinId] ?: self.allSkins.firstObject;
}

- (JFCardFacePreset *)currentCardFacePreset {
    for (JFCardFacePreset *preset in self.allCardFacePresets) {
        if ([preset.presetId isEqualToString:self.currentCardFacePresetId]) return preset;
    }
    return self.allCardFacePresets.firstObject;
}

- (JFSkin *)skinById:(NSString *)skinId {
    for (JFSkin *s in self.allSkins) {
        if ([s.skinId isEqualToString:skinId]) return s;
    }
    return nil;
}

- (BOOL)isUnlocked:(NSString *)skinId {
    return [self.unlockedSet containsObject:skinId];
}

- (BOOL)purchaseSkin:(NSString *)skinId {
    JFSkin *s = [self skinById:skinId];
    if (!s) return NO;
    if ([self isUnlocked:skinId]) return YES;
    if (s.price > 0) {
        if (![[JFProfileStore shared] spendCoins:s.price]) return NO;
    }
    [self.unlockedSet addObject:skinId];
    [self save];
    [self broadcast];
    return YES;
}

- (BOOL)applySkin:(NSString *)skinId {
    if (![self isUnlocked:skinId]) return NO;
    if ([self.currentSkinId isEqualToString:skinId]) return YES;
    self.currentSkinId = skinId;
    [self save];
    [self broadcast];
    if (JFAppIconManager.shared.followsTheme) {
        [JFAppIconManager.shared applyIconForSkinId:skinId completion:nil];
    }
    [[JFAnalyticsTracker shared] trackEvent:@"skin_apply" properties:@{ @"skinId": skinId }];
    return YES;
}

- (BOOL)applyCardFacePreset:(NSString *)presetId {
    BOOL exists = NO;
    for (JFCardFacePreset *preset in self.allCardFacePresets) {
        if ([preset.presetId isEqualToString:presetId]) {
            exists = YES;
            break;
        }
    }
    if (!exists) return NO;
    if ([self.currentCardFacePresetId isEqualToString:presetId]) return YES;
    self.currentCardFacePresetId = presetId;
    [self save];
    [self broadcast];
    [[JFAnalyticsTracker shared] trackEvent:@"card_face_preset_apply" properties:@{ @"presetId": presetId }];
    return YES;
}

@end
