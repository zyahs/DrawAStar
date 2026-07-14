//
//  JFProfileViewController.m
//  JiFeng_UpApp
//

#import "JFProfileViewController.h"
#import "JFTheme.h"
#import "JFProfileStore.h"
#import "JFAchievementStore.h"
#import "JFSkinShopViewController.h"
#import "JFAchievementsViewController.h"
#import "JFSkinStore.h"

@interface JFProfileViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAGradientLayer *heroGradient;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *signatureLabel;
@property (nonatomic, strong) UILabel *levelLabel;
@property (nonatomic, strong) UILabel *coinLabel;
@property (nonatomic, strong) UILabel *streakLabel;
@property (nonatomic, strong) UILabel *gameLabel;
@property (nonatomic, strong) UIView *themeBackground;

@end

@implementation JFProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.themeBackground = [JFTheme installThemedBackgroundInView:self.view];
    [self setupScroll];
    [self setupHero];
    [self setupActions];
    [self setupStats];
    [self setupConstraints];
    [self refreshProfile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshProfile)
                                                 name:JFProfileDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSkinChanged)
                                                 name:JFSkinDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self refreshProfile];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.heroGradient.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 260);
}

- (void)onSkinChanged {
    [self.themeBackground removeFromSuperview];
    self.themeBackground = [JFTheme installThemedBackgroundInView:self.view];
    [self.view sendSubviewToBack:self.themeBackground];
    [self refreshProfile];
}

- (void)setupScroll {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];
}

- (void)setupHero {
    UIView *hero = [[UIView alloc] init];
    hero.translatesAutoresizingMaskIntoConstraints = NO;
    hero.tag = 9201;
    hero.layer.cornerRadius = 0;
    hero.clipsToBounds = YES;
    [self.contentView addSubview:hero];

    self.heroGradient = [CAGradientLayer layer];
    [hero.layer addSublayer:self.heroGradient];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.contentMode = UIViewContentModeCenter;
    self.avatarView.tintColor = [UIColor whiteColor];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    self.avatarView.layer.cornerRadius = 44;
    self.avatarView.layer.cornerCurve = kCACornerCurveContinuous;
    self.avatarView.layer.borderWidth = 1;
    self.avatarView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.28].CGColor;
    self.avatarView.clipsToBounds = YES;
    [hero addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    self.nameLabel.textColor = [JFTheme textPrimary];
    [hero addSubview:self.nameLabel];

    self.signatureLabel = [[UILabel alloc] init];
    self.signatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.signatureLabel.font = [JFTheme fontBody];
    self.signatureLabel.textColor = [UIColor colorWithWhite:1 alpha:0.76];
    self.signatureLabel.numberOfLines = 2;
    [hero addSubview:self.signatureLabel];

    [NSLayoutConstraint activateConstraints:@[
        [hero.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [hero.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [hero.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [hero.heightAnchor constraintEqualToConstant:260],

        [self.avatarView.leadingAnchor constraintEqualToAnchor:hero.leadingAnchor constant:JFSpacing20],
        [self.avatarView.bottomAnchor constraintEqualToAnchor:hero.bottomAnchor constant:-JFSpacing32],
        [self.avatarView.widthAnchor constraintEqualToConstant:88],
        [self.avatarView.heightAnchor constraintEqualToConstant:88],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:JFSpacing16],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:hero.trailingAnchor constant:-JFSpacing20],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor constant:JFSpacing8],

        [self.signatureLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.signatureLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],
        [self.signatureLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:JFSpacing8],
    ]];
}

- (void)setupActions {
    NSArray<UIButton *> *buttons = @[
        [self actionButtonWithTitle:@"编辑昵称" image:@"pencil" action:@selector(onEditName)],
        [self actionButtonWithTitle:@"换头像" image:@"person.crop.circle" action:@selector(onPickAvatar)],
        [self actionButtonWithTitle:@"换背景" image:@"paintpalette" action:@selector(onPickBackground)],
        [self actionButtonWithTitle:@"签名" image:@"quote.bubble" action:@selector(onEditSignature)],
    ];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:buttons];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = JFSpacing12;
    stack.tag = 9202;
    [self.contentView addSubview:stack];
}

