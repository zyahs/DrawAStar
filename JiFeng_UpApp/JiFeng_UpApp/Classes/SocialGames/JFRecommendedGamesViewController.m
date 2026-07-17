//
//  JFRecommendedGamesViewController.m
//  JiFeng_UpApp
//

#import "JFRecommendedGamesViewController.h"
#import "JFSocialGameGuide.h"
#import "JFTheme.h"
#import "JFSkinStore.h"
#import "JFAnalyticsTracker.h"

#pragma mark - Guide cell

@interface JFSocialGuideCell : UITableViewCell
@property (nonatomic, strong) UIView *surfaceView;
@property (nonatomic, strong) UIView *iconSurface;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UIImageView *playIcon;
@property (nonatomic, strong) UIImageView *chevronView;
- (void)configureWithGuide:(JFSocialGameGuide *)guide index:(NSInteger)index;
@end

@implementation JFSocialGuideCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _surfaceView = [[UIView alloc] init];
        _surfaceView.translatesAutoresizingMaskIntoConstraints = NO;
        _surfaceView.layer.cornerRadius = 8;
        _surfaceView.layer.borderWidth = 1;
        [self.contentView addSubview:_surfaceView];

        _iconSurface = [[UIView alloc] init];
        _iconSurface.translatesAutoresizingMaskIntoConstraints = NO;
        _iconSurface.layer.cornerRadius = 8;
        [_surfaceView addSubview:_iconSurface];

        _iconView = [[UIImageView alloc] init];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:24
                                                                                                    weight:UIImageSymbolWeightSemibold];
        [_iconSurface addSubview:_iconView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [JFTheme fontHeadline];
        [_surfaceView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        _subtitleLabel.numberOfLines = 1;
        [_surfaceView addSubview:_subtitleLabel];

        _metaLabel = [[UILabel alloc] init];
        _metaLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _metaLabel.font = [JFTheme fontCaption];
        _metaLabel.numberOfLines = 1;
        _metaLabel.adjustsFontSizeToFitWidth = YES;
        _metaLabel.minimumScaleFactor = 0.75;
        [_surfaceView addSubview:_metaLabel];

        _playIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"play.circle.fill"]];
        _playIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _playIcon.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:17
                                                                                                    weight:UIImageSymbolWeightSemibold];
        _playIcon.accessibilityLabel = @"可在 App 内开始";
        [_surfaceView addSubview:_playIcon];

        _chevronView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        _chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        _chevronView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:13
                                                                                                       weight:UIImageSymbolWeightBold];
        [_surfaceView addSubview:_chevronView];

        [NSLayoutConstraint activateConstraints:@[
            [_surfaceView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
            [_surfaceView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_surfaceView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_surfaceView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],

            [_iconSurface.leadingAnchor constraintEqualToAnchor:_surfaceView.leadingAnchor constant:12],
            [_iconSurface.centerYAnchor constraintEqualToAnchor:_surfaceView.centerYAnchor],
            [_iconSurface.widthAnchor constraintEqualToConstant:52],
            [_iconSurface.heightAnchor constraintEqualToConstant:52],

            [_iconView.centerXAnchor constraintEqualToAnchor:_iconSurface.centerXAnchor],
            [_iconView.centerYAnchor constraintEqualToAnchor:_iconSurface.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:30],
            [_iconView.heightAnchor constraintEqualToConstant:30],

            [_titleLabel.topAnchor constraintEqualToAnchor:_surfaceView.topAnchor constant:13],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_iconSurface.trailingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_playIcon.leadingAnchor constant:-8],

            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:3],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-8],

            [_metaLabel.topAnchor constraintEqualToAnchor:_subtitleLabel.bottomAnchor constant:5],
            [_metaLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_metaLabel.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-8],

            [_playIcon.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],
            [_playIcon.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-8],
            [_playIcon.widthAnchor constraintEqualToConstant:20],
            [_playIcon.heightAnchor constraintEqualToConstant:20],

            [_chevronView.trailingAnchor constraintEqualToAnchor:_surfaceView.trailingAnchor constant:-12],
            [_chevronView.centerYAnchor constraintEqualToAnchor:_surfaceView.centerYAnchor],
            [_chevronView.widthAnchor constraintEqualToConstant:12],
            [_chevronView.heightAnchor constraintEqualToConstant:18],
        ]];
    }
    return self;
}

