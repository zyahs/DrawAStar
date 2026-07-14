//
//  JFSkinStore.m
//  JiFeng_UpApp
//

#import "JFSkinStore.h"
#import "JFProfileStore.h"
#import "JFAnalyticsTracker.h"

NSNotificationName const JFSkinDidChangeNotification = @"JFSkinDidChangeNotification";

static NSString * const kJFSkinKey      = @"jf_skin_v1";
static NSString * const kK_Current      = @"current";
static NSString * const kK_Unlocked     = @"unlocked";  // 数组,皮肤 id

#pragma mark - JFSkin

@implementation JFSkin
@end

static JFSkin *Sk(NSString *sid, NSString *name, NSString *desc,
                  CGFloat r1, CGFloat g1, CGFloat b1,
                  CGFloat r2, CGFloat g2, CGFloat b2,
                  CGFloat r3, CGFloat g3, CGFloat b3,
                  CGFloat rt, CGFloat gt, CGFloat bt,
                  CGFloat rb, CGFloat gb, CGFloat bb,
                  NSString *pattern,
                  NSString *symbol,
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
    s.price = price;
    return s;
}

#pragma mark - JFSkinStore

@interface JFSkinStore ()
@property (nonatomic, strong) NSArray<JFSkin *> *allSkins;
@property (nonatomic, copy) NSString *currentSkinId;
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
               @"stars", @"sparkles", 0),
            Sk(@"monster", @"精灵冒险", @"草地、能量球和伙伴感",
               0.18, 0.68, 0.36,
               0.99, 0.78, 0.24,
               0.20, 0.55, 1.00,
               0.06, 0.18, 0.12,
               0.02, 0.34, 0.22,
               @"monsters", @"bolt.circle.fill", 360),
            Sk(@"kitty", @"Kitty 糖果屋", @"蝴蝶结、奶油粉和软糖",
               1.00, 0.46, 0.66,
               1.00, 0.82, 0.90,
               0.98, 0.22, 0.42,
               0.18, 0.07, 0.14,
               0.48, 0.15, 0.28,
               @"bows", @"heart.circle.fill", 360),
            Sk(@"sunset", @"落日电玩城", @"暖橙霓虹,复古街机",
               0.99, 0.45, 0.36,
               0.99, 0.72, 0.30,
               0.99, 0.38, 0.62,
               0.18, 0.08, 0.16,
               0.52, 0.16, 0.10,
               @"sunset", @"sun.max.fill", 260),
            Sk(@"ocean", @"深海水族馆", @"蓝绿流光,像夜潜海面",
               0.20, 0.55, 0.92,
               0.25, 0.78, 0.92,
               0.30, 0.88, 0.62,
               0.02, 0.10, 0.20,
               0.03, 0.28, 0.36,
               @"bubbles", @"drop.fill", 320),
            Sk(@"forest", @"森林露营", @"树影、萤火与自然绿",
               0.20, 0.70, 0.50,
               0.45, 0.85, 0.40,
               0.95, 0.85, 0.35,
               0.04, 0.12, 0.08,
               0.08, 0.28, 0.14,
               @"leaves", @"leaf.fill", 420),
            Sk(@"sakura", @"樱花祭", @"粉白纸灯,轻甜但不腻",
               0.96, 0.55, 0.78,
               0.99, 0.78, 0.85,
               0.62, 0.45, 0.95,
               0.16, 0.08, 0.14,
               0.38, 0.18, 0.30,
               @"petals", @"camera.macro", 520),
            Sk(@"midnight", @"赛博夜跑", @"黑紫底、青粉光轨",
               0.32, 0.18, 0.55,
               0.95, 0.20, 0.62,
               0.20, 0.95, 0.75,
               0.02, 0.02, 0.07,
               0.16, 0.05, 0.22,
               @"neon", @"waveform.path.ecg", 780),
            Sk(@"gold", @"皇室剧场", @"金色幕布和奖章感",
               0.85, 0.65, 0.20,
               0.95, 0.85, 0.40,
               0.65, 0.25, 0.20,
               0.12, 0.08, 0.04,
               0.34, 0.22, 0.08,
               @"medals", @"crown.fill", 980),
            Sk(@"custom", @"自定义工坊", @"用当前资料背景做轻定制",
               0.45, 0.45, 0.50,
               0.65, 0.65, 0.70,
               0.85, 0.85, 0.92,
               0.07, 0.08, 0.10,
               0.20, 0.22, 0.28,
               @"custom", @"slider.horizontal.3", 0),
        ];
        [self load];
    }
    return self;
}

#pragma mark - 持久化

- (void)load {
    NSDictionary *root = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kJFSkinKey];
    NSString *cur = root[kK_Current];
    NSArray *un  = root[kK_Unlocked];
    if (![cur isKindOfClass:[NSString class]] || cur.length == 0) cur = @"default";
    if (![un isKindOfClass:[NSArray class]]) un = @[];
    self.unlockedSet = [NSMutableSet setWithArray:un];
    [self.unlockedSet addObject:@"default"]; // 默认皮肤永远解锁
    // 当前皮肤如果未解锁,回退到默认
    if (![self.unlockedSet containsObject:cur]) cur = @"default";
    self.currentSkinId = cur;
}

- (void)save {
    NSDictionary *root = @{
        kK_Current  : self.currentSkinId ?: @"default",
        kK_Unlocked : self.unlockedSet.allObjects ?: @[],
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
    [[JFAnalyticsTracker shared] trackEvent:@"skin_apply" properties:@{ @"skinId": skinId }];
    return YES;
}

@end
