//
//  HomeViewController.m
//

#import "HomeViewController.h"
#import "JFTheme.h"
#import "JFGameEntry.h"
#import "JFGameTileCell.h"
#import "JFProfileStore.h"
#import "JFAchievementStore.h"
#import "JFDailyChallengeStore.h"
#import "JFAchievementsViewController.h"
#import "JFSkinShopViewController.h"
#import "JFProfileViewController.h"
#import "JFLeaderboardViewController.h"
#import "JFSkinStore.h"
#import "JFBackendClient.h"
#import "JFAnalyticsTracker.h"
#import "JFChatViewController.h"
#import "rootVcViewController.h"

// 跳转目的地
#import "StarDrawingViewController.h"
#import "EntangleMergeViewController.h"
#import "CubeViewController.h"
#import "FiveQiVc.h"
#import "UndercoverViewController.h"
#import "KingGameViewController.h"
#import "JFCardCollectionViewController.h"
#import "GestureBombViewController.h"
#import "JFPuzzleViewController.h"
#import "JFSnakeViewController.h"
#import "JF2048ViewController.h"
#import "JFSudokuViewController.h"
#import "JFMemoryViewController.h"
#import "JFReactionViewController.h"
#import "JFRhythmViewController.h"
#import "JFSokobanViewController.h"
#import "JFPacmanViewController.h"
#import "JFRecommendedGamesViewController.h"
#import "JFNeverHaveIEverViewController.h"
#import "JFDrawGuessViewController.h"

@interface HomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView              *themedBackgroundView;

@property (nonatomic, strong) UIScrollView        *scrollView;
@property (nonatomic, strong) UIView              *contentView;

// header
@property (nonatomic, strong) UILabel             *titleLabel;
@property (nonatomic, strong) UILabel             *subtitleLabel;

// profile bar
@property (nonatomic, strong) UIView              *profileBar;
@property (nonatomic, strong) UILabel             *levelLabel;
@property (nonatomic, strong) UILabel             *coinsLabel;
@property (nonatomic, strong) UILabel             *streakLabel;
@property (nonatomic, strong) UILabel             *achLabel;
@property (nonatomic, strong) UIView              *progressBg;
@property (nonatomic, strong) UIView              *progressFill;
@property (nonatomic, strong) NSLayoutConstraint  *progressFillWidth;

// daily challenge
@property (nonatomic, strong) UIView              *dailyBanner;
@property (nonatomic, strong) UILabel             *dailyTitleLabel;
@property (nonatomic, strong) UILabel             *dailyDescLabel;
@property (nonatomic, strong) UILabel             *dailyStatusLabel;

// quick actions
@property (nonatomic, strong) UIView              *tabPageContainer;
@property (nonatomic, strong) UIView              *footerScrimView;
@property (nonatomic, strong) CAGradientLayer     *footerScrimGradient;
@property (nonatomic, strong) UIView              *quickActionsPanel;
@property (nonatomic, strong) NSArray<UIButton *> *footerTabButtons;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIViewController *> *footerTabControllers;
@property (nonatomic, strong, nullable) UIViewController *activeFooterTabController;
@property (nonatomic, assign) NSInteger selectedFooterTabIndex;

// games grid
@property (nonatomic, strong) UICollectionView    *collectionView;
@property (nonatomic, strong) NSLayoutConstraint  *collectionHeight;
@property (nonatomic, strong) NSArray<JFGameEntry *> *entries;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.entries = [JFGameEntry allEntries];
    self.footerTabControllers = [NSMutableDictionary dictionary];
    self.selectedFooterTabIndex = 0;

    [self setupBackground];
    [self setupScroll];
    [self setupHeader];
    [self setupProfileBar];
    [self setupDailyBanner];
    [self setupQuickActions];
    [self setupCollectionView];
    [self setupConstraints];

    [self animateEntrance];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshDynamic)
                                                 name:JFProfileDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshDynamic)
                                                 name:JFDailyChallengeDidUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAchievementUnlocked:)
                                                 name:JFAchievementUnlockedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSkinChanged)
                                                 name:JFSkinDidChangeNotification
                                               object:nil];
}