- (void)configureWithGuide:(JFSocialGameGuide *)guide index:(NSInteger)index {
    NSArray<UIColor *> *colors = [JFTheme gradientColorsForIndex:index];
    UIColor *accent = colors.firstObject ?: [JFTheme accent];
    self.surfaceView.backgroundColor = [[JFTheme backgroundElevated] colorWithAlphaComponent:0.86];
    self.surfaceView.layer.borderColor = [JFTheme cardBorder].CGColor;
    self.iconSurface.backgroundColor = [accent colorWithAlphaComponent:0.18];
    self.iconView.image = [UIImage systemImageNamed:guide.symbolName] ?: [UIImage systemImageNamed:@"person.3.fill"];
    self.iconView.tintColor = accent;
    self.titleLabel.text = guide.title;
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.subtitleLabel.text = guide.subtitle;
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.metaLabel.text = [NSString stringWithFormat:@"%@ · %@ · %@", guide.playersText, guide.durationText, guide.moodText];
    self.metaLabel.textColor = [JFTheme textTertiary];
    self.playIcon.hidden = !guide.playableInApp;
    self.playIcon.tintColor = [JFTheme success];
    self.chevronView.tintColor = [JFTheme textTertiary];
    self.accessibilityLabel = [NSString stringWithFormat:@"%@，%@，%@，%@", guide.title, guide.playersText,
                               guide.durationText, guide.playableInApp ? @"可直接开始" : @"查看规则"];
}

@end

#pragma mark - Guide detail

@interface JFSocialGameGuideDetailViewController : rootVcViewController
@property (nonatomic, strong) JFSocialGameGuide *guide;
@property (nonatomic, copy, nullable) void (^launchHandler)(JFGameKind kind);
- (instancetype)initWithGuide:(JFSocialGameGuide *)guide;
@end

@implementation JFSocialGameGuideDetailViewController

