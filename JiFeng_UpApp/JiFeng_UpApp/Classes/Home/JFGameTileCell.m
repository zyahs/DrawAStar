//
//  JFGameTileCell.m
//

#import "JFGameTileCell.h"
#import "JFTheme.h"

@interface JFGameTileCell ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView     *iconView;
@property (nonatomic, strong) UILabel         *titleLabel;
@property (nonatomic, strong) UILabel         *subtitleLabel;
@property (nonatomic, strong) UIView          *badgeView;     // 联机标识
@property (nonatomic, strong) UILabel         *badgeLabel;
@property (nonatomic, strong) UIView          *statsBadge;    // 已玩次数 / 最佳成绩
@property (nonatomic, strong) UILabel         *statsLabel;
@end

@implementation JFGameTileCell

+ (NSString *)reuseId { return @"JFGameTileCell"; }

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.contentView.layer.cornerRadius  = JFRadiusLarge;
    self.contentView.layer.cornerCurve   = kCACornerCurveContinuous;
    self.contentView.layer.masksToBounds = YES;

    // 渐变背景
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint   = CGPointMake(1, 1);
    [self.contentView.layer insertSublayer:self.gradientLayer atIndex:0];

    // 顶部高光叠加 —— 让卡片更立体
    CAGradientLayer *gloss = [CAGradientLayer layer];
    gloss.colors = @[(__bridge id)[UIColor colorWithWhite:1 alpha:0.20].CGColor,
                     (__bridge id)[UIColor colorWithWhite:1 alpha:0.0].CGColor];
    gloss.startPoint = CGPointMake(0, 0);
    gloss.endPoint   = CGPointMake(0, 0.6);
    [self.contentView.layer addSublayer:gloss];
    [self.contentView.layer setValue:gloss forKey:@"glossLayer"];

    // 主图标
    self.iconView = [[UIImageView alloc] init];
    self.iconView.tintColor = [UIColor whiteColor];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightSemibold];
    [self.contentView addSubview:self.iconView];

    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [JFTheme fontHeadline];
    self.titleLabel.textColor = [JFTheme textOnAccent];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.75;
    [self.contentView addSubview:self.titleLabel];

    // 副标题
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [JFTheme fontCaption];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.subtitleLabel];

    // 联机徽标
    self.badgeView = [[UIView alloc] init];
    self.badgeView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
    self.badgeView.layer.cornerRadius = 9;
    self.badgeView.layer.borderWidth = 0.5;
    self.badgeView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.45].CGColor;
    self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeView.hidden = YES;
    [self.contentView addSubview:self.badgeView];

    self.badgeLabel = [[UILabel alloc] init];
    self.badgeLabel.text = @"联机";
    self.badgeLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.badgeView addSubview:self.badgeLabel];

    // 已玩 / 最佳 角标(右下)
    self.statsBadge = [[UIView alloc] init];
    self.statsBadge.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
    self.statsBadge.layer.cornerRadius = 8;
    self.statsBadge.layer.borderWidth = 0.5;
    self.statsBadge.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
    self.statsBadge.translatesAutoresizingMaskIntoConstraints = NO;
    self.statsBadge.hidden = YES;
    [self.contentView addSubview:self.statsBadge];

    self.statsLabel = [[UILabel alloc] init];
    self.statsLabel.font = [UIFont systemFontOfSize:9.5 weight:UIFontWeightSemibold];
    self.statsLabel.textColor = [UIColor whiteColor];
    self.statsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.statsBadge addSubview:self.statsLabel];

    // 阴影(在 self,不能 clip)
    [JFTheme applyCardShadow:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:JFSpacing16],
        [self.iconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing16],
        [self.iconView.widthAnchor constraintEqualToConstant:42],
        [self.iconView.heightAnchor constraintEqualToConstant:42],

        [self.badgeView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:JFSpacing12],
        [self.badgeView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing12],
        [self.badgeView.heightAnchor constraintEqualToConstant:18],

        [self.badgeLabel.leadingAnchor constraintEqualToAnchor:self.badgeView.leadingAnchor constant:6],
        [self.badgeLabel.trailingAnchor constraintEqualToAnchor:self.badgeView.trailingAnchor constant:-6],
        [self.badgeLabel.centerYAnchor constraintEqualToAnchor:self.badgeView.centerYAnchor],

        [self.subtitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-JFSpacing12],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing16],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing12],

        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.subtitleLabel.topAnchor constant:-2],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:JFSpacing16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing12],

        [self.statsBadge.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-JFSpacing12],
        [self.statsBadge.bottomAnchor   constraintEqualToAnchor:self.contentView.bottomAnchor constant:-JFSpacing12],
        [self.statsBadge.heightAnchor   constraintEqualToConstant:18],

        [self.statsLabel.leadingAnchor  constraintEqualToAnchor:self.statsBadge.leadingAnchor constant:6],
        [self.statsLabel.trailingAnchor constraintEqualToAnchor:self.statsBadge.trailingAnchor constant:-6],
        [self.statsLabel.centerYAnchor  constraintEqualToAnchor:self.statsBadge.centerYAnchor],
    ]];
}

- (void)setStatsPlayCount:(NSInteger)playCount bestScore:(NSInteger)bestScore {
    if (playCount <= 0) {
        self.statsBadge.hidden = YES;
        return;
    }
    self.statsBadge.hidden = NO;
    if (bestScore > 0) {
        self.statsLabel.text = [NSString stringWithFormat:@"%ld 次 · 最佳 %ld", (long)playCount, (long)bestScore];
    } else {
        self.statsLabel.text = [NSString stringWithFormat:@"已玩 %ld 次", (long)playCount];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.contentView.bounds;
    CAGradientLayer *gloss = [self.contentView.layer valueForKey:@"glossLayer"];
    gloss.frame = self.contentView.bounds;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                       cornerRadius:JFRadiusLarge].CGPath;
}

- (void)configureWithEntry:(JFGameEntry *)entry index:(NSInteger)index {
    self.titleLabel.text = entry.title;
    self.subtitleLabel.text = entry.subtitle;
    self.iconView.image = [UIImage systemImageNamed:entry.symbolName];
    self.badgeView.hidden = !entry.supportsMultipeer;

    NSArray<UIColor *> *colors = [JFTheme gradientColorsForIndex:index];
    self.gradientLayer.colors = @[(__bridge id)colors.firstObject.CGColor,
                                  (__bridge id)colors.lastObject.CGColor];
}

#pragma mark - 按压反馈

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.18
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.contentView.transform = highlighted ? CGAffineTransformMakeScale(0.96, 0.96)
                                                 : CGAffineTransformIdentity;
        self.layer.shadowOpacity = highlighted ? 0.12 : 0.25;
    } completion:nil];
}

@end
