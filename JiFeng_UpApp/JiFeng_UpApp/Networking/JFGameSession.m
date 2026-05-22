//
//  JFGameSession.m
//  Factory + JFGamePeer 实现
//

#import "JFGameSession.h"
#import "JFLocalGameSession.h"
#import "JFRemoteGameSession.h"

@implementation JFGamePeer
- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[JFGamePeer class]]) return NO;
    JFGamePeer *o = object;
    return [self.peerId isEqualToString:o.peerId];
}
- (NSUInteger)hash { return self.peerId.hash; }
@end

@implementation JFGameSessionFactory

+ (id<JFGameSession>)sessionForServiceType:(NSString *)serviceType
                                      mode:(JFSessionMode)mode {
    switch (mode) {
        case JFSessionModeLocal:
            return [[JFLocalGameSession alloc] initWithServiceType:serviceType];
        case JFSessionModeRemote:
            return [[JFRemoteGameSession alloc] initWithServiceType:serviceType];
    }
    return [[JFLocalGameSession alloc] initWithServiceType:serviceType];
}

+ (id<JFGameSession>)localSessionForServiceType:(NSString *)serviceType {
    return [[JFLocalGameSession alloc] initWithServiceType:serviceType];
}

@end