- (void)onSkinChanged {
    [self.themedBackgroundView removeFromSuperview];
    self.themedBackgroundView = [JFTheme installThemedBackgroundInView:self.view];
    [self.view sendSubviewToBack:self.themedBackgroundView];

    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.profileBar.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.progressFill.backgroundColor = [JFTheme accent];
    self.dailyBanner.layer.borderColor = [[JFTheme accent] colorWithAlphaComponent:0.6].CGColor;
    self.dailyBanner.backgroundColor   = [[JFTheme accent] colorWithAlphaComponent:0.10];
    [self refreshDynamic];
    [self.collectionView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[JFAnalyticsTracker shared] endCurrentGameSessionWithReason:@"back_to_home"];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[JFProfileStore shared] markAppActive];
    [[JFAchievementStore shared] evaluateProfileOnly:[JFProfileStore shared]];
    [[JFBackendClient shared] ensureSignedInWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) return;
        [[JFProfileStore shared] pullRemoteProfileWithCompletion:nil];
        [[JFProfileStore shared] pushLocalProfileWithCompletion:nil];
    }];
    [self refreshDynamic];
}

- (BOOL)prefersStatusBarHidden { return NO; }
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

#pragma mark - 背景

- (void)setupBackground {
    self.themedBackgroundView = [JFTheme installThemedBackgroundInView:self.view];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
    self.collectionHeight.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height;
    self.footerScrimGradient.frame = self.footerScrimView.bounds;

    // 进度条同步
    self.progressFillWidth.constant = MAX(0, self.progressBg.bounds.size.width * [[JFProfileStore shared] progressToNextLevel]);
}

#pragma mark - Scroll / Content

- (void)setupScroll {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 96, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];
}

#pragma mark - Header

- (void)setupHeader {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"一桌好戏";
    self.titleLabel.font = [JFTheme fontTitleXL];
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"人到齐，马上开玩";
    self.subtitleLabel.font = [JFTheme fontBody];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.subtitleLabel];
}

#pragma mark - Profile bar

- (void)setupProfileBar {
    self.profileBar = [[UIView alloc] init];
    self.profileBar.translatesAutoresizingMaskIntoConstraints = NO;
    [JFTheme decorateGlassPanel:self.profileBar];
    [self.contentView addSubview:self.profileBar];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfileBarTapped)];
    [self.profileBar addGestureRecognizer:tap];

    self.levelLabel  = [self chipLabel];
    self.coinsLabel  = [self chipLabel];
    self.streakLabel = [self chipLabel];
    self.achLabel    = [self chipLabel];

    UIStackView *chips = [[UIStackView alloc] initWithArrangedSubviews:@[self.levelLabel, self.coinsLabel, self.streakLabel, self.achLabel]];
    chips.translatesAutoresizingMaskIntoConstraints = NO;
    chips.axis = UILayoutConstraintAxisHorizontal;
    chips.distribution = UIStackViewDistributionFillEqually;
    chips.spacing = JFSpacing8;
    [self.profileBar addSubview:chips];

    self.progressBg = [[UIView alloc] init];
    self.progressBg.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBg.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    self.progressBg.layer.cornerRadius = 3;
    self.progressBg.clipsToBounds = YES;
    [self.profileBar addSubview:self.progressBg];

    self.progressFill = [[UIView alloc] init];
    self.progressFill.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressFill.backgroundColor = [JFTheme accent];
    self.progressFill.layer.cornerRadius = 3;
    [self.progressBg addSubview:self.progressFill];

    self.progressFillWidth = [self.progressFill.widthAnchor constraintEqualToConstant:0];

    [NSLayoutConstraint activateConstraints:@[
        [chips.topAnchor      constraintEqualToAnchor:self.profileBar.topAnchor constant:JFSpacing12],
        [chips.leadingAnchor  constraintEqualToAnchor:self.profileBar.leadingAnchor constant:JFSpacing12],
        [chips.trailingAnchor constraintEqualToAnchor:self.profileBar.trailingAnchor constant:-JFSpacing12],
        [chips.heightAnchor   constraintEqualToConstant:28],

        [self.progressBg.topAnchor      constraintEqualToAnchor:chips.bottomAnchor constant:JFSpacing12],
        [self.progressBg.leadingAnchor  constraintEqualToAnchor:self.profileBar.leadingAnchor constant:JFSpacing12],
        [self.progressBg.trailingAnchor constraintEqualToAnchor:self.profileBar.trailingAnchor constant:-JFSpacing12],
        [self.progressBg.heightAnchor   constraintEqualToConstant:6],
        [self.progressBg.bottomAnchor   constraintEqualToAnchor:self.profileBar.bottomAnchor constant:-JFSpacing12],

        [self.progressFill.leadingAnchor constraintEqualToAnchor:self.progressBg.leadingAnchor],
        [self.progressFill.topAnchor     constraintEqualToAnchor:self.progressBg.topAnchor],
        [self.progressFill.bottomAnchor  constraintEqualToAnchor:self.progressBg.bottomAnchor],
        self.progressFillWidth,
    ]];
}

