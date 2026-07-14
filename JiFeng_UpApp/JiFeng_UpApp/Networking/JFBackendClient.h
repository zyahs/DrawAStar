//
//  JFBackendClient.h
//  JiFeng_UpApp
//

#import <Foundation/Foundation.h>
#import "JFLeaderboardClient.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const JFBackendAuthDidChangeNotification;

@interface JFBackendClient : NSObject <JFLeaderboardClient>

+ (instancetype)shared;

@property (nonatomic, readonly) BOOL signedIn;
@property (nonatomic, readonly, nullable) NSString *userId;
@property (nonatomic, copy) NSString *baseURLString;

- (void)configureDefault;
- (void)ensureSignedInWithCompletion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

- (void)fetchProfileWithCompletion:(void (^)(NSDictionary * _Nullable profile, NSError * _Nullable error))completion;
- (void)updateProfile:(NSDictionary *)profile
           completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

- (void)fetchChatMessagesInRoom:(NSString *)room
                            take:(NSInteger)take
                      completion:(void (^)(NSArray<NSDictionary *> * _Nullable messages, NSError * _Nullable error))completion;

- (void)sendChatMessage:(NSString *)content
                 inRoom:(NSString *)room
             completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

- (void)submitAnalyticsEvents:(NSArray<NSDictionary *> *)events
                    completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
