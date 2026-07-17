//
//  JFSkinShopViewController.m
//  JiFeng_UpApp
//

#import "JFSkinShopViewController.h"
#import "JFSkinStore.h"
#import "JFProfileStore.h"
#import "JFTheme.h"
#import "JFGamePieceSkin.h"
#import "JFAppIconManager.h"

#pragma mark - Cell

@interface JFSkinCell : UICollectionViewCell
@property (nonatomic, strong) UIView    *previewView;
@property (nonatomic, strong) CAGradientLayer *previewGradient;
@property (nonatomic, strong) UIImageView *motifView;
@property (nonatomic, strong) JFGamePieceSkinView *cardPreview;
@property (nonatomic, strong) JFSkinnedDieView *diePreview;
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
        _motifView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20];
        _motifView.contentMode = UIViewContentModeScaleAspectFit;
        _motifView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightBlack];
        [_previewView addSubview:_motifView];

        _cardPreview = [[JFGamePieceSkinView alloc] init];
        _cardPreview.translatesAutoresizingMaskIntoConstraints = NO;
        _cardPreview.surfaceStyle = JFGamePieceSurfaceStyleCardBack;
        _cardPreview.transform = CGAffineTransformMakeRotation(-7.0 * M_PI / 180.0);
        _cardPreview.layer.shadowColor = UIColor.blackColor.CGColor;
        _cardPreview.layer.shadowOpacity = 0.34;
        _cardPreview.layer.shadowRadius = 6;
        _cardPreview.layer.shadowOffset = CGSizeMake(0, 4);
        [_previewView addSubview:_cardPreview];

        _diePreview = [[JFSkinnedDieView alloc] init];
        _diePreview.translatesAutoresizingMaskIntoConstraints = NO;
        _diePreview.face = 5;
        _diePreview.highlighted = YES;
        _diePreview.transform = CGAffineTransformMakeRotation(6.0 * M_PI / 180.0);
        [_previewView addSubview:_diePreview];

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
            [_previewView.heightAnchor   constraintEqualToConstant:96],

            [_motifView.trailingAnchor constraintEqualToAnchor:_previewView.trailingAnchor constant:2],
            [_motifView.topAnchor constraintEqualToAnchor:_previewView.topAnchor constant:-2],
            [_motifView.widthAnchor constraintEqualToConstant:58],
            [_motifView.heightAnchor constraintEqualToConstant:58],

            [_cardPreview.leadingAnchor constraintEqualToAnchor:_previewView.leadingAnchor constant:22],
            [_cardPreview.centerYAnchor constraintEqualToAnchor:_previewView.centerYAnchor],
            [_cardPreview.widthAnchor constraintEqualToConstant:50],
            [_cardPreview.heightAnchor constraintEqualToConstant:72],

            [_diePreview.trailingAnchor constraintEqualToAnchor:_previewView.trailingAnchor constant:-20],
            [_diePreview.centerYAnchor constraintEqualToAnchor:_previewView.centerYAnchor constant:4],
            [_diePreview.widthAnchor constraintEqualToConstant:52],
            [_diePreview.heightAnchor constraintEqualToConstant:52],

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
    self.cardPreview.skin = skin;
    self.diePreview.skin = skin;
    self.diePreview.face = (labs((long)skin.skinId.hash) % 6) + 1;
    self.motifView.tintColor = [[JFGamePieceSkin cardBackDetailColorForSkin:skin] colorWithAlphaComponent:0.18];
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

#pragma mark - Card face preset cell

@interface JFCardFacePresetCell : UICollectionViewCell
@property (nonatomic, strong) UIView *previewView;
@property (nonatomic, strong) UIImageView *motifView;
@property (nonatomic, strong) JFGamePieceSkinView *cardSurface;
@property (nonatomic, strong) JFCardFaceArtworkView *artworkView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIImageView *selectedIcon;
- (void)bindPreset:(JFCardFacePreset *)preset;
@end