- (UILabel *)chipLabel {
    UILabel *l = [[UILabel alloc] init];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    l.font = [JFTheme fontCallout];
    l.textColor = [JFTheme textPrimary];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    l.layer.cornerRadius = JFRadiusSmall;
    l.layer.cornerCurve = kCACornerCurveContinuous;
    l.layer.borderWidth = 0.5;
    l.layer.borderColor = [JFTheme cardBorder].CGColor;
    l.clipsToBounds = YES;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.6;
    return l;
}

- (void)onProfileBarTapped {
    [JFTheme hapticImpactLight];
    [self selectFooterTabAtIndex:5];
}

#pragma mark - Daily banner

- (void)setupDailyBanner {
    self.dailyBanner = [[UIView alloc] init];
    self.dailyBanner.translatesAutoresizingMaskIntoConstraints = NO;
    [JFTheme decorateGlassPanel:self.dailyBanner];
    self.dailyBanner.layer.borderColor  = [[JFTheme accent] colorWithAlphaComponent:0.6].CGColor;
    self.dailyBanner.backgroundColor    = [[JFTheme accent] colorWithAlphaComponent:0.10];
    [self.contentView addSubview:self.dailyBanner];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDailyTapped)];
    [self.dailyBanner addGestureRecognizer:tap];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"sun.max.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [JFTheme accent];
    icon.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightSemibold];
    [self.dailyBanner addSubview:icon];

    self.dailyTitleLabel = [[UILabel alloc] init];
    self.dailyTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dailyTitleLabel.font = [JFTheme fontHeadline];
    self.dailyTitleLabel.textColor = [JFTheme textPrimary];
    [self.dailyBanner addSubview:self.dailyTitleLabel];

    self.dailyDescLabel = [[UILabel alloc] init];
    self.dailyDescLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dailyDescLabel.font = [JFTheme fontCaption];
    self.dailyDescLabel.textColor = [JFTheme textSecondary];
    self.dailyDescLabel.numberOfLines = 1;
    [self.dailyBanner addSubview:self.dailyDescLabel];

    self.dailyStatusLabel = [[UILabel alloc] init];
    self.dailyStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dailyStatusLabel.font = [JFTheme fontCaption];
    self.dailyStatusLabel.textAlignment = NSTextAlignmentRight;
    [self.dailyBanner addSubview:self.dailyStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor   constraintEqualToAnchor:self.dailyBanner.leadingAnchor constant:JFSpacing16],
        [icon.centerYAnchor   constraintEqualToAnchor:self.dailyBanner.centerYAnchor],
        [icon.widthAnchor     constraintEqualToConstant:28],
        [icon.heightAnchor    constraintEqualToConstant:28],

        [self.dailyTitleLabel.topAnchor      constraintEqualToAnchor:self.dailyBanner.topAnchor constant:JFSpacing12],
        [self.dailyTitleLabel.leadingAnchor  constraintEqualToAnchor:icon.trailingAnchor constant:JFSpacing12],
        [self.dailyTitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.dailyStatusLabel.leadingAnchor constant:-JFSpacing8],

        [self.dailyDescLabel.topAnchor      constraintEqualToAnchor:self.dailyTitleLabel.bottomAnchor constant:2],
        [self.dailyDescLabel.leadingAnchor  constraintEqualToAnchor:self.dailyTitleLabel.leadingAnchor],
        [self.dailyDescLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.dailyStatusLabel.leadingAnchor constant:-JFSpacing8],
        [self.dailyDescLabel.bottomAnchor   constraintEqualToAnchor:self.dailyBanner.bottomAnchor constant:-JFSpacing12],

        [self.dailyStatusLabel.trailingAnchor constraintEqualToAnchor:self.dailyBanner.trailingAnchor constant:-JFSpacing16],
        [self.dailyStatusLabel.centerYAnchor  constraintEqualToAnchor:self.dailyBanner.centerYAnchor],
        [self.dailyStatusLabel.widthAnchor    constraintGreaterThanOrEqualToConstant:60],
    ]];
}