- (instancetype)initWithGuide:(JFSocialGameGuide *)guide {
    if ((self = [super init])) {
        _guide = guide;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = self.guide.title;
    titleLabel.font = [JFTheme fontTitle];
    titleLabel.textColor = [JFTheme textPrimary];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.75;
    [self.view addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = self.guide.subtitle;
    subtitleLabel.font = [JFTheme fontCaption];
    subtitleLabel.textColor = [JFTheme textSecondary];
    [self.view addSubview:subtitleLabel];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];

    UIStackView *contentStack = [[UIStackView alloc] init];
    contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 14;
    [scrollView addSubview:contentStack];

    UIView *introView = [[UIView alloc] init];
    introView.backgroundColor = [[JFTheme backgroundElevated] colorWithAlphaComponent:0.82];
    introView.layer.cornerRadius = 8;
    introView.layer.borderWidth = 1;
    introView.layer.borderColor = [JFTheme cardBorder].CGColor;

    UIImage *guideImage = [UIImage systemImageNamed:self.guide.symbolName] ?: [UIImage systemImageNamed:@"person.3.fill"];
    UIImageView *introIcon = [[UIImageView alloc] initWithImage:guideImage];
    introIcon.translatesAutoresizingMaskIntoConstraints = NO;
    introIcon.tintColor = [JFTheme accent];
    introIcon.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:30
                                                                                               weight:UIImageSymbolWeightSemibold];
    [introView addSubview:introIcon];

    UILabel *summaryLabel = [self bodyLabel:self.guide.summary];
    [introView addSubview:summaryLabel];
    [NSLayoutConstraint activateConstraints:@[
        [introIcon.leadingAnchor constraintEqualToAnchor:introView.leadingAnchor constant:14],
        [introIcon.topAnchor constraintEqualToAnchor:introView.topAnchor constant:16],
        [introIcon.widthAnchor constraintEqualToConstant:38],
        [introIcon.heightAnchor constraintEqualToConstant:38],
        [summaryLabel.topAnchor constraintEqualToAnchor:introView.topAnchor constant:14],
        [summaryLabel.leadingAnchor constraintEqualToAnchor:introIcon.trailingAnchor constant:12],
        [summaryLabel.trailingAnchor constraintEqualToAnchor:introView.trailingAnchor constant:-14],
        [summaryLabel.bottomAnchor constraintEqualToAnchor:introView.bottomAnchor constant:-14],
    ]];
    [contentStack addArrangedSubview:introView];

    UIStackView *metaColumn = [[UIStackView alloc] init];
    metaColumn.axis = UILayoutConstraintAxisVertical;
    metaColumn.spacing = 10;
    [metaColumn addArrangedSubview:[self metaRowWithLeftSymbol:@"person.2.fill"
                                                     leftText:self.guide.playersText
                                                  rightSymbol:@"clock.fill"
                                                    rightText:self.guide.durationText]];
    [metaColumn addArrangedSubview:[self metaRowWithLeftSymbol:@"sparkles"
                                                     leftText:self.guide.moodText
                                                  rightSymbol:@"shippingbox.fill"
                                                    rightText:self.guide.props]];
    [contentStack addArrangedSubview:metaColumn];

    [contentStack addArrangedSubview:[self sectionTitle:@"开始前准备"]];
    [contentStack addArrangedSubview:[self bodyLabel:self.guide.setup]];

    [contentStack addArrangedSubview:[self separatorView]];
    [contentStack addArrangedSubview:[self sectionTitle:@"详细玩法"]];
    [self.guide.steps enumerateObjectsUsingBlock:^(NSString *step, NSUInteger idx, BOOL *stop) {
        [contentStack addArrangedSubview:[self stepRow:step number:idx + 1]];
    }];

    [contentStack addArrangedSubview:[self separatorView]];
    [contentStack addArrangedSubview:[self sectionTitle:@"玩得更舒服"]];
    for (NSString *tip in self.guide.tips) {
        [contentStack addArrangedSubview:[self tipRow:tip]];
    }

    if (self.guide.playableInApp) {
        UIButton *launchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
        configuration.title = @"在 App 内开始";
        configuration.image = [UIImage systemImageNamed:@"play.fill"];
        configuration.imagePadding = 8;
        configuration.baseBackgroundColor = [JFTheme brandPrimary];
        configuration.baseForegroundColor = [JFTheme textOnAccent];
        configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        launchButton.configuration = configuration;
        [launchButton addTarget:self action:@selector(onLaunch) forControlEvents:UIControlEventTouchUpInside];
        [launchButton.heightAnchor constraintEqualToConstant:52].active = YES;
        [contentStack addArrangedSubview:launchButton];
    }

    UIView *bottomSpace = [[UIView alloc] init];
    [bottomSpace.heightAnchor constraintEqualToConstant:18].active = YES;
    [contentStack addArrangedSubview:bottomSpace];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [titleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

        [scrollView.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:14],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],

        [contentStack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentStack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:18],
        [contentStack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-18],
        [contentStack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentStack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-36],
    ]];

    [[JFAnalyticsTracker shared] trackEvent:@"social_guide_view"
                                  properties:@{ @"guideId": self.guide.guideId ?: @"" }];
}

- (UILabel *)bodyLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = [JFTheme fontBody];
    label.textColor = [JFTheme textSecondary];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    return label;
}

- (UILabel *)sectionTitle:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [JFTheme fontHeadline];
    label.textColor = [JFTheme textPrimary];
    return label;
}

- (UIView *)separatorView {
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [JFTheme separator];
    [separator.heightAnchor constraintEqualToConstant:1].active = YES;
    return separator;
}

