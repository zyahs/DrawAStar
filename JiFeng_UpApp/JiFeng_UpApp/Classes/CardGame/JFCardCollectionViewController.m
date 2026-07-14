//
//  JFCardCollectionViewController.m
//  JiFeng_UpApp
//

#import "JFCardCollectionViewController.h"
#import "CardsGameViewController.h"
#import "JFCardArcadeViewController.h"
#import "JFCardNetworkRoomViewController.h"
#import "JFAnalyticsTracker.h"
#import "JFTheme.h"

typedef NS_ENUM(NSInteger, JFCardCollectionGroup) {
    JFCardCollectionGroupParty = 0,
    JFCardCollectionGroupArcade,
};

@interface JFCardCollectionItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *players;
@property (nonatomic, copy) NSString *serviceType;
@property (nonatomic, copy) NSString *ruleGuide;
@property (nonatomic, assign) NSInteger recommendedDealCount;
@property (nonatomic, assign) JFCardCollectionGroup group;
@property (nonatomic, assign) NSInteger mode;
@end

@implementation JFCardCollectionItem
@end

@interface JFCardCollectionCell : UICollectionViewCell
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UIView *iconWell;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *groupLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *playersLabel;
- (void)configureWithItem:(JFCardCollectionItem *)item index:(NSInteger)index;
@end

@implementation JFCardCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.contentView.layer.cornerRadius = 8;
        self.contentView.layer.cornerCurve = kCACornerCurveContinuous;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.layer.borderWidth = 1;
        self.contentView.layer.borderColor = [JFTheme cardBorder].CGColor;

        _gradient = [CAGradientLayer layer];
        _gradient.startPoint = CGPointMake(0, 0);
        _gradient.endPoint = CGPointMake(1, 1);
        [self.contentView.layer insertSublayer:_gradient atIndex:0];

        _iconWell = [[UIView alloc] init];
        _iconWell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
        _iconWell.layer.cornerRadius = 8;
        _iconWell.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_iconWell];

        _iconView = [[UIImageView alloc] init];
        _iconView.tintColor = UIColor.whiteColor;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [_iconWell addSubview:_iconView];

        _groupLabel = [[UILabel alloc] init];
        _groupLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        _groupLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.72];
        _groupLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_groupLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.numberOfLines = 1;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.78;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _subtitleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.76];
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_subtitleLabel];

        _playersLabel = [[UILabel alloc] init];
        _playersLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _playersLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        _playersLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_playersLabel];

        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        chevron.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:chevron];

        [NSLayoutConstraint activateConstraints:@[
            [_iconWell.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_iconWell.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_iconWell.widthAnchor constraintEqualToConstant:42],
            [_iconWell.heightAnchor constraintEqualToConstant:42],

            [_iconView.centerXAnchor constraintEqualToAnchor:_iconWell.centerXAnchor],
            [_iconView.centerYAnchor constraintEqualToAnchor:_iconWell.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:23],
            [_iconView.heightAnchor constraintEqualToConstant:23],

            [_groupLabel.centerYAnchor constraintEqualToAnchor:_iconWell.centerYAnchor],
            [_groupLabel.leadingAnchor constraintEqualToAnchor:_iconWell.trailingAnchor constant:8],
            [_groupLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-10],

            [_titleLabel.topAnchor constraintEqualToAnchor:_iconWell.bottomAnchor constant:11],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],

            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],

            [_playersLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_playersLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],

            [chevron.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [chevron.centerYAnchor constraintEqualToAnchor:_playersLabel.centerYAnchor],
            [chevron.widthAnchor constraintEqualToConstant:8],
            [chevron.heightAnchor constraintEqualToConstant:13],
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradient.frame = self.contentView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.transform = CGAffineTransformIdentity;
    self.alpha = 1;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity;
        self.contentView.alpha = highlighted ? 0.82 : 1.0;
    }];
}