- (void)setupStats {
    self.levelLabel = [self statLabel];
    self.coinLabel = [self statLabel];
    self.streakLabel = [self statLabel];
    self.gameLabel = [self statLabel];

    UIStackView *grid = [[UIStackView alloc] initWithArrangedSubviews:@[self.levelLabel, self.coinLabel, self.streakLabel, self.gameLabel]];
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    grid.axis = UILayoutConstraintAxisVertical;
    grid.spacing = JFSpacing12;
    grid.tag = 9203;
    [self.contentView addSubview:grid];

    UIButton *ach = [self actionButtonWithTitle:@"成就墙" image:@"medal" action:@selector(onAchievements)];
    ach.tag = 9204;
    [self.contentView addSubview:ach];

    UIButton *skin = [self actionButtonWithTitle:@"皮肤商店" image:@"sparkles" action:@selector(onSkinShop)];
    skin.tag = 9205;
    [self.contentView addSubview:skin];
}

- (void)setupConstraints {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    UIView *hero = [self.contentView viewWithTag:9201];
    UIView *actions = [self.contentView viewWithTag:9202];
    UIView *stats = [self.contentView viewWithTag:9203];
    UIView *ach = [self.contentView viewWithTag:9204];
    UIView *skin = [self.contentView viewWithTag:9205];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],
        [hero.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],

        [actions.topAnchor constraintEqualToAnchor:hero.bottomAnchor constant:JFSpacing20],
        [actions.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing20],
        [actions.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing20],

        [stats.topAnchor constraintEqualToAnchor:actions.bottomAnchor constant:JFSpacing20],
        [stats.leadingAnchor constraintEqualToAnchor:actions.leadingAnchor],
        [stats.trailingAnchor constraintEqualToAnchor:actions.trailingAnchor],

        [ach.topAnchor constraintEqualToAnchor:stats.bottomAnchor constant:JFSpacing20],
        [ach.leadingAnchor constraintEqualToAnchor:actions.leadingAnchor],
        [ach.trailingAnchor constraintEqualToAnchor:actions.trailingAnchor],
        [ach.heightAnchor constraintEqualToConstant:52],

        [skin.topAnchor constraintEqualToAnchor:ach.bottomAnchor constant:JFSpacing12],
        [skin.leadingAnchor constraintEqualToAnchor:actions.leadingAnchor],
        [skin.trailingAnchor constraintEqualToAnchor:actions.trailingAnchor],
        [skin.heightAnchor constraintEqualToConstant:52],
        [skin.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-JFSpacing32],
    ]];
}

- (UIButton *)actionButtonWithTitle:(NSString *)title image:(NSString *)image action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tintColor = [JFTheme textPrimary];
    [JFTheme decorateGlassPanel:button];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        config.contentInsets = NSDirectionalEdgeInsetsMake(0, JFSpacing16, 0, JFSpacing16);
        config.imagePadding = JFSpacing8;
        config.title = title;
        config.image = [UIImage systemImageNamed:image];
        button.configuration = config;
    } else {
        [button setTitle:[NSString stringWithFormat:@"  %@", title] forState:UIControlStateNormal];
        [button setImage:[UIImage systemImageNamed:image] forState:UIControlStateNormal];
    }
    [button setTitleColor:[JFTheme textPrimary] forState:UIControlStateNormal];
    button.titleLabel.font = [JFTheme fontCallout];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintEqualToConstant:52].active = YES;
    return button;
}

- (UILabel *)statLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [JFTheme fontCallout];
    label.textColor = [JFTheme textPrimary];
    label.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    label.layer.cornerRadius = JFRadiusMedium;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.layer.borderWidth = 1.0;
    label.layer.borderColor = [JFTheme cardBorder].CGColor;
    label.clipsToBounds = YES;
    label.textAlignment = NSTextAlignmentCenter;
    [label.heightAnchor constraintEqualToConstant:48].active = YES;
    return label;
}

- (void)refreshProfile {
    JFProfileStore *p = [JFProfileStore shared];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightSemibold];
    self.avatarView.image = [UIImage systemImageNamed:p.avatarSymbolName withConfiguration:cfg] ?: [UIImage systemImageNamed:@"person.crop.circle.fill" withConfiguration:cfg];
    self.nameLabel.text = p.displayName;
    self.signatureLabel.text = p.signature;
    self.levelLabel.text = [NSString stringWithFormat:@"等级 Lv %ld · 距离下一级 %ld 风之币", (long)p.level, (long)[p coinsToNextLevel]];
    self.coinLabel.text = [NSString stringWithFormat:@"风之币 %ld · 总积分 %ld", (long)p.coins, (long)p.totalScore];
    self.streakLabel.text = [NSString stringWithFormat:@"连续 %ld 天 · 最高连续 %ld 天", (long)p.currentStreakDays, (long)p.longestStreakDays];
    self.gameLabel.text = [NSString stringWithFormat:@"总局数 %ld · 成就 %ld/%ld", (long)p.totalGamesPlayed, (long)[JFAchievementStore shared].unlockedCount, (long)[JFAchievementStore shared].totalCount];
    [self applyBackgroundStyle:p.backgroundStyle];
}

