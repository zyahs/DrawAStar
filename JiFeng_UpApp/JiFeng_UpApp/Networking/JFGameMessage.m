//
//  JFGameMessage.m
//

#import "JFGameMessage.h"

NSString * const JFMessageTypeHello       = @"hello";
NSString * const JFMessageTypePing        = @"ping";
NSString * const JFMessageTypePong        = @"pong";

NSString * const JFMessageTypeIdentity    = @"identity";
NSString * const JFMessageTypeVoteList    = @"vote_list";
NSString * const JFMessageTypeVote        = @"vote";
NSString * const JFMessageTypeVoteResult  = @"vote_result";

NSString * const JFMessageTypeKingDeal    = @"king_deal";

@implementation JFGameMessage

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload {
    JFGameMessage *m = [[self alloc] init];
    m.type = type;
    m.timestamp = [[NSDate date] timeIntervalSince1970];
    m.payload = payload ?: @{};
    return m;
}

- (NSData *)dataRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.type)    dict[@"type"]    = self.type;
    if (self.from)    dict[@"from"]    = self.from;
    if (self.to)      dict[@"to"]      = self.to;
    if (self.payload) dict[@"payload"] = self.payload;
    dict[@"ts"] = @(self.timestamp);

    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    if (err) {
        NSLog(@"[JFGameMessage] encode error: %@", err);
        return nil;
    }
    return data;
}

+ (nullable instancetype)messageFromData:(NSData *)data {
    if (!data.length) return nil;
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err || ![obj isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *dict = obj;
    NSString *type = dict[@"type"];
    if (![type isKindOfClass:[NSString class]] || type.length == 0) return nil;

    JFGameMessage *m = [[self alloc] init];
    m.type      = type;
    m.from      = [dict[@"from"] isKindOfClass:[NSString class]] ? dict[@"from"] : nil;
    m.to        = [dict[@"to"]   isKindOfClass:[NSString class]] ? dict[@"to"]   : nil;
    m.timestamp = [dict[@"ts"] doubleValue];
    NSDictionary *p = dict[@"payload"];
    m.payload   = [p isKindOfClass:[NSDictionary class]] ? p : @{};
    return m;
}

@end