- (void)onDailyTapped {
    [JFTheme hapticImpactMedium];
    JFDailyChallenge *c = [[JFDailyChallengeStore shared] todayChallenge];
    [[JFAnalyticsTracker shared] trackGameCardClick:c.kind source:@"daily_challenge"];
    UIViewController *vc = [self destinationForKind:c.kind];
    if (vc) {
        [[JFAnalyticsTracker shared] beginGameSession:c.kind source:@"daily_challenge"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Quick Actions

- (void)setupQuickActions {
    self.tabPageContainer = [[UIView alloc] init];
    self.tabPageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabPageContainer.hidden = YES;
    [self.view addSubview:self.tabPageContainer];

    self.footerScrimView = [[UIView alloc] init];
    self.footerScrimView.translatesAutoresizingMaskIntoConstraints = NO;
    self.footerScrimView.userInteractionEnabled = NO;
    [self.view addSubview:self.footerScrimView];

    self.footerScrimGradient = [CAGradientLayer layer];
    self.footerScrimGradient.colors = @[
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.66].CGColor,
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.92].CGColor,
    ];
    self.footerScrimGradient.locations = @[@0.0, @0.42, @1.0];
    self.footerScrimGradient.startPoint = CGPointMake(0.5, 0.0);
    self.footerScrimGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.footerScrimView.layer addSublayer:self.footerScrimGradient];

    self.quickActionsPanel = [[UIView alloc] init];
    self.quickActionsPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [JFTheme decorateGlassPanel:self.quickActionsPanel];
    self.quickActionsPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.58];
    self.quickActionsPanel.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20].CGColor;
    self.quickActionsPanel.layer.cornerRadius = 22;
    self.quickActionsPanel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.quickActionsPanel.layer.shadowOpacity = 0.42;
    self.quickActionsPanel.layer.shadowRadius = 18;
    self.quickActionsPanel.layer.shadowOffset = CGSizeMake(0, 8);
    [self.view addSubview:self.quickActionsPanel];

    NSArray<UIButton *> *buttons = @[
        [self quickActionButtonWithTitle:@"游戏" image:@"gamecontroller.fill" action:@selector(onQuickGames)],
        [self quickActionButtonWithTitle:@"排行榜" image:@"chart.bar.xaxis" action:@selector(onQuickLeaderboard)],
        [self quickActionButtonWithTitle:@"大厅聊天" image:@"bubble.left.and.bubble.right.fill" action:@selector(onQuickChat)],
        [self quickActionButtonWithTitle:@"成就墙" image:@"medal.fill" action:@selector(onQuickAchievements)],
        [self quickActionButtonWithTitle:@"皮肤商店" image:@"sparkles" action:@selector(onQuickSkins)],
        [self quickActionButtonWithTitle:@"个人主页" image:@"person.crop.circle.fill" action:@selector(onQuickProfile)],
    ];
    self.footerTabButtons = buttons;
    for (NSInteger i = 0; i < buttons.count; i++) {
        buttons[i].tag = i;
    }

    UIStackView *tabs = [[UIStackView alloc] initWithArrangedSubviews:buttons];
    tabs.translatesAutoresizingMaskIntoConstraints = NO;
    tabs.axis = UILayoutConstraintAxisHorizontal;
    tabs.distribution = UIStackViewDistributionFillEqually;
    tabs.alignment = UIStackViewAlignmentFill;
    tabs.spacing = 4;
    [self.quickActionsPanel addSubview:tabs];

    [NSLayoutConstraint activateConstraints:@[
        [tabs.topAnchor constraintEqualToAnchor:self.quickActionsPanel.topAnchor constant:JFSpacing8],
        [tabs.leadingAnchor constraintEqualToAnchor:self.quickActionsPanel.leadingAnchor constant:JFSpacing8],
        [tabs.trailingAnchor constraintEqualToAnchor:self.quickActionsPanel.trailingAnchor constant:-JFSpacing8],
        [tabs.bottomAnchor constraintEqualToAnchor:self.quickActionsPanel.bottomAnchor constant:-JFSpacing8],
    ]];
    [self updateFooterTabSelection];
}