@implementation JFCardFacePresetCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentView.layer.cornerRadius = JFRadiusMedium;
        self.contentView.layer.cornerCurve = kCACornerCurveContinuous;
        self.contentView.layer.borderWidth = 1;
        self.contentView.clipsToBounds = YES;

        _previewView = [[UIView alloc] init];
        _previewView.translatesAutoresizingMaskIntoConstraints = NO;
        _previewView.clipsToBounds = YES;
        [self.contentView addSubview:_previewView];

        _motifView = [[UIImageView alloc] init];
        _motifView.translatesAutoresizingMaskIntoConstraints = NO;
        _motifView.contentMode = UIViewContentModeScaleAspectFit;
        _motifView.tintColor = [[JFTheme accent] colorWithAlphaComponent:0.16];
        [_previewView addSubview:_motifView];

        _cardSurface = [[JFGamePieceSkinView alloc] init];
        _cardSurface.translatesAutoresizingMaskIntoConstraints = NO;
        _cardSurface.surfaceStyle = JFGamePieceSurfaceStyleCardFace;
        _cardSurface.layer.shadowColor = UIColor.blackColor.CGColor;
        _cardSurface.layer.shadowOpacity = 0.30;
        _cardSurface.layer.shadowRadius = 7;
        _cardSurface.layer.shadowOffset = CGSizeMake(0, 4);
        [_previewView addSubview:_cardSurface];

        _artworkView = [[JFCardFaceArtworkView alloc] init];
        _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardSurface addSubview:_artworkView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [JFTheme fontHeadline];
        _nameLabel.textColor = [JFTheme textPrimary];
        [self.contentView addSubview:_nameLabel];

        _descLabel = [[UILabel alloc] init];
        _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descLabel.font = [JFTheme fontCaption];
        _descLabel.textColor = [JFTheme textSecondary];
        _descLabel.numberOfLines = 2;
        [self.contentView addSubview:_descLabel];

        UIImageSymbolConfiguration *checkConfig = [UIImageSymbolConfiguration configurationWithPointSize:19
                                                                                                    weight:UIImageSymbolWeightBold];
        _selectedIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"
                                                                       withConfiguration:checkConfig]];
        _selectedIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _selectedIcon.tintColor = [JFTheme success];
        [self.contentView addSubview:_selectedIcon];

        UILayoutGuide *guide = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_previewView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_previewView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_previewView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_previewView.heightAnchor constraintEqualToConstant:116],

            [_motifView.centerXAnchor constraintEqualToAnchor:_previewView.centerXAnchor constant:48],
            [_motifView.centerYAnchor constraintEqualToAnchor:_previewView.centerYAnchor constant:-2],
            [_motifView.widthAnchor constraintEqualToConstant:72],
            [_motifView.heightAnchor constraintEqualToConstant:72],

            [_cardSurface.centerXAnchor constraintEqualToAnchor:_previewView.centerXAnchor],
            [_cardSurface.centerYAnchor constraintEqualToAnchor:_previewView.centerYAnchor],
            [_cardSurface.widthAnchor constraintEqualToConstant:72],
            [_cardSurface.heightAnchor constraintEqualToConstant:102],

            [_artworkView.topAnchor constraintEqualToAnchor:_cardSurface.topAnchor],
            [_artworkView.leadingAnchor constraintEqualToAnchor:_cardSurface.leadingAnchor],
            [_artworkView.trailingAnchor constraintEqualToAnchor:_cardSurface.trailingAnchor],
            [_artworkView.bottomAnchor constraintEqualToAnchor:_cardSurface.bottomAnchor],

            [_nameLabel.topAnchor constraintEqualToAnchor:_previewView.bottomAnchor constant:JFSpacing12],
            [_nameLabel.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_selectedIcon.leadingAnchor constant:-JFSpacing8],

            [_selectedIcon.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
            [_selectedIcon.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
            [_selectedIcon.widthAnchor constraintEqualToConstant:22],
            [_selectedIcon.heightAnchor constraintEqualToConstant:22],

            [_descLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:JFSpacing4],
            [_descLabel.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
            [_descLabel.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
            [_descLabel.bottomAnchor constraintLessThanOrEqualToAnchor:guide.bottomAnchor],
        ]];
    }
    return self;
}

