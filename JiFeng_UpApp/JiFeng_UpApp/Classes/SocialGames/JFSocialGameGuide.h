//
//  JFSocialGameGuide.h
//  JiFeng_UpApp
//

#import <Foundation/Foundation.h>
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JFSocialGameMood) {
    JFSocialGameMoodIcebreaker,
    JFSocialGameMoodFriends,
    JFSocialGameMoodLively,
    JFSocialGameMoodThinking,
};

@interface JFSocialGameGuide : NSObject

@property (nonatomic, copy) NSString *guideId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbolName;
@property (nonatomic, assign) NSInteger minPlayers;
@property (nonatomic, assign) NSInteger maxPlayers;
@property (nonatomic, assign) NSInteger durationMinutes;
@property (nonatomic, assign) JFSocialGameMood mood;
@property (nonatomic, copy) NSString *props;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *setup;
@property (nonatomic, copy) NSArray<NSString *> *steps;
@property (nonatomic, copy) NSArray<NSString *> *tips;
@property (nonatomic, strong, nullable) NSNumber *launchKindValue;

@property (nonatomic, readonly) NSString *playersText;
@property (nonatomic, readonly) NSString *durationText;
@property (nonatomic, readonly) NSString *moodText;
@property (nonatomic, readonly) BOOL playableInApp;

+ (NSArray<JFSocialGameGuide *> *)allGuides;
+ (NSString *)displayNameForMood:(JFSocialGameMood)mood;

@end

NS_ASSUME_NONNULL_END