- (UIButton *)quickActionButtonWithTitle:(NSString *)title image:(NSString *)image action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tintColor = [JFTheme textPrimary];
    button.backgroundColor = [UIColor clearColor];
    button.layer.cornerRadius = 14;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.72;
    button.titleLabel.numberOfLines = 1;
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        config.title = title;
        config.image = [UIImage systemImageNamed:image];
        config.imagePlacement = NSDirectionalRectEdgeTop;
        config.imagePadding = 2;
        config.contentInsets = NSDirectionalEdgeInsetsMake(5, 1, 5, 1);
        config.baseForegroundColor = [JFTheme textPrimary];
        config.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> *(NSDictionary<NSAttributedStringKey,id> *incoming) {
            NSMutableDictionary<NSAttributedStringKey,id> *outgoing = [incoming mutableCopy];
            outgoing[NSFontAttributeName] = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
            return outgoing;
        };
        button.configuration = config;
    } else {
        [button setTitle:title forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:image] forState:UIControlStateNormal];
    }
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)onQuickGames {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:0];
}

- (void)onQuickLeaderboard {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:1];
}

- (void)onQuickChat {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:2];
}

- (void)onQuickAchievements {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:3];
}

- (void)onQuickSkins {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:4];
}

- (void)onQuickProfile {
    [JFTheme hapticSelection];
    [self selectFooterTabAtIndex:5];
}

- (void)selectFooterTabAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.footerTabButtons.count) return;
    if (self.selectedFooterTabIndex == index && ((index == 0 && self.scrollView.hidden == NO) || self.activeFooterTabController)) return;

    self.selectedFooterTabIndex = index;
    [self updateFooterTabSelection];

    if (index == 0) {
        [self.activeFooterTabController beginAppearanceTransition:NO animated:YES];
        [self.activeFooterTabController willMoveToParentViewController:nil];
        [self.activeFooterTabController.view removeFromSuperview];
        [self.activeFooterTabController removeFromParentViewController];
        [self.activeFooterTabController endAppearanceTransition];
        self.activeFooterTabController = nil;
        self.tabPageContainer.hidden = YES;
        self.scrollView.hidden = NO;
        return;
    }

    UIViewController *vc = [self footerTabControllerAtIndex:index];
    if (!vc || vc == self.activeFooterTabController) return;

    if (self.activeFooterTabController) {
        [self.activeFooterTabController beginAppearanceTransition:NO animated:YES];
        [self.activeFooterTabController willMoveToParentViewController:nil];
        [self.activeFooterTabController.view removeFromSuperview];
        [self.activeFooterTabController removeFromParentViewController];
        [self.activeFooterTabController endAppearanceTransition];
    }

    self.scrollView.hidden = YES;
    self.tabPageContainer.hidden = NO;
    self.activeFooterTabController = vc;

    [vc beginAppearanceTransition:YES animated:YES];
    [self addChildViewController:vc];
    vc.view.translatesAutoresizingMaskIntoConstraints = NO;
    vc.view.alpha = 0;
    [self.tabPageContainer addSubview:vc.view];
    [NSLayoutConstraint activateConstraints:@[
        [vc.view.topAnchor constraintEqualToAnchor:self.tabPageContainer.topAnchor],
        [vc.view.leadingAnchor constraintEqualToAnchor:self.tabPageContainer.leadingAnchor],
        [vc.view.trailingAnchor constraintEqualToAnchor:self.tabPageContainer.trailingAnchor],
        [vc.view.bottomAnchor constraintEqualToAnchor:self.tabPageContainer.bottomAnchor],
    ]];
    [vc didMoveToParentViewController:self];
    [UIView animateWithDuration:0.18 animations:^{
        vc.view.alpha = 1;
    } completion:^(__unused BOOL finished) {
        [vc endAppearanceTransition];
    }];
}

