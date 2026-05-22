//
//  JFSkinStore.m
//  JiFeng_UpApp
//

#import "JFSkinStore.h"
#import "JFProfileStore.h"

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
                  NSInteger price) {
    JFSkin *s = [JFSkin new];
    s.skinId = sid;
    s.displayName = name;
    s.desc = desc;
    s.brandPrimary   = [UIColor colorWithRed:r1 green:g1 blue:b1 alpha:1];
    s.brandSecondary = [UIColor colorWithRed:r2 green:g2 blue:b2 alpha:1];
    s.accent         = [UIColor colorWithRed:r3 green:g3 blue:b3 alpha:1];
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
        // 8 套皮肤 —— 第一套免费,其余按价格阶梯
        _allSkins = @[
            Sk(@"default", @"经典紫蓝", @"默认主题,沉稳百搭",
               0.46, 0.42, 0.95,
               0.96, 0.45, 0.78,
               0.20, 0.85, 0.78, 0),
            Sk(@"sunset", @"晚霞橙", @"温暖落日,氛围拉满",
               0.99, 0.45, 0.36,
               0.99, 0.72, 0.30,
               0.99, 0.38, 0.62, 200),
            Sk(@"ocean", @"深海蓝", @"清凉宁静,沉浸感十足",
               0.20, 0.55, 0.92,
               0.25, 0.78, 0.92,
               0.30, 0.88, 0.62, 300),
            Sk(@"forest", @"翠林绿", @"生机盎然,治愈系",
               0.20, 0.70, 0.50,
               0.45, 0.85, 0.40,
               0.95, 0.85, 0.35, 400),
            Sk(@"sakura", @"樱花粉", @"少女心爆棚",
               0.96, 0.55, 0.78,
               0.99, 0.78, 0.85,
               0.62, 0.45, 0.95, 500),
            Sk(@"midnight", @"暗夜霓虹", @"赛博朋克风",
               0.32, 0.18, 0.55,
               0.95, 0.20, 0.62,
               0.20, 0.95, 0.75, 800),
            Sk(@"gold", @"皇室金", @"奢华尊贵",
               0.85, 0.65, 0.20,
               0.95, 0.85, 0.40,
               0.65, 0.25, 0.20, 1200),
            Sk(@"mono", @"极简灰", @"性冷淡风,纯粹专注",
               0.45, 0.45, 0.50,
               0.65, 0.65, 0.70,
               0.85, 0.85, 0.92, 600),
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
    return YES;
}

@end