- (UIStackView *)metaRowWithLeftSymbol:(NSString *)leftSymbol
                              leftText:(NSString *)leftText
                           rightSymbol:(NSString *)rightSymbol
                             rightText:(NSString *)rightText {
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self metaItemWithSymbol:leftSymbol text:leftText],
        [self metaItemWithSymbol:rightSymbol text:rightText],
    ]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 12;
    return row;
}

- (UIStackView *)metaItemWithSymbol:(NSString *)symbol text:(NSString *)text {
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol]];
    icon.tintColor = [JFTheme accent];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [icon.widthAnchor constraintEqualToConstant:19].active = YES;
    [icon.heightAnchor constraintEqualToConstant:19].active = YES;
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = [JFTheme textSecondary];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.75;
    UIStackView *item = [[UIStackView alloc] initWithArrangedSubviews:@[icon, label]];
    item.axis = UILayoutConstraintAxisHorizontal;
    item.alignment = UIStackViewAlignmentCenter;
    item.spacing = 7;
    return item;
}

- (UIStackView *)stepRow:(NSString *)text number:(NSUInteger)number {
    UILabel *numberLabel = [[UILabel alloc] init];
    numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)number];
    numberLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    numberLabel.textColor = [JFTheme textOnAccent];
    numberLabel.textAlignment = NSTextAlignmentCenter;
    numberLabel.backgroundColor = [JFTheme brandPrimary];
    numberLabel.layer.cornerRadius = 8;
    numberLabel.clipsToBounds = YES;
    [numberLabel.widthAnchor constraintEqualToConstant:28].active = YES;
    [numberLabel.heightAnchor constraintEqualToConstant:28].active = YES;
    UILabel *body = [self bodyLabel:text];
    body.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[numberLabel, body]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentTop;
    row.spacing = 12;
    return row;
}

- (UIStackView *)tipRow:(NSString *)text {
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.shield.fill"]];
    icon.tintColor = [JFTheme success];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [icon.widthAnchor constraintEqualToConstant:20].active = YES;
    [icon.heightAnchor constraintEqualToConstant:20].active = YES;
    UILabel *label = [self bodyLabel:text];
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[icon, label]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentTop;
    row.spacing = 10;
    return row;
}

- (void)onLaunch {
    if (!self.guide.launchKindValue || !self.launchHandler) return;
    [JFTheme hapticImpactMedium];
    [[JFAnalyticsTracker shared] trackEvent:@"social_guide_launch"
                                  properties:@{ @"guideId": self.guide.guideId ?: @"" }];
    self.launchHandler((JFGameKind)self.guide.launchKindValue.integerValue);
}

@end

#pragma mark - Recommended list

@interface JFRecommendedGamesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSArray<JFSocialGameGuide *> *allGuides;
@property (nonatomic, copy) NSArray<JFSocialGameGuide *> *filteredGuides;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UISegmentedControl *peopleControl;
@property (nonatomic, strong) UIButton *moodButton;
@property (nonatomic, strong) UIButton *randomButton;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger moodFilter;
@end