- (void)configureWithItem:(JFCardCollectionItem *)item index:(NSInteger)index {
    NSArray<UIColor *> *colors = [JFTheme gradientColorsForIndex:index + (item.group == JFCardCollectionGroupParty ? 0 : 4)];
    self.gradient.colors = @[
        (__bridge id)[colors[0] colorWithAlphaComponent:0.86].CGColor,
        (__bridge id)[colors[1] colorWithAlphaComponent:0.58].CGColor,
        (__bridge id)[[JFTheme backgroundSecondary] colorWithAlphaComponent:0.96].CGColor,
    ];
    self.iconView.image = [UIImage systemImageNamed:item.symbol];
    self.groupLabel.text = item.group == JFCardCollectionGroupParty ? @"派对桌" : @"策略桌";
    self.titleLabel.text = item.title;
    self.subtitleLabel.text = item.subtitle;
    self.playersLabel.text = item.players;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@，%@，%@", item.title, item.subtitle, item.players];
}

@end

@interface JFCardCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UISegmentedControl *filterControl;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<JFCardCollectionItem *> *allItems;
@property (nonatomic, copy) NSArray<JFCardCollectionItem *> *visibleItems;
@end

@implementation JFCardCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"纸牌游乐场";
    self.allItems = [self buildItems];
    self.visibleItems = self.allItems;
    [self buildUI];
}

