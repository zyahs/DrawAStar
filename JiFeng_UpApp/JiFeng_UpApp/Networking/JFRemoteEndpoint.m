//
//  JFRemoteEndpoint.m
//
//  TODO: 上线时把这里改成正式地址。
//

#import "JFRemoteEndpoint.h"

@implementation JFRemoteEndpoint

+ (BOOL)remoteEnabled {
    return YES;
}

+ (NSString *)webSocketURLString {
    // TODO: 替换为真实的 WebSocket 地址,例:
    // return @"wss://api.your-domain.com/jfgame/ws";
    return @"";
}

+ (NSString *)apiBaseURLString {
    return @"https://zy-fbdy.com/jifeng-api";
}

+ (NSString *)clientVersion {
    NSString *v = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] ?: @"0.0";
    NSString *b = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]            ?: @"0";
    return [NSString stringWithFormat:@"%@(%@)", v, b];
}

@end
