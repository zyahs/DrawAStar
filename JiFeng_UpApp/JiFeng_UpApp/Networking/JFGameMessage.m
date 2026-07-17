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

NSString * const JFMessageTypeCardRound   = @"card_round";
NSString * const JFMessageTypeCardDeal    = @"card_deal";
NSString * const JFMessageTypeCardReveal  = @"card_reveal";
NSString * const JFMessageTypeCardResult  = @"card_result";

NSString * const JFMessageTypeDiceRound   = @"dice_round";
NSString * const JFMessageTypeDiceSubmit  = @"dice_submit";
NSString * const JFMessageTypeDiceResult  = @"dice_result";
NSString * const JFMessageTypeDrawGuessState  = @"draw_guess_state";
NSString * const JFMessageTypeDrawGuessSecret = @"draw_guess_secret";
NSString * const JFMessageTypeDrawGuessStroke = @"draw_guess_stroke";
NSString * const JFMessageTypeDrawGuessClear  = @"draw_guess_clear";
NSString * const JFMessageTypeDrawGuessAnswer = @"draw_guess_answer";
NSString * const JFMessageTypeDrawGuessResult = @"draw_guess_result";
NSString * const JFMessageTypeHaveYouNotState = @"have_you_not_state";
NSString * const JFMessageTypeHaveYouNotStatement = @"have_you_not_statement";
NSString * const JFMessageTypeHaveYouNotVote = @"have_you_not_vote";

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