- (NSArray<JFCardCollectionItem *> *)buildItems {
    NSMutableArray<JFCardCollectionItem *> *items = [NSMutableArray array];
    NSArray<NSDictionary *> *party = @[
        @{@"title": @"小姐牌", @"subtitle": @"经典身份与全场任务", @"symbol": @"person.crop.circle.badge.questionmark", @"players": @"3-12 人 · 支持联机", @"mode": @(JFCardPartyModeMiss), @"service": @"card-miss", @"deal": @1, @"guide": @"顺时针每轮一人抽牌并执行牌面规则。身份牌与禁令持续到同点数再次出现；冲突时以最新规则为准。"},
        @{@"title": @"大姐牌", @"subtitle": @"主持、带队与同步挑战", @"symbol": @"person.crop.circle.badge.checkmark", @"players": @"3-12 人 · 支持联机", @"mode": @(JFCardPartyModeBigSister), @"service": @"card-sister", @"deal": @1, @"guide": @"抽到 2 的玩家成为大姐并主持当前轮次，下一张 2 出现时交接。其余牌按顺时针执行，完成后再进入下一位。"},
        @{@"title": @"少爷牌", @"subtitle": @"即兴表演与夸张挑战", @"symbol": @"theatermasks.fill", @"players": @"3-10 人 · 支持联机", @"mode": @(JFCardPartyModeYoungMaster), @"service": @"card-master", @"deal": @1, @"guide": @"每轮抽牌者先朗读任务，再在规定时间内完成表演。全员投票是否过关；不过关可扣 1 分或接受一项轻量替代任务。"},
        @{@"title": @"国王指令", @"subtitle": @"每张牌都是一道王令", @"symbol": @"crown.fill", @"players": @"4-12 人 · 支持联机", @"mode": @(JFCardPartyModeKingsOrder), @"service": @"card-king", @"deal": @1, @"guide": @"抽牌者负责宣读并主持王令，涉及多人时先点名再开始。K 可新增一条全场规则，并持续到下一张 K 出现。"},
        @{@"title": @"反应禁令", @"subtitle": @"看牌执行，最慢者接受挑战", @"symbol": @"bolt.fill", @"players": @"3-12 人 · 支持联机", @"mode": @(JFCardPartyModeReaction), @"service": @"card-react", @"deal": @1, @"guide": @"翻牌后所有人立刻按牌面动作响应。主持人确认最后一名或做错者；有争议时本轮作废重发，不连续惩罚同一人。"},
        @{@"title": @"幸运轮抽", @"subtitle": @"轮流累计点数，率先到 30", @"symbol": @"sparkles", @"players": @"2-8 人 · 支持联机", @"mode": @(JFCardPartyModeLuckyDraw), @"service": @"card-lucky", @"deal": @1, @"guide": @"按顺时针轮流抽一张并累计个人分数，A 为 1，J/Q/K 为 10。红牌允许再抽一次，率先达到 30 分者获胜。"},
    ];
    [party enumerateObjectsUsingBlock:^(NSDictionary *row, NSUInteger idx, BOOL *stop) {
        JFCardCollectionItem *item = [JFCardCollectionItem new];
        item.title = row[@"title"]; item.subtitle = row[@"subtitle"]; item.symbol = row[@"symbol"]; item.players = row[@"players"];
        item.serviceType = row[@"service"]; item.ruleGuide = row[@"guide"]; item.recommendedDealCount = [row[@"deal"] integerValue];
        item.group = JFCardCollectionGroupParty; item.mode = [row[@"mode"] integerValue];
        [items addObject:item];
    }];

    NSArray<NSDictionary *> *arcade = @[
        @{@"title": @"高低猜牌", @"subtitle": @"判断下一张更高还是更低", @"symbol": @"arrow.up.arrow.down", @"players": @"单人 / 2-12 人联机", @"mode": @(JFCardArcadeModeHighLow), @"service": @"card-highlow", @"deal": @2, @"guide": @"本机模式连续判断下一张牌高低；联机模式由房主每轮私发两张牌，亮牌后按第二张牌的点数比较排名。"},
        @{@"title": @"二十一点", @"subtitle": @"要牌或停牌，尽量接近 21", @"symbol": @"suit.spade.fill", @"players": @"单人 / 2-12 人联机", @"mode": @(JFCardArcadeModeBlackjack), @"service": @"card-blackjack", @"deal": @2, @"guide": @"A 可计 1 或 11，J/Q/K 计 10。每人先收两张牌，超过 21 点爆牌；未爆牌且最接近 21 点者获胜。"},
        @{@"title": @"金字塔", @"subtitle": @"配对点数 13，拆完整座牌塔", @"symbol": @"triangle.fill", @"players": @"单人 / 多人竞速", @"mode": @(JFCardArcadeModePyramid), @"service": @"card-pyramid", @"deal": @28, @"guide": @"只可操作没有被其他牌压住的明牌，两张点数合计 13 即可消除，K 单独消除。联机时每位玩家收到独立牌组并竞速完成。"},
        @{@"title": @"多人比大小", @"subtitle": @"任意人数，每轮私发后统一亮牌", @"symbol": @"rectangle.split.2x1.fill", @"players": @"2-12 人联机", @"mode": @(JFCardArcadeModeWar), @"service": @"card-war", @"deal": @1, @"guide": @"房主每轮给所有参与者私发一张牌，玩家只能看到自己的牌。全部亮牌后比较点数，A 最大；同点并列获胜。"},
    ];
    [arcade enumerateObjectsUsingBlock:^(NSDictionary *row, NSUInteger idx, BOOL *stop) {
        JFCardCollectionItem *item = [JFCardCollectionItem new];
        item.title = row[@"title"]; item.subtitle = row[@"subtitle"]; item.symbol = row[@"symbol"]; item.players = row[@"players"];
        item.serviceType = row[@"service"]; item.ruleGuide = row[@"guide"]; item.recommendedDealCount = [row[@"deal"] integerValue];
        item.group = JFCardCollectionGroupArcade; item.mode = [row[@"mode"] integerValue];
        [items addObject:item];
    }];
    return items;
}

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"纸牌游乐场";
    self.titleLabel.textColor = [JFTheme textPrimary];
    self.titleLabel.font = [JFTheme fontTitle];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"10 种玩法 · 本机开局与多人联机牌桌";
    self.subtitleLabel.textColor = [JFTheme textSecondary];
    self.subtitleLabel.font = [JFTheme fontCallout];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.subtitleLabel];

    self.filterControl = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"派对", @"策略"]];
    self.filterControl.selectedSegmentIndex = 0;
    self.filterControl.selectedSegmentTintColor = [[JFTheme accent] colorWithAlphaComponent:0.86];
    [self.filterControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [JFTheme textPrimary], NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.filterControl addTarget:self action:@selector(onFilterChanged) forControlEvents:UIControlEventValueChanged];
    self.filterControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.filterControl];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(4, 16, 20, 16);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.collectionView registerClass:JFCardCollectionCell.class forCellWithReuseIdentifier:@"cardMode"];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:64],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-64],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],

        [self.filterControl.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:14],
        [self.filterControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.filterControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.filterControl.heightAnchor constraintEqualToConstant:34],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.filterControl.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)onFilterChanged {
    [JFTheme hapticSelection];
    if (self.filterControl.selectedSegmentIndex == 0) {
        self.visibleItems = self.allItems;
    } else {
        JFCardCollectionGroup group = self.filterControl.selectedSegmentIndex == 1 ? JFCardCollectionGroupParty : JFCardCollectionGroupArcade;
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JFCardCollectionItem *item, NSDictionary *bindings) {
            return item.group == group;
        }];
        self.visibleItems = [self.allItems filteredArrayUsingPredicate:predicate];
    }
    [self.collectionView reloadData];
    [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.adjustedContentInset.top) animated:NO];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.visibleItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JFCardCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cardMode" forIndexPath:indexPath];
    JFCardCollectionItem *item = self.visibleItems[indexPath.item];
    NSInteger sourceIndex = [self.allItems indexOfObjectIdenticalTo:item];
    [cell configureWithItem:item index:sourceIndex == NSNotFound ? indexPath.item : sourceIndex];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = floor((collectionView.bounds.size.width - 16 * 2 - 12) / 2.0);
    return CGSizeMake(width, 164);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JFCardCollectionItem *item = self.visibleItems[indexPath.item];
    [JFTheme hapticImpactMedium];

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:item.title
                                                                  message:item.ruleGuide
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [menu addAction:[UIAlertAction actionWithTitle:@"本机玩法"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        [weakSelf pushLocalGameForItem:item];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"创建联机牌桌"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        [weakSelf pushNetworkGameForItem:item asHost:YES roomCode:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"加入联机牌桌"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        [weakSelf presentJoinPromptForItem:item message:nil];
    }]];
    [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    menu.popoverPresentationController.sourceView = cell ?: collectionView;
    menu.popoverPresentationController.sourceRect = cell ? cell.bounds : CGRectMake(collectionView.bounds.size.width / 2.0, collectionView.bounds.size.height / 2.0, 1, 1);
    [self presentViewController:menu animated:YES completion:nil];
}