- (UIViewController *)footerTabControllerAtIndex:(NSInteger)index {
    NSNumber *key = @(index);
    UIViewController *vc = self.footerTabControllers[key];
    if (vc) return vc;

    switch (index) {
        case 1: vc = [[JFLeaderboardViewController alloc] init]; break;
        case 2: vc = [[JFChatViewController alloc] init]; break;
        case 3: vc = [[JFAchievementsViewController alloc] init]; break;
        case 4: vc = [[JFSkinShopViewController alloc] init]; break;
        case 5: vc = [[JFProfileViewController alloc] init]; break;
        default: break;
    }

    if ([vc isKindOfClass:[rootVcViewController class]]) {
        ((rootVcViewController *)vc).jfSuppressBackButton = YES;
    }
    if (vc) self.footerTabControllers[key] = vc;
    return vc;
}

- (void)updateFooterTabSelection {
    for (UIButton *button in self.footerTabButtons) {
        BOOL selected = button.tag == self.selectedFooterTabIndex;
        button.backgroundColor = selected ? [[JFTheme accent] colorWithAlphaComponent:0.22] : UIColor.clearColor;
        button.layer.borderWidth = selected ? 0.8 : 0;
        button.layer.borderColor = selected ? [[JFTheme accent] colorWithAlphaComponent:0.55].CGColor : [UIColor clearColor].CGColor;
        button.tintColor = selected ? [JFTheme accent] : [JFTheme textPrimary];
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *config = button.configuration;
            config.baseForegroundColor = selected ? [JFTheme accent] : [JFTheme textPrimary];
            button.configuration = config;
        }
    }
}

#pragma mark - CollectionView

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = JFSpacing12;
    layout.minimumLineSpacing      = JFSpacing12;
    layout.sectionInset = UIEdgeInsetsMake(JFSpacing8, JFSpacing20, JFSpacing24, JFSpacing20);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate   = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.scrollEnabled = NO;
    [self.collectionView registerClass:[JFGameTileCell class]
            forCellWithReuseIdentifier:[JFGameTileCell reuseId]];

    [self.contentView addSubview:self.collectionView];
}

- (void)setupConstraints {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.collectionHeight = [self.collectionView.heightAnchor constraintEqualToConstant:600];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor      constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor      constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentView.leadingAnchor  constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentView.bottomAnchor   constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentView.widthAnchor    constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],

        [self.titleLabel.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor constant:JFSpacing16],
        [self.titleLabel.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing20],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing20],

        [self.subtitleLabel.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],
        [self.subtitleLabel.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing20],
        [self.subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing20],

        [self.profileBar.topAnchor      constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:JFSpacing16],
        [self.profileBar.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing20],
        [self.profileBar.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing20],

        [self.dailyBanner.topAnchor      constraintEqualToAnchor:self.profileBar.bottomAnchor constant:JFSpacing12],
        [self.dailyBanner.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing20],
        [self.dailyBanner.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing20],
        [self.dailyBanner.heightAnchor   constraintEqualToConstant:64],

        [self.tabPageContainer.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.tabPageContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tabPageContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tabPageContainer.bottomAnchor constraintEqualToAnchor:self.quickActionsPanel.topAnchor constant:-JFSpacing8],

        [self.footerScrimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.footerScrimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.footerScrimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.footerScrimView.heightAnchor constraintEqualToConstant:140],

        [self.quickActionsPanel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing12],
        [self.quickActionsPanel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing12],
        [self.quickActionsPanel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-JFSpacing8],
        [self.quickActionsPanel.heightAnchor constraintEqualToConstant:68],

        [self.collectionView.topAnchor      constraintEqualToAnchor:self.dailyBanner.bottomAnchor constant:JFSpacing12],
        [self.collectionView.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.collectionView.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor],
        self.collectionHeight,
    ]];
}

#pragma mark - Dynamic refresh