@implementation JFRecommendedGamesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.allGuides = [JFSocialGameGuide allGuides];
    self.filteredGuides = self.allGuides;
    self.moodFilter = -1;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"推荐游戏";
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textColor = [JFTheme textPrimary];
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.text = @"按人数和气氛，快速找到今晚适合的玩法";
    self.subtitleLabel.font = [JFTheme fontCaption];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.subtitleLabel.numberOfLines = 1;
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.minimumScaleFactor = 0.8;
    [self.view addSubview:self.subtitleLabel];

    self.peopleControl = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"2-4 人", @"5-8 人", @"9 人+"]];
    self.peopleControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.peopleControl.selectedSegmentIndex = 0;
    self.peopleControl.selectedSegmentTintColor = [JFTheme brandPrimary];
    [self.peopleControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary]}
                                     forState:UIControlStateNormal];
    [self.peopleControl addTarget:self action:@selector(onFilterChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.peopleControl];

    self.moodButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.moodButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.moodButton.showsMenuAsPrimaryAction = YES;
    [self.view addSubview:self.moodButton];

    self.randomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.randomButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIButtonConfiguration *randomConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    randomConfiguration.title = @"帮我选";
    randomConfiguration.image = [UIImage systemImageNamed:@"shuffle"];
    randomConfiguration.imagePadding = 7;
    randomConfiguration.baseBackgroundColor = [JFTheme brandPrimary];
    randomConfiguration.baseForegroundColor = [JFTheme textOnAccent];
    randomConfiguration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    self.randomButton.configuration = randomConfiguration;
    [self.randomButton addTarget:self action:@selector(onRandom) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.randomButton];

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultLabel.font = [JFTheme fontCaption];
    self.resultLabel.textColor = [JFTheme textTertiary];
    [self.view addSubview:self.resultLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 116;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:JFSocialGuideCell.class forCellReuseIdentifier:@"guide"];
    [self.view addSubview:self.tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.peopleControl.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:16],
        [self.peopleControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.peopleControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.peopleControl.heightAnchor constraintEqualToConstant:36],

        [self.moodButton.topAnchor constraintEqualToAnchor:self.peopleControl.bottomAnchor constant:10],
        [self.moodButton.leadingAnchor constraintEqualToAnchor:self.peopleControl.leadingAnchor],
        [self.moodButton.widthAnchor constraintEqualToConstant:142],
        [self.moodButton.heightAnchor constraintEqualToConstant:40],

        [self.randomButton.topAnchor constraintEqualToAnchor:self.moodButton.topAnchor],
        [self.randomButton.trailingAnchor constraintEqualToAnchor:self.peopleControl.trailingAnchor],
        [self.randomButton.widthAnchor constraintEqualToConstant:124],
        [self.randomButton.heightAnchor constraintEqualToConstant:40],

        [self.resultLabel.topAnchor constraintEqualToAnchor:self.moodButton.bottomAnchor constant:9],
        [self.resultLabel.leadingAnchor constraintEqualToAnchor:self.peopleControl.leadingAnchor],
        [self.resultLabel.trailingAnchor constraintEqualToAnchor:self.peopleControl.trailingAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:self.resultLabel.bottomAnchor constant:4],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];

    [self rebuildMoodMenu];
    [self applyFiltersTracking:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTheme)
                                                 name:JFSkinDidChangeNotification
                                               object:nil];
}

- (void)refreshTheme {
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.resultLabel.textColor = [JFTheme textTertiary];
    self.peopleControl.selectedSegmentTintColor = [JFTheme brandPrimary];
    UIButtonConfiguration *randomConfiguration = self.randomButton.configuration;
    randomConfiguration.baseBackgroundColor = [JFTheme brandPrimary];
    randomConfiguration.baseForegroundColor = [JFTheme textOnAccent];
    self.randomButton.configuration = randomConfiguration;
    [self rebuildMoodMenu];
    [self.tableView reloadData];
}

