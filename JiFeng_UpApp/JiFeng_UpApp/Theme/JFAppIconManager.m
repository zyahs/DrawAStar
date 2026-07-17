//
//  JFAppIconManager.m
//  JiFeng_UpApp
//

#import "JFAppIconManager.h"
#import <UIKit/UIKit.h>
#import "JFSkinStore.h"
#import "JFAnalyticsTracker.h"

NSNotificationName const JFAppIconDidChangeNotification = @"JFAppIconDidChangeNotification";

static NSString * const kJFFollowThemeIconKey = @"jf_app_icon_follows_theme_v1";
static NSString * const kJFAppIconErrorDomain = @"com.couyiju.app-icon";

@interface JFAppIconManager ()
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *iconNamesBySkinId;
@end

@implementation JFAppIconManager

+ (instancetype)shared {
    static JFAppIconManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _iconNamesBySkinId = @{
            @"monster": @"AppIconAdventure",
            @"kitty": @"AppIconCandy",
            @"sunset": @"AppIconSunset",
            @"ocean": @"AppIconOcean",
            @"forest": @"AppIconForest",
            @"sakura": @"AppIconSakura",
            @"midnight": @"AppIconCyber",
            @"gold": @"AppIconRoyal",
            @"porcelain": @"AppIconPorcelain",
            @"celestial": @"AppIconCelestial",
            @"noir": @"AppIconNoir",
            @"prism": @"AppIconPrism",
            @"custom": @"AppIconAtelier",
        };

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        if ([defaults objectForKey:kJFFollowThemeIconKey] == nil) {
            _followsTheme = YES;
        } else {
            _followsTheme = [defaults boolForKey:kJFFollowThemeIconKey];
        }
    }
    return self;
}

- (BOOL)supportsAlternateIcons {
    return UIApplication.sharedApplication.supportsAlternateIcons;
}

- (NSString *)currentAlternateIconName {
    return UIApplication.sharedApplication.alternateIconName;
}

- (void)setFollowsTheme:(BOOL)followsTheme {
    if (_followsTheme == followsTheme) return;
    _followsTheme = followsTheme;
    [NSUserDefaults.standardUserDefaults setBool:followsTheme forKey:kJFFollowThemeIconKey];

    if (followsTheme) {
        [self applyIconForSkinId:JFSkinStore.shared.currentSkinId completion:nil];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:JFAppIconDidChangeNotification object:self];
}

- (NSString *)alternateIconNameForSkinId:(NSString *)skinId {
    if (skinId.length == 0 || [skinId isEqualToString:@"default"]) return nil;
    return self.iconNamesBySkinId[skinId];
}

- (NSString *)skinIdForCurrentIcon {
    NSString *iconName = self.currentAlternateIconName;
    if (iconName.length == 0) return @"default";
    __block NSString *skinId = nil;
    [self.iconNamesBySkinId enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        if ([value isEqualToString:iconName]) {
            skinId = key;
            *stop = YES;
        }
    }];
    return skinId;
}

- (void)applyIconForSkinId:(NSString *)skinId completion:(JFAppIconCompletion)completion {
    UIApplication *application = UIApplication.sharedApplication;
    if (!application.supportsAlternateIcons) {
        NSError *error = [NSError errorWithDomain:kJFAppIconErrorDomain
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey: @"当前设备不支持切换桌面图标"}];
        if (completion) completion(NO, error);
        return;
    }

    NSString *iconName = [self alternateIconNameForSkinId:skinId];
    NSString *currentName = application.alternateIconName;
    BOOL bothPrimary = iconName.length == 0 && currentName.length == 0;
    if (bothPrimary || [currentName isEqualToString:iconName]) {
        if (completion) completion(YES, nil);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [application setAlternateIconName:iconName completionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    [NSNotificationCenter.defaultCenter postNotificationName:JFAppIconDidChangeNotification object:self];
                    [[JFAnalyticsTracker shared] trackEvent:@"app_icon_apply"
                                                properties:@{ @"skinId": skinId ?: @"default",
                                                              @"iconName": iconName ?: @"primary",
                                                              @"followsTheme": @(self.followsTheme) }];
                }
                if (completion) completion(error == nil, error);
            });
        }];
    });
}

@end