- (void)refreshDynamic {
    JFProfileStore *p = [JFProfileStore shared];
    self.levelLabel.text  = [NSString stringWithFormat:@"Lv %ld", (long)p.level];
    self.coinsLabel.text  = [NSString stringWithFormat:@"风之币 %ld", (long)p.coins];
    self.streakLabel.text = [NSString stringWithFormat:@"连续 %ld 天", (long)p.currentStreakDays];
    JFAchievementStore *a = [JFAchievementStore shared];
    self.achLabel.text    = [NSString stringWithFormat:@"成就 %ld/%ld", (long)a.unlockedCount, (long)a.totalCount];

    CGFloat fillW = MAX(0, (self.progressBg.bounds.size.width) * [p progressToNextLevel]);
    self.progressFillWidth.constant = fillW;
    [UIView animateWithDuration:0.25 animations:^{ [self.profileBar layoutIfNeeded]; }];

    JFDailyChallenge *c = [[JFDailyChallengeStore shared] todayChallenge];
    self.dailyTitleLabel.text = [NSString stringWithFormat:@"今日挑战 · %@", c.title];
    self.dailyDescLabel.text  = c.desc;
    if (c.completed) {
        self.dailyStatusLabel.text = @"已完成";
        self.dailyStatusLabel.textColor = [JFTheme success];
    } else {
        self.dailyStatusLabel.text = @"开始";
        self.dailyStatusLabel.textColor = [JFTheme accent];
    }

    [self.collectionView reloadData];
}

- (void)onAchievementUnlocked:(NSNotification *)note {
    JFAchievement *a = note.userInfo[@"achievement"];
    if (!a) return;
    [self showAchievementToast:a];
}

#pragma mark - Achievement Toast

- (void)showAchievementToast:(JFAchievement *)a {
    UIView *toast = [[UIView alloc] init];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.backgroundColor = [JFTheme backgroundElevated];
    toast.layer.cornerRadius = JFRadiusMedium;
    toast.layer.cornerCurve  = kCACornerCurveContinuous;
    toast.layer.borderWidth  = 1;
    toast.layer.borderColor  = [[JFTheme accent] colorWithAlphaComponent:0.7].CGColor;
    toast.layer.shadowColor  = [UIColor blackColor].CGColor;
    toast.layer.shadowRadius = 12;
    toast.layer.shadowOpacity= 0.4;
    toast.layer.shadowOffset = CGSizeMake(0, 6);
    toast.alpha = 0;
    [self.view addSubview:toast];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:a.symbolName]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [JFTheme accent];
    icon.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightSemibold];
    [toast addSubview:icon];

    UILabel *l1 = [[UILabel alloc] init];
    l1.translatesAutoresizingMaskIntoConstraints = NO;
    l1.font = [JFTheme fontHeadline];
    l1.textColor = [JFTheme textPrimary];
    l1.text = [NSString stringWithFormat:@"成就达成 · %@", a.title];
    [toast addSubview:l1];

    UILabel *l2 = [[UILabel alloc] init];
    l2.translatesAutoresizingMaskIntoConstraints = NO;
    l2.font = [JFTheme fontCaption];
    l2.textColor = [JFTheme warning];
    l2.text = [NSString stringWithFormat:@"%@ · +%ld 风之币", a.desc, (long)a.coinReward];
    [toast addSubview:l2];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [toast.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [toast.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [toast.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [icon.leadingAnchor   constraintEqualToAnchor:toast.leadingAnchor constant:JFSpacing12],
        [icon.centerYAnchor   constraintEqualToAnchor:toast.centerYAnchor],
        [icon.widthAnchor     constraintEqualToConstant:32],
        [icon.heightAnchor    constraintEqualToConstant:32],

        [l1.topAnchor         constraintEqualToAnchor:toast.topAnchor constant:JFSpacing12],
        [l1.leadingAnchor     constraintEqualToAnchor:icon.trailingAnchor constant:JFSpacing12],
        [l1.trailingAnchor    constraintEqualToAnchor:toast.trailingAnchor constant:-JFSpacing12],

        [l2.topAnchor         constraintEqualToAnchor:l1.bottomAnchor constant:2],
        [l2.leadingAnchor     constraintEqualToAnchor:l1.leadingAnchor],
        [l2.trailingAnchor    constraintEqualToAnchor:l1.trailingAnchor],
        [l2.bottomAnchor      constraintEqualToAnchor:toast.bottomAnchor constant:-JFSpacing12],
    ]];

    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
    [UIView animateWithDuration:0.35 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.45 delay:2.4 options:0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL f) {
            [toast removeFromSuperview];
        }];
    }];
}