- (void)rebuildMoodMenu {
    NSMutableArray<UIAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    UIAction *allAction = [UIAction actionWithTitle:@"全部氛围"
                                             image:[UIImage systemImageNamed:@"slider.horizontal.3"]
                                        identifier:nil
                                           handler:^(__kindof UIAction *action) {
        weakSelf.moodFilter = -1;
        [weakSelf rebuildMoodMenu];
        [weakSelf applyFiltersTracking:YES];
    }];
    allAction.state = self.moodFilter < 0 ? UIMenuElementStateOn : UIMenuElementStateOff;
    [actions addObject:allAction];
    NSArray<NSString *> *symbols = @[@"face.smiling", @"bubble.left.and.bubble.right.fill", @"sparkles", @"questionmark.circle.fill"];
    for (NSInteger mood = JFSocialGameMoodIcebreaker; mood <= JFSocialGameMoodThinking; mood++) {
        UIAction *action = [UIAction actionWithTitle:[JFSocialGameGuide displayNameForMood:mood]
                                              image:[UIImage systemImageNamed:symbols[mood]]
                                         identifier:nil
                                            handler:^(__kindof UIAction *selectedAction) {
            weakSelf.moodFilter = mood;
            [weakSelf rebuildMoodMenu];
            [weakSelf applyFiltersTracking:YES];
        }];
        action.state = self.moodFilter == mood ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    self.moodButton.menu = [UIMenu menuWithTitle:@"选择今晚的氛围" children:actions];
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = self.moodFilter < 0 ? @"全部氛围" : [JFSocialGameGuide displayNameForMood:self.moodFilter];
    configuration.image = [UIImage systemImageNamed:@"slider.horizontal.3"];
    configuration.imagePadding = 7;
    configuration.baseForegroundColor = [JFTheme accent];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    self.moodButton.configuration = configuration;
}

- (void)onFilterChanged {
    [JFTheme hapticSelection];
    [self applyFiltersTracking:YES];
}

- (void)applyFiltersTracking:(BOOL)track {
    NSInteger people = self.peopleControl.selectedSegmentIndex;
    NSInteger mood = self.moodFilter;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JFSocialGameGuide *guide, NSDictionary *bindings) {
        BOOL matchesPeople = YES;
        if (people == 1) matchesPeople = guide.minPlayers <= 4 && guide.maxPlayers >= 2;
        else if (people == 2) matchesPeople = guide.minPlayers <= 8 && guide.maxPlayers >= 5;
        else if (people == 3) matchesPeople = guide.maxPlayers >= 9;
        BOOL matchesMood = mood < 0 || guide.mood == mood;
        return matchesPeople && matchesMood;
    }];
    self.filteredGuides = [self.allGuides filteredArrayUsingPredicate:predicate];
    self.resultLabel.text = [NSString stringWithFormat:@"找到 %lu 个玩法 · 点开可查看完整规则", (unsigned long)self.filteredGuides.count];
    [self.tableView reloadData];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"当前条件没有合适玩法，换个人数或氛围试试";
    emptyLabel.font = [JFTheme fontBody];
    emptyLabel.textColor = [JFTheme textSecondary];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 2;
    self.tableView.backgroundView = self.filteredGuides.count == 0 ? emptyLabel : nil;
    self.randomButton.enabled = self.filteredGuides.count > 0;
    self.randomButton.alpha = self.randomButton.enabled ? 1 : 0.5;

    if (track) {
        [[JFAnalyticsTracker shared] trackEvent:@"social_guide_filter"
                                      properties:@{ @"people": @(people), @"mood": @(mood),
                                                    @"resultCount": @(self.filteredGuides.count) }];
    }
}

- (void)onRandom {
    if (self.filteredGuides.count == 0) return;
    [JFTheme hapticImpactMedium];
    JFSocialGameGuide *guide = self.filteredGuides[arc4random_uniform((uint32_t)self.filteredGuides.count)];
    [[JFAnalyticsTracker shared] trackEvent:@"social_guide_random"
                                  properties:@{ @"guideId": guide.guideId ?: @"" }];
    [self showGuide:guide];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredGuides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JFSocialGuideCell *cell = [tableView dequeueReusableCellWithIdentifier:@"guide" forIndexPath:indexPath];
    [cell configureWithGuide:self.filteredGuides[indexPath.row] index:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [JFTheme hapticSelection];
    [self showGuide:self.filteredGuides[indexPath.row]];
}

- (void)showGuide:(JFSocialGameGuide *)guide {
    JFSocialGameGuideDetailViewController *detail = [[JFSocialGameGuideDetailViewController alloc] initWithGuide:guide];
    __weak typeof(self) weakSelf = self;
    detail.launchHandler = ^(JFGameKind kind) {
        if (weakSelf.launchGameHandler) weakSelf.launchGameHandler(kind);
    };
    [self.navigationController pushViewController:detail animated:YES];
}

@end