- (void)bindPreset:(JFCardFacePreset *)preset {
    JFSkin *skin = [JFGamePieceSkin currentSkin];
    self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    self.previewView.backgroundColor = [[JFTheme brandPrimary] colorWithAlphaComponent:0.12];
    self.motifView.image = [UIImage systemImageNamed:preset.symbolName ?: @"suit.heart.fill"];
    self.motifView.tintColor = [[JFTheme accent] colorWithAlphaComponent:0.16];
    self.cardSurface.skin = skin;
    self.artworkView.skin = skin;
    self.artworkView.presetId = preset.presetId;
    [self.artworkView configureWithRank:@"K" suit:@"♥" compact:NO];

    self.nameLabel.text = preset.displayName;
    self.descLabel.text = preset.desc;

    BOOL selected = [[[JFSkinStore shared] currentCardFacePresetId] isEqualToString:preset.presetId];
    self.selectedIcon.hidden = !selected;
    self.contentView.layer.borderColor = selected ? [JFTheme accent].CGColor : [JFTheme cardBorder].CGColor;
    self.contentView.layer.borderWidth = selected ? 2 : 1;
    self.accessibilityLabel = [NSString stringWithFormat:@"牌面预设 %@%@", preset.displayName,
                               selected ? @", 当前使用" : @""];
}

@end

@interface JFSkinSectionHeader : UICollectionReusableView
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation JFSkinSectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        _titleLabel.textColor = [JFTheme textPrimary];
        [self addSubview:_titleLabel];
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:JFSpacing16],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-JFSpacing16],
            [_titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-JFSpacing8],
        ]];
    }
    return self;
}

@end

#pragma mark - VC