- (void)pushLocalGameForItem:(JFCardCollectionItem *)item {
    [[JFAnalyticsTracker shared] trackEvent:@"game_mode_select"
                                  gameKind:JFGameKindCard
                                properties:@{ @"mode": item.serviceType ?: @"card", @"playType": @"local" }];
    UIViewController *destination = nil;
    if (item.group == JFCardCollectionGroupParty) {
        destination = [[CardsGameViewController alloc] initWithPartyMode:(JFCardPartyMode)item.mode];
    } else {
        destination = [[JFCardArcadeViewController alloc] initWithMode:(JFCardArcadeMode)item.mode];
    }
    [self.navigationController pushViewController:destination animated:YES];
}

- (void)pushNetworkGameForItem:(JFCardCollectionItem *)item
                        asHost:(BOOL)asHost
                      roomCode:(NSString * _Nullable)roomCode {
    [[JFAnalyticsTracker shared] trackEvent:@"game_mode_select"
                                  gameKind:JFGameKindCard
                                properties:@{
                                    @"mode": item.serviceType ?: @"card",
                                    @"playType": @"online",
                                    @"role": asHost ? @"host" : @"player",
                                }];
    NSInteger partyMode = item.group == JFCardCollectionGroupParty ? item.mode : -1;
    JFCardNetworkRoomViewController *room =
        [[JFCardNetworkRoomViewController alloc] initWithGameTitle:item.title
                                                       serviceType:item.serviceType
                                                    modeIdentifier:item.serviceType
                                                         ruleGuide:item.ruleGuide
                                              recommendedDealCount:item.recommendedDealCount
                                                         partyMode:partyMode
                                                            asHost:asHost
                                                          roomCode:roomCode];
    [self.navigationController pushViewController:room animated:YES];
}

- (void)presentJoinPromptForItem:(JFCardCollectionItem *)item message:(NSString * _Nullable)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"加入%@", item.title]
                                                                   message:message ?: @"输入房主页面上的 6 位房间码；人数较少时也可以直接加入最近创建的同玩法牌桌。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"例如 A1B2C3";
        textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyJoin;
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"加入最近牌桌"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        [weakSelf pushNetworkGameForItem:item asHost:NO roomCode:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"按房间码加入"
                                             style:UIAlertActionStyleDefault
                                           handler:^(__unused UIAlertAction *action) {
        NSString *code = [[alert.textFields.firstObject.text ?: @""
                           stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
        if (code.length != 6) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf presentJoinPromptForItem:item message:@"房间码固定为 6 位，请检查后重新输入。"];
            });
            return;
        }
        [weakSelf pushNetworkGameForItem:item asHost:NO roomCode:code];
    }]];
    [self presentViewController:alert animated:YES completion:^{
        [alert.textFields.firstObject becomeFirstResponder];
    }];
}

@end
