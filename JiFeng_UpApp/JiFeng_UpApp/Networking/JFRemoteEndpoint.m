//
//  JFRemoteEndpoint.m
//
//  TODO: 上线时把这里改成正式地址。
//

#import "JFRemoteEndpoint.h"

@implementation JFRemoteEndpoint

+ (BOOL)remoteEnabled {
    // 上线后改 YES,或者根据 BuildSetting / 远程开关动态决定
    return NO;
}

+ (NSString *)webSocketURLString {
    // TODO: 替换为真实的 WebSocket 地址,例:
    // return @"wss://api.your-domain.com/jfgame/ws";
    return @"";
}

+ (NSString *)apiBaseURLString {
    // TODO: 替换为真实的 REST 基址,例:
    // return @"https://api.your-domain.com/jfgame";
    return @"";
}

+ (NSString *)clientVersion {
    NSString *v = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] ?: @"0.0";
    NSString *b = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]            ?: @"0";
    return [NSString stringWithFormat:@"%@(%@)", v, b];
}

@end
