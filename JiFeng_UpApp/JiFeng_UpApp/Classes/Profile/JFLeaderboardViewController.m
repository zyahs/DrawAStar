//
//  JFLeaderboardViewController.m
//  JiFeng_UpApp
//

#import "JFLeaderboardViewController.h"
#import "JFTheme.h"
#import "JFGameEntry.h"
#import "JFLeaderboardClient.h"

@interface JFLeaderboardRowCell : UITableViewCell
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
- (void)configure:(JFLeaderboardEntry *)entry;
@end

@implementation JFLeaderboardRowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _rankLabel = [[UILabel alloc] init];
        _rankLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _rankLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        _rankLabel.textColor = [JFTheme accent];
        _rankLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_rankLabel];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [JFTheme fontCallout];
        _nameLabel.textColor = [JFTheme textPrimary];
        [self.contentView addSubview:_nameLabel];

        _scoreLabel = [[UILabel alloc] init];
        _scoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _scoreLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
        _scoreLabel.textColor = [JFTheme warning];
        _scoreLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_scoreLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_rankLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing12],
            [_rankLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_rankLabel.widthAnchor constraintEqualToConstant:42],

            [_nameLabel.leadingAnchor constraintEqualToAnchor:_rankLabel.trailingAnchor constant:JFSpacing12],
            [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_scoreLabel.leadingAnchor constant:-JFSpacing12],

            [_scoreLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing16],
            [_scoreLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_scoreLabel.widthAnchor constraintEqualToConstant:92],
        ]];
    }
    return self;
}

- (void)configure:(JFLeaderboardEntry *)entry {
    self.rankLabel.text = [NSString stringWithFormat:@"%ld", (long)entry.rank];
    self.nameLabel.text = entry.isMe ? [NSString stringWithFormat:@"%@ · 我", entry.displayName] : entry.displayName;
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)entry.score];
    self.contentView.backgroundColor = entry.isMe ? [[JFTheme accent] colorWithAlphaComponent:0.10] : UIColor.clearColor;
}

@end

@interface JFLeaderboardViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray<JFGameEntry *> *games;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) UIButton *gameButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray<JFLeaderboardEntry *> *entries;
@property (nonatomic, strong) UIView *themeBackground;
@end

@implementation JFLeaderboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.games = [JFGameEntry allEntries];
    self.entries = @[];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.themeBackground = [JFTheme installThemedBackgroundInView:self.view];
    [self setupUI];
    [self loadLeaderboard];
}

- (void)setupUI {
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"排行榜";
    title.font = [JFTheme fontTitle];
    title.textColor = [JFTheme textPrimary];
    [self.view addSubview:title];

    self.gameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.gameButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameButton.tintColor = [JFTheme textPrimary];
    [JFTheme decorateGlassPanel:self.gameButton];
    [self.gameButton addTarget:self action:@selector(onPickGame) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gameButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = [JFTheme separator];
    self.tableView.rowHeight = 56;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JFLeaderboardRowCell class] forCellReuseIdentifier:@"row"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text = @"暂无排行";
    self.emptyLabel.font = [JFTheme fontBody];
    self.emptyLabel.textColor = [JFTheme textSecondary];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:JFSpacing16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [self.gameButton.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:JFSpacing20],
        [self.gameButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [self.gameButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],
        [self.gameButton.heightAnchor constraintEqualToConstant:48],

        [self.tableView.topAnchor constraintEqualToAnchor:self.gameButton.bottomAnchor constant:JFSpacing12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    [self updateGameButton];
}

- (void)updateGameButton {
    JFGameEntry *game = self.games[self.selectedIndex];
    [self.gameButton setTitle:[NSString stringWithFormat:@"  %@ 排行榜", game.title] forState:UIControlStateNormal];
    [self.gameButton setImage:[UIImage systemImageNamed:game.symbolName] forState:UIControlStateNormal];
    self.gameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
}

- (void)loadLeaderboard {
    JFGameEntry *game = self.games[self.selectedIndex];
    [[JFLeaderboardClient shared] fetchTopScoresForGame:game.kind difficulty:0 limit:50 completion:^(NSArray<JFLeaderboardEntry *> * _Nullable entries, __unused JFLeaderboardEntry * _Nullable myEntry, __unused NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.entries = entries ?: @[];
            self.emptyLabel.hidden = self.entries.count > 0;
            [self.tableView reloadData];
        });
    }];
}

- (void)onPickGame {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择小游戏" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < self.games.count; i++) {
        JFGameEntry *game = self.games[i];
        [sheet addAction:[UIAlertAction actionWithTitle:game.title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            self.selectedIndex = i;
            [self updateGameButton];
            [self loadLeaderboard];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.gameButton;
    sheet.popoverPresentationController.sourceRect = self.gameButton.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JFLeaderboardRowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row" forIndexPath:indexPath];
    [cell configure:self.entries[indexPath.row]];
    return cell;
}

@end