@interface JFSkinShopViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collection;
@property (nonatomic, strong) UILabel *coinsLabel;
@property (nonatomic, strong) UILabel *iconStatusLabel;
@property (nonatomic, strong) UISwitch *iconFollowSwitch;
@property (nonatomic, strong) UIButton *iconPickerButton;
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

    UIView *iconBar = [UIView new];
    iconBar.translatesAutoresizingMaskIntoConstraints = NO;
    [JFTheme decorateGlassPanel:iconBar];
    [self.view addSubview:iconBar];

    UIImageView *iconMark = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"app.badge.fill"]];
    iconMark.translatesAutoresizingMaskIntoConstraints = NO;
    iconMark.tintColor = [JFTheme accent];
    iconMark.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:23 weight:UIImageSymbolWeightSemibold];
    [iconBar addSubview:iconMark];

    UILabel *iconTitle = [UILabel new];
    iconTitle.translatesAutoresizingMaskIntoConstraints = NO;
    iconTitle.text = @"桌面图标";
    iconTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    iconTitle.textColor = [JFTheme textPrimary];
    [iconBar addSubview:iconTitle];

    UILabel *iconStatus = [UILabel new];
    iconStatus.translatesAutoresizingMaskIntoConstraints = NO;
    iconStatus.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    iconStatus.textColor = [JFTheme textSecondary];
    iconStatus.lineBreakMode = NSLineBreakByTruncatingTail;
    [iconBar addSubview:iconStatus];
    self.iconStatusLabel = iconStatus;

    UISwitch *followSwitch = [UISwitch new];
    followSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    followSwitch.onTintColor = [JFTheme brandPrimary];
    followSwitch.accessibilityLabel = @"桌面图标跟随主题";
    [followSwitch addTarget:self action:@selector(iconFollowChanged:) forControlEvents:UIControlEventValueChanged];
    [iconBar addSubview:followSwitch];
    self.iconFollowSwitch = followSwitch;

    UIButton *pickerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    pickerButton.translatesAutoresizingMaskIntoConstraints = NO;
    [pickerButton setImage:[UIImage systemImageNamed:@"square.grid.2x2.fill"] forState:UIControlStateNormal];
    [pickerButton setTitle:@" 选择" forState:UIControlStateNormal];
    pickerButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    pickerButton.tintColor = [JFTheme accent];
    pickerButton.accessibilityHint = @"从已解锁主题中选择桌面图标";
    [pickerButton addTarget:self action:@selector(showIconPicker:) forControlEvents:UIControlEventTouchUpInside];
    [iconBar addSubview:pickerButton];
    self.iconPickerButton = pickerButton;

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
    [cv registerClass:[JFCardFacePresetCell class] forCellWithReuseIdentifier:@"cardFace"];
    [cv registerClass:[JFSkinSectionHeader class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"header"];
    [self.view addSubview:cv];
    self.collection = cv;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:72],
        [title.topAnchor constraintEqualToAnchor:safe.topAnchor constant:JFSpacing16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:coins.leadingAnchor constant:-JFSpacing12],

        [coins.centerYAnchor  constraintEqualToAnchor:title.centerYAnchor],
        [coins.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],

        [iconBar.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:JFSpacing16],
        [iconBar.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:JFSpacing16],
        [iconBar.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-JFSpacing16],
        [iconBar.heightAnchor constraintEqualToConstant:68],

        [iconMark.leadingAnchor constraintEqualToAnchor:iconBar.leadingAnchor constant:JFSpacing16],
        [iconMark.centerYAnchor constraintEqualToAnchor:iconBar.centerYAnchor],
        [iconMark.widthAnchor constraintEqualToConstant:28],
        [iconMark.heightAnchor constraintEqualToConstant:28],

        [iconTitle.leadingAnchor constraintEqualToAnchor:iconMark.trailingAnchor constant:JFSpacing12],
        [iconTitle.topAnchor constraintEqualToAnchor:iconBar.topAnchor constant:JFSpacing12],
        [iconTitle.trailingAnchor constraintLessThanOrEqualToAnchor:pickerButton.leadingAnchor constant:-JFSpacing8],

        [iconStatus.leadingAnchor constraintEqualToAnchor:iconTitle.leadingAnchor],
        [iconStatus.topAnchor constraintEqualToAnchor:iconTitle.bottomAnchor constant:2],
        [iconStatus.trailingAnchor constraintLessThanOrEqualToAnchor:pickerButton.leadingAnchor constant:-JFSpacing8],

        [pickerButton.trailingAnchor constraintEqualToAnchor:followSwitch.leadingAnchor constant:-JFSpacing8],
        [pickerButton.centerYAnchor constraintEqualToAnchor:iconBar.centerYAnchor],
        [pickerButton.heightAnchor constraintEqualToConstant:40],

        [followSwitch.trailingAnchor constraintEqualToAnchor:iconBar.trailingAnchor constant:-JFSpacing12],
        [followSwitch.centerYAnchor constraintEqualToAnchor:iconBar.centerYAnchor],

        [cv.topAnchor      constraintEqualToAnchor:iconBar.bottomAnchor constant:JFSpacing8],
        [cv.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor],
        [cv.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [cv.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFSkinDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFProfileDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChanged) name:JFAppIconDidChangeNotification object:nil];
    [self refreshIconControls];
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
    [self refreshIconControls];
    [self.collection reloadData];
}

- (void)refreshCoins {
    self.coinsLabel.text = [NSString stringWithFormat:@"💰 %ld", (long)[JFProfileStore shared].coins];
}

