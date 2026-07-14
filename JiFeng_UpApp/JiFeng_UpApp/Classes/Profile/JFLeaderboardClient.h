//
//  JFLeaderboardClient.h
//  JiFeng_UpApp
//
//  排行榜抽象层。
//  - 当前 default 是 LocalMock 实现:把分数写到 NSUserDefaults,提供假榜单。
//  - 后端接入后,新增一个 NetworkImpl,setSharedClient: 替换即可,
//    业务侧(Profile / 各游戏)零改动。
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFLeaderboardEntry : NSObject
@property (nonatomic, copy)   NSString *playerId;     // 当前用户匿名 id
@property (nonatomic, copy)   NSString *displayName;  // 昵称
@property (nonatomic, assign) NSInteger score;
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, strong) NSDate   *date;
@property (nonatomic, assign) BOOL      isMe;
@end

#pragma mark -

typedef void (^JFLeaderboardSubmitCompletion)(BOOL success, NSError * _Nullable error);
typedef void (^JFLeaderboardFetchCompletion)(NSArray<JFLeaderboardEntry *> * _Nullable entries,
                                             JFLeaderboardEntry * _Nullable myEntry,
                                             NSError * _Nullable error);

@protocol JFLeaderboardClient <NSObject>

@required

/// 上传一条新成绩。后端会内部去重/取最大值。
- (void)submitScore:(NSInteger)score
            forGame:(JFGameKind)kind
         difficulty:(NSInteger)difficulty
            duration:(NSTimeInterval)duration
                 win:(BOOL)win
               extra:(nullable NSDictionary<NSString *, id> *)extra
         completion:(JFLeaderboardSubmitCompletion _Nullable)completion;

/// 拉取榜单 Top N。同时返回当前用户成绩(可能不在 top 里)。
- (void)fetchTopScoresForGame:(JFGameKind)kind
                    difficulty:(NSInteger)difficulty
                         limit:(NSInteger)limit
                    completion:(JFLeaderboardFetchCompletion)completion;

/// 当前匿名用户 id(本地生成 UUID,后端接入后由后端下发)
- (NSString *)playerId;

/// 当前昵称
- (NSString *)displayName;
- (void)setDisplayName:(NSString *)name;

@end

#pragma mark -

@interface JFLeaderboardClient : NSObject

/// 业务侧统一通过这个拿。默认是 LocalMock。
+ (id<JFLeaderboardClient>)shared;

/// 后端接入后,在 AppDelegate 里调一次替换即可。
+ (void)setSharedClient:(id<JFLeaderboardClient>)client;

@end

NS_ASSUME_NONNULL_END