#pragma mark - Entrance

- (void)animateEntrance {
    NSArray *views = @[self.titleLabel, self.subtitleLabel, self.profileBar, self.dailyBanner, self.footerScrimView, self.quickActionsPanel];
    for (NSInteger i = 0; i < views.count; i++) {
        UIView *v = views[i];
        v.alpha = 0;
        v.transform = CGAffineTransformMakeTranslation(0, 12);
        [UIView animateWithDuration:0.5
                              delay:0.06 * i
             usingSpringWithDamping:0.85
              initialSpringVelocity:0.3
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            v.alpha = 1.0;
            v.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

#pragma mark - DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.entries.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFGameTileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[JFGameTileCell reuseId]
                                                                     forIndexPath:indexPath];
    JFGameEntry *e = self.entries[indexPath.item];
    [cell configureWithEntry:e index:indexPath.item];

    JFProfileStore *p = [JFProfileStore shared];
    [cell setStatsPlayCount:[p playCountForGame:e.kind] bestScore:[p bestScoreForGame:e.kind]];

    return cell;
}

#pragma mark - Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat sideInset = JFSpacing20 * 2;
    CGFloat itemSpacing = JFSpacing12;
    CGFloat totalWidth = collectionView.bounds.size.width - sideInset - itemSpacing;
    CGFloat w = totalWidth / 2.0;
    CGFloat h = w * 1.10;
    return CGSizeMake(floor(w), floor(h));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [JFTheme hapticImpactMedium];
    JFGameEntry *entry = self.entries[indexPath.item];
    [[JFAnalyticsTracker shared] trackGameCardClick:entry.kind source:@"home_grid"];
    UIViewController *vc = [self destinationForKind:entry.kind];
    if (vc) {
        [[JFAnalyticsTracker shared] beginGameSession:entry.kind source:@"home_grid"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - 路由

- (nullable UIViewController *)destinationForKind:(JFGameKind)kind {
    switch (kind) {
        case JFGameKindDrawBoard: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            return [storyboard instantiateViewControllerWithIdentifier:@"778"];
        }
        case JFGameKindTruthOrDare: return [[EntangleMergeViewController alloc] init];
        case JFGameKindDice:        return [[CubeViewController alloc] init];
        case JFGameKindFiveInRow:   return [[FiveQiVc alloc] init];
        case JFGameKindUndercover:  return [[UndercoverViewController alloc] init];
        case JFGameKindKing:        return [[KingGameViewController alloc] init];
        case JFGameKindCard:        return [[JFCardCollectionViewController alloc] init];
        case JFGameKindGesture:     return [[GestureBombViewController alloc] init];
        case JFGameKindPuzzle:      return [[JFPuzzleViewController alloc] init];
        case JFGameKindSnake:       return [[JFSnakeViewController alloc] init];
        case JFGameKind2048:        return [[JF2048ViewController alloc] init];
        case JFGameKindSudoku:      return [[JFSudokuViewController alloc] init];
        case JFGameKindMemory:      return [[JFMemoryViewController alloc] init];
        case JFGameKindReaction:    return [[JFReactionViewController alloc] init];
        case JFGameKindRhythm:      return [[JFRhythmViewController alloc] init];
        case JFGameKindSokoban:     return [[JFSokobanViewController alloc] init];
        case JFGameKindPacman:      return [[JFPacmanViewController alloc] init];
        case JFGameKindRecommendedSocial: {
            JFRecommendedGamesViewController *recommended = [[JFRecommendedGamesViewController alloc] init];
            __weak typeof(self) weakSelf = self;
            recommended.launchGameHandler = ^(JFGameKind targetKind) {
                UIViewController *target = [weakSelf destinationForKind:targetKind];
                if (!target) return;
                [[JFAnalyticsTracker shared] beginGameSession:targetKind source:@"social_recommendation"];
                [weakSelf.navigationController pushViewController:target animated:YES];
            };
            return recommended;
        }
        case JFGameKindNeverHaveIEver: return [[JFNeverHaveIEverViewController alloc] init];
        case JFGameKindDrawGuess: return [[JFDrawGuessViewController alloc] init];
    }
    return nil;
}

@end