- (void)refreshIconControls {
    JFAppIconManager *manager = JFAppIconManager.shared;
    self.iconFollowSwitch.on = manager.followsTheme;
    self.iconFollowSwitch.enabled = manager.supportsAlternateIcons;
    self.iconPickerButton.enabled = manager.supportsAlternateIcons;
    self.iconPickerButton.alpha = manager.supportsAlternateIcons ? 1.0 : 0.42;

    if (!manager.supportsAlternateIcons) {
        self.iconStatusLabel.text = @"当前设备暂不支持";
        return;
    }
    NSString *iconSkinId = manager.skinIdForCurrentIcon ?: @"default";
    JFSkin *iconSkin = [JFSkinStore.shared skinById:iconSkinId];
    NSString *name = iconSkin.displayName ?: @"星夜游乐场";
    self.iconStatusLabel.text = manager.followsTheme
        ? [NSString stringWithFormat:@"跟随主题 · %@", name]
        : [NSString stringWithFormat:@"自选 · %@", name];
}

- (void)iconFollowChanged:(UISwitch *)sender {
    [JFTheme hapticSelection];
    JFAppIconManager.shared.followsTheme = sender.isOn;
    [self refreshIconControls];
    [self toast:sender.isOn ? @"桌面图标将跟随主题" : @"已保留当前桌面图标"];
}

- (void)showIconPicker:(UIButton *)sender {
    JFAppIconManager *manager = JFAppIconManager.shared;
    if (!manager.supportsAlternateIcons) return;

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择桌面图标"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *currentSkinId = manager.skinIdForCurrentIcon ?: @"default";
    __weak typeof(self) weakSelf = self;
    for (JFSkin *skin in JFSkinStore.shared.allSkins) {
        if (![JFSkinStore.shared isUnlocked:skin.skinId]) continue;
        NSString *title = [skin.skinId isEqualToString:currentSkinId]
            ? [NSString stringWithFormat:@"✓ %@", skin.displayName]
            : skin.displayName;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            manager.followsTheme = NO;
            [manager applyIconForSkinId:skin.skinId completion:^(BOOL success, NSError *error) {
                [weakSelf refreshIconControls];
                if (success) {
                    [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
                    [weakSelf toast:[NSString stringWithFormat:@"已使用 %@ 图标", skin.displayName]];
                } else {
                    [JFTheme hapticNotification:UINotificationFeedbackTypeError];
                    [weakSelf toast:error.localizedDescription ?: @"图标切换失败"];
                }
            }];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = sender;
    sheet.popoverPresentationController.sourceRect = sender.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? [JFSkinStore shared].allCardFacePresets.count
                        : [JFSkinStore shared].allSkins.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        JFCardFacePresetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cardFace"
                                                                               forIndexPath:indexPath];
        JFCardFacePreset *preset = [JFSkinStore shared].allCardFacePresets[indexPath.item];
        [cell bindPreset:preset];
        return cell;
    }
    JFSkinCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"skin" forIndexPath:indexPath];
    JFSkin *s = [JFSkinStore shared].allSkins[indexPath.item];
    [cell bindSkin:s];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = (cv.bounds.size.width - JFSpacing16 * 2 - JFSpacing12) / 2.0;
    return CGSizeMake(floor(w), indexPath.section == 0 ? 198 : 208);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.bounds.size.width, section == 0 ? 40 : 48);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                  atIndexPath:(NSIndexPath *)indexPath {
    JFSkinSectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                     withReuseIdentifier:@"header"
                                                                            forIndexPath:indexPath];
    header.titleLabel.text = indexPath.section == 0 ? @"牌面预设" : @"全局主题";
    return header;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        JFCardFacePreset *preset = [JFSkinStore shared].allCardFacePresets[indexPath.item];
        if ([[JFSkinStore shared].currentCardFacePresetId isEqualToString:preset.presetId]) return;
        [JFTheme hapticSelection];
        [[JFSkinStore shared] applyCardFacePreset:preset.presetId];
        [JFTheme hapticNotification:UINotificationFeedbackTypeSuccess];
        [self toast:[NSString stringWithFormat:@"已切换到 %@", preset.displayName]];
        return;
    }
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
