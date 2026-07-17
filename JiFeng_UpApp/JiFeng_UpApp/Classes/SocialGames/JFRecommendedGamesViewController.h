//
//  JFRecommendedGamesViewController.h
//  JiFeng_UpApp
//

#import "rootVcViewController.h"
#import "JFGameEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface JFRecommendedGamesViewController : rootVcViewController

@property (nonatomic, copy, nullable) void (^launchGameHandler)(JFGameKind kind);

@end

NS_ASSUME_NONNULL_END
