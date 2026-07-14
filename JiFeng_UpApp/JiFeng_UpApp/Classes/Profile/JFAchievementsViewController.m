//
//  JFAchievementsViewController.m
//  JiFeng_UpApp
//

#import "JFAchievementsViewController.h"
#import "JFTheme.h"
#import "JFAchievementStore.h"

#pragma mark - Cell

@interface JFAchCell : UICollectionViewCell
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *rewardLabel;
- (void)configureWith:(JFAchievement *)a;
@end

@implementation JFAchCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor clearColor];

        self.card = [[UIView alloc] init];
        self.card.translatesAutoresizingMaskIntoConstraints = NO;
        self.card.layer.cornerRadius = JFRadiusMedium;
        self.card.layer.cornerCurve = kCACornerCurveContinuous;
        self.card.layer.borderWidth = 0.5;
        self.card.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.card.backgroundColor = [JFTheme backgroundSecondary];
        [self.contentView addSubview:self.card];

        self.iconView = [[UIImageView alloc] init];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.tintColor = [JFTheme accent];
        self.iconView.preferredSymbolConfiguration =
            [UIImageSymbolConfiguration configurationWithPointSize:32 weight:UIImageSymbolWeightSemibold];
        [self.card addSubview:self.iconView];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.font = [JFTheme fontHeadline];
        self.titleLabel.textColor = [JFTheme textPrimary];
        self.titleLabel.numberOfLines = 1;
        [self.card addSubview:self.titleLabel];

        self.descLabel = [[UILabel alloc] init];
        self.descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.descLabel.font = [JFTheme fontCaption];
        self.descLabel.textColor = [JFTheme textSecondary];
        self.descLabel.numberOfLines = 2;
        [self.card addSubview:self.descLabel];

        self.rewardLabel = [[UILabel alloc] init];
        self.rewardLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.rewardLabel.font = [JFTheme fontCaption];
        self.rewardLabel.textColor = [JFTheme warning];
        [self.card addSubview:self.rewardLabel];

        [NSLayoutConstraint activateConstraints:@[
            [self.card.topAnchor      constraintEqualToAnchor:self.contentView.topAnchor],
            [self.card.leadingAnchor  constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [self.card.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor],

            [self.iconView.topAnchor      constraintEqualToAnchor:self.card.topAnchor constant:JFSpacing12],
            [self.iconView.leadingAnchor  constraintEqualToAnchor:self.card.leadingAnchor constant:JFSpacing12],
            [self.iconView.widthAnchor    constraintEqualToConstant:36],
            [self.iconView.heightAnchor   constraintEqualToConstant:36],

            [self.titleLabel.topAnchor      constraintEqualToAnchor:self.card.topAnchor constant:JFSpacing12],
            [self.titleLabel.leadingAnchor  constraintEqualToAnchor:self.iconView.trailingAnchor constant:JFSpacing12],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-JFSpacing12],

            [self.descLabel.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],
            [self.descLabel.leadingAnchor  constraintEqualToAnchor:self.titleLabel.leadingAnchor],
            [self.descLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

            [self.rewardLabel.bottomAnchor   constraintEqualToAnchor:self.card.bottomAnchor constant:-JFSpacing8],
            [self.rewardLabel.leadingAnchor  constraintEqualToAnchor:self.card.leadingAnchor constant:JFSpacing12],
            [self.rewardLabel.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-JFSpacing12],
        ]];
    }
    return self;
}

- (void)configureWith:(JFAchievement *)a {
    self.titleLabel.text = a.title;
    self.descLabel.text = a.desc;
    self.iconView.image = [UIImage systemImageNamed:a.symbolName];
    self.rewardLabel.text = a.unlocked
        ? [NSString stringWithFormat:@"已获得 · +%ld 风之币", (long)a.coinReward]
        : [NSString stringWithFormat:@"+%ld 风之币", (long)a.coinReward];

    if (a.unlocked) {
        self.card.alpha = 1.0;
        self.iconView.tintColor = [JFTheme accent];
        self.card.layer.borderColor = [JFTheme accent].CGColor;
    } else {
        self.card.alpha = 0.55;
        self.iconView.tintColor = [JFTheme textTertiary];
        self.card.layer.borderColor = [JFTheme cardBorder].CGColor;
    }
}

@end

#pragma mark - VC

@interface JFAchievementsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<JFAchievement *> *items;
@end

@implementation JFAchievementsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];
    self.items = [[JFAchievementStore shared] allAchievements];

    [self buildBackground];
    [self buildUI];
}

- (void)buildBackground {
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.24];
    [self.view addSubview:overlay];
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"成就";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    [self.view addSubview:self.titleLabel];

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger u = [JFAchievementStore shared].unlockedCount;
    NSInteger t = [JFAchievementStore shared].totalCount;
    self.summaryLabel.text = [NSString stringWithFormat:@"已获得 %ld / %ld", (long)u, (long)t];
    self.summaryLabel.textColor = [JFTheme textSecondary];
    self.summaryLabel.font = [JFTheme fontBody];
    [self.view addSubview:self.summaryLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = JFSpacing12;
    layout.minimumLineSpacing = JFSpacing12;
    layout.sectionInset = UIEdgeInsetsMake(JFSpacing8, JFSpacing20, JFSpacing20, JFSpacing20);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[JFAchCell class] forCellWithReuseIdentifier:@"ach"];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing12],
        [self.titleLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.summaryLabel.topAnchor      constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:JFSpacing4],
        [self.summaryLabel.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],

        [self.collectionView.topAnchor      constraintEqualToAnchor:self.summaryLabel.bottomAnchor constant:JFSpacing12],
        [self.collectionView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

#pragma mark - Data

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFAchCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ach" forIndexPath:indexPath];
    [cell configureWith:self.items[indexPath.item]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = collectionView.bounds.size.width - JFSpacing20 * 2;
    return CGSizeMake(w, 96);
}

@end
