//
//  JFSkinShopViewController.m
//  JiFeng_UpApp
//

#import "JFSkinShopViewController.h"
#import "JFSkinStore.h"
#import "JFProfileStore.h"
#import "JFTheme.h"

#pragma mark - Cell

@interface JFSkinCell : UICollectionViewCell
@property (nonatomic, strong) UIView    *previewView;
@property (nonatomic, strong) CAGradientLayer *previewGradient;
@property (nonatomic, strong) UIImageView *motifView;
@property (nonatomic, strong) UILabel   *nameLabel;
@property (nonatomic, strong) UILabel   *descLabel;
@property (nonatomic, strong) UILabel   *priceLabel;
@property (nonatomic, strong) UILabel   *badgeLabel;  // 已使用 / 已解锁
- (void)bindSkin:(JFSkin *)skin;
@end

@implementation JFSkinCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.layer.cornerRadius = JFRadiusMedium;
        self.contentView.layer.cornerCurve  = kCACornerCurveContinuous;
        self.contentView.layer.borderWidth  = 1.0;
        self.contentView.layer.borderColor  = [JFTheme cardBorder].CGColor;
        self.contentView.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.07];
        self.contentView.clipsToBounds      = YES;

        _previewView = [UIView new];
        _previewView.translatesAutoresizingMaskIntoConstraints = NO;
        _previewView.layer.cornerRadius = 18;
        _previewView.layer.cornerCurve = kCACornerCurveContinuous;
        _previewView.clipsToBounds = YES;
        [self.contentView addSubview:_previewView];

        _previewGradient = [CAGradientLayer layer];
        _previewGradient.startPoint = CGPointMake(0.08, 0.0);
        _previewGradient.endPoint = CGPointMake(0.95, 1.0);
        [_previewView.layer addSublayer:_previewGradient];

        _motifView = [[UIImageView alloc] init];
        _motifView.translatesAutoresizingMaskIntoConstraints = NO;
        _motifView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
        _motifView.contentMode = UIViewContentModeScaleAspectFit;
        _motifView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:42 weight:UIImageSymbolWeightBlack];
        [_previewView addSubview:_motifView];

        _nameLabel = [UILabel new];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [JFTheme fontHeadline];
        _nameLabel.textColor = [JFTheme textPrimary];
        [self.contentView addSubview:_nameLabel];

        _descLabel = [UILabel new];
        _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descLabel.font = [JFTheme fontCaption];
        _descLabel.textColor = [JFTheme textSecondary];
        _descLabel.numberOfLines = 2;
        [self.contentView addSubview:_descLabel];

        _priceLabel = [UILabel new];
        _priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _priceLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        _priceLabel.textColor = [JFTheme warning];
        _priceLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_priceLabel];

        _badgeLabel = [UILabel new];
        _badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _badgeLabel.textColor = [UIColor whiteColor];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.layer.cornerRadius = 8;
        _badgeLabel.layer.masksToBounds = YES;
        _badgeLabel.hidden = YES;
        [self.contentView addSubview:_badgeLabel];

        UILayoutGuide *g = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_previewView.topAnchor      constraintEqualToAnchor:g.topAnchor constant:JFSpacing4],
            [_previewView.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
            [_previewView.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
            [_previewView.heightAnchor   constraintEqualToConstant:82],

            [_motifView.centerXAnchor constraintEqualToAnchor:_previewView.centerXAnchor],
            [_motifView.centerYAnchor constraintEqualToAnchor:_previewView.centerYAnchor],
            [_motifView.widthAnchor constraintEqualToConstant:62],
            [_motifView.heightAnchor constraintEqualToConstant:62],

            [_nameLabel.topAnchor      constraintEqualToAnchor:_previewView.bottomAnchor constant:JFSpacing12],
            [_nameLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_priceLabel.leadingAnchor constant:-JFSpacing8],

            [_descLabel.topAnchor      constraintEqualToAnchor:_nameLabel.bottomAnchor constant:JFSpacing4],
            [_descLabel.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
            [_descLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],

            [_priceLabel.bottomAnchor   constraintEqualToAnchor:g.bottomAnchor],
            [_priceLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],

            [_badgeLabel.topAnchor      constraintEqualToAnchor:g.topAnchor constant:JFSpacing4],
            [_badgeLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor],
            [_badgeLabel.heightAnchor   constraintEqualToConstant:18],
            [_badgeLabel.widthAnchor    constraintGreaterThanOrEqualToConstant:50],
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewGradient.frame = self.previewView.bounds;
}

- (void)bindSkin:(JFSkin *)skin {
    self.previewGradient.colors = @[(__bridge id)skin.backgroundTop.CGColor,
                                    (__bridge id)skin.brandPrimary.CGColor,
                                    (__bridge id)skin.backgroundBottom.CGColor];
    self.previewGradient.locations = @[@0.0, @0.55, @1.0];
    self.motifView.image = [UIImage systemImageNamed:skin.symbolName ?: @"sparkles"];
    self.nameLabel.text = skin.displayName;
    self.descLabel.text = skin.desc;

    BOOL unlocked = [[JFSkinStore shared] isUnlocked:skin.skinId];
    BOOL using    = [[[JFSkinStore shared] currentSkinId] isEqualToString:skin.skinId];

    if (using) {
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = @"  使用中  ";
        self.badgeLabel.backgroundColor = [JFTheme success];
        self.contentView.layer.borderColor = [JFTheme accent].CGColor;
        self.contentView.layer.borderWidth = 2;
    } else if (unlocked) {
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = @"  已解锁  ";
        self.badgeLabel.backgroundColor = [JFTheme brandPrimary];
        self.contentView.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.contentView.layer.borderWidth = 1;
    } else {
        self.badgeLabel.hidden = YES;
        self.contentView.layer.borderColor = [JFTheme cardBorder].CGColor;
        self.contentView.layer.borderWidth = 1;
    }

    if (skin.price <= 0) {
        self.priceLabel.text = @"免费";
        self.priceLabel.textColor = [JFTheme textSecondary];
    } else if (unlocked) {
        self.priceLabel.text = @"";
    } else {
        self.priceLabel.text = [NSString stringWithFormat:@"💰 %ld", (long)skin.price];
        self.priceLabel.textColor = [JFTheme warning];
    }
}

@end

#pragma mark - VC

@interface JFSkinShopViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collection;
@property (nonatomic, strong) UILabel *coinsLabel;
@end

@implementation JFSkinShopViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [JFTheme backgroundPrimary];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"主题工坊";
    title.font = [JFTheme fontTitle];
    title.textColor = [JFTheme textPrimary];
    [self.view addSubview:title];

    UILabel *coins = [UILabel new];
    coins.translatesAutoresizingMaskIntoConstraints = NO;
    coins.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    coins.textColor = [JFTheme warning];
    coins.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:coins];
    self.coinsLabel = coins;
    [self refreshCoins];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = JFSpacing12;
    layout.minimumLineSpacing      = JFSpacing12;
    layout.sectionInset            = UIEdgeInsetsMake(JFSpacing12, JFSpacing16, JFSpacing16, JFSpacing16);

    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    cv.backgroundColor = [UIColor clearColor];
    cv.dataSource = self;
    cv.delegate   = self;
    cv.alwaysBounceVertical = YES;
    [cv registerClass:[JFSkinCell class] forCellWithReuseIdentifier:@"skin"];
    [self.view addSubview:cv];
    self.collection = cv;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:JFSpacing16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:coins.leadingAnchor constant:-JFSpacing12],

        [coins.centerYAnchor  constraintEqualToAnchor:title.centerYAnchor],
        [coins.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [cv.topAnchor      constraintEqualToAnchor:title.bottomAnchor constant:JFSpacing20],
        [cv.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [cv.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [cv.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFSkinDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFProfileDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onChanged {
    [self refreshCoins];
    [self.collection reloadData];
}

- (void)refreshCoins {
    self.coinsLabel.text = [NSString stringWithFormat:@"💰 %ld", (long)[JFProfileStore shared].coins];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [JFSkinStore shared].allSkins.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFSkinCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"skin" forIndexPath:indexPath];
    JFSkin *s = [JFSkinStore shared].allSkins[indexPath.item];
    [cell bindSkin:s];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = (cv.bounds.size.width - JFSpacing16 * 2 - JFSpacing12) / 2.0;
    return CGSizeMake(floor(w), 150);
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JFSkin *s = [JFSkinStore shared].allSkins[indexPath.item];
    [JFTheme hapticSelection];

    if ([[JFSkinStore shared] isUnlocked:s.skinId]) {
        if ([[[JFSkinStore shared] currentSkinId] isEqualToString:s.skinId]) {
            return; // 已经在用
        }
        [[JFSkinStore shared] applySkin:s.skinId];
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        [self toast:[NSString stringWithFormat:@"已切换到 %@", s.displayName]];
    } else {
        // 弹确认
        NSString *msg = [NSString stringWithFormat:@"消耗 %ld 金币解锁 %@?", (long)s.price, s.displayName];
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"购买皮肤" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            BOOL ok = [[JFSkinStore shared] purchaseSkin:s.skinId];
            if (ok) {
                [[JFSkinStore shared] applySkin:s.skinId];
                [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
                [self toast:[NSString stringWithFormat:@"解锁成功!已切换到 %@", s.displayName]];
            } else {
                [JFTheme hapticNotification:UINotificationFeedbackTypeError];
                [self toast:@"金币不足,继续玩游戏赚币吧"];
            }
        }]];
        [self presentViewController:a animated:YES completion:nil];
    }
}

#pragma mark - Toast

- (void)toast:(NSString *)text {
    UILabel *l = [UILabel new];
    l.text = text;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    l.layer.cornerRadius = 12;
    l.layer.masksToBounds = YES;
    l.alpha = 0;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:l];
    [NSLayoutConstraint activateConstraints:@[
        [l.centerXAnchor  constraintEqualToAnchor:self.view.centerXAnchor],
        [l.bottomAnchor   constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-60],
        [l.heightAnchor   constraintEqualToConstant:36],
        [l.widthAnchor    constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.8],
    ]];
    UIEdgeInsets ei = UIEdgeInsetsMake(0, 16, 0, 16);
    l.preservesSuperviewLayoutMargins = NO;
    l.layoutMargins = ei;
    [UIView animateWithDuration:0.18 animations:^{ l.alpha = 1; } completion:^(BOOL fin){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{ l.alpha = 0; } completion:^(BOOL f){
                [l removeFromSuperview];
            }];
        });
    }];
}

@end