- (void)applyBackgroundStyle:(NSString *)style {
    NSArray<UIColor *> *colors = @[[JFTheme brandPrimary], [JFTheme brandSecondary], [JFTheme accent]];
    if ([style isEqualToString:@"sunset"]) {
        colors = @[[UIColor colorWithRed:0.98 green:0.36 blue:0.42 alpha:1],
                   [UIColor colorWithRed:0.99 green:0.70 blue:0.30 alpha:1],
                   [UIColor colorWithRed:0.32 green:0.18 blue:0.45 alpha:1]];
    } else if ([style isEqualToString:@"ocean"]) {
        colors = @[[UIColor colorWithRed:0.10 green:0.42 blue:0.86 alpha:1],
                   [UIColor colorWithRed:0.20 green:0.82 blue:0.86 alpha:1],
                   [UIColor colorWithRed:0.04 green:0.12 blue:0.20 alpha:1]];
    } else if ([style isEqualToString:@"forest"]) {
        colors = @[[UIColor colorWithRed:0.18 green:0.64 blue:0.42 alpha:1],
                   [UIColor colorWithRed:0.76 green:0.82 blue:0.30 alpha:1],
                   [UIColor colorWithRed:0.04 green:0.16 blue:0.12 alpha:1]];
    }
    self.heroGradient.colors = @[(__bridge id)colors[0].CGColor, (__bridge id)colors[1].CGColor, (__bridge id)colors[2].CGColor];
    self.heroGradient.startPoint = CGPointMake(0, 0);
    self.heroGradient.endPoint = CGPointMake(1, 1);
}

- (void)onEditName {
    [self showTextEditorWithTitle:@"编辑昵称" value:[JFProfileStore shared].displayName placeholder:@"输入昵称" handler:^(NSString *text) {
        [[JFProfileStore shared] updateDisplayName:text];
    }];
}

- (void)onEditSignature {
    [self showTextEditorWithTitle:@"编辑签名" value:[JFProfileStore shared].signature placeholder:@"写一句签名" handler:^(NSString *text) {
        [[JFProfileStore shared] updateSignature:text];
    }];
}

- (void)showTextEditorWithTitle:(NSString *)title value:(NSString *)value placeholder:(NSString *)placeholder handler:(void (^)(NSString *text))handler {
    [JFTheme hapticImpactLight];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = value;
        textField.placeholder = placeholder;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        if (handler) handler(alert.textFields.firstObject.text ?: @"");
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onPickAvatar {
    [self showChoiceSheetWithTitle:@"选择头像"
                           choices:@[
        @[@"person.crop.circle.fill", @"默认"],
        @[@"gamecontroller.fill", @"玩家"],
        @[@"sparkles", @"星光"],
        @[@"flame.fill", @"热场"],
        @[@"crown.fill", @"王者"],
    ] handler:^(NSString *value) {
        [[JFProfileStore shared] updateAvatarSymbolName:value];
    }];
}

- (void)onPickBackground {
    [self showChoiceSheetWithTitle:@"选择背景"
                           choices:@[
        @[@"aurora", @"极光"],
        @[@"sunset", @"落日"],
        @[@"ocean", @"海面"],
        @[@"forest", @"森林"],
    ] handler:^(NSString *value) {
        [[JFProfileStore shared] updateBackgroundStyle:value];
    }];
}

- (void)showChoiceSheetWithTitle:(NSString *)title choices:(NSArray<NSArray<NSString *> *> *)choices handler:(void (^)(NSString *value))handler {
    [JFTheme hapticImpactLight];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSArray<NSString *> *choice in choices) {
        NSString *value = choice.firstObject ?: @"";
        NSString *label = choice.count > 1 ? choice[1] : value;
        [sheet addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            if (handler) handler(value);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height - 40, 1, 1);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onAchievements {
    [self.navigationController pushViewController:[[JFAchievementsViewController alloc] init] animated:YES];
}

- (void)onSkinShop {
    [self.navigationController pushViewController:[[JFSkinShopViewController alloc] init] animated:YES];
}

@end
