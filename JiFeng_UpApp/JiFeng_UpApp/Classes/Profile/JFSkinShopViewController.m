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
@property (nonatomic, strong) UIView    *swatch1;
@property (nonatomic, strong) UIView    *swatch2;
@property (nonatomic, strong) UIView    *swatch3;
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
        self.contentView.backgroundColor    = [JFTheme backgroundSecondary];
        self.contentView.clipsToBounds      = YES;

        _swatch1 = [UIView new]; _swatch1.translatesAutoresizingMaskIntoConstraints = NO;
        _swatch2 = [UIView new]; _swatch2.translatesAutoresizingMaskIntoConstraints = NO;
        _swatch3 = [UIView new]; _swatch3.translatesAutoresizingMaskIntoConstraints = NO;
        for (UIView *v in @[_swatch1, _swatch2, _swatch3]) {
            v.layer.cornerRadius = 12;
            [self.contentView addSubview:v];
        }

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
            [_swatch1.topAnchor      constraintEqualToAnchor:g.topAnchor constant:JFSpacing8],
            [_swatch1.leadingAnchor  constraintEqualToAnchor:g.leadingAnchor],
            [_swatch1.widthAnchor    constraintEqualToConstant:24],
            [_swatch1.heightAnchor   constraintEqualToConstant:24],

            [_swatch2.topAnchor      constraintEqualToAnchor:_swatch1.topAnchor],
            [_swatch2.leadingAnchor  constraintEqualToAnchor:_swatch1.trailingAnchor constant:JFSpacing8],
            [_swatch2.widthAnchor    constraintEqualToConstant:24],
            [_swatch2.heightAnchor   constraintEqualToConstant:24],

            [_swatch3.topAnchor      constraintEqualToAnchor:_swatch1.topAnchor],
            [_swatch3.leadingAnchor  constraintEqualToAnchor:_swatch2.trailingAnchor constant:JFSpacing8],
            [_swatch3.widthAnchor    constraintEqualToConstant:24],
            [_swatch3.heightAnchor   constraintEqualToConstant:24],

            [_nameLabel.topAnchor      constraintEqualToAnchor:_swatch1.bottomAnchor constant:JFSpacing12],
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

- (void)bindSkin:(JFSkin *)skin {
    self.swatch1.backgroundColor = skin.brandPrimary;
    self.swatch2.backgroundColor = skin.brandSecondary;
    self.swatch3.backgroundColor = skin.accent;
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
    self.title = @"皮肤商店";

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
        [coins.topAnchor      constraintEqualToAnchor:safe.topAnchor constant:JFSpacing8],
        [coins.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [cv.topAnchor      constraintEqualToAnchor:coins.bottomAnchor constant:JFSpacing4],
        [cv.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [cv.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [cv.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFSkinDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFProfileDidChangeNotification object:nil];
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
